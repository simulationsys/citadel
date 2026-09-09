"""Schema versioning for farm.db.

Detection is `PRAGMA user_version`: a single-writer SQLite file with one linear
migration history needs nothing more. Migrate rather than reseed — farm.db is
gitignored, so a "recreate" destroys the only field data that ever existed.
"""
from __future__ import annotations

import sqlite3

SCHEMA_VERSION = 1

# Target DDL: docs/backend-integration.md §3, plus four additions it omits —
# event_id on actuator_logs (audit sync must be idempotent), max_runtime_sec on
# actuator_state and irrigation_requests ("irrigate for 5 minutes" is otherwise
# unexpressible), and limitation on observations (why a result is weak).
SCHEMA = """
CREATE TABLE IF NOT EXISTS readings (
  id                INTEGER PRIMARY KEY AUTOINCREMENT,
  event_id          TEXT UNIQUE NOT NULL,
  device_id         TEXT NOT NULL,
  zone_id           TEXT NOT NULL,
  soil_moisture_pct REAL,
  temperature_c     REAL,
  humidity_pct      REAL,
  rainfall_mm       REAL,
  water_level_pct   REAL,
  relay_reported    TEXT,
  captured_at       TEXT NOT NULL,
  received_at       TEXT NOT NULL,
  synced_at         TEXT
);
CREATE INDEX IF NOT EXISTS idx_readings_zone_time ON readings(zone_id, received_at DESC);

CREATE TABLE IF NOT EXISTS observations (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  event_id      TEXT UNIQUE NOT NULL,
  kind          TEXT NOT NULL,
  zone_id       TEXT NOT NULL,
  crop          TEXT,
  label         TEXT NOT NULL,
  confidence    REAL NOT NULL,
  count         INTEGER DEFAULT 1,
  image_quality TEXT,
  limitation    TEXT,
  reading_id    INTEGER REFERENCES readings(id),
  captured_at   TEXT NOT NULL,
  received_at   TEXT NOT NULL,
  synced_at     TEXT
);
CREATE INDEX IF NOT EXISTS idx_observations_zone_time ON observations(zone_id, received_at DESC);

CREATE TABLE IF NOT EXISTS actuator_state (
  actuator_id     TEXT PRIMARY KEY,
  zone_id         TEXT NOT NULL,
  desired_state   TEXT NOT NULL,
  reported_state  TEXT,
  desired_at      TEXT NOT NULL,
  reported_at     TEXT,
  max_runtime_sec INTEGER
);

CREATE TABLE IF NOT EXISTS irrigation_requests (
  id              TEXT PRIMARY KEY,
  zone_id         TEXT NOT NULL,
  requested_by    TEXT NOT NULL,
  status          TEXT NOT NULL,
  approved_by     TEXT,
  created_at      TEXT NOT NULL,
  approved_at     TEXT,
  max_runtime_sec INTEGER,
  synced_at       TEXT
);

CREATE TABLE IF NOT EXISTS actuator_logs (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  event_id     TEXT UNIQUE NOT NULL,
  actuator_id  TEXT NOT NULL,
  zone_id      TEXT NOT NULL,
  action       TEXT NOT NULL,
  status       TEXT NOT NULL,
  requested_by TEXT NOT NULL,
  timestamp    TEXT NOT NULL,
  synced_at    TEXT
);
"""


def _tables(conn: sqlite3.Connection) -> set[str]:
    return {r[0] for r in conn.execute("SELECT name FROM sqlite_master WHERE type='table'")}


def _columns(conn: sqlite3.Connection, table: str) -> set[str]:
    return {r[1] for r in conn.execute(f"PRAGMA table_info({table})")}


