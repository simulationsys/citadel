"""SQLite access for the edge API.

Module-level functions, not Depends-injected connections: for a single-writer
SQLite file that buys nothing, and the Phase 4 cloud-push task has no request
scope and would need a second path.
"""
from __future__ import annotations

import os
import sqlite3
import uuid
from contextlib import contextmanager
from datetime import datetime, timezone
from pathlib import Path

from .migrate import migrate

# Dead-man switch default: the 15 minutes the old advisory text already promised.
MAX_RUNTIME_SEC = int(os.getenv("CITADEL_MAX_RUNTIME_SEC", "900"))
# The server does not know the node's reporting interval, so the fault window is
# configurable rather than "two intervals".
FAULT_SLACK_SEC = int(os.getenv("CITADEL_ACTUATOR_FAULT_SECONDS", "35"))

DEFAULT_ZONE = "zone-a"
DEFAULT_DEVICE = "field-node-01"


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def _parse(ts: str | None) -> datetime | None:
    try:
        return datetime.fromisoformat(ts) if ts else None
    except ValueError:  # a device clock can send anything
        return None


def age_seconds(ts: str | None) -> float | None:
    parsed = _parse(ts)
    if parsed is None:
        return None
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=timezone.utc)
    return (datetime.now(timezone.utc) - parsed).total_seconds()


def db_path() -> Path:
    """A function, not a constant, so tests can point CITADEL_DB_PATH at a temp file."""
    return Path(os.getenv("CITADEL_DB_PATH")
                or Path(__file__).resolve().parents[1] / "farm.db")


@contextmanager
def db():
    conn = sqlite3.connect(db_path(), check_same_thread=False, timeout=5.0)
    conn.row_factory = sqlite3.Row
    try:
        yield conn
        conn.commit()
    except BaseException:
        conn.rollback()
        raise
    finally:
        conn.close()


def init_db() -> None:
    with db() as conn:
        # WAL is a no-op inside a transaction, so it goes here and not in migrate().
        conn.execute("PRAGMA journal_mode=WAL")
        migrate(conn)
        # Real deployments must wait for the field node. Plausible seed values
        # make a disconnected system look healthy and undermine the hardware
        # demo. Synthetic state is available only through an explicit demo flag.
        if os.getenv("CITADEL_SEED_DEMO_DATA", "0").lower() in {"1", "true", "yes"}:
            seed_if_empty(conn)


def seed_if_empty(conn: sqlite3.Connection) -> None:
    """Populate explicit demo mode. Never called by the default runtime."""
    if conn.execute("SELECT COUNT(*) FROM readings").fetchone()[0]:
        return
    now = now_iso()
    conn.execute(
        "INSERT INTO readings (event_id, device_id, zone_id, soil_moisture_pct,"
        " temperature_c, humidity_pct, rainfall_mm, water_level_pct, captured_at, received_at)"
        " VALUES (?,?,?,?,?,?,?,?,?,?)",
        (f"seed-{uuid.uuid4()}", DEFAULT_DEVICE, DEFAULT_ZONE, 24.0, 34.0, 55.0, 0.0, 12.0, now, now),
    )
    reading_id = conn.execute("SELECT last_insert_rowid()").fetchone()[0]
    conn.execute(
        "INSERT INTO observations (event_id, kind, zone_id, crop, label, confidence,"
        " image_quality, reading_id, captured_at, received_at) VALUES (?,?,?,?,?,?,?,?,?,?)",
        (f"seed-{uuid.uuid4()}", "crop_health", DEFAULT_ZONE, "tomato", "healthy", 0.94,
         "acceptable", reading_id, now, now),
    )
    conn.execute(
        "INSERT INTO actuator_state (actuator_id, zone_id, desired_state, desired_at)"
        " VALUES (?,?,?,?)",
        (actuator_id_for(DEFAULT_ZONE), DEFAULT_ZONE, "OFF", now),
    )


# --------------------------------------------------------------------------
# readings
# --------------------------------------------------------------------------

_SENSORS = ("soilMoisturePct", "temperatureC", "humidityPct", "rainfallMm", "waterLevelPct")


