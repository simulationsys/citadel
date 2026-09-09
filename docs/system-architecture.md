# Citadel — Full System Architecture (hardware → edge → apps)

Offline-first smart-farming platform. Nothing in the live path depends on the internet: the ESP32, the Raspberry Pi, the phone and the dashboard all sit on one local Wi-Fi LAN.

---

## Layer 0 — Field hardware (the physical node)

| Component | Interface | Pin | Status |
|---|---|---|---|
| ESP32-WROOM-32 (38-pin DevKit) | MCU, Wi-Fi b/g/n | — | Live. Jumpered pin-to-pin (too wide for the breadboard rows) |
| DHT11 temp + humidity | 1-wire digital, internal pull-up | GPIO4 | Live (~28 °C, ~75 % RH) |
| HC-SR04 ultrasonic (tank/water level) | TRIG out / ECHO in | GPIO32 / GPIO33 | Live. ECHO through a 1 kΩ + 2 kΩ divider (3× 1 kΩ) — 5 V → 3.3 V |
| Relay module (irrigation pump control) | digital out | GPIO26 | Control side live, held LOW on boot (pump OFF by default). Load side / pump **not wired** |
| Capacitive soil-moisture v1.2 | analog (ADC1) | GPIO34 | **Not purchased.** Pin floats → reports a meaningless 100 % |
| Tipping-bucket rain gauge | interrupt/pulse | GPIO15 reserved | **Not available.** Firmware hardcodes `rainfallMm: 0` |
| Status LED | digital out | GPIO2 | Onboard |
| Power | 5 V rail + GND rail | — | Pi powered from a 2.1 A power-bank port (a weaker source caused a reproducible under-voltage boot failure) |

**Compute host:** Raspberry Pi 3B+, Raspberry Pi OS Lite 64-bit, headless over SSH (`citadel-pi.local`, LAN `192.168.1.31`). Node.js v20 + a Python 3 venv.

**Firmware loop** (`firmware/esp32-field-node/field_node/field_node.ino`), every 10 s:

1. Read soil ADC → calibrated % (`SOIL_DRY_VALUE 3200` / `SOIL_WET_VALUE 1400`).
2. Read DHT11 → temp/humidity; on NaN, substitute 25 °C / 50 % and flag `sensorStatus.dht = "error"`.
3. Read HC-SR04 → distance → tank % (`TANK_EMPTY_CM 100` / `TANK_FULL_CM 10`); pulse timeout → flag `ultrasonic: "error"`.
4. Serialize one JSON payload and always print it to Serial @115200 (works with no network at all).
5. If Wi-Fi is up, HTTP POST it to `EDGE_API_URL`. Serial is the fallback transport — it is never skipped.

Payload contract:

```json
{"deviceId":"field-node-01","zoneId":"zone-a","soilMoisturePct":100.0,
 "temperatureC":28.6,"humidityPct":73.2,"rainfallMm":0.0,"waterLevelPct":0.0,
 "sensorStatus":{"dht":"ok","ultrasonic":"ok"}}
```

---

## Layer 1 — Edge services (on the Pi)

Two backends exist today; the ESP32 currently posts to the **Python** one.

### A. Python dashboard/edge API — `apps/dashboard/backend`, port **3000** (the live path)

FastAPI + SQLite (`farm.db`), also serves the dashboard UI from `static/`.

- `POST /v1/readings` — ingest, persist, return full farm state
- `GET /v1/farm-state` — latest reading + advisories + relay state + latest vision result
- `GET /v1/history?limit=N`
- `POST /v1/crop-health` — raw JPEG bytes → subprocess into `ml/vision/src/inference.py`; persists non-inconclusive diagnoses
- `POST /v1/vision-results`
- `POST /v1/actuator-command` — `START_IRRIGATION` / `STOP_IRRIGATION` / `TOGGLE`, audited in `actuator_logs`
- `GET /health`

Tables: `readings`, `vision_results`, `actuator_logs`, `actuator_state`. Advisories come from `advisory_engine.build_advisories(reading, latest_vision)`.

### B. Node edge API — `services/edge-api`, port **3001** (parallel implementation, in-memory)

`FarmStore` in memory, zone-aware, plus an irrigation *request/approve* workflow that is explicitly **not** a pump command. Calls the pest-risk service at `RISK_SERVICE_URL` with a 1.2 s timeout and falls back to `buildFallbackAdvisories()` on any failure. Endpoints: `/v1/zones`, `/v1/farm-state`, `/v1/history`, `/v1/readings`, `/v1/observations`, `/v1/irrigation/requests[/:id/approve]`, `/v1/crop-health`.

