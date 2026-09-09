"""SQLite database storage for Citadel Cloud API."""
from __future__ import annotations

import os
import sqlite3
from contextlib import contextmanager
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Tuple

SCHEMA = """
CREATE TABLE IF NOT EXISTS cloud_readings (
  id                INTEGER PRIMARY KEY AUTOINCREMENT,
  farm_id           TEXT NOT NULL,
  event_id          TEXT NOT NULL,
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
  synced_at         TEXT NOT NULL,
  UNIQUE(farm_id, event_id)
);
CREATE INDEX IF NOT EXISTS idx_cloud_readings_farm_zone ON cloud_readings(farm_id, zone_id, received_at DESC);

CREATE TABLE IF NOT EXISTS cloud_observations (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  farm_id       TEXT NOT NULL,
  event_id      TEXT NOT NULL,
  kind          TEXT NOT NULL,
  zone_id       TEXT NOT NULL,
  crop          TEXT,
  label         TEXT NOT NULL,
  confidence    REAL NOT NULL,
  count         INTEGER DEFAULT 1,
  image_quality TEXT,
  limitation    TEXT,
  reading_id    INTEGER,
  captured_at   TEXT NOT NULL,
  received_at   TEXT NOT NULL,
  synced_at     TEXT NOT NULL,
  UNIQUE(farm_id, event_id)
);
CREATE INDEX IF NOT EXISTS idx_cloud_observations_farm_zone ON cloud_observations(farm_id, zone_id, received_at DESC);

CREATE TABLE IF NOT EXISTS cloud_irrigation_requests (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  farm_id         TEXT NOT NULL,
  request_id      TEXT NOT NULL,
  zone_id         TEXT NOT NULL,
  requested_by    TEXT NOT NULL,
  status          TEXT NOT NULL,
  approved_by     TEXT,
  created_at      TEXT NOT NULL,
  approved_at     TEXT,
  max_runtime_sec INTEGER,
  synced_at       TEXT NOT NULL,
  UNIQUE(farm_id, request_id)
);

CREATE TABLE IF NOT EXISTS cloud_actuator_logs (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  farm_id      TEXT NOT NULL,
  event_id     TEXT NOT NULL,
  actuator_id  TEXT NOT NULL,
  zone_id      TEXT NOT NULL,
  action       TEXT NOT NULL,
  status       TEXT NOT NULL,
  requested_by TEXT NOT NULL,
  timestamp    TEXT NOT NULL,
  synced_at    TEXT NOT NULL,
  UNIQUE(farm_id, event_id)
);
"""


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def db_path() -> Path:
    return Path(os.getenv("CITADEL_CLOUD_DB_PATH")
                or Path(__file__).resolve().parents[1] / "cloud.db")


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
        conn.execute("PRAGMA journal_mode = WAL")
        conn.execute("PRAGMA synchronous = NORMAL")
        conn.executescript(SCHEMA)


def ingest_batch(
    farm_id: str,
    readings: List[Dict[str, Any]],
    observations: List[Dict[str, Any]],
    irrigation_requests: List[Dict[str, Any]],
    actuator_logs: List[Dict[str, Any]],
) -> Tuple[List[str], List[str]]:
    """Ingest synced records with INSERT OR IGNORE / ON CONFLICT DO NOTHING.
    
    A row already present is accepted (not rejected) so retried requests
    stop being pushed once confirmed by the cloud.
    """
    accepted: List[str] = []
    rejected: List[str] = []
    synced_time = now_iso()

    with db() as conn:
        # 1. Readings
        for r in readings:
            event_id = r.get("eventId")
            if not event_id:
                rejected.append("unknown-reading")
                continue
            try:
                conn.execute(
                    """
                    INSERT INTO cloud_readings (
                        farm_id, event_id, device_id, zone_id, soil_moisture_pct,
                        temperature_c, humidity_pct, rainfall_mm, water_level_pct,
                        relay_reported, captured_at, received_at, synced_at
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    ON CONFLICT(farm_id, event_id) DO NOTHING
                    """,
                    (
                        farm_id, event_id, r["deviceId"], r["zoneId"],
                        r.get("soilMoisturePct"), r.get("temperatureC"),
                        r.get("humidityPct"), r.get("rainfallMm"),
                        r.get("waterLevelPct"), r.get("relayReported"),
                        r["capturedAt"], r["receivedAt"], synced_time,
                    ),
                )
                accepted.append(event_id)
            except Exception:
                rejected.append(event_id)

        # 2. Observations
        for o in observations:
            event_id = o.get("eventId")
            if not event_id:
                rejected.append("unknown-observation")
                continue
            try:
                conn.execute(
                    """
                    INSERT INTO cloud_observations (
                        farm_id, event_id, kind, zone_id, crop, label, confidence,
                        count, image_quality, limitation, reading_id,
                        captured_at, received_at, synced_at
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    ON CONFLICT(farm_id, event_id) DO NOTHING
                    """,
                    (
                        farm_id, event_id, o["kind"], o["zoneId"], o.get("crop"),
                        o["label"], o["confidence"], o.get("count", 1),
                        o.get("imageQuality"), o.get("limitation"),
                        o.get("readingId"), o["capturedAt"], o["receivedAt"],
                        synced_time,
                    ),
                )
                accepted.append(event_id)
            except Exception:
                rejected.append(event_id)

        # 3. Irrigation requests
        for req in irrigation_requests:
            req_id = req.get("id")
            if not req_id:
                rejected.append("unknown-irrigation-request")
                continue
            try:
                # Update if already exists with new status/approved_at or insert
                conn.execute(
                    """
                    INSERT INTO cloud_irrigation_requests (
                        farm_id, request_id, zone_id, requested_by, status,
                        approved_by, created_at, approved_at, max_runtime_sec, synced_at
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    ON CONFLICT(farm_id, request_id) DO UPDATE SET
                        status = excluded.status,
                        approved_by = excluded.approved_by,
                        approved_at = excluded.approved_at,
                        max_runtime_sec = excluded.max_runtime_sec,
                        synced_at = excluded.synced_at
                    """,
                    (
                        farm_id, req_id, req["zoneId"], req["requestedBy"],
                        req["status"], req.get("approvedBy"), req["createdAt"],
                        req.get("approvedAt"), req.get("maxRuntimeSec"), synced_time,
                    ),
                )
                accepted.append(req_id)
            except Exception:
                rejected.append(req_id)

        # 4. Actuator logs
        for log in actuator_logs:
            event_id = log.get("eventId")
            if not event_id:
                rejected.append("unknown-actuator-log")
                continue
            try:
                conn.execute(
                    """
                    INSERT INTO cloud_actuator_logs (
                        farm_id, event_id, actuator_id, zone_id, action,
                        status, requested_by, timestamp, synced_at
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                    ON CONFLICT(farm_id, event_id) DO NOTHING
                    """,
                    (
                        farm_id, event_id, log["actuatorId"], log["zoneId"],
                        log["action"], log["status"], log["requestedBy"],
                        log["timestamp"], synced_time,
                    ),
                )
                accepted.append(event_id)
            except Exception:
                rejected.append(event_id)

    return accepted, rejected

