"""Explainable Phase 1 risk rules. Keep crop profiles outside rule code as they mature."""
from __future__ import annotations

from .profiles import CropRiskProfile, TOMATO_DEMO
from .schemas import Advisory, PestObservation, SensorReading


def evaluate(reading: SensorReading, pests: list[PestObservation] | None = None, profile: CropRiskProfile = TOMATO_DEMO) -> list[Advisory]:
    advisories: list[Advisory] = []
    evidence = {
        "soilMoisturePct": reading.soil_moisture_pct,
        "temperatureC": reading.temperature_c,
        "humidityPct": reading.humidity_pct,
        "rainfallMm": reading.rainfall_mm,
        "waterLevelPct": reading.water_level_pct,
    }

    # Flood risk must take precedence over watering advice.
    if reading.water_level_pct >= profile.flood_water_level_pct or reading.rainfall_mm >= profile.flood_rainfall_mm:
        advisories.append(Advisory("flood", "critical", "Flood-risk alert", "High water level or intense rainfall detected. Check drainage and avoid irrigation.", "CHECK_DRAINAGE", evidence))
    elif reading.soil_moisture_pct < profile.irrigation_moisture_pct:
        advisories.append(Advisory("irrigation", "warning", "Irrigate now", "Low soil moisture detected. Inspect the zone and irrigate if conditions remain dry.", "REVIEW_IRRIGATION", evidence))

    if reading.temperature_c >= profile.heat_temperature_c and reading.soil_moisture_pct < profile.heat_moisture_pct:
        advisories.append(Advisory("heat", "warning", "Heat-stress risk", "High temperature and dry soil can stress the crop. Prefer irrigation during cooler hours.", "SCHEDULE_EVENING_IRRIGATION", evidence))

    if reading.humidity_pct >= profile.disease_humidity_pct and reading.temperature_c >= profile.disease_temperature_c:
        advisories.append(Advisory("disease_risk", "info", "Humidity risk increasing", "Warm, humid conditions can favour crop disease. Inspect leaves before treatment.", "INSPECT_LEAVES", evidence))

    for pest in pests or []:
        if pest.confidence < profile.minimum_pest_confidence:
            continue
        severity = "warning" if pest.count >= profile.high_pest_count else "info"
        advisories.append(Advisory("pest", severity, "Pest activity detected", f"Possible {pest.label} activity was detected. Inspect affected plants and use targeted intervention only if confirmed.", "INSPECT_AFFECTED_PLANTS", {**evidence, "pest": pest.__dict__}))
    return advisories
