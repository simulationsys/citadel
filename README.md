# Citadel — Smart Farming Assistant

Offline-first farm monitoring. An ESP32 reads field sensors and drives a relay; a
Raspberry Pi runs the edge API, stores readings in SQLite, generates advisories,
runs crop-health inference, and serves both the dashboard and the farmer app —
**entirely over the local Wi-Fi LAN, with no internet dependency**. Cloud sync
exists and is off by default.

```text
apps/farmer-app/            Flutter mobile app (Android + iOS)
services/
  edge-api/                 FastAPI + SQLite edge service, port 3001 (the node)
    app/                    main, db, advisories, vision bridge, cloud sync
    static/index.html       dashboard UI, served at /
  cloud-api/                Optional multi-farm sync target, port 3002
ml/
  vision/                   Crop-health model, training pipeline, inference CLI
  pest-risk/                Advisory rules engine (citadel_pest_risk), port 8001
firmware/esp32-field-node/  Sensors, relay, HTTP transport
deploy/                     systemd unit + env templates (not installed)
packages/contracts/         Legacy shared JS payload helpers
docs/                       Architecture, demo, hardware, audit reports
```

## Run it locally

Python 3.11+ required (`ml/pest-risk` declares `requires-python = ">=3.11"`).

```bash
cd services/edge-api
python3 -m venv .venv
.venv/bin/pip install -e ../../ml/pest-risk     # must come first
.venv/bin/pip install -r requirements.txt
cd ../.. && services/edge-api/.venv/bin/python -m uvicorn app.main:app \
    --app-dir services/edge-api --host 0.0.0.0 --port 3001
```

The dashboard is then at `http://localhost:3001/`, and the OpenAPI contract at
`/openapi.json`. For Raspberry Pi setup — including the `tflite-runtime`
inference path and a systemd service — see [deploy/README.md](deploy/README.md).

Post a reading to change the farm state:

```bash
curl -X POST http://localhost:3001/v1/readings \
  -H 'Content-Type: application/json' \
  -d '{"eventId":"demo-1","soilMoisturePct":12,"temperatureC":38,"humidityPct":40}'
```

## Tests

```bash
cd services/edge-api && .venv/bin/python -m unittest discover -s tests -v   # 36
cd ml/pest-risk      && python -m unittest discover -s tests -v             # 14
cd ml/vision         && python -m unittest discover -s tests -v             # 20
cd services/cloud-api && python -m unittest discover -s tests -v            #  2
cd apps/farmer-app   && flutter test                                        # requires Flutter
```

## What is and is not working

| Area | State |
| --- | --- |
| ESP32 → edge API → SQLite → dashboard | Implemented and previously demonstrated on hardware |
| Crop-health model (tomato, 5 classes, TFLite) | Implemented; **needs `tflite-runtime` installed on the Pi** |
| Advisory / environmental-risk rules | Implemented and covered by tests |
| Irrigation approval → relay downlink → acknowledgement | Implemented and covered by tests; **not yet demonstrated on hardware** |
| Pest detection model | **Not built.** `/v1/pest/analyze` honestly returns 503 |
| Soil-moisture sensor | **Not wired.** Firmware omits the field rather than sending a floating value |
| Rain gauge | **Not wired.** Field omitted |
| Cloud sync | Implemented, dormant unless `CITADEL_CLOUD_URL` is set; **untested end to end** |
| Automatic startup | Template in `deploy/`, **not installed** |

Current readiness assessment: [docs/pre-pitch-integration-report.md](docs/pre-pitch-integration-report.md).

## Ownership

| Area | Owner |
| --- | --- |
| `firmware/esp32-field-node` | device + sensors |
| `ml/vision` | crop-health vision |
| `ml/pest-risk` | advisory and risk rules |
| `services/edge-api` | edge API, storage, actuator safety |
| `apps/farmer-app` | farmer mobile app |
| `services/cloud-api`, `deploy` | sync and deployment |
