# Edge API

Runs on the Raspberry Pi/Jetson farm node. It accepts local sensor readings and creates offline advisories.

- `GET /health` checks the node.
- `GET /v1/farm-state` returns the latest reading and advisories.
- `POST /v1/readings` accepts ESP32 gateway readings.

The current in-memory store is intentional boilerplate; replace it with SQLite before field testing.
