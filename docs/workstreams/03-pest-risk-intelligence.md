# Workstream 03 — Pest AI and farm-risk intelligence

## Context

This workstream owns two related decisions: spotting visible pest activity and translating environmental/crop signals into early, understandable risk. Pest outbreaks and water/climate stress are both more useful when reported before they become visibly severe. The advisory should favour targeted inspection and action, rather than broad chemical recommendations.

## Phase 1 MVP outcome

For the selected crop, one pest category can be identified or approximated from an image, with an activity/severity level. The same local intelligence layer transforms sensor readings into at least these demonstrable advisory conditions: irrigation need, heat/drought stress, and high-rainfall or water-level/flood risk.

The starter rule layer is `services/edge-api/src/advisory.js`. Its thresholds are placeholders intended to make the system demonstrable; they should not be represented as agronomic prescriptions.

## Scope

- Choose one locally relevant pest and an image/detection strategy suitable for available camera placement and data.
- Represent pest evidence as a count, class confidence, activity level, or inspection recommendation, depending on what the model can truthfully support.
- Design the risk score or rule system combining moisture, temperature, humidity, rainfall/water level, crop-health result, and pest signals.
- Convert internal signals into concise advisory objects: severity, explanation, suggested next action, and rationale.
- Make uncertainty and conflicting inputs visible. For example, a low moisture reading during rain should not lead to an unqualified irrigation instruction.
- Establish a clear boundary between a decision-support alert and actuation. Risk intelligence recommends; irrigation actuation has its own safety/approval model.

## Interfaces

Sensor readings arrive from the firmware path and use the shared contracts. Crop-health events arrive from Workstream 02. The backend returns the combined farm state at `GET /v1/farm-state`; the mobile app and dashboard display the same advisory vocabulary.

```json
{
  "type": "heat",
  "severity": "warning",
  "title": "Heat-stress risk",
  "message": "High temperature and dry soil.",
  "action": "SCHEDULE_EVENING_IRRIGATION"
}
```

## Practical MVP evidence

- Changing demo sensor values visibly changes the advisory outcome.
- A pest/crop result can elevate or add a targeted inspection alert.
- The explanation makes it clear which observation led to the recommendation.

## Design space still open

The pest, model method, advisory threshold approach, risk-score math, crop-specific calibration, and the number of risks demonstrated are open choices. Strong evidence, traceable reasoning, and restrained recommendations matter more than complexity.
