import sqlite3
import os
from datetime import datetime, timezone

DB_PATH = os.path.join(os.path.dirname(os.path.dirname(__file__)), "farm.db")

def get_db():
    conn = sqlite3.connect(DB_PATH, check_same_thread=False)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    conn = get_db()
    cursor = conn.cursor()
    
    # Readings table
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS readings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            device_id TEXT NOT NULL,
            zone_id TEXT NOT NULL,
            soil_moisture_pct REAL NOT NULL,
            temperature_c REAL NOT NULL,
            humidity_pct REAL NOT NULL,
            rainfall_mm REAL DEFAULT 0,
            water_level_pct REAL DEFAULT 0,
            captured_at TEXT NOT NULL
        )
    """)
    
    # Vision results table
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS vision_results (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            kind TEXT NOT NULL,
            crop TEXT NOT NULL,
            label TEXT NOT NULL,
            confidence REAL NOT NULL,
            image_quality TEXT DEFAULT 'acceptable',
            captured_at TEXT NOT NULL
        )
    """)
    
    # Actuator audit logs table
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS actuator_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            actuator_id TEXT NOT NULL,
            action TEXT NOT NULL,
            status TEXT NOT NULL,
            requested_by TEXT DEFAULT 'system',
            timestamp TEXT NOT NULL
        )
    """)
    
    # Actuator state (relay state) table
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS actuator_state (
            id INTEGER PRIMARY KEY,
            relay_state TEXT NOT NULL,
            updated_at TEXT NOT NULL
        )
    """)
    
    conn.commit()

    # Seed initial reading if database is empty
    cursor.execute("SELECT COUNT(*) as count FROM readings")
    if cursor.fetchone()["count"] == 0:
        now = datetime.now(timezone.utc).isoformat()
        cursor.execute("""
            INSERT INTO readings (device_id, zone_id, soil_moisture_pct, temperature_c, humidity_pct, rainfall_mm, water_level_pct, captured_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """, ('field-node-01', 'zone-a', 24.0, 34.0, 55.0, 0.0, 12.0, now))
        
        cursor.execute("""
            INSERT INTO actuator_state (id, relay_state, updated_at)
            VALUES (1, 'OFF', ?)
        """, (now,))
        
        cursor.execute("""
            INSERT INTO vision_results (kind, crop, label, confidence, image_quality, captured_at)
            VALUES ('crop_health', 'tomato', 'healthy', 0.94, 'acceptable', ?)
        """, (now,))
        
        conn.commit()
    conn.close()

def save_reading(data: dict):
    conn = get_db()
    cursor = conn.cursor()
    now = data.get("capturedAt") or datetime.now(timezone.utc).isoformat()
    cursor.execute("""
        INSERT INTO readings (device_id, zone_id, soil_moisture_pct, temperature_c, humidity_pct, rainfall_mm, water_level_pct, captured_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    """, (
        data.get("deviceId", "field-node-01"),
        data.get("zoneId", "zone-a"),
        float(data.get("soilMoisturePct", 24)),
        float(data.get("temperatureC", 34)),
        float(data.get("humidityPct", 55)),
        float(data.get("rainfallMm", 0)),
        float(data.get("waterLevelPct", 0)),
        now
    ))
    conn.commit()
    reading_id = cursor.lastrowid
    cursor.execute("SELECT * FROM readings WHERE id = ?", (reading_id,))
    row = dict(cursor.fetchone())
    conn.close()
    return format_reading(row)

def save_vision_result(data: dict):
    conn = get_db()
    cursor = conn.cursor()
    now = data.get("capturedAt") or datetime.now(timezone.utc).isoformat()
    cursor.execute("""
        INSERT INTO vision_results (kind, crop, label, confidence, image_quality, captured_at)
        VALUES (?, ?, ?, ?, ?, ?)
    """, (
        data.get("kind", "crop_health"),
        data.get("crop", "tomato"),
        data.get("label", "healthy"),
        float(data.get("confidence", 0.9)),
        data.get("imageQuality", "acceptable"),
        now
    ))
    conn.commit()
    result_id = cursor.lastrowid
    cursor.execute("SELECT * FROM vision_results WHERE id = ?", (result_id,))
    row = dict(cursor.fetchone())
    conn.close()
    return format_vision(row)

def get_latest_reading():
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM readings ORDER BY id DESC LIMIT 1")
    row = cursor.fetchone()
    conn.close()
    if row:
        return format_reading(dict(row))
    return None

def get_latest_vision():
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM vision_results ORDER BY id DESC LIMIT 1")
    row = cursor.fetchone()
    conn.close()
    if row:
        return format_vision(dict(row))
    return None

def get_relay_state():
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT relay_state FROM actuator_state WHERE id = 1")
    row = cursor.fetchone()
    conn.close()
    return row["relay_state"] if row else "OFF"

def update_relay_state(state: str, requested_by: str = "user"):
    conn = get_db()
    cursor = conn.cursor()
    now = datetime.now(timezone.utc).isoformat()
    cursor.execute("INSERT OR REPLACE INTO actuator_state (id, relay_state, updated_at) VALUES (1, ?, ?)", (state, now))
    cursor.execute("""
        INSERT INTO actuator_logs (actuator_id, action, status, requested_by, timestamp)
        VALUES (?, ?, ?, ?, ?)
    """, ("pump-relay-01", f"SET_RELAY_{state}", "SUCCESS", requested_by, now))
    conn.commit()
    conn.close()
    return {"relayState": state, "updatedAt": now}

def get_readings_history(limit: int = 20):
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM readings ORDER BY id DESC LIMIT ?", (limit,))
    rows = cursor.fetchall()
    conn.close()
    return [format_reading(dict(r)) for r in reversed(rows)]

def format_reading(r: dict) -> dict:
    return {
        "id": r["id"],
        "deviceId": r["device_id"],
        "zoneId": r["zone_id"],
        "soilMoisturePct": r["soil_moisture_pct"],
        "temperatureC": r["temperature_c"],
        "humidityPct": r["humidity_pct"],
        "rainfallMm": r["rainfall_mm"],
        "waterLevelPct": r["water_level_pct"],
        "capturedAt": r["captured_at"]
    }

def format_vision(v: dict) -> dict:
    return {
        "id": v["id"],
        "kind": v["kind"],
        "crop": v["crop"],
        "label": v["label"],
        "confidence": v["confidence"],
        "imageQuality": v["image_quality"],
        "capturedAt": v["captured_at"]
    }
