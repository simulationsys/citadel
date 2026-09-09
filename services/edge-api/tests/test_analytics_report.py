"""Local analytics report contract."""
from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
sys.path.insert(0, str(Path(__file__).resolve().parent))

from test_edge_api import EdgeApiTestCase  # noqa: E402


class AnalyticsReportTests(EdgeApiTestCase):
    def setUp(self):
        super().setUp()
        # Reports in these tests contain only explicitly posted field data.
        import os
        os.environ["CITADEL_SEED_DEMO_DATA"] = "0"

    def test_empty_report_is_honest_and_actionable(self):
        report = self.client().get(
            "/v1/analytics/report", params={"zoneId": "zone-a", "hours": 24}
        )
        self.assertEqual(report.status_code, 200)
        body = report.json()
        self.assertEqual(body["mode"], "local-edge-analysis")
        self.assertEqual(body["summary"]["readingCount"], 0)
        self.assertEqual(body["metrics"]["temperatureC"]["trend"], "unavailable")
        self.assertEqual(body["recommendations"][0]["title"], "Reconnect the field node")

    def test_report_aggregates_real_readings_scans_and_irrigation(self):
        client = self.client()
        samples = [
            {"eventId": "report-1", "zoneId": "zone-a", "soilMoisturePct": 20,
             "temperatureC": 39, "humidityPct": 65, "rainfallMm": 0,
             "waterLevelPct": 15},
            {"eventId": "report-2", "zoneId": "zone-a", "soilMoisturePct": 30,
             "temperatureC": 35, "humidityPct": 70, "rainfallMm": 2,
             "waterLevelPct": 20},
            {"eventId": "report-3", "zoneId": "zone-a", "soilMoisturePct": 45,
             "temperatureC": 31, "humidityPct": 72, "rainfallMm": 1,
             "waterLevelPct": 25},
        ]
        for sample in samples:
            self.assertEqual(client.post("/v1/readings", json=sample).status_code, 201)
        client.post("/v1/observations", json={
            "eventId": "scan-1", "zoneId": "zone-a", "kind": "crop_health",
            "crop": "tomato", "label": "early_blight", "confidence": 0.91,
        })
        request_id = client.post("/v1/irrigation/requests", json={
            "zoneId": "zone-a", "requestedBy": "farmer-app"
        }).json()["id"]
        client.post(f"/v1/irrigation/requests/{request_id}/approve", json={})

        body = client.get("/v1/analytics/report", params={"zoneId": "zone-a"}).json()
        self.assertEqual(body["summary"]["readingCount"], 3)
        self.assertEqual(body["summary"]["dataCompletenessPct"], 100.0)
        self.assertEqual(body["summary"]["cropScanCount"], 1)
        self.assertEqual(body["summary"]["approvedIrrigationCount"], 1)
        self.assertEqual(body["metrics"]["soilMoisturePct"]["minimum"], 20.0)
        self.assertEqual(body["metrics"]["soilMoisturePct"]["maximum"], 45.0)
        self.assertEqual(body["metrics"]["rainfallMm"]["average"], 1.0)
        self.assertEqual(body["cropHealth"]["latest"]["label"], "early_blight")
        self.assertIn("irrigation", body["risks"])
        self.assertTrue(any(item["title"] == "Inspect affected leaves"
                            for item in body["recommendations"]))

    def test_report_is_zone_scoped_and_validates_period(self):
        client = self.client()
        client.post("/v1/readings", json={"eventId": "a", "zoneId": "zone-a",
                                          "temperatureC": 20})
        client.post("/v1/readings", json={"eventId": "b", "zoneId": "zone-b",
                                          "temperatureC": 40})
        body = client.get("/v1/analytics/report", params={"zoneId": "zone-b"}).json()
        self.assertEqual(body["summary"]["readingCount"], 1)
        self.assertEqual(body["metrics"]["temperatureC"]["average"], 40.0)
        self.assertEqual(client.get("/v1/analytics/report", params={"hours": 0}).status_code, 422)


if __name__ == "__main__":
    import unittest
    unittest.main()
