"""Local, explainable farm analytics built from the edge SQLite history."""
from __future__ import annotations

from collections import Counter
from datetime import datetime, timedelta, timezone
from statistics import mean

from . import db as store
from .advisories import build_advisories

METRICS = {
    "soilMoisturePct": ("soil_moisture_pct", "%"),
    "temperatureC": ("temperature_c", "°C"),
    "humidityPct": ("humidity_pct", "%"),
    "rainfallMm": ("rainfall_mm", "mm"),
    "waterLevelPct": ("water_level_pct", "%"),
}


def _parse(value: str | None) -> datetime | None:
    try:
        parsed = datetime.fromisoformat(value) if value else None
        if parsed and parsed.tzinfo is None:
            parsed = parsed.replace(tzinfo=timezone.utc)
        return parsed
    except ValueError:
        return None


def _round(value: float | None) -> float | None:
    return round(value, 2) if value is not None else None


def _metric(rows: list[dict], column: str, unit: str) -> dict:
    values = [float(row[column]) for row in rows if row[column] is not None]
    if not values:
        return {
            "unit": unit, "count": 0, "latest": None, "average": None,
            "minimum": None, "maximum": None, "trend": "unavailable",
        }
    midpoint = max(1, len(values) // 2)
    older, newer = values[:midpoint], values[midpoint:]
    delta = mean(newer) - mean(older) if newer else 0.0
    tolerance = max(0.5, abs(mean(values)) * 0.03)
    trend = "rising" if delta > tolerance else "falling" if delta < -tolerance else "stable"
    return {
        "unit": unit,
        "count": len(values),
        "latest": _round(values[-1]),
        "average": _round(mean(values)),
        "minimum": _round(min(values)),
        "maximum": _round(max(values)),
        "trend": trend,
    }


def build_report(zone_id: str, hours: int = 168) -> dict:
    hours = max(1, min(int(hours), 24 * 90))
    generated_at = datetime.now(timezone.utc)
    cutoff = generated_at - timedelta(hours=hours)

    with store.db() as conn:
        raw_readings = [dict(row) for row in conn.execute(
            "SELECT * FROM readings WHERE zone_id=? ORDER BY received_at ASC", (zone_id,)
        ).fetchall()]
        readings = [row for row in raw_readings
                    if (_parse(row.get("received_at")) or datetime.min.replace(tzinfo=timezone.utc)) >= cutoff]
        observations = [dict(row) for row in conn.execute(
            "SELECT * FROM observations WHERE zone_id=? AND kind='crop_health' "
            "ORDER BY received_at ASC", (zone_id,)
        ).fetchall()]
        observations = [row for row in observations
                        if (_parse(row.get("received_at")) or datetime.min.replace(tzinfo=timezone.utc)) >= cutoff]
        irrigation = [dict(row) for row in conn.execute(
            "SELECT * FROM irrigation_requests WHERE zone_id=? ORDER BY created_at ASC", (zone_id,)
        ).fetchall()]
        irrigation = [row for row in irrigation
                      if (_parse(row.get("created_at")) or datetime.min.replace(tzinfo=timezone.utc)) >= cutoff]

    metrics = {name: _metric(readings, column, unit)
               for name, (column, unit) in METRICS.items()}
    risk_counts: Counter[str] = Counter()
    for row in readings:
        formatted = store.format_reading(row)
        for advisory in build_advisories(formatted, []):
            risk_counts[advisory["type"]] += 1

    label_counts = Counter(str(row["label"]) for row in observations)
    latest_scan = store.format_observation(observations[-1]) if observations else None
    expected_values = len(readings) * len(METRICS)
    reported_values = sum(metric["count"] for metric in metrics.values())
    completeness = round(reported_values / expected_values * 100, 1) if expected_values else 0.0

    recommendations: list[dict] = []
    if not readings:
        recommendations.append({"priority": "high", "title": "Reconnect the field node",
                                "message": "No sensor readings exist in this reporting period."})
    if risk_counts["flood"]:
        recommendations.append({"priority": "high", "title": "Inspect drainage",
                                "message": f"Flood-risk conditions appeared in {risk_counts['flood']} readings."})
    if risk_counts["irrigation"]:
        recommendations.append({"priority": "medium", "title": "Review irrigation timing",
                                "message": f"Low-moisture conditions appeared in {risk_counts['irrigation']} readings."})
    if risk_counts["heat"]:
        recommendations.append({"priority": "medium", "title": "Protect crops from heat stress",
                                "message": f"Heat-stress conditions appeared in {risk_counts['heat']} readings."})
    unhealthy = sum(count for label, count in label_counts.items()
                    if label not in {"healthy", "invalid_image", "inconclusive"})
    if unhealthy:
        recommendations.append({"priority": "high", "title": "Inspect affected leaves",
                                "message": f"{unhealthy} crop scan(s) reported a possible visible condition."})
    if completeness < 80 and readings:
        recommendations.append({"priority": "medium", "title": "Check missing sensors",
                                "message": f"Only {completeness}% of expected sensor fields were reported."})
    if not recommendations:
        recommendations.append({"priority": "low", "title": "Continue monitoring",
                                "message": "No urgent threshold event was found in the selected period."})

    return {
        "status": "ok",
        "mode": "local-edge-analysis",
        "zoneId": zone_id,
        "generatedAt": generated_at.isoformat(),
        "period": {"hours": hours, "from": cutoff.isoformat(), "to": generated_at.isoformat()},
        "summary": {
            "readingCount": len(readings),
            "dataCompletenessPct": completeness,
            "cropScanCount": len(observations),
            "irrigationRequestCount": len(irrigation),
            "approvedIrrigationCount": sum(1 for row in irrigation if row["status"] == "approved"),
        },
        "metrics": metrics,
        "risks": dict(risk_counts),
        "cropHealth": {"latest": latest_scan, "labelCounts": dict(label_counts)},
        "recommendations": recommendations,
    }
