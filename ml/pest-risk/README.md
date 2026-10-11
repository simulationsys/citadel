# Pest and environmental-risk intelligence

This is the local intelligence service for Citadel's pest and environmental-risk feature. It turns normalized field readings and pest evidence into conservative, farmer-readable advisories. It is deliberately separated from UI code: the backend can call it locally without mobile or dashboard clients knowing its rules.

## What Phase 1 supports

- Water stress / irrigation need
- Heat stress from high temperature and dry soil
- Humidity-supported disease-risk inspection prompt
- Flood risk from water level or heavy rainfall
- Pest activity based on an image-model result, count, and confidence

The default thresholds are **demo values**, not crop prescriptions. Crop, soil type, irrigation system, and field validation should inform a later profile.

## Run the deterministic demo

```powershell
python -m src.main --reading fixtures/dry_heat.json --pest fixtures/whitefly_activity.json
python -m unittest discover -s tests -v
```

The CLI prints the JSON contract the edge API can store and return. Risk evaluation has no runtime third-party dependency. Create an isolated environment and install the API and model dependencies:

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt -r requirements-model.txt
.\.venv\Scripts\python.exe -m uvicorn src.api:app --host 0.0.0.0 --port 8001
```

Open `http://localhost:8001/docs` to test the service. `pest_inference.py` supports TensorFlow Lite SSD-style models with an image supplied as base64. It intentionally reports `503 model_not_ready` until a real `.tflite` model and labels file are supplied.

## Integration contract

Input: a sensor reading and optional pest result. Output: a list of advisories with `type`, `severity`, `title`, `message`, `action`, and `evidence`. The backend remains responsible for persistence and explicit actuator approval.

## API surface

- `GET /health` — service/model readiness
- `GET /v1/profiles` — supported crop-risk profiles
- `POST /v1/risk/evaluate` — evaluate readings and optional pest observations
- `POST /v1/pest/analyze` — run the loaded local TFLite model over an image and return observations
- `POST /v1/crop-health/analyze` — validate image quality and run the bundled tomato-health classifier
- `POST /v1/farm-state` — analyze pest observations/image plus readings in one request

## Model handoff

Place an exported `pest_detector.tflite` and matching `labels.txt` in `models/` or set `CITADEL_PEST_MODEL` and `CITADEL_PEST_LABELS`. The service does not pretend that a model is available when it is not. Verify output-tensor ordering against the selected model with real validation images before deploying it to a farm.

Image requests use base64-encoded JPEG/PNG bytes without a data-URI prefix and are limited to 5 MB. On a Raspberry Pi, prefer the compatible `tflite-runtime` wheel rather than the full TensorFlow package.