def _v0_to_v1(conn: sqlite3.Connection) -> None:
    """Legacy (app/db.py's original four tables) or empty → the §3 schema.

    Every step is guarded on sqlite_master, so a fresh database and a migrated
    one converge on byte-identical DDL. The rebuild-copy-rename dance is not
    optional: SQLite cannot drop the NOT NULL on temperature_c/humidity_pct.
    """
    tables = _tables(conn)

    # --- readings ---------------------------------------------------------
    if "readings" in tables and "event_id" not in _columns(conn, "readings"):
        conn.execute("""
            CREATE TABLE readings_new (
              id                INTEGER PRIMARY KEY AUTOINCREMENT,
              event_id          TEXT UNIQUE NOT NULL,
              device_id         TEXT NOT NULL,
              zone_id           TEXT NOT NULL,
              soil_moisture_pct REAL,
              temperature_c     REAL,
              humidity_pct      REAL,
              rainfall_mm       REAL,
              water_level_pct   REAL,
              relay_reported    TEXT,
              captured_at       TEXT NOT NULL,
              received_at       TEXT NOT NULL,
              synced_at         TEXT
            )
        """)
        conn.execute("""
            INSERT INTO readings_new
              (id, event_id, device_id, zone_id, soil_moisture_pct, temperature_c,
               humidity_pct, rainfall_mm, water_level_pct, captured_at, received_at)
            SELECT id, 'legacy-reading-' || id, device_id, zone_id, soil_moisture_pct,
                   temperature_c, humidity_pct, rainfall_mm, water_level_pct,
                   captured_at, captured_at
            FROM readings
        """)
        conn.execute("DROP TABLE readings")
        conn.execute("ALTER TABLE readings_new RENAME TO readings")

    # --- vision_results → observations ------------------------------------
    if "vision_results" in tables:
        conn.executescript(SCHEMA)  # observations must exist before the copy
        conn.execute("""
            INSERT INTO observations
              (event_id, kind, zone_id, crop, label, confidence, image_quality,
               captured_at, received_at)
            SELECT 'legacy-vision-' || id, kind, 'zone-a', crop, label, confidence,
                   image_quality, captured_at, captured_at
            FROM vision_results
        """)
        conn.execute("DROP TABLE vision_results")

    # --- actuator_state: id/relay_state/updated_at → the desired/reported shape
    if "actuator_state" in tables and "desired_state" not in _columns(conn, "actuator_state"):
        legacy = conn.execute(
            "SELECT relay_state, updated_at FROM actuator_state WHERE id = 1"
        ).fetchone()
        conn.execute("DROP TABLE actuator_state")
        conn.executescript(SCHEMA)
        if legacy:
            conn.execute(
                "INSERT INTO actuator_state (actuator_id, zone_id, desired_state, desired_at)"
                " VALUES ('pump-relay-01', 'zone-a', ?, ?)",
                (legacy[0], legacy[1]),
            )

    # --- actuator_logs: rebuilt, not ALTERed, so both paths produce one DDL
    if "actuator_logs" in tables and "event_id" not in _columns(conn, "actuator_logs"):
        conn.execute("""
            CREATE TABLE actuator_logs_new (
              id           INTEGER PRIMARY KEY AUTOINCREMENT,
              event_id     TEXT UNIQUE NOT NULL,
              actuator_id  TEXT NOT NULL,
              zone_id      TEXT NOT NULL,
              action       TEXT NOT NULL,
              status       TEXT NOT NULL,
              requested_by TEXT NOT NULL,
              timestamp    TEXT NOT NULL,
              synced_at    TEXT
            )
        """)
        conn.execute("""
            INSERT INTO actuator_logs_new
              (id, event_id, actuator_id, zone_id, action, status, requested_by, timestamp)
            SELECT id, 'legacy-log-' || id, actuator_id, 'zone-a', action, status,
                   COALESCE(requested_by, 'system'), timestamp
            FROM actuator_logs
        """)
        conn.execute("DROP TABLE actuator_logs")
        conn.execute("ALTER TABLE actuator_logs_new RENAME TO actuator_logs")

    # Creates whatever the guards above did not, including on a fresh database.
    conn.executescript(SCHEMA)


LADDER = {0: _v0_to_v1}


def migrate(conn: sqlite3.Connection) -> int:
    """Run every pending step in one transaction. Idempotent: a DB already at
    SCHEMA_VERSION does no work and touches nothing."""
    version = conn.execute("PRAGMA user_version").fetchone()[0]
    if version >= SCHEMA_VERSION:
        return version
    with conn:  # one transaction: a half-migrated farm.db is worse than none
        while version < SCHEMA_VERSION:
            LADDER[version](conn)
            version += 1
        conn.execute(f"PRAGMA user_version = {version}")
    return version


if __name__ == "__main__":  # smallest runnable check: legacy in, §3 schema out
    legacy_ddl = """
        CREATE TABLE readings (id INTEGER PRIMARY KEY AUTOINCREMENT, device_id TEXT NOT NULL,
          zone_id TEXT NOT NULL, soil_moisture_pct REAL NOT NULL, temperature_c REAL NOT NULL,
          humidity_pct REAL NOT NULL, rainfall_mm REAL DEFAULT 0, water_level_pct REAL DEFAULT 0,
          captured_at TEXT NOT NULL);
        CREATE TABLE vision_results (id INTEGER PRIMARY KEY AUTOINCREMENT, kind TEXT NOT NULL,
          crop TEXT NOT NULL, label TEXT NOT NULL, confidence REAL NOT NULL,
          image_quality TEXT DEFAULT 'acceptable', captured_at TEXT NOT NULL);
        CREATE TABLE actuator_logs (id INTEGER PRIMARY KEY AUTOINCREMENT, actuator_id TEXT NOT NULL,
          action TEXT NOT NULL, status TEXT NOT NULL, requested_by TEXT DEFAULT 'system',
          timestamp TEXT NOT NULL);
        CREATE TABLE actuator_state (id INTEGER PRIMARY KEY, relay_state TEXT NOT NULL,
          updated_at TEXT NOT NULL);
        INSERT INTO readings VALUES (1,'n','zone-a',24,34,55,0,12,'T1');
        INSERT INTO vision_results VALUES (1,'crop_health','tomato','healthy',0.94,'acceptable','T1');
        INSERT INTO actuator_logs VALUES (1,'pump-relay-01','SET_RELAY_ON','SUCCESS','test','T1');
        INSERT INTO actuator_state VALUES (1,'ON','T1');
    """
    c = sqlite3.connect(":memory:")
    c.executescript(legacy_ddl)
    assert migrate(c) == 1
    assert migrate(c) == 1, "migrate must be idempotent"
    assert _tables(c) >= {"readings", "observations", "actuator_state",
                          "irrigation_requests", "actuator_logs"}
    assert "vision_results" not in _tables(c)
    assert c.execute("SELECT event_id, captured_at FROM readings").fetchone() == \
        ("legacy-reading-1", "T1")
    assert c.execute("SELECT actuator_id, desired_state FROM actuator_state").fetchall() == \
        [("pump-relay-01", "ON")]
    assert c.execute("SELECT label FROM observations").fetchone() == ("healthy",)
    print("migrate.py self-check ok")
