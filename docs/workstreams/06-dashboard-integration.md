# Workstream 06 — Dashboard and system integration

## Context

The dashboard makes Citadel legible to a cooperative operator, evaluator, or farm manager. Integration makes the project real: it ensures a physical sensor change can become a visible recommendation and that each component shares the same meaning for a zone, event, severity, and time.

## Phase 1 MVP outcome

A web dashboard displays live local farm state, current alerts, and a small history or trend view where available. It runs alongside the edge API and demonstrates the same information as the farmer app at a more operational level. The full system has a rehearsed, repeatable demo flow with known fallback data for hardware or network failures.

The dependency-free starter in `apps/dashboard/` already polls `GET /v1/farm-state` and renders current sensor metrics and advisories.

## Scope

- Dashboard information model: field/zone selector if needed, device status, sensor summary, active risk alerts, and a useful historical view.
- Local edge API integration and transparent handling when a node is unavailable or data is stale.
- Consistent styling/meaning for advisory types and severities across dashboard and mobile app.
- Cross-module contract checks with firmware, AI, risk, backend, and mobile owners.
- Repeatable field and presentation scenario: normal state, irrigation need, disease/pest finding, and flood/heat scenario.
- Integration defect tracking and final environment readiness, including practical run instructions.

## Interfaces

The dashboard should consume farm-state data rather than duplicate decision logic. It may use a history endpoint once the backend exposes one. The dashboard’s value is the context around recommendations: what changed, which zone/device is affected, and how urgent it is.

## Practical MVP evidence

- Starting the edge API and dashboard produces a working local view without cloud configuration.
- A changed sensor payload changes the dashboard state.
- At least one view explains both the alert and the data supporting it.
- The demo can still communicate the full system path if a physical component is unavailable, without hiding that it is a fallback.

## Design space still open

Charting library, framework, visual design, deployment approach, history depth, and the exact demo tooling are open. The emphasis is on a reliable narrative and integration quality, not a dense analytics product.