> These two are a known duplication — `docs/backend-integration.md` tracks consolidating onto one.

### C. Pest & risk intelligence — `ml/pest-risk`, port **8001**

FastAPI over a pure-Python rules engine (zero third-party runtime deps for evaluation): `/v1/risk/evaluate`, `/v1/pest/analyze`, `/v1/farm-state`, `/v1/profiles`, `/health`. Covers water stress, heat stress, humidity-driven disease-inspection prompts, flood risk and pest activity, against crop profiles (`tomato-demo`). The TFLite pest detector is optional and returns `503 model_not_ready` until a real `pest_detector.tflite` + `labels.txt` are supplied — it never fakes availability.

### D. Cloud API — `services/cloud-api`, port **3002**

Placeholder only. Intended role: durable multi-farm storage and accepting delayed edge sync batches.

---

## Layer 2 — Vision model

`ml/vision` — MobileNetV2 → TFLite, **2.40 MB**, mean latency **34.3 ms**. Classes: `healthy, early_blight, late_blight, leaf_spot, yellow_leaf_curl_virus` (tomato only). Input 224×224 RGB uint8, normalization baked into the graph. Frozen 749-image test set: **95.3 %** overall accuracy.

Confidence policy: ≥ 0.80 surfaced normally (98.5 % accurate in that bucket) · 0.50–0.79 surfaced with a limitation note · < 0.50 overridden to `inconclusive`, no diagnosis. A pre-inference quality gate rejects blurry / dark / bright / low-res / non-leaf images. Known weak spot: the fungal cluster (early_blight ↔ leaf_spot ↔ late_blight); early_blight recall 71.8 %.

Dataset pipeline in `src/dataset/`: download → clean → dedup → preprocess → augment → split → verify, each stage writing a JSON report to `datasets/crop_health/metadata/`.

---

## Layer 3 — Clients

**Farmer mobile app** — Flutter (`apps/farmer-app`), Android + iOS. Screens: home, scan (camera → crop health), scan result, advisory detail, history, profile, settings.

The data layer is the interesting part — `HybridFarmStateRepository`:

1. try `HttpFarmStateRepository` (live edge API),
2. which itself serves a SharedPreferences cache before throwing,
3. and only on first-run-offline falls through to `MockFarmStateRepository`.

So the UI never goes blank. Base URL and zone are user-editable in Settings (`EdgeConfig`, default `http://192.168.1.31:3000`). Polls every 30 s; the freshness banner turns stale at 2 min, critical at 15 min.

**Dashboard** — static HTML/JS served by the Python backend at `/`; a Node dev server also exists at `apps/dashboard/src/server.js`.

**Shared contracts** — `packages/contracts/src/events.js`: `createSensorReading()` and the advisory type enum (`irrigation, disease, pest, heat, flood`), mirrored by hand in the Flutter `AppConstants`.

---

## End-to-end flows

**Telemetry:** sensors → ESP32 (10 s) → Wi-Fi HTTP POST → Pi `:3000/v1/readings` → SQLite → advisory engine → farm state → dashboard + phone poll (30 s).

**Crop scan:** farmer photographs a leaf → app POSTs JPEG bytes → `/v1/crop-health` → subprocess TFLite inference → quality gate + confidence policy → persisted as a vision result → advisory → back to the app.

**Irrigation (human-in-the-loop):** advisory raised → farmer/operator approves → `POST /v1/actuator-command` → `actuator_state` + `actuator_logs`. The relay defaults OFF on every boot. In the Node API, request/approve records are deliberately *not* pump commands — firmware must acknowledge physical action separately.

**Degradation ladder:** no cloud → still fully functional · no Wi-Fi → ESP32 keeps printing to Serial and the phone serves its cache · pest service down → edge fallback rules · vision model missing → `inconclusive`, not a crash · sensor NaN → safe defaults plus a `sensorStatus` error flag.

---

## Ports

| Port | Service |
|---|---|
| 3000 | Python edge/dashboard API + dashboard UI (**live path**) |
| 3001 | Node edge API |
| 3002 | Cloud API (placeholder) |
| 8001 | Pest & risk intelligence |
| 115200 baud | ESP32 serial fallback |
