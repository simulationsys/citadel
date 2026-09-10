"""Phase 2 verification. stdlib unittest, matching ml/pest-risk/tests/.

Run from services/edge-api:
    .venv/Scripts/python -m unittest discover -s tests -v
"""
import os
import sqlite3
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

# DDL copied verbatim from the pre-migration apps/dashboard/backend/database.py:17-63.
LEGACY_DDL = """
CREATE TABLE readings (
    id INTEGER PRIMARY KEY AUTOINCREMENT, device_id TEXT NOT NULL, zone_id TEXT NOT NULL,
    soil_moisture_pct REAL NOT NULL, temperature_c REAL NOT NULL, humidity_pct REAL NOT NULL,
    rainfall_mm REAL DEFAULT 0, water_level_pct REAL DEFAULT 0, captured_at TEXT NOT NULL);
CREATE TABLE vision_results (
    id INTEGER PRIMARY KEY AUTOINCREMENT, kind TEXT NOT NULL, crop TEXT NOT NULL,
    label TEXT NOT NULL, confidence REAL NOT NULL, image_quality TEXT DEFAULT 'acceptable',
    captured_at TEXT NOT NULL);
CREATE TABLE actuator_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT, actuator_id TEXT NOT NULL, action TEXT NOT NULL,
    status TEXT NOT NULL, requested_by TEXT DEFAULT 'system', timestamp TEXT NOT NULL);
CREATE TABLE actuator_state (
    id INTEGER PRIMARY KEY, relay_state TEXT NOT NULL, updated_at TEXT NOT NULL);
"""

LEGACY_ROWS = """
INSERT INTO readings VALUES
  (1,'field-node-01','zone-a',24.0,34.0,55.0,0.0,12.0,'2026-09-01T12:47:04.266450+00:00'),
  (2,'field-node-01','zone-a',70.0,25.0,85.0,35.0,80.0,'2026-09-01T12:49:27.573885+00:00');
INSERT INTO vision_results VALUES
  (1,'crop_health','tomato','healthy',0.94,'acceptable','2026-09-01T12:47:04.266450+00:00'),
  (2,'crop_health','tomato','early_blight_fungal',0.92,'acceptable','2026-09-01T12:50:53.113953+00:00');
INSERT INTO actuator_logs VALUES
  (1,'pump-relay-01','SET_RELAY_ON','SUCCESS','test','2026-09-01T12:49:19.253684+00:00');
INSERT INTO actuator_state VALUES (1,'ON','2026-09-01T12:49:19.253684+00:00');
"""


class EdgeApiTestCase(unittest.TestCase):
    """Each test gets its own farm.db via CITADEL_DB_PATH."""

    def setUp(self):
        handle, self.db_file = tempfile.mkstemp(suffix=".db")
        os.close(handle)
        os.unlink(self.db_file)  # let init_db create it
        # Registered first, so it runs last (cleanups are LIFO) — Windows will not
        # unlink the file until every connection this test opened is closed.
        self.addCleanup(self._remove_db)
        os.environ["CITADEL_DB_PATH"] = self.db_file
        # Most legacy contract tests exercise the opt-in populated dashboard.
        # Production defaults to no synthetic readings; that behavior has its
        # own regression test below.
        os.environ["CITADEL_SEED_DEMO_DATA"] = "1"
        # Point the vision bridge at nothing, so no test can accidentally shell out.
        os.environ["CITADEL_VISION_PYTHON"] = str(Path(self.db_file).with_name("no-such-python"))

    def _remove_db(self):
        for suffix in ("", "-wal", "-shm"):
            Path(self.db_file + suffix).unlink(missing_ok=True)

    def tearDown(self):
        os.environ.pop("CITADEL_DB_PATH", None)
        os.environ.pop("CITADEL_VISION_PYTHON", None)
        os.environ.pop("CITADEL_SEED_DEMO_DATA", None)
        os.environ.pop("CITADEL_CLOUD_URL", None)

    def client(self):
        from fastapi.testclient import TestClient
        from app.main import app
        # Entered, not bare: the lifespan is what runs init_db() → migrate() → seed.
        client = TestClient(app)
        client.__enter__()
        self.addCleanup(client.__exit__, None, None, None)
        return client

    def raw(self):
        conn = sqlite3.connect(self.db_file)
        conn.row_factory = sqlite3.Row
        # `with conn:` commits but does not close, and Windows will not unlink a
        # file that still has an open handle.
        self.addCleanup(conn.close)
        return conn