def save_reading(data: dict) -> tuple[dict, bool]:
    """Returns (reading, duplicate). An absent eventId gets a server-side uuid4
    and never deduplicates; a present one that collides returns the stored row.

    A replay is never an error: the node retried because it *lost the response*,
    and rejecting it leaves the relay never learning its commanded state.
    """
    event_id = str(data.get("eventId") or f"srv-{uuid.uuid4()}")
    received = now_iso()
    captured = data.get("capturedAt") or received
    values = (
        event_id,
        str(data.get("deviceId") or DEFAULT_DEVICE),
        str(data.get("zoneId") or DEFAULT_ZONE),
        data.get("soilMoisturePct"), data.get("temperatureC"), data.get("humidityPct"),
        data.get("rainfallMm"), data.get("waterLevelPct"),
        data.get("relayReported"),
        captured, received,
    )
    with db() as conn:
        try:
            conn.execute(
                "INSERT INTO readings (event_id, device_id, zone_id, soil_moisture_pct,"
                " temperature_c, humidity_pct, rainfall_mm, water_level_pct, relay_reported,"
                " captured_at, received_at) VALUES (?,?,?,?,?,?,?,?,?,?,?)",
                values,
            )
            duplicate = False
        except sqlite3.IntegrityError:
            duplicate = True
        row = conn.execute("SELECT * FROM readings WHERE event_id = ?", (event_id,)).fetchone()
    return format_reading(dict(row)), duplicate


def get_latest_reading(zone_id: str = DEFAULT_ZONE, conn: sqlite3.Connection | None = None):
    sql = "SELECT * FROM readings WHERE zone_id = ? ORDER BY id DESC LIMIT 1"
    if conn is not None:
        row = conn.execute(sql, (zone_id,)).fetchone()
        return format_reading(dict(row)) if row else None
    with db() as own:
        row = own.execute(sql, (zone_id,)).fetchone()
    return format_reading(dict(row)) if row else None


def get_readings_history(zone_id: str = DEFAULT_ZONE, limit: int = 20) -> list[dict]:
    limit = max(1, min(int(limit), 200))
    with db() as conn:
        rows = conn.execute(
            "SELECT * FROM readings WHERE zone_id = ? ORDER BY id DESC LIMIT ?",
            (zone_id, limit),
        ).fetchall()
    return [format_reading(dict(r)) for r in reversed(rows)]


def get_zones() -> list[dict]:
    with db() as conn:
        rows = conn.execute(
            "SELECT zone_id, COUNT(*) AS n, MAX(received_at) AS last FROM readings"
            " GROUP BY zone_id ORDER BY zone_id"
        ).fetchall()
    return [{"zoneId": r["zone_id"], "readingCount": r["n"], "lastReadingAt": r["last"]}
            for r in rows]


# --------------------------------------------------------------------------
# observations
# --------------------------------------------------------------------------

def save_observation(data: dict) -> dict:
    received = now_iso()
    zone_id = str(data.get("zoneId") or DEFAULT_ZONE)
    with db() as conn:
        # Stitch the observation to the environmental conditions at capture time.
        latest = conn.execute(
            "SELECT id FROM readings WHERE zone_id = ? ORDER BY id DESC LIMIT 1", (zone_id,)
        ).fetchone()
        event_id = str(data.get("eventId") or f"srv-{uuid.uuid4()}")
        try:
            conn.execute(
                "INSERT INTO observations (event_id, kind, zone_id, crop, label, confidence,"
                " count, image_quality, limitation, reading_id, captured_at, received_at)"
                " VALUES (?,?,?,?,?,?,?,?,?,?,?,?)",
                (event_id, str(data.get("kind") or "crop_health"), zone_id, data.get("crop"),
                 str(data["label"]), float(data["confidence"]), int(data.get("count", 1) or 1),
                 data.get("imageQuality"), data.get("limitation"),
                 latest["id"] if latest else None,
                 data.get("capturedAt") or received, received),
            )
        except sqlite3.IntegrityError:
            pass
        row = conn.execute("SELECT * FROM observations WHERE event_id = ?", (event_id,)).fetchone()
    return format_observation(dict(row))


