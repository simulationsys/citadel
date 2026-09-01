# Citadel workstreams — Phase 1 MVP

Citadel is an offline-first Smart Farming Assistant for Indian farms. A field node observes soil and environmental conditions, captures crop images, performs as much analysis as practical at the edge, and surfaces a short, actionable advisory. The intended value is earlier intervention: less unnecessary watering and pesticide use, fewer missed crop-stress signals, and a useful system even with unreliable internet.

## Phase 1: one credible farm loop

The MVP proves one complete loop for a single crop and one demonstration zone:

```text
Sensors + camera → field node → local API / intelligence → advisory → mobile + dashboard
```

The baseline loop detects low soil moisture and produces an irrigation advisory. It also demonstrates a leaf/pest AI result and an environmental risk warning such as heat or flooding. A real model may be substituted by a representative small model or a clearly labelled demo result while data collection is ongoing; the system boundary and result format should remain the same.

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
