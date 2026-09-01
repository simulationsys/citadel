import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from src.risk_engine import evaluate
from src.schemas import PestObservation, SensorReading


class RiskEngineTests(unittest.TestCase):
    def test_dry_heat_and_pest_create_explainable_advisories(self):
        reading = SensorReading("node-1", soil_moisture_pct=22, temperature_c=39, humidity_pct=34)
        types = {item.type for item in evaluate(reading, [PestObservation("whitefly", 0.84, 5)])}
        self.assertEqual(types, {"irrigation", "heat", "pest"})

    def test_flood_suppresses_irrigation_advice(self):
        reading = SensorReading("node-1", soil_moisture_pct=10, rainfall_mm=35, water_level_pct=80)
        types = {item.type for item in evaluate(reading)}
        self.assertIn("flood", types)
        self.assertNotIn("irrigation", types)

    def test_low_confidence_pest_is_not_an_alert(self):
        reading = SensorReading("node-1", soil_moisture_pct=50)
        types = {item.type for item in evaluate(reading, [PestObservation("whitefly", 0.2, 9)])}
        self.assertNotIn("pest", types)


if __name__ == "__main__":
    unittest.main()