def get_observations(zone_id: str = DEFAULT_ZONE, limit: int = 10) -> list[dict]:
    with db() as conn:
        rows = conn.execute(
            "SELECT * FROM observations WHERE zone_id = ? ORDER BY id DESC LIMIT ?",
            (zone_id, limit),
        ).fetchall()
    return [format_observation(dict(r)) for r in rows]


def get_latest_vision(zone_id: str = DEFAULT_ZONE):
    """The dashboard's `latestVision` field — newest crop_health observation."""
    with db() as conn:
        row = conn.execute(
            "SELECT * FROM observations WHERE zone_id = ? AND kind = 'crop_health'"
            " ORDER BY id DESC LIMIT 1", (zone_id,)
        ).fetchone()
    return format_vision(dict(row)) if row else None


# --------------------------------------------------------------------------
# actuator
# --------------------------------------------------------------------------

def actuator_id_for(zone_id: str) -> str:
    # zone-a keeps the historical id so migrated audit logs still join.
    return "pump-relay-01" if zone_id == DEFAULT_ZONE else f"pump-{zone_id}"


def reconcile(conn: sqlite3.Connection, zone_id: str, relay_reported: str | None = None) -> dict:
    """The single place desired/reported state is settled. Every read and write
    path calls it, so no caller can forget the auto-OFF."""
    row = conn.execute("SELECT * FROM actuator_state WHERE zone_id = ?", (zone_id,)).fetchone()
    if row is None:
        conn.execute(
            "INSERT INTO actuator_state (actuator_id, zone_id, desired_state, desired_at)"
            " VALUES (?,?,?,?)", (actuator_id_for(zone_id), zone_id, "OFF", now_iso()))
        row = conn.execute("SELECT * FROM actuator_state WHERE zone_id = ?", (zone_id,)).fetchone()

    state = dict(row)

    # Mirror the node's dead-man timer. Without this, `reported` goes OFF when the
    # node's lease expires while `desired` is still ON — a permanent phantom fault
    # after every single irrigation.
    if state["desired_state"] == "ON":
        age = age_seconds(state["desired_at"])
        budget = (state["max_runtime_sec"] or MAX_RUNTIME_SEC) + FAULT_SLACK_SEC
        if age is not None and age > budget:
            conn.execute(
                "UPDATE actuator_state SET desired_state='OFF', desired_at=?, max_runtime_sec=NULL"
                " WHERE zone_id=?", (now_iso(), zone_id))
            log_actuator(conn, state["actuator_id"], zone_id, "SET_RELAY_OFF", "auto-runtime-limit")
            state = dict(conn.execute(
                "SELECT * FROM actuator_state WHERE zone_id = ?", (zone_id,)).fetchone())

    # Write reported_state only when the node actually said something: an absent
    # field must not blank a state we already know.
    if relay_reported:
        conn.execute(
            "UPDATE actuator_state SET reported_state=?, reported_at=? WHERE zone_id=?",
            (str(relay_reported).upper(), now_iso(), zone_id))
        state = dict(conn.execute(
            "SELECT * FROM actuator_state WHERE zone_id = ?", (zone_id,)).fetchone())

    return state


def set_desired_state(conn: sqlite3.Connection, zone_id: str, state: str,
                      requested_by: str, max_runtime_sec: int | None = None) -> dict:
    row = reconcile(conn, zone_id)
    runtime = None
    if state == "ON" and max_runtime_sec:
        runtime = max(60, min(int(max_runtime_sec), 3600))  # the farmer's number, bounded
    conn.execute(
        "UPDATE actuator_state SET desired_state=?, desired_at=?, max_runtime_sec=? WHERE zone_id=?",
        (state, now_iso(), runtime, zone_id))
    log_actuator(conn, row["actuator_id"], zone_id, f"SET_RELAY_{state}", requested_by)
    return dict(conn.execute("SELECT * FROM actuator_state WHERE zone_id = ?", (zone_id,)).fetchone())


