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
| Capacitive soil-moisture v1.2 | analog (ADC1) | GPIO34 | **Not purchased.** `SOIL_SENSOR_WIRED = false`; the field is omitted from the payload |
| Tipping-bucket rain gauge | interrupt/pulse | GPIO15 reserved | **Not available.** `RAIN_GAUGE_WIRED = false`; field omitted |
| Status LED | digital out | GPIO2 | Onboard |
| Power | 5 V rail + GND rail | — | Pi powered from a 2.1 A power-bank port (a weaker source caused a reproducible under-voltage boot failure) |

**Compute host:** Raspberry Pi 3B+, Raspberry Pi OS Lite 64-bit, headless over SSH (`citadel-pi.local`, LAN `192.168.1.31`). Node.js v20 + a Python 3 venv.

**Firmware loop** (`firmware/esp32-field-node/field_node/field_node.ino`), every 10 s:

**Dead-man timer** runs first, every loop iteration, ungated by the network or
the post interval. Then, every 10 s:

1. Mint a stable `eventId` (`deviceId-bootNonce-counter`) for this sample.
2. Read each sensor. **A failed or absent sensor is omitted from the payload**,
   never substituted — a fabricated 25 °C is indistinguishable to the risk
   engine from a real one, and a floating soil pin reading ~100 % would suppress
   the irrigation advisory it is meant to trigger.
3. Attach `relayReported` — the node's acknowledgement of its own relay.
4. Print the JSON to Serial @115200, then POST it if Wi-Fi is up.
5. On 201 (stored) **or** 200 (duplicate replay), parse the `command` in the
   response body and apply it. A malformed, unknown-actuator, or
   out-of-range command is ignored; nothing here can turn the relay ON from
   bad input.

Payload contract (soil and rainfall absent because those sensors are not wired):

```json
{"eventId":"field-node-01-3f2a91cc-00000042","deviceId":"field-node-01",
 "zoneId":"zone-a","temperatureC":28.6,"humidityPct":73.2,
 "waterLevelPct":0.0,"relayReported":"OFF"}
```

There is **no persistent retry queue**: a reading whose POST fails is dropped,
and the next interval is a genuinely new sample.

---

## Layer 1 — Edge services (on the Pi)

> Updated 2026-09-10. The dual-backend split described in earlier revisions is
> gone: `apps/dashboard/backend` (port 3000) and the Node `services/edge-api`
> were consolidated into one FastAPI service on **port 3001** (commit `3b7dc01`).

### Edge API — `services/edge-api`, port **3001** (the only backend)

FastAPI + SQLite (`farm.db`, WAL), serves the dashboard from `static/index.html`.

- `POST /v1/readings` — node uplink. 201 stored / 200 duplicate replay; both
  responses carry the relay `command`
- `GET /v1/farm-state?zoneId=` — reading, **server-computed `freshness`**,
  observations, advisories, actuator, pending requests
- `GET /v1/history`, `GET /v1/zones`, `GET /health`
- `POST /v1/crop-health?zoneId=` — multipart, field `image`
- `POST /v1/observations`
- `POST /v1/irrigation/requests` + `/{id}/approve` + `/{id}/decline`
- `POST /v1/actuator-command` — audited manual override
- `POST /v1/pest/analyze` — always 503; no pest model exists

Tables: `readings`, `observations`, `actuator_state`, `actuator_logs`,
`irrigation_requests`. Every table carries `synced_at` for cloud push.

Advisories come from `app/advisories.py`, which is a shape adapter only — the
thresholds live in `citadel_pest_risk.profiles`, so there is exactly one copy of
the rules.

### Pest & risk rules — `ml/pest-risk` (installed as `citadel_pest_risk`)

Pure-stdlib rules engine, imported in-process by the edge API. Also exposes its
own FastAPI surface on port 8001 for standalone use. Covers water stress, heat
stress, humidity-driven disease-inspection prompts, flood risk and pest
activity. The TFLite pest detector is absent and reports `503 model_not_ready`
rather than pretending.