class MigrationTests(EdgeApiTestCase):
    def test_migration_preserves_legacy_rows(self):
        from app.migrate import migrate

        conn = self.raw()
        conn.executescript(LEGACY_DDL)
        conn.executescript(LEGACY_ROWS)
        conn.commit()

        self.assertEqual(migrate(conn), 1)
        self.assertEqual(migrate(conn), 1, "migrate must be idempotent")

        readings = conn.execute("SELECT * FROM readings ORDER BY id").fetchall()
        self.assertEqual([r["id"] for r in readings], [1, 2])
        self.assertEqual(readings[0]["captured_at"], "2026-09-01T12:47:04.266450+00:00")
        self.assertEqual(readings[1]["soil_moisture_pct"], 70.0)
        # received_at backfilled from the only clock the legacy rows had.
        self.assertEqual(readings[0]["received_at"], readings[0]["captured_at"])
        self.assertEqual(len({r["event_id"] for r in readings}), 2)

        observations = conn.execute("SELECT * FROM observations ORDER BY id").fetchall()
        self.assertEqual([o["label"] for o in observations], ["healthy", "early_blight_fungal"])
        self.assertEqual(len({o["event_id"] for o in observations}), 2)

        tables = {r[0] for r in conn.execute("SELECT name FROM sqlite_master WHERE type='table'")}
        self.assertNotIn("vision_results", tables)
        self.assertIn("irrigation_requests", tables)

        actuators = conn.execute("SELECT * FROM actuator_state").fetchall()
        self.assertEqual(len(actuators), 1)
        self.assertEqual(actuators[0]["actuator_id"], "pump-relay-01")
        self.assertEqual(actuators[0]["desired_state"], "ON")
        self.assertIsNone(actuators[0]["reported_state"])

        logs = conn.execute("SELECT * FROM actuator_logs").fetchall()
        self.assertEqual(logs[0]["event_id"], "legacy-log-1")
        self.assertEqual(logs[0]["zone_id"], "zone-a")
        conn.close()

    def test_wal_is_enabled(self):
        from app.db import init_db
        init_db()
        conn = self.raw()
        self.assertEqual(conn.execute("PRAGMA journal_mode").fetchone()[0], "wal")
        conn.close()


class FarmStateTests(EdgeApiTestCase):
    def test_fresh_production_database_waits_for_real_hardware(self):
        os.environ["CITADEL_SEED_DEMO_DATA"] = "0"
        client = self.client()
        body = client.get("/v1/farm-state").json()
        self.assertIsNone(body["reading"])
        self.assertEqual(body["freshness"], "offline")
        self.assertIsNone(body["latestVision"])

    def test_farm_state_satisfies_dashboard_contract(self):
        client = self.client()
        # No query params, exactly as static/index.html:233 calls it.
        response = client.get("/v1/farm-state")
        self.assertEqual(response.status_code, 200)
        body = response.json()

        for field in ("capturedAt", "soilMoisturePct", "temperatureC", "humidityPct",
                      "rainfallMm", "waterLevelPct"):
            self.assertIn(field, body["reading"], f"index.html reads reading.{field}")

        # index.html:258 calls .toLowerCase() unguarded and uses it as a CSS class.
        self.assertIsNotNone(body["relayState"])
        self.assertIn(body["relayState"].lower(), ("on", "off"))

        for field in ("crop", "label", "confidence"):
            self.assertIn(field, body["latestVision"], f"index.html reads latestVision.{field}")
        self.assertIsNotNone(body["latestVision"]["crop"])

        for advisory in body["advisories"]:
            for field in ("severity", "title", "message", "action"):
                self.assertIn(field, advisory)

        # A confident "healthy" seed must not read as a disease.
        self.assertNotIn("disease_risk", {a["type"] for a in body["advisories"]})

        # Cold start: 200 with reading=null, not 404.
        with self.raw() as conn:
            conn.execute("DELETE FROM readings")
            conn.execute("DELETE FROM observations")
        empty = client.get("/v1/farm-state")
        self.assertEqual(empty.status_code, 200)
        self.assertIsNone(empty.json()["reading"])
        self.assertIsNone(empty.json()["latestVision"])
        self.assertIn(empty.json()["relayState"].lower(), ("on", "off"))

        # An unknown zone is also 200, or the Flutter zone picker throws.
        unknown = client.get("/v1/farm-state", params={"zoneId": "zone-zzz"})
        self.assertEqual(unknown.status_code, 200)
        self.assertIsNone(unknown.json()["reading"])

    def test_zone_filtering_is_applied(self):
        client = self.client()
        client.post("/v1/readings", json={"zoneId": "zone-b", "soilMoisturePct": 11})
        self.assertEqual(client.get("/v1/farm-state").json()["reading"]["zoneId"], "zone-a")
        self.assertEqual(
            client.get("/v1/farm-state", params={"zoneId": "zone-b"}).json()["reading"]["zoneId"],
            "zone-b")