def desired_command(state: dict) -> dict:
    """The downlink that rides the POST /v1/readings response."""
    on = state["desired_state"] == "ON"
    return {
        "actuatorId": state["actuator_id"],
        "relayState": state["desired_state"],
        # 0 when OFF; the node refuses an unbounded ON, which is the flood.
        "maxRuntimeSec": (state["max_runtime_sec"] or MAX_RUNTIME_SEC) if on else 0,
    }


def in_sync(state: dict) -> bool:
    # NULL counts as in sync: today's firmware never echoes, and treating that as
    # a fault would show a permanent red light on every deployment.
    return state["reported_state"] is None or state["reported_state"] == state["desired_state"]


def log_actuator(conn: sqlite3.Connection, actuator_id: str, zone_id: str,
                 action: str, requested_by: str, status: str = "SUCCESS") -> None:
    conn.execute(
        "INSERT INTO actuator_logs (event_id, actuator_id, zone_id, action, status,"
        " requested_by, timestamp) VALUES (?,?,?,?,?,?,?)",
        (f"log-{uuid.uuid4()}", actuator_id, zone_id, action, status, requested_by, now_iso()))


# --------------------------------------------------------------------------
# irrigation requests
# --------------------------------------------------------------------------

def create_irrigation_request(zone_id: str, requested_by: str,
                              max_runtime_sec: int | None = None) -> dict:
    request = {
        "id": f"irrigation-{uuid.uuid4()}",
        "zone_id": zone_id,
        "requested_by": requested_by,
        "status": "pending",
        "approved_by": None,
        "created_at": now_iso(),
        "approved_at": None,
        "max_runtime_sec": max_runtime_sec,
    }
    with db() as conn:
        conn.execute(
            "INSERT INTO irrigation_requests (id, zone_id, requested_by, status, created_at,"
            " max_runtime_sec) VALUES (?,?,?,?,?,?)",
            (request["id"], zone_id, requested_by, "pending", request["created_at"],
             max_runtime_sec))
    return format_irrigation_request(request)


def get_irrigation_request(conn: sqlite3.Connection, request_id: str):
    return conn.execute("SELECT * FROM irrigation_requests WHERE id = ?", (request_id,)).fetchone()


def pending_irrigation_requests(zone_id: str) -> list[dict]:
    with db() as conn:
        rows = conn.execute(
            "SELECT * FROM irrigation_requests WHERE zone_id = ? AND status = 'pending'"
            " ORDER BY created_at DESC LIMIT 10", (zone_id,)).fetchall()
    return [format_irrigation_request(dict(r)) for r in rows]


def pending_sync_count() -> int:
    with db() as conn:
        return sum(conn.execute(f"SELECT COUNT(*) FROM {t} WHERE synced_at IS NULL").fetchone()[0]
                   for t in ("readings", "observations", "irrigation_requests", "actuator_logs"))


# --------------------------------------------------------------------------
# mappers — camelCase on purpose: format_reading emits exactly the keys
# citadel_pest_risk.SensorReading.from_dict consumes. A free adapter; don't
# build a translation layer between them.
# --------------------------------------------------------------------------

def format_reading(r: dict) -> dict:
    return {
        "id": r["id"],
        "eventId": r["event_id"],
        "deviceId": r["device_id"],
        "zoneId": r["zone_id"],
        "soilMoisturePct": r["soil_moisture_pct"],
        "temperatureC": r["temperature_c"],
        "humidityPct": r["humidity_pct"],
        "rainfallMm": r["rainfall_mm"],
        "waterLevelPct": r["water_level_pct"],
        "relayReported": r["relay_reported"],
        "capturedAt": r["captured_at"],
        "receivedAt": r["received_at"],
    }


def format_observation(o: dict) -> dict:
    return {
        "id": o["id"],
        "eventId": o["event_id"],
        "kind": o["kind"],
        "zoneId": o["zone_id"],
        "crop": o["crop"],
        "label": o["label"],
        "confidence": o["confidence"],
        "count": o["count"],
        "imageQuality": o["image_quality"],
        "limitation": o["limitation"],
        "readingId": o["reading_id"],
        "capturedAt": o["captured_at"],
        "receivedAt": o["received_at"],
    }


