import sys
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from fastapi.testclient import TestClient
from src.api import app


class ApiTests(unittest.TestCase):
    def setUp(self):
        self.client = TestClient(app)
        self.reading = {
            "deviceId": "node-1",
            "zoneId": "zone-a",
            "soilMoisturePct": 22,
            "temperatureC": 39,
            "humidityPct": 35,
            "rainfallMm": 0,
            "waterLevelPct": 8,
        }

    def test_health_is_available_without_a_model(self):
        response = self.client.get("/health")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["model"], "not_ready")

    def test_risk_endpoint_returns_sensor_and_pest_advisories(self):
        response = self.client.post("/v1/risk/evaluate", json={"reading": self.reading, "pests": [{"label": "whitefly", "confidence": 0.9, "count": 4}]})
        self.assertEqual(response.status_code, 200)
        self.assertEqual({item["type"] for item in response.json()["advisories"]}, {"irrigation", "heat", "pest"})

    def test_image_endpoint_is_explicit_when_model_is_unavailable(self):
        response = self.client.post("/v1/pest/analyze", json={"imageBase64": "aGVsbG8="})
        self.assertEqual(response.status_code, 503)
        self.assertEqual(response.json()["detail"]["code"], "model_not_ready")

    def test_crop_endpoint_rejects_malformed_base64_before_loading_model(self):
        response = self.client.post("/v1/crop-health/analyze", json={"imageBase64": "not-base64!"})
        self.assertEqual(response.status_code, 422)
        self.assertEqual(response.json()["detail"]["code"], "invalid_image")

    def test_crop_endpoint_returns_stable_result_contract(self):
        expected = {"kind": "crop_health", "crop": "tomato", "label": "healthy", "confidence": 0.91,
                    "imageQuality": "acceptable", "limitation": None, "modelVersion": "v1.1.0", "latencyMs": 3.2}

        class FakeClassifier:
            def analyze_bytes(self, value):
                self.value = value
                return expected

        with patch("src.api.crop_classifier", return_value=FakeClassifier()):
            response = self.client.post("/v1/crop-health/analyze", json={"imageBase64": "aGVsbG8="})
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["result"], expected)


if __name__ == "__main__":
    unittest.main()
