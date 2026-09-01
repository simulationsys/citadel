# Citadel workstreams — Phase 1 MVP

Citadel is an offline-first Smart Farming Assistant for Indian farms. A field node observes soil and environmental conditions, captures crop images, performs as much analysis as practical at the edge, and surfaces a short, actionable advisory. The intended value is earlier intervention: less unnecessary watering and pesticide use, fewer missed crop-stress signals, and a useful system even with unreliable internet.

## Phase 1: one credible farm loop

The MVP proves one complete loop for a single crop and one demonstration zone:

```text
Sensors + camera → field node → local API / intelligence → advisory → mobile + dashboard
```

The baseline loop detects low soil moisture and produces an irrigation advisory. It also demonstrates a leaf/pest AI result and an environmental risk warning such as heat or flooding. A real model may be substituted by a representative small model or a clearly labelled demo result while data collection is ongoing; the system boundary and result format should remain the same.

## Build and integration flow

All workstreams should follow this flow. The team does **not** wait for completed hardware or trained models before the API, mobile app, dashboard, and intelligence work begins.

```text
Phase 1: simulated field payload → edge API → advisory → mobile app + dashboard
Phase 2: real ESP32 sensor payload replaces the simulator → same edge API
Phase 3: crop/pest image results replace AI sample results → same edge API
Phase 4: end-to-end field-node demonstration
```

### Phase 1 — simulated field data

The backend exposes the local API and accepts representative JSON payloads. The mobile app and dashboard consume its responses. The crop-health, pest, and risk workstreams use sample model results and sample readings to establish advisory behaviour. This is a complete software integration path, not a claim that real sensor integration has happened.

```json
{
  "deviceId": "demo-node-01",
  "zoneId": "zone-a",
  "soilMoisturePct": 22,
  "temperatureC": 39,
  "humidityPct": 32,
  "rainfallMm": 0,
  "waterLevelPct": 8
}
```

### Phase 2 — hardware replaces the simulator

Once the shared field node produces stable, calibrated readings, firmware sends the **same** payload shape to the existing edge endpoint. No mobile, dashboard, or risk-engine rewrite should be required merely because the source changes from simulated data to ESP32 data.

```text
Before hardware: manual JSON / demo script → edge API
After hardware:  ESP32 + sensors → edge API
```

### Phase 3 — AI replaces sample results

The disease and pest modules follow the same principle. They first expose a stable result shape using representative data, then replace that implementation with locally running model inference. The backend remains the sole integration point: UI clients do not communicate directly with firmware or ML components.

### Integration rules

- All workstreams use the shared contracts and treat the edge API as the boundary between modules.
- API changes are made deliberately and communicated before dependent modules are changed.
- A recommendation is distinct from a pump command; safety/approval remains explicit.
- Each phase should retain a controlled fallback input for repeatable testing and the SIH demo.

## Common exchange format

The shared device reading is represented by `packages/contracts/src/events.js` and the edge API accepts it at `POST /v1/readings`.

```json
{
  "deviceId": "field-node-01",
  "zoneId": "zone-a",
  "soilMoisturePct": 24,
  "temperatureC": 34,
  "humidityPct": 55,
  "rainfallMm": 0,
  "waterLevelPct": 12
}
```

An advisory should remain farmer-readable: a type, severity, title, explanation, and suggested action. The exact schemas, thresholds, models, persistence choice, and transport protocol are deliberately not fixed here; they should reflect the hardware and evidence available during the build.

## Ownership map

| Brief | Scope |
| --- | --- |
| `01-firmware-iot.md` | Field sensors, actuator safety, local communication |
| `02-crop-health-ai.md` | Disease and nutrient-deficiency vision |
| `03-pest-risk-intelligence.md` | Pest vision plus irrigation/environment risk logic |
| `04-farmer-mobile-app.md` | Farmer action surface |
| `05-backend-edge-system.md` | Local system, persistence, sync, APIs |
| `06-dashboard-integration.md` | Operator view, integration, demo reliability |

Hardware assembly and end-to-end field testing are shared by the whole team.
