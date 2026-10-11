# Edge API

FastAPI + SQLite, runs on the Raspberry Pi farm node, port **3001**. Accepts
sensor readings and AI observations, generates advisories, mediates irrigation
approval, hands the node its relay command, and serves the dashboard.

The contract of record is `/openapi.json`. This page is a summary, not a
substitute.

## Endpoints

| Method | Path | Notes |
| --- | --- | --- |
| GET | `/health` | Node status, `modelStatus`, pending sync count, actuator sync |
| GET | `/` | Dashboard UI (`static/index.html`), same-origin |
| GET | `/v1/zones` | Zones that have reported |
| GET | `/v1/farm-state?zoneId=` | Reading, server-computed `freshness`, observations, advisories, actuator, pending requests |
| GET | `/v1/history?zoneId=&limit=` | Recent readings, oldest first |
| GET | `/v1/analytics/report?zoneId=&hours=` | On-demand local farmer report from sensor, scan, risk, and irrigation history |
| POST | `/v1/assistant/ask` | Optional online Gemini RAG assistant using curated guidance and the latest local farm report |
| POST | `/v1/readings` | Node uplink. **201** stored, **200** duplicate replay. Both carry `command` |
| POST | `/v1/observations` | Crop-health or pest observations |
| POST | `/v1/crop-health?zoneId=` | **multipart/form-data**, field name `image` |
| POST | `/v1/pest/analyze` | Always **503 `model_not_ready`** — no pest model exists |
| POST | `/v1/irrigation/requests` | Records intent. Returns the request **flat**. Does not command the pump |
| POST | `/v1/irrigation/requests/{id}/approve` | The only normal ON transition. Returns `{request, actuator, command}` |
| POST | `/v1/irrigation/requests/{id}/decline` | Desired state stays OFF |
| POST | `/v1/actuator-command` | Manual override, always audited |

> **Response-shape asymmetry, on purpose.** Create returns the request object
> flat; approve and decline wrap it as `{"request": ...}`. The Flutter client
> accepts both (`IrrigationRequest.fromAny`). Do not "fix" one side alone —
> reading `body['request']['id']` from the flat create response is exactly the
> bug that made approval fail silently for weeks.

## Safety model

The pump turns on because a human approved a specific request. That property is
enforced here and covered by `tests/test_safety_and_e2e.py`:

- An advisory never changes actuator state; neither does creating a request.
- Approval (or an explicit, separately audited override) is the only ON path.
- Runtime is clamped to 60–3600 s. `maxRuntimeSec` is 0 whenever the command is OFF.
- `reconcile()` runs on every read and write path, so no caller can skip the
  auto-OFF when a lease expires.
- `desiredState` and `reportedState` stay distinct; `inSync` exposes divergence.
- Every actuator change writes to `actuator_logs`, including the automatic
  runtime-expiry OFF.
- A replayed `eventId` is 200, never 409, and still carries the current command —
  the node retried precisely because it lost that command.

The firmware carries its own independent dead-man timer. Neither side is
trusted to be the only shutoff.

## Crop-health inference

`app/vision.py` runs `ml/vision/src/inference.py` as a subprocess. The
subprocess boundary is deliberate: `ml/vision` and `citadel_pest_risk` both
claim the top-level package name `src`, so one interpreter cannot import both.

Interpreter resolution: `CITADEL_VISION_PYTHON`, then `ml/vision/.venv`, then
the interpreter running this service. That last fallback means a single shared
venv on the Pi is enough — install `ml/vision/requirements-pi.txt` alongside
this service's own requirements.

Failures map to distinct statuses, and none of them can be mistaken for a
diagnosis:

| Condition | CLI exit | HTTP |
| --- | --- | --- |
| No TFLite runtime, missing/unloadable model, tensor mismatch | 3 | **503** `vision_unavailable` |
| Subprocess produced no parsable JSON | non-zero | **502** `vision_bad_output` |
| Exceeded 30 s | — | **504** `vision_timeout` |
| Model ran, confidence < 0.50 | 0 | **200**, `label: "inconclusive"` |

`inconclusive` means the model ran and was not confident. It is never used for
an infrastructure failure.

## Environment

| Variable | Default | Purpose |
| --- | --- | --- |
| `CITADEL_DB_PATH` | `services/edge-api/farm.db` | SQLite file. Set explicitly under systemd |
| `CITADEL_VISION_PYTHON` | auto | Interpreter for the inference CLI |
| `CITADEL_CROP_MODEL` | `crop_health_mobilenetv2_v1.1.tflite` | Model artifact |
| `CITADEL_MAX_RUNTIME_SEC` | `900` | Default irrigation lease |
| `CITADEL_ACTUATOR_FAULT_SECONDS` | `35` | Slack before the server mirrors the node's dead-man |
| `CITADEL_CLOUD_URL` | unset | **Unset disables cloud sync entirely** |
| `CITADEL_FARM_ID` | `farm-001` | Identifies this farm to the cloud |

## Run

```bash
python3 -m venv .venv
.venv/bin/pip install -e ../../ml/pest-risk     # must come first
.venv/bin/pip install -r requirements.txt
cd ../.. && services/edge-api/.venv/bin/python -m uvicorn app.main:app \
    --app-dir services/edge-api --host 0.0.0.0 --port 3001

# tests
cd services/edge-api && .venv/bin/python -m unittest discover -s tests -v
```

`0.0.0.0` is required: the phone and the ESP32 reach this over the LAN, and
`localhost` on either device means that device.
