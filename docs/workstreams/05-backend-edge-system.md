# Workstream 05 — Backend and edge system

## Context

The backend is the connective tissue of the product, but Phase 1 centres on the local edge system—not a dependency on remote cloud infrastructure. It accepts events from the farm node and vision modules, exposes a consistent state to the app/dashboard, retains enough history for the demo, and later synchronizes when connectivity returns.

## Phase 1 MVP outcome

The edge API receives a sensor reading, validates/normalizes it, derives or requests advisories, and returns a stable `farm-state` response to local clients. It can retain recent readings/events across a restart if the selected persistence layer is ready; otherwise its ephemeral limitation is explicit for the hackathon demo.

`services/edge-api/` is already runnable with no external packages. `services/cloud-api/` is intentionally only a placeholder for the delayed-sync boundary. `packages/contracts/` is the source of shared data shapes.

## Scope

- Local API design, input validation, error handling, and device/zone identification.
- Reading, image-result, advisory, and action-event lifecycle.
- Local persistence and retention suitable for intermittent network conditions.
- Integration point for crop/pest inference and the risk/advisory engine.
- Controlled actuator-request pathway, auditability, and safe command acknowledgement.
- Delayed cloud-sync design: what is queued locally, how duplicate events are handled, and what can still work offline.
- Basic system observability: health status, recent device contact, and enough logs to debug a demo issue.

## Interfaces

The existing MVP routes establish a simple initial contract:

- `GET /health`
- `GET /v1/farm-state`
- `POST /v1/readings`

The dashboard and farmer app consume farm state. Firmware supplies readings. AI modules supply named results with confidence and metadata. The shared contract must evolve carefully when each part is integrated, since it is the main point where independently built modules meet.

## Practical MVP evidence

- A JSON reading posted locally produces a state and advisory visible to both UI surfaces.
- Network absence does not prevent the edge API from serving local consumers.
- Invalid payloads and unavailable AI results fail gracefully rather than collapsing the farm state.

## Design space still open

Implementation language beyond the existing Node starter, database choice, authentication, queueing mechanism, model invocation method, and cloud vendor are open. A small local system with clear interfaces is more valuable in Phase 1 than a broad remote platform.
