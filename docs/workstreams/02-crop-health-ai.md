# Workstream 02 — Crop health AI

## Context

Farmers frequently notice disease or nutrient stress only after it spreads. This workstream turns a clear crop/leaf image into a cautious, useful crop-health signal that can be combined with local sensor context. The project should avoid claiming universal crop diagnosis: Phase 1 should be honest and crop-specific.

## Phase 1 MVP outcome

For one chosen crop, a submitted leaf image produces a result such as `healthy`, `possible early blight`, or `possible nitrogen deficiency`, with confidence and a human-readable limitation. The result reaches the local edge system without requiring a cloud request during the demonstration.

The workspace is `ml/vision/`. It currently provides a small Python entrypoint and dependency direction; model data, evaluation records, exported artifacts, and inference adapters can evolve from there.

## Scope

- Select the Phase 1 crop, its highest-value visible conditions, and the framing conditions under which imagery is usable.
- Establish a defensible dataset path: public sources, field images, augmentation, class balance, and validation separation.
- Develop a lightweight classification or detection approach appropriate for the available edge hardware.
- Produce a compact inference artifact suitable for the intended device, ideally with a reproducible path from training to export.
- Define the crop-health result supplied to the backend: class, confidence, image metadata, and an explanation appropriate to uncertainty.
- Consider image-quality gates such as blur, bad lighting, or no-leaf framing so weak inputs do not create false certainty.

## Interfaces

Crop health results feed the advisory layer rather than directly issuing pesticide instructions. A compatible result can look like:

```json
{
  "kind": "crop_health",
  "crop": "tomato",
  "label": "possible_early_blight",
  "confidence": 0.82,
  "imageQuality": "acceptable"
}
```

The backend/edge workstream will expose the final image-result route and retain results; the mobile app needs a concise status and a usable image-capture flow. The dashboard needs a time-stamped event, not raw model internals.

## Practical MVP evidence

- A small fixed test set demonstrates correct/incorrect cases and the model’s limits.
- Inference runs locally on the selected edge device or through a clearly isolated adapter that can be deployed there.
- A leaf photo produces a result that appears in an advisory or event history.

## Design space still open

The crop, class list, architecture, dataset source, confidence policy, and whether nutrient deficiency is a separate classifier or deferred from Phase 1 are intentionally open. The goal is a credible diagnostic signal, not the largest number of labels.
