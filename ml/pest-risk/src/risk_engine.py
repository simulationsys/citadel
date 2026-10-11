"""Explainable Phase 1 risk rules. Keep crop profiles outside rule code as they mature."""
from __future__ import annotations

from .profiles import CropRiskProfile, TOMATO_DEMO
from .schemas import Advisory, PestObservation, SensorReading

# Authoritative advisory vocabulary — every string in the system is a member of this set.
# The edge API asserts against this constant; openapi.json publishes a Literal enum from it.
ADVISORY_TYPES: frozenset[str] = frozenset({"flood", "irrigation", "heat", "disease_risk", "pest"})

# Crop-health labels that are not a disease. Without this guard a confident
# "healthy" clears disease_confident_confidence and renders as
# "Possible crop disease detected: healthy".
NON_DISEASE_LABELS: frozenset[str] = frozenset({"healthy", "invalid_image", "inconclusive"})


def _at_least(v: float | None, t: float) -> bool:
    """True iff sensor value is present and >= threshold. A missing sensor never fires."""
    return v is not None and v >= t


def _below(v: float | None, t: float) -> bool:
    """True iff sensor value is present and < threshold. A missing sensor never fires."""
    return v is not None and v < t


def evaluate(
    reading: SensorReading,
    pests: list[PestObservation] | None = None,
    profile: CropRiskProfile = TOMATO_DEMO,
) -> list[Advisory]:
    advisories: list[Advisory] = []
    evidence = {
        "soilMoisturePct": reading.soil_moisture_pct,
        "temperatureC": reading.temperature_c,
        "humidityPct": reading.humidity_pct,
        "rainfallMm": reading.rainfall_mm,
        "waterLevelPct": reading.water_level_pct,
    }

    # Flood risk must take precedence over watering advice.
    # Flood fires on water level alone — no thermometer required.
    if _at_least(reading.water_level_pct, profile.flood_water_level_pct) or _at_least(reading.rainfall_mm, profile.flood_rainfall_mm):
        advisories.append(Advisory(
            "flood", "critical",
            "Flood-risk alert",
            "High water level or intense rainfall detected. Check drainage and avoid irrigation.",
            "CHECK_DRAINAGE", evidence,
        ))
    elif _below(reading.soil_moisture_pct, profile.irrigation_moisture_pct):
        advisories.append(Advisory(
            "irrigation", "warning",
            "Irrigate now",
            "Low soil moisture detected. Inspect the zone and irrigate if conditions remain dry.",
            "REVIEW_IRRIGATION", evidence,
        ))

    # Both thermometer and soil sensor required; a missing thermometer never fires heat.
    if _at_least(reading.temperature_c, profile.heat_temperature_c) and _below(reading.soil_moisture_pct, profile.heat_moisture_pct):
        advisories.append(Advisory(
            "heat", "warning",
            "Heat-stress risk",
            "High temperature and dry soil can stress the crop. Prefer irrigation during cooler hours.",
            "SCHEDULE_EVENING_IRRIGATION", evidence,
        ))

    # Both thermometer and humidity sensor required.
    if _at_least(reading.humidity_pct, profile.disease_humidity_pct) and _at_least(reading.temperature_c, profile.disease_temperature_c):
        advisories.append(Advisory(
            "disease_risk", "info",
            "Humidity risk increasing",
            "Warm, humid conditions can favour crop disease. Inspect leaves before treatment.",
            "INSPECT_LEAVES", evidence,
        ))

    for pest in pests or []:
        if pest.crop_health:
            # Crop-health branch: vision result reused via PestObservation with crop_health=True.
            # Emits disease_risk when confidence clears the profile threshold, completing
            # the leaf-blight demo beat that advisory_engine.py previously provided.
            if (pest.label.lower() not in NON_DISEASE_LABELS
                    and pest.confidence >= profile.disease_confident_confidence):
                advisories.append(Advisory(
                    "disease_risk", "warning",
                    "Possible crop disease detected",
                    f"Vision analysis identified possible {pest.label} on a leaf sample. Inspect nearby plants before treating.",
                    "INSPECT_LEAVES",
                    {**evidence, "cropHealth": {"label": pest.label, "confidence": pest.confidence}},
                ))
        else:
            if pest.confidence < profile.minimum_pest_confidence:
                continue
            severity: str = "warning" if pest.count >= profile.high_pest_count else "info"
            advisories.append(Advisory(
                "pest", severity,
                "Pest activity detected",
                f"Possible {pest.label} activity was detected. Inspect affected plants and use targeted intervention only if confirmed.",
                "INSPECT_AFFECTED_PLANTS",
                {**evidence, "pest": pest.__dict__},
            ))

    return advisories