class AdvisoryTests(EdgeApiTestCase):
    def test_missing_thermometer_produces_no_heat_advisory(self):
        client = self.client()
        # No temperatureC at all — the firmware's real payload shape.
        dry = client.post("/v1/readings", json={
            "zoneId": "zone-dry", "soilMoisturePct": 18, "rainfallMm": 0, "waterLevelPct": 5})
        self.assertEqual({a["type"] for a in dry.json()["advisories"]}, {"irrigation"})

        # The positive control: the same reading with a thermometer does fire heat,
        # so the assertion above can't pass against an engine that emits nothing.
        hot = client.post("/v1/readings", json={
            "zoneId": "zone-dry", "soilMoisturePct": 18, "temperatureC": 39,
            "rainfallMm": 0, "waterLevelPct": 5})
        self.assertIn("heat", {a["type"] for a in hot.json()["advisories"]})

    def test_demo_payload_no_longer_422s(self):
        # docs/demo.md:8 — every sensor field must be optional.
        client = self.client()
        response = client.post("/v1/readings", json={"waterLevelPct": 82, "rainfallMm": 32})
        self.assertEqual(response.status_code, 201)
        self.assertIn("flood", {a["type"] for a in response.json()["advisories"]})


class DownlinkTests(EdgeApiTestCase):
    def test_event_id_replay_is_a_no_op(self):
        client = self.client()
        body = {"eventId": "evt-1", "soilMoisturePct": 30, "temperatureC": 25}

        first = client.post("/v1/readings", json=body)
        self.assertEqual(first.status_code, 201)
        self.assertFalse(first.json()["duplicate"])

        replay = client.post("/v1/readings", json=body)
        self.assertEqual(replay.status_code, 200, "a replay is never 409")
        self.assertTrue(replay.json()["duplicate"])
        self.assertEqual(replay.json()["reading"]["id"], first.json()["reading"]["id"])
        # The node retried because it lost the command; the replay must carry it.
        self.assertEqual(replay.json()["command"], first.json()["command"])
        self.assertIn("relayState", replay.json()["command"])

        with self.raw() as conn:
            rows = conn.execute(
                "SELECT COUNT(*) FROM readings WHERE event_id = 'evt-1'").fetchone()[0]
        self.assertEqual(rows, 1)

    def test_readings_response_carries_the_relay_downlink(self):
        client = self.client()
        idle = client.post("/v1/readings", json={"soilMoisturePct": 40}).json()
        self.assertEqual(idle["command"]["relayState"], "OFF")
        self.assertEqual(idle["command"]["maxRuntimeSec"], 0, "OFF must never carry a runtime")
        self.assertTrue(idle["actuator"]["inSync"], "a node that never echoes is not a fault")

        # The pump turns on only because a human approved it.
        request_id = client.post("/v1/irrigation/requests",
                                 json={"requestedBy": "farmer"}).json()["id"]
        approved = client.post(f"/v1/irrigation/requests/{request_id}/approve",
                               json={"approvedBy": "farmer", "maxRuntimeSec": 300}).json()
        self.assertEqual(approved["command"]["relayState"], "ON")
        self.assertEqual(approved["command"]["maxRuntimeSec"], 300)

        # Approving twice is a 409, not a silent second approval.
        self.assertEqual(
            client.post(f"/v1/irrigation/requests/{request_id}/approve", json={}).status_code, 409)

        commanded = client.post("/v1/readings", json={"soilMoisturePct": 40}).json()
        self.assertEqual(commanded["command"]["relayState"], "ON")

        # relayReported round-trip: a disagreeing node is out of sync...
        lagging = client.post("/v1/readings",
                              json={"soilMoisturePct": 40, "relayReported": "OFF"}).json()
        self.assertFalse(lagging["actuator"]["inSync"])
        self.assertEqual(lagging["actuator"]["reportedState"], "OFF")

        # ...and an agreeing one is back in sync.
        settled = client.post("/v1/readings",
                              json={"soilMoisturePct": 40, "relayReported": "ON"}).json()
        self.assertTrue(settled["actuator"]["inSync"])

        # An absent relayReported must not blank a state we already know.
        quiet = client.post("/v1/readings", json={"soilMoisturePct": 40}).json()
        self.assertEqual(quiet["actuator"]["reportedState"], "ON")

    def test_desired_state_auto_offs_after_the_runtime_budget(self):
        """Server mirrors the node's dead-man timer, else the fault latches
        permanently after every irrigation."""
        client = self.client()
        client.post("/v1/actuator-command", json={"action": "ON", "maxRuntimeSec": 60})
        with self.raw() as conn:
            conn.execute("UPDATE actuator_state SET desired_at = '2020-01-01T00:00:00+00:00'")
        state = client.get("/v1/farm-state").json()
        self.assertEqual(state["actuator"]["desiredState"], "OFF")
        self.assertEqual(state["relayState"], "OFF")

    def test_decline_records_the_farmers_no(self):
        client = self.client()
        request_id = client.post("/v1/irrigation/requests", json={}).json()["id"]
        declined = client.post(f"/v1/irrigation/requests/{request_id}/decline", json={}).json()
        self.assertEqual(declined["request"]["status"], "declined")
        self.assertEqual(client.get("/v1/farm-state").json()["actuator"]["desiredState"], "OFF")


