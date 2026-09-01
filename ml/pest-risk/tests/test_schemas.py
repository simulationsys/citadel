import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from src.schemas import PestObservation, SensorReading


class SchemaTests(unittest.TestCase):
    def test_reading_rejects_invalid_percentages(self):
        with self.assertRaises(ValueError):
            SensorReading.from_dict({"deviceId": "n1", "soilMoisturePct": 101, "temperatureC": 30, "humidityPct": 40})

    def test_pest_rejects_invalid_confidence(self):
        with self.assertRaises(ValueError):
            PestObservation.from_dict({"label": "whitefly", "confidence": 1.1})


if __name__ == "__main__":
    unittest.main()
