"""Small, dependency-free contracts shared by pest detection and risk evaluation."""
from __future__ import annotations

from dataclasses import asdict, dataclass
from typing import Literal

Severity = Literal["info", "warning", "critical"]


@dataclass(frozen=True)
class SensorReading:
    device_id: str
    zone_id: str = "zone-a"
    soil_moisture_pct: float = 0.0
    temperature_c: float = 0.0
    humidity_pct: float = 0.0
    rainfall_mm: float = 0.0
    water_level_pct: float = 0.0

    @classmethod
    def from_dict(cls, value: dict) -> "SensorReading":
        reading = cls(
            device_id=str(value["deviceId"]),
            zone_id=str(value.get("zoneId", "zone-a")),
            soil_moisture_pct=float(value["soilMoisturePct"]),
            temperature_c=float(value["temperatureC"]),
            humidity_pct=float(value["humidityPct"]),
            rainfall_mm=float(value.get("rainfallMm", 0)),
            water_level_pct=float(value.get("waterLevelPct", 0)),
        )
        for field_name in ("soil_moisture_pct", "humidity_pct", "water_level_pct"):
            field_value = getattr(reading, field_name)
            if not 0 <= field_value <= 100:
                raise ValueError(f"{field_name} must be between 0 and 100")
        if reading.rainfall_mm < 0:
            raise ValueError("rainfall_mm cannot be negative")
        return reading


@dataclass(frozen=True)
class PestObservation:
    label: str
    confidence: float
    count: int = 1

    @classmethod
    def from_dict(cls, value: dict) -> "PestObservation":
        observation = cls(label=str(value["label"]), confidence=float(value["confidence"]), count=int(value.get("count", 1)))
        if not 0 <= observation.confidence <= 1:
            raise ValueError("confidence must be between 0 and 1")
        if observation.count < 0:
            raise ValueError("count cannot be negative")
        return observation


@dataclass(frozen=True)
class Advisory:
    type: str
    severity: Severity
    title: str
    message: str
    action: str
    evidence: dict

    def as_api_dict(self) -> dict:
        return asdict(self)
