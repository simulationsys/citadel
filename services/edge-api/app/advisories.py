"""The only advisory implementation in the repository.

Replaces app/advisory_engine.py and services/edge-api/src/advisory.js. Thresholds
live in citadel_pest_risk.profiles, not here — this file is a shape adapter and
nothing else. Any rule written below is a fourth copy of the rules.
"""
from __future__ import annotations

from citadel_pest_risk.risk_engine import ADVISORY_TYPES, evaluate
from citadel_pest_risk.schemas import PestObservation, SensorReading

__all__ = ["ADVISORY_TYPES", "build_advisories"]


def _current(observations: list[dict]) -> list[dict]:
    """Only the newest crop_health observation describes the crop *now* — a later
    'healthy' supersedes an earlier 'early_blight_fungal', and without this a
    resolved disease alarms forever. Pest observations are counts of separate
    sightings, so the whole recent window stays.
    """
    seen_crop_health = False
    current = []
    for observation in observations:  # newest first
        if observation.get("kind") == "crop_health":
            if seen_crop_health:
                continue
            seen_crop_health = True
        current.append(observation)
    return current


def build_advisories(reading: dict | None, observations: list[dict] | None = None) -> list[dict]:
    """`reading` is a format_reading() dict — its camelCase keys are exactly what
    SensorReading.from_dict consumes. `observations` is newest-first.
    """
    if not reading:
        return []
    pests = [
        PestObservation(
            label=str(o["label"]),
            confidence=float(o["confidence"]),
            count=int(o.get("count") or 1),
            crop_health=(o.get("kind") == "crop_health"),
        )
        for o in _current(observations or [])
    ]
    return [advisory.as_api_dict() for advisory in evaluate(SensorReading.from_dict(reading), pests)]
