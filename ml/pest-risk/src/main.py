"""Evaluate a JSON fixture locally; useful before the field node exists."""
from __future__ import annotations

import argparse
import json
from pathlib import Path

from .risk_engine import evaluate
from .schemas import PestObservation, SensorReading


def load_json(path: str) -> dict:
    return json.loads(Path(path).read_text(encoding="utf-8"))


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--reading", required=True, help="Sensor-reading JSON fixture")
    parser.add_argument("--pest", help="Optional pest-observation JSON fixture")
    args = parser.parse_args()
    reading = SensorReading.from_dict(load_json(args.reading))
    pests = [PestObservation.from_dict(load_json(args.pest))] if args.pest else []
    print(json.dumps({"reading": reading.__dict__, "pests": [item.__dict__ for item in pests], "advisories": [item.as_api_dict() for item in evaluate(reading, pests)]}, indent=2))


if __name__ == "__main__":
    main()
