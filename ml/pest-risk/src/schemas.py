"""Small, dependency-free contracts shared by pest detection and risk evaluation."""
from __future__ import annotations

from dataclasses import asdict, dataclass
from typing import Literal

Severity = Literal["info", "warning", "critical"]


@dataclass(frozen=True)
class SensorReading:
    device_id: str
    zone_id: str = "zone-a"
    # Positional defaults unchanged so existing tests keep passing.
    # None means the sensor was absent or failed — never treat as 0.
    soil_moisture_pct: float | None = 0.0
    temperature_c: float | None = None
    humidity_pct: float | None = None
    rainfall_mm: float = 0.0
    water_level_pct: float = 0.0

    @classmethod
    def from_dict(cls, value: dict) -> "SensorReading":
        def optional(key: str, default=None):
            raw = value.get(key, default)
            return None if raw is None else float(raw)

        reading = cls(
            device_id=str(value["deviceId"]),
            zone_id=str(value.get("zoneId", "zone-a")),
            soil_moisture_pct=optional("soilMoisturePct", 0.0),
            temperature_c=optional("temperatureC"),
            humidity_pct=optional("humidityPct"),
            # An explicit null means the same as an absent key: these two default
            # to 0 because the firmware genuinely defaults them, and 0 rainfall /
            # 0 water level can never raise a false flood alert.
            rainfall_mm=float(value.get("rainfallMm") or 0),
            water_level_pct=float(value.get("waterLevelPct") or 0),
        )
        for field_name in ("soil_moisture_pct", "humidity_pct", "water_level_pct"):
            v = getattr(reading, field_name)
            if v is not None and not 0 <= v <= 100:
                raise ValueError(f"{field_name} must be between 0 and 100")
        if reading.rainfall_mm < 0:
            raise ValueError("rainfall_mm cannot be negative")
        return reading


@dataclass(frozen=True)
class PestObservation:
    label: str
    confidence: float
    count: int = 1
    # crop_health observations reuse this dataclass with label = crop class name.
    crop_health: bool = False

    @classmethod
    def from_dict(cls, value: dict) -> "PestObservation":
        observation = cls(
            label=str(value["label"]),
            confidence=float(value["confidence"]),
            count=int(value.get("count", 1)),
            crop_health=bool(value.get("cropHealth", False)),
        )
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
