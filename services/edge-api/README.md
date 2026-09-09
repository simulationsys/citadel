# Edge API

Runs on the Raspberry Pi/Jetson farm node. It accepts local sensor readings, AI observations, creates offline advisories, and keeps a bounded local event history.

- `GET /health` checks the node.
- `GET /v1/farm-state?zoneId=zone-a` returns the latest reading, observations, advisories, and irrigation-request audit state.
- `GET /v1/zones` and `GET /v1/history` provide local operational context.
- `POST /v1/readings` accepts ESP32 gateway readings.
- `POST /v1/observations` accepts crop-health or pest model outputs.
- `POST /v1/crop-health?zoneId=zone-a` accepts raw JPEG/PNG bytes and returns the crop result plus updated farm state.
- `POST /v1/pest-detection?zoneId=zone-a` accepts raw JPEG/PNG bytes and returns detected pests plus updated farm state.
- `POST /v1/irrigation/requests` and `POST /v1/irrigation/requests/:id/approve` record explicit human approval; they never issue a direct pump command.

Set `RISK_SERVICE_URL=http://127.0.0.1:8001` to consume `ml/pest-risk` locally. Without it, the edge API safely uses its built-in fallback rules. The current in-memory store is intentional MVP storage; replace it with SQLite before field testing.
