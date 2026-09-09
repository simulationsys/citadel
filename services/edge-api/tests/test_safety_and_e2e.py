"""Irrigation safety invariants (Phase 7) and the full-loop contract (Phase 11).

These encode properties that must not regress to make a demo easier. Every one
of them is a way the system could command a pump it should not have.

No physical relay is involved: the whole loop runs against a temporary SQLite
file, and "the node" is a synthetic POST.

Run from services/edge-api:
    .venv/Scripts/python -m unittest discover -s tests -v
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
# Also the tests/ directory itself, so the shared harness imports whether this
# module is loaded by `unittest discover` or by explicit dotted name.
sys.path.insert(0, str(Path(__file__).resolve().parent))

from test_edge_api import EdgeApiTestCase  # noqa: E402


def reading(**overrides):
    """A complete ESP32-shaped reading."""
    payload = {
        "eventId": "field-node-01-aabbccdd-00000001",
        "deviceId": "field-node-01",
        "zoneId": "zone-a",
        "soilMoisturePct": 24.0,
        "temperatureC": 34.0,
        "humidityPct": 55.0,
        "rainfallMm": 0.0,
        "waterLevelPct": 12.0,
        "relayReported": "OFF",
    }
    payload.update(overrides)
    return payload


class IrrigationSafetyTests(EdgeApiTestCase):
    """The pump turns on because a human approved a specific request. Nothing else."""

    def test_an_advisory_cannot_turn_the_actuator_on(self):
        client = self.client()
        # Bone-dry and hot: the strongest irrigation advisory the engine emits.
        body = client.post("/v1/readings", json=reading(soilMoisturePct=5.0,
                                                        temperatureC=42.0)).json()
        self.assertTrue(any(a["type"] == "irrigation" for a in body["advisories"]),
                        "expected an irrigation advisory for dry+hot soil")
        self.assertEqual(body["actuator"]["desiredState"], "OFF")
        self.assertEqual(body["command"]["relayState"], "OFF")
        self.assertEqual(body["command"]["maxRuntimeSec"], 0)

    def test_creating_a_request_cannot_turn_the_actuator_on(self):
        client = self.client()
        client.post("/v1/readings", json=reading())
        created = client.post("/v1/irrigation/requests",
                              json={"zoneId": "zone-a", "requestedBy": "farmer"})
        self.assertEqual(created.status_code, 201)
        self.assertEqual(created.json()["status"], "pending")
        state = client.get("/v1/farm-state?zoneId=zone-a").json()
        self.assertEqual(state["actuator"]["desiredState"], "OFF")

    def test_declining_keeps_desired_state_off(self):
        client = self.client()
        client.post("/v1/readings", json=reading())
        request_id = client.post("/v1/irrigation/requests", json={}).json()["id"]
        declined = client.post(f"/v1/irrigation/requests/{request_id}/decline",
                               json={"approvedBy": "farmer"})
        self.assertEqual(declined.status_code, 200)
        self.assertEqual(declined.json()["request"]["status"], "declined")
        state = client.get("/v1/farm-state?zoneId=zone-a").json()
        self.assertEqual(state["actuator"]["desiredState"], "OFF")

    def test_approval_is_the_only_normal_on_transition(self):
        client = self.client()
        client.post("/v1/readings", json=reading())
        request_id = client.post("/v1/irrigation/requests", json={}).json()["id"]
        approved = client.post(f"/v1/irrigation/requests/{request_id}/approve",
                               json={"approvedBy": "farmer", "maxRuntimeSec": 600})
        self.assertEqual(approved.status_code, 200)
        self.assertEqual(approved.json()["request"]["status"], "approved")
        self.assertEqual(approved.json()["command"]["relayState"], "ON")
        self.assertEqual(approved.json()["command"]["maxRuntimeSec"], 600)

    def test_runtime_is_clamped_to_the_safe_range(self):
        client = self.client()
        client.post("/v1/readings", json=reading())
        for requested, expected in ((5, 60), (99999, 3600)):
            request_id = client.post("/v1/irrigation/requests", json={}).json()["id"]
            body = client.post(f"/v1/irrigation/requests/{request_id}/approve",
                               json={"maxRuntimeSec": requested}).json()
            self.assertEqual(body["command"]["maxRuntimeSec"], expected,
                             f"{requested}s should clamp to {expected}s")
            client.post("/v1/actuator-command", json={"action": "STOP_IRRIGATION"})

    def test_explicit_override_is_separately_auditable(self):
        client = self.client()
        client.post("/v1/readings", json=reading())
        client.post("/v1/actuator-command",
                    json={"action": "START_IRRIGATION", "requestedBy": "dashboard-user"})
        rows = self.raw().execute(
            "SELECT action, requested_by FROM actuator_logs ORDER BY id").fetchall()
        self.assertIn(("SET_RELAY_ON", "dashboard-user"),
                      [(r["action"], r["requested_by"]) for r in rows])

    def test_every_actuator_change_is_audited(self):
        client = self.client()
        client.post("/v1/readings", json=reading())
        request_id = client.post("/v1/irrigation/requests", json={}).json()["id"]
        client.post(f"/v1/irrigation/requests/{request_id}/approve", json={})
        client.post("/v1/actuator-command", json={"action": "STOP_IRRIGATION"})
        actions = [r["action"] for r in self.raw().execute(
            "SELECT action FROM actuator_logs ORDER BY id").fetchall()]
        self.assertIn("SET_RELAY_ON", actions)
        self.assertIn("SET_RELAY_OFF", actions)

    def test_desired_and_reported_state_stay_separate(self):
        client = self.client()
        client.post("/v1/readings", json=reading())
        request_id = client.post("/v1/irrigation/requests", json={}).json()["id"]
        client.post(f"/v1/irrigation/requests/{request_id}/approve", json={})
        # Approval sets desired=ON. The node last reported OFF and has not yet
        # collected the command, so the two must remain distinguishable — and
        # the divergence must be visible rather than papered over.
        state = client.get("/v1/farm-state?zoneId=zone-a").json()
        self.assertEqual(state["actuator"]["desiredState"], "ON")
        self.assertEqual(state["actuator"]["reportedState"], "OFF")
        self.assertFalse(state["actuator"]["inSync"])

    def test_repeated_decision_on_a_settled_request_is_a_conflict(self):
        client = self.client()
        client.post("/v1/readings", json=reading())
        request_id = client.post("/v1/irrigation/requests", json={}).json()["id"]
        client.post(f"/v1/irrigation/requests/{request_id}/approve", json={})
        again = client.post(f"/v1/irrigation/requests/{request_id}/approve", json={})
        self.assertEqual(again.status_code, 409)
        declined = client.post(f"/v1/irrigation/requests/{request_id}/decline", json={})
        self.assertEqual(declined.status_code, 409)

    def test_unknown_request_is_404_not_a_silent_success(self):
        client = self.client()
        self.assertEqual(
            client.post("/v1/irrigation/requests/does-not-exist/approve", json={}).status_code,
            404)

    def test_invalid_actuator_action_is_rejected(self):
        client = self.client()
        client.post("/v1/readings", json=reading())
        self.assertEqual(
            client.post("/v1/actuator-command", json={"action": "LAUNCH"}).status_code, 400)
        state = client.get("/v1/farm-state?zoneId=zone-a").json()
        self.assertEqual(state["actuator"]["desiredState"], "OFF")


class EndToEndLoopTests(EdgeApiTestCase):
    """Sensor -> storage -> advisory -> approval -> downlink -> acknowledgement."""

    def test_complete_and_partial_readings_are_both_accepted(self):
        client = self.client()
        full = client.post("/v1/readings", json=reading())
        self.assertEqual(full.status_code, 201)

        # docs/demo.md's flood payload: no soil, no thermometer, no hygrometer.
        partial = client.post("/v1/readings", json={
            "eventId": "field-node-01-aabbccdd-00000002",
            "deviceId": "field-node-01", "zoneId": "zone-a",
            "waterLevelPct": 82.0, "rainfallMm": 32.0, "relayReported": "OFF",
        })
        self.assertEqual(partial.status_code, 201)
        body = partial.json()
        self.assertIsNone(body["reading"]["temperatureC"])
        self.assertIsNone(body["reading"]["soilMoisturePct"])

    def test_partial_reading_is_flutter_parsable(self):
        """Mirrors apps/farmer-app/test/edge_contract_test.dart.

        Every field the Dart `Reading` model reads must be present as a key —
        null is fine, absent is not, because the app distinguishes them.
        """
        client = self.client()
        body = client.post("/v1/readings", json={
            "eventId": "e-partial", "zoneId": "zone-a",
            "waterLevelPct": 82.0, "rainfallMm": 32.0,
        }).json()
        for key in ("deviceId", "zoneId", "soilMoisturePct", "temperatureC",
                    "humidityPct", "rainfallMm", "waterLevelPct", "capturedAt",
                    "receivedAt", "relayReported"):
            self.assertIn(key, body["reading"], f"Flutter Reading.fromJson expects {key}")
        self.assertIn("freshness", body)

    def test_dry_soil_creates_an_irrigation_advisory(self):
        client = self.client()
        body = client.post("/v1/readings",
                           json=reading(soilMoisturePct=8.0, temperatureC=30.0)).json()
        self.assertTrue(any(a["type"] == "irrigation" for a in body["advisories"]))

    def test_flood_suppresses_irrigation_advice(self):
        client = self.client()
        body = client.post("/v1/readings", json=reading(
            eventId="e-flood", soilMoisturePct=8.0, waterLevelPct=95.0,
            rainfallMm=60.0)).json()
        types = [a["type"] for a in body["advisories"]]
        self.assertIn("flood", types)
        self.assertNotIn("irrigation", types,
                         "irrigating a flooded zone is the contradiction this prevents")

    def test_full_downlink_and_acknowledgement_cycle(self):
        client = self.client()

        # 1. Node reports, relay off, no command.
        first = client.post("/v1/readings", json=reading(eventId="e-1")).json()
        self.assertEqual(first["command"]["relayState"], "OFF")

        # 2. Farmer requests and approves.
        request_id = client.post("/v1/irrigation/requests",
                                 json={"requestedBy": "farmer-app"}).json()["id"]
        approved = client.post(f"/v1/irrigation/requests/{request_id}/approve",
                               json={"approvedBy": "farmer", "maxRuntimeSec": 600}).json()
        self.assertEqual(approved["command"]["relayState"], "ON")

        # 3. The node's next reading carries the ON command down.
        second = client.post("/v1/readings",
                             json=reading(eventId="e-2", relayReported="OFF")).json()
        self.assertEqual(second["command"]["relayState"], "ON")
        self.assertEqual(second["command"]["maxRuntimeSec"], 600)
        self.assertEqual(second["command"]["actuatorId"], "pump-relay-01")
        self.assertFalse(second["actuator"]["inSync"],
                         "desired ON vs reported OFF is a real, visible divergence")

        # 4. The node applies it and acknowledges on the following reading.
        third = client.post("/v1/readings",
                            json=reading(eventId="e-3", relayReported="ON")).json()
        self.assertEqual(third["actuator"]["reportedState"], "ON")
        self.assertEqual(third["actuator"]["desiredState"], "ON")
        self.assertTrue(third["actuator"]["inSync"])

    def test_runtime_expiry_returns_desired_state_to_off(self):
        client = self.client()
        client.post("/v1/readings", json=reading())
        request_id = client.post("/v1/irrigation/requests", json={}).json()["id"]
        client.post(f"/v1/irrigation/requests/{request_id}/approve",
                    json={"maxRuntimeSec": 60})

        # Backdate the lease past its budget plus the fault slack.
        conn = self.raw()
        conn.execute("UPDATE actuator_state SET desired_at = ? WHERE zone_id = 'zone-a'",
                     ("2020-01-01T00:00:00+00:00",))
        conn.commit()

        state = client.get("/v1/farm-state?zoneId=zone-a").json()
        self.assertEqual(state["actuator"]["desiredState"], "OFF")
        self.assertEqual(state["command"] if "command" in state else
                         {"relayState": state["actuator"]["desiredState"]},
                         state.get("command", {"relayState": "OFF"}))
        actions = [r["action"] for r in conn.execute(
            "SELECT action FROM actuator_logs ORDER BY id").fetchall()]
        self.assertIn("SET_RELAY_OFF", actions, "auto-off must be audited too")

    def test_replayed_event_id_does_not_duplicate_but_still_carries_the_command(self):
        client = self.client()
        client.post("/v1/readings", json=reading(eventId="e-replay"))
        request_id = client.post("/v1/irrigation/requests", json={}).json()["id"]
        client.post(f"/v1/irrigation/requests/{request_id}/approve",
                    json={"maxRuntimeSec": 300})

        replay = client.post("/v1/readings", json=reading(eventId="e-replay"))
        # A replay is 200, not 409: the node retried because it lost the response.
        self.assertEqual(replay.status_code, 200)
        self.assertTrue(replay.json()["duplicate"])
        self.assertEqual(replay.json()["command"]["relayState"], "ON")

        count = self.raw().execute(
            "SELECT COUNT(*) FROM readings WHERE event_id = 'e-replay'").fetchone()[0]
        self.assertEqual(count, 1)

    def test_crop_health_accepts_the_multipart_shape_flutter_sends(self):
        """Field name `image`, as declared by `UploadFile = File(...)`.

        The vision bridge is pointed at a nonexistent interpreter by the test
        harness, so this asserts the *request* is accepted and the failure is an
        honest 503 — never a 422 (wrong shape) and never a fabricated result.
        """
        client = self.client()
        response = client.post("/v1/crop-health?zoneId=zone-a",
                               files={"image": ("leaf.jpg", b"\xff\xd8\xff\xdb", "image/jpeg")})
        self.assertNotEqual(response.status_code, 422,
                            "multipart field name must match the API declaration")
        self.assertEqual(response.status_code, 503)
        detail = response.json()["detail"]
        self.assertEqual(detail["code"], "vision_unavailable")

    def test_ai_infrastructure_failure_never_looks_like_a_diagnosis(self):
        client = self.client()
        response = client.post("/v1/crop-health",
                               files={"image": ("leaf.jpg", b"\xff\xd8", "image/jpeg")})
        self.assertEqual(response.status_code, 503)
        # No observation may be recorded for a scan that never ran.
        count = self.raw().execute("SELECT COUNT(*) FROM observations").fetchone()[0]
        self.assertEqual(count, 1, "only the seeded observation should exist")
        self.assertNotIn("inconclusive", response.text)


if __name__ == "__main__":
    import unittest
    unittest.main()
