"""Crop profiles keep Phase 1 thresholds visible and replaceable."""
from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class CropRiskProfile:
    name: str
    irrigation_moisture_pct: float
    heat_temperature_c: float
    heat_moisture_pct: float
    disease_humidity_pct: float
    disease_temperature_c: float
    flood_water_level_pct: float
    flood_rainfall_mm: float
    minimum_pest_confidence: float
    high_pest_count: int


TOMATO_DEMO = CropRiskProfile(
    name="tomato-demo",
    irrigation_moisture_pct=30,
    heat_temperature_c=38,
    heat_moisture_pct=40,
    disease_humidity_pct=85,
    disease_temperature_c=20,
    flood_water_level_pct=75,
    flood_rainfall_mm=30,
    minimum_pest_confidence=0.65,
    high_pest_count=3,
)

PROFILES = {TOMATO_DEMO.name: TOMATO_DEMO}


def get_profile(name: str) -> CropRiskProfile:
    try:
        return PROFILES[name]
    except KeyError as error:
        raise ValueError(f"Unknown crop profile '{name}'. Available: {', '.join(PROFILES)}") from error