### Cloud API — `services/cloud-api`, port **3002**

Real, with a `/v1/sync/batch` endpoint and tests. The edge node pushes to it
only when `CITADEL_CLOUD_URL` is set; unset (the default) means the background
task never starts. **Not demonstrated end to end.**

## Layer 2 — Vision model

`ml/vision` — MobileNetV2 → TFLite, **2.40 MB**, mean latency **34.3 ms**. Classes: `healthy, early_blight, late_blight, leaf_spot, yellow_leaf_curl_virus` (tomato only). Input 224×224 RGB uint8, normalization baked into the graph. Frozen 749-image test set: **95.3 %** overall accuracy.

Confidence policy: ≥ 0.80 surfaced normally (98.5 % accurate in that bucket) · 0.50–0.79 surfaced with a limitation note · < 0.50 overridden to `inconclusive`, no diagnosis. A pre-inference quality gate rejects blurry / dark / bright / low-res / non-leaf images. Known weak spot: the fungal cluster (early_blight ↔ leaf_spot ↔ late_blight); early_blight recall 71.8 %.

Dataset pipeline in `src/dataset/`: download → clean → dedup → preprocess → augment → split → verify, each stage writing a JSON report to `datasets/crop_health/metadata/`.

---

## Layer 3 — Clients

**Farmer mobile app** — Flutter (`apps/farmer-app`), Android + iOS. Screens: home, scan (camera → crop health), scan result, advisory detail, history, profile, settings.

Offline policy, by data type:

- **Farm state** falls back to a SharedPreferences cache, returned marked
  `fromCache` so the UI labels it stale. It is never presented as live.
- **Crop scans and irrigation decisions do not fall back.** They surface the
  error. There is no truthful offline answer to "what disease is this?" or
  "did the pump turn on?", and the silent mock fallback that used to answer
  both was removed.

Every sensor field is nullable; a missing one renders as `--`, not as a
plausible number. Base URL and zone are editable in Settings (`EdgeConfig`,
default `http://192.168.1.31:3001`). Polls every 30 s; freshness comes from the
server's `freshness` field rather than a client-side timer.

**Dashboard** — static HTML/JS served by the edge API at `/`, same-origin.

**Advisory vocabulary** — owned by `citadel_pest_risk.risk_engine.ADVISORY_TYPES`
and published in `/openapi.json`: `flood, irrigation, heat, disease_risk, pest`.
`packages/contracts/src/events.js` is a legacy JS mirror and is no longer the
source of truth.

---

## End-to-end flows

**Telemetry:** sensors → ESP32 (10 s) → Wi-Fi POST → Pi `:3001/v1/readings` →
SQLite → rules engine → farm state → dashboard + phone poll (30 s).

**Crop scan:** farmer photographs a leaf → app POSTs **multipart** (`image`) →
`/v1/crop-health` → subprocess TFLite inference → quality gate, then confidence
policy → observation persisted → back to the app. Infrastructure failure returns
503/502/504 and is shown as unavailable, never as a diagnosis.

**Irrigation (human-in-the-loop), the full loop:**
advisory (changes nothing) → request created (changes nothing) → **farmer
approves** → desired state ON, audited → command rides the node's next reading
response → node validates and applies it, arming its own local timer → node
reports `relayReported: "ON"` on the following reading → desired and reported
in sync. Both the server and the firmware independently enforce the runtime
limit; neither is trusted as the only shutoff.

**Degradation ladder:** no cloud → fully functional (sync is off by default) ·
no Wi-Fi → ESP32 keeps printing to Serial and running its dead-man timer, phone
serves its cache marked stale · vision runtime missing → 503, visible, not a
fake `inconclusive` · sensor failed → field omitted, so no rule fires on it.

---

## Ports

| Port | Service |
|---|---|
| 3001 | Edge API + dashboard UI (**the only backend**) |
| 3002 | Cloud API (optional sync target, off by default) |
| 8001 | Pest & risk rules, standalone FastAPI surface |
| 115200 baud | ESP32 serial output |