def format_vision(o: dict) -> dict:
    """Deprecated `latestVision` shape. Sole consumer: static/index.html:262-264,
    which writes `crop` straight into textContent — hence the coalesce."""
    return {
        "id": o["id"],
        "kind": o["kind"],
        "crop": o["crop"] or "unknown",
        "label": o["label"],
        "confidence": o["confidence"],
        "imageQuality": o["image_quality"] or "acceptable",
        "capturedAt": o["captured_at"],
    }


def format_actuator(state: dict) -> dict:
    return {
        "actuatorId": state["actuator_id"],
        "zoneId": state["zone_id"],
        "desiredState": state["desired_state"],
        "reportedState": state["reported_state"],
        "desiredAt": state["desired_at"],
        "reportedAt": state["reported_at"],
        "maxRuntimeSec": state["max_runtime_sec"],
        "inSync": in_sync(state),
    }


def format_irrigation_request(r: dict) -> dict:
    return {
        "id": r["id"],
        "zoneId": r["zone_id"],
        "requestedBy": r["requested_by"],
        "status": r["status"],
        "approvedBy": r["approved_by"],
        "createdAt": r["created_at"],
        "approvedAt": r["approved_at"],
        "maxRuntimeSec": r["max_runtime_sec"],
    }


def format_actuator_log(l: dict) -> dict:
    return {
        "id": l["id"],
        "eventId": l["event_id"],
        "actuatorId": l["actuator_id"],
        "zoneId": l["zone_id"],
        "action": l["action"],
        "status": l["status"],
        "requestedBy": l["requested_by"],
        "timestamp": l["timestamp"],
    }


def get_pending_sync_records(limit: int = 50) -> dict:
    """Fetch un-synced records across all tables, oldest first."""
    with db() as conn:
        readings = [
            format_reading(dict(r))
            for r in conn.execute(
                "SELECT * FROM readings WHERE synced_at IS NULL ORDER BY id ASC LIMIT ?", (limit,)
            ).fetchall()
        ]
        observations = [
            format_observation(dict(o))
            for o in conn.execute(
                "SELECT * FROM observations WHERE synced_at IS NULL ORDER BY id ASC LIMIT ?", (limit,)
            ).fetchall()
        ]
        irrigation_requests = [
            format_irrigation_request(dict(req))
            for req in conn.execute(
                "SELECT * FROM irrigation_requests WHERE synced_at IS NULL ORDER BY created_at ASC LIMIT ?", (limit,)
            ).fetchall()
        ]
        actuator_logs = [
            format_actuator_log(dict(log))
            for log in conn.execute(
                "SELECT * FROM actuator_logs WHERE synced_at IS NULL ORDER BY id ASC LIMIT ?", (limit,)
            ).fetchall()
        ]
    return {
        "readings": readings,
        "observations": observations,
        "irrigationRequests": irrigation_requests,
        "actuatorLogs": actuator_logs,
    }


def mark_records_synced(accepted_ids: list[str]) -> int:
    """Stamp synced_at on successfully synced records (matching event_id or request id)."""
    if not accepted_ids:
        return 0
    synced_time = now_iso()
    placeholders = ",".join("?" for _ in accepted_ids)
    count = 0
    with db() as conn:
        cur1 = conn.execute(
            f"UPDATE readings SET synced_at = ? WHERE event_id IN ({placeholders}) AND synced_at IS NULL",
            [synced_time, *accepted_ids],
        )
        cur2 = conn.execute(
            f"UPDATE observations SET synced_at = ? WHERE event_id IN ({placeholders}) AND synced_at IS NULL",
            [synced_time, *accepted_ids],
        )
        cur3 = conn.execute(
            f"UPDATE irrigation_requests SET synced_at = ? WHERE id IN ({placeholders}) AND synced_at IS NULL",
            [synced_time, *accepted_ids],
        )
        cur4 = conn.execute(
            f"UPDATE actuator_logs SET synced_at = ? WHERE event_id IN ({placeholders}) AND synced_at IS NULL",
            [synced_time, *accepted_ids],
        )
        count = cur1.rowcount + cur2.rowcount + cur3.rowcount + cur4.rowcount
    return count