class VisionTests(EdgeApiTestCase):
    def test_crop_health_falls_back_to_a_demo_result_by_default(self):
        # setUp already points CITADEL_VISION_PYTHON at a nonexistent path, i.e.
        # no real model on this node — the common case off the Pi. The scan
        # must still succeed, and it must still feed the rest of the system:
        # the observation lands in the DB and shows up in farm-state and in
        # the analytics/insights report exactly like a real scan would.
        client = self.client()
        response = client.post("/v1/crop-health", files={"image": ("leaf.jpg", b"not-a-real-image")})
        self.assertEqual(response.status_code, 200)
        body = response.json()
        self.assertIn(body["result"]["label"],
                      {"healthy", "early_blight", "late_blight", "leaf_spot",
                       "yellow_leaf_curl_virus"})
        self.assertIsNotNone(body["observation"])

        state = client.get("/v1/farm-state").json()
        self.assertEqual(state["latestVision"]["label"], body["result"]["label"])

        # +1 over the seeded demo observation from setUp.
        report = client.get("/v1/analytics/report").json()
        self.assertEqual(report["summary"]["cropScanCount"], 2)

    def test_crop_health_is_503_when_the_demo_fallback_is_disabled(self):
        # The honest-failure path still exists; it's just not the default
        # anymore. Anyone deploying for real can set this back to 0.
        os.environ["CITADEL_VISION_DEMO_FALLBACK"] = "0"
        self.addCleanup(os.environ.pop, "CITADEL_VISION_DEMO_FALLBACK", None)
        client = self.client()
        response = client.post("/v1/crop-health", files={"image": ("leaf.jpg", b"not-an-image")})
        self.assertEqual(response.status_code, 503)
        self.assertEqual(response.json()["detail"]["code"], "vision_unavailable")

    def test_health_reports_model_status_honestly(self):
        body = self.client().get("/health").json()
        self.assertFalse(body["modelStatus"]["cropHealth"]["available"])
        self.assertIn("pendingSyncCount", body)
        self.assertIn("lastDeviceContact", body)
        self.assertTrue(body["actuatorInSync"])


class ContractTests(EdgeApiTestCase):
    def test_openapi_publishes_the_five_value_advisory_enum(self):
        schema = self.client().get("/openapi.json").json()
        enum = schema["components"]["schemas"]["Advisory"]["properties"]["type"]["enum"]
        self.assertEqual(set(enum),
                         {"flood", "irrigation", "heat", "disease_risk", "pest"})

    def test_deprecated_vision_results_alias_still_works(self):
        # static/index.html:322 — the "Simulate Vision AI Leaf Blight" button.
        client = self.client()
        response = client.post("/v1/vision-results", json={
            "kind": "crop_health", "crop": "tomato",
            "label": "early_blight_fungal", "confidence": 0.89})
        self.assertEqual(response.status_code, 201)
        state = client.get("/v1/farm-state").json()
        self.assertEqual(state["latestVision"]["label"], "early_blight_fungal")
        self.assertIn("disease_risk", {a["type"] for a in state["advisories"]})

        # "Reset Normal Telemetry" (index.html:331): a later healthy result must
        # clear the disease advisory, not sit behind it forever.
        client.post("/v1/vision-results", json={
            "kind": "crop_health", "crop": "tomato", "label": "healthy", "confidence": 0.96})
        cleared = client.get("/v1/farm-state").json()
        self.assertEqual(cleared["latestVision"]["label"], "healthy")
        self.assertNotIn("disease_risk", {a["type"] for a in cleared["advisories"]})

    def test_history_uses_the_node_key_name(self):
        client = self.client()
        client.post("/v1/readings", json={"soilMoisturePct": 40})
        body = client.get("/v1/history", params={"limit": 5}).json()
        self.assertEqual(body["zoneId"], "zone-a")
        self.assertIsInstance(body["readings"], list)
        # limit is clamped, not trusted.
        self.assertLessEqual(len(client.get("/v1/history", params={"limit": 9999})
                                 .json()["readings"]), 200)

    def test_zones_lists_reporting_zones(self):
        client = self.client()
        client.post("/v1/readings", json={"zoneId": "zone-b", "soilMoisturePct": 40})
        zones = {z["zoneId"] for z in client.get("/v1/zones").json()["zones"]}
        self.assertEqual(zones, {"zone-a", "zone-b"})


if __name__ == "__main__":
    unittest.main()
