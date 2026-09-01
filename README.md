# Citadel — Smart Farming Assistant

Citadel is an offline-first farm monitoring platform. An ESP32 reads field sensors and controls a relay; an edge device receives readings, runs vision inference, generates advisories, and syncs to the cloud when a connection exists.

```text
apps/                  Farmer and operator interfaces
  farmer-app/          Expo/React Native mobile app
  dashboard/           Browser dashboard
services/
  edge-api/            Farm-node API and local decision engine
  cloud-api/           Sync and multi-farm API
firmware/esp32-field-node/  Sensors, relay, and transport
ml/vision/             Model training/export/inference
packages/contracts/    Shared event payloads and advisory terms
infra/                 Deployment material
docs/                  Architecture and demo guide
```

Run `npm run dev:edge` and `npm run dev:dashboard` for the local demo. POST a reading to `http://localhost:3001/v1/readings` to update the farm state.

| Area | Owner |
| --- | --- |
| `firmware/esp32-field-node` | device + sensors |
| `ml/vision` | disease/pest vision |
| `services/edge-api/src/advisory.js` | irrigation and risk logic |
| `apps/farmer-app` | farmer mobile app |
| `apps/dashboard` | dashboard |
| `services/cloud-api`, `packages/contracts`, `infra` | sync, contracts, integration |
