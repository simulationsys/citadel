# Crop Health AI — Phase 1 MVP Specification

> **Workstream 02** · Status: **Phase 1 — specification frozen**
> Last updated: 2026-09-01

---

## 1. Selected crop

**Tomato** (*Solanum lycopersicum*)

### Rationale

- The existing workstream document (`docs/workstreams/02-crop-health-ai.md`)
  already uses tomato as the example crop (`"crop": "tomato"`,
  `"label": "possible_early_blight"`).
- Tomato is the most studied crop in publicly available leaf-disease datasets
  (PlantVillage, PlantDoc, AI Challenger). It has the largest per-class sample
  count, providing a strong foundation for a credible MVP.
- Tomato diseases (blights, spots) present with clearly distinguishable visual
  symptoms on leaves — well suited to a lightweight CNN classifier.
- Tomato is widely grown in Indian smallholder farms and Citadel targets Indian
  agriculture.

---

## 2. Supported classes

| # | Label constant           | Display name             | Dataset source class       |
|---|--------------------------|--------------------------|----------------------------|
| 0 | `healthy`                | Healthy                  | Tomato — healthy           |
| 1 | `early_blight`           | Possible early blight    | Tomato — Early blight      |
| 2 | `late_blight`            | Possible late blight     | Tomato — Late blight       |
| 3 | `leaf_spot`              | Possible leaf spot       | Tomato — Septoria leaf spot|
| 4 | `yellow_leaf_curl_virus` | Possible leaf curl virus | Tomato — Yellow Leaf Curl Virus |

**5 classes total.** This is the minimum credible set: one healthy baseline, two
high-impact fungal diseases, one bacterial/fungal spot, and one viral condition
with clearly distinct visual presentation.

### Out-of-scope conditions (Phase 1)

The following are **not** classified in Phase 1. Images showing these conditions
should be reported as low-confidence or `inconclusive`:

- Nutrient deficiencies (nitrogen, phosphorus, potassium, calcium) — visually
  ambiguous without soil data; deferred to Phase 2 with sensor fusion.
- Spider mite damage — overlaps with Workstream 03 (Pest AI).
- Bacterial speck, bacterial spot — too visually similar to each other and to
  leaf spot for reliable lightweight classification.
- Target spot, mosaic virus — insufficient distinct samples in primary datasets
  to meet the validation bar.
- Any non-tomato crop image — the model does not detect crop type; a non-tomato
  leaf may produce an arbitrary class with false confidence.

---

## 3. Image requirements

### Capture conditions

| Parameter         | Requirement                                           |
|-------------------|-------------------------------------------------------|
| Subject           | Single leaf or small cluster of leaves, filling > 40% of the frame |
| Distance          | 15–40 cm from the leaf surface                        |
| Lighting          | Diffused daylight preferred; avoid direct flash glare |
| Background        | Any; leaf must be visually dominant                    |
| Orientation       | Any rotation is acceptable                            |
| Input resolution  | Minimum 224 × 224 px (model input); capture at ≥ 640 × 480 recommended |
| Format            | JPEG or PNG (JPEG preferred for size on-device)       |
| Max file size     | 5 MB (pre-resize)                                     |

### Quality states

| State        | Criteria                                                                 | System behaviour                                                         |
|--------------|--------------------------------------------------------------------------|--------------------------------------------------------------------------|
| `acceptable` | Leaf is in focus, adequately lit, and fills ≥ 40% of the frame           | Run inference normally                                                   |
| `poor`       | Minor blur, partial shadow, or leaf occupies 20–40% of frame             | Run inference but cap confidence at `medium`; add `limitation` note      |
| `invalid`    | Extreme blur, no visible leaf, total darkness/saturation, corrupted file | Return `label: "invalid_image"`, `confidence: 0.0`, skip classification  |

### Handling unsuitable images

- **`poor` quality**: The result is returned with `imageQuality: "poor"` and
  `limitation` set to a human-readable reason (e.g.,
  `"Image quality is poor; result may be unreliable"`). The advisory layer
  should treat this as informational, not actionable.
- **`invalid` quality**: No classification is attempted. The result is returned
  immediately with `label: "invalid_image"` and a `limitation` message. The
  Edge API records the event but does not generate a disease advisory.

> **Note:** Image quality classification in Phase 1 will use heuristic checks
> (Laplacian variance for blur, brightness histogram analysis). A learned
> quality gate may be added in Phase 2.

---

## 4. Confidence policy

### Tiers

| Tier     | Confidence range | Interpretation                                           | System behaviour                                                          |
|----------|------------------|----------------------------------------------------------|---------------------------------------------------------------------------|
| **High** | ≥ 0.80           | Model is confident in this prediction                    | Result is surfaced as the primary finding in advisory/dashboard            |
| **Medium** | 0.50 – 0.79    | Plausible but uncertain                                  | Result is surfaced with a qualifying note; advisory recommends inspection  |
| **Low**  | < 0.50           | Model is not confident; prediction may be wrong          | Label is reported as `"inconclusive"`; no disease advisory is generated    |

### Design principles

1. **Prefer uncertainty over false certainty.** A low-confidence result must
   never trigger a definitive disease advisory or treatment recommendation.
2. **Do not suppress low-confidence results.** They are still recorded in the
   event history and visible in the dashboard for the operator.
3. **Threshold calibration.** The numerical boundaries above (0.80, 0.50) are
   initial working values chosen for safety. They **must** be recalibrated
   after Phase 2 evaluation on a held-out test set with clinical-style
   precision/recall analysis. These values will be stored in a configuration
   file (`ml/vision/config/confidence_thresholds.json`), not hardcoded.

### Confidence-to-label override

When `confidence < 0.50`, the system overrides the predicted label:

```
reported_label = "inconclusive" if confidence < LOW_THRESHOLD else predicted_label
```

This prevents the downstream advisory from acting on unreliable predictions.

---

## 5. Output contract

The crop-health result is the single structured object produced by the Crop
Health AI module and consumed by the Edge API. It is compatible with the
existing advisory vocabulary in `packages/contracts/src/events.js`.

### Schema

```json
{
  "kind": "crop_health",
  "crop": "tomato",
  "label": "early_blight",
  "confidence": 0.87,
  "imageQuality": "acceptable",
  "limitation": null
}
```

### Field definitions

| Field          | Type              | Required | Values / constraints                                                                                      |
|----------------|-------------------|----------|-----------------------------------------------------------------------------------------------------------|
| `kind`         | `string`          | yes      | Always `"crop_health"`                                                                                    |
| `crop`         | `string`          | yes      | `"tomato"` (Phase 1); extensible to other crops later                                                     |
| `label`        | `string`          | yes      | One of: `"healthy"`, `"early_blight"`, `"late_blight"`, `"leaf_spot"`, `"yellow_leaf_curl_virus"`, `"inconclusive"`, `"invalid_image"` |
| `confidence`   | `number`          | yes      | `0.0` – `1.0`; softmax probability of the predicted class                                                |
| `imageQuality` | `string`          | yes      | One of: `"acceptable"`, `"poor"`, `"invalid"`                                                             |
| `limitation`   | `string \| null`  | yes      | `null` when no limitation; otherwise a human-readable explanation (≤ 200 chars)                           |

### Compatibility notes

- The `kind` field distinguishes crop-health results from future pest results
  (Workstream 03 will use `"kind": "pest_detection"`). The Edge API already
  supports advisory types `DISEASE`, `PEST`, etc. via `advisoryTypes` in
  `packages/contracts/src/events.js`.
- The contract deliberately omits model internals (architecture name, logit
  vector, gradient maps). These belong in training logs, not in the API
  surface.
- The `limitation` field carries the uncertainty message to the farmer-facing
  UI without requiring the frontend to interpret confidence tiers.

### Example responses

**High confidence, good image:**
```json
{
  "kind": "crop_health",
  "crop": "tomato",
  "label": "late_blight",
  "confidence": 0.92,
  "imageQuality": "acceptable",
  "limitation": null
}
```

**Medium confidence, poor image:**
```json
{
  "kind": "crop_health",
  "crop": "tomato",
  "label": "leaf_spot",
  "confidence": 0.63,
  "imageQuality": "poor",
  "limitation": "Image quality is poor; result may be unreliable. Consider re-capturing in better light."
}
```

**Low confidence (overridden to inconclusive):**
```json
{
  "kind": "crop_health",
  "crop": "tomato",
  "label": "inconclusive",
  "confidence": 0.34,
  "imageQuality": "acceptable",
  "limitation": "Model confidence is too low to identify a specific condition."
}
```

**Invalid image:**
```json
{
  "kind": "crop_health",
  "crop": "tomato",
  "label": "invalid_image",
  "confidence": 0.0,
  "imageQuality": "invalid",
  "limitation": "No identifiable leaf in the image. Please capture a clear photo of a single leaf."
}
```

---

## 6. Dataset requirements

### Primary data sources

| Source                  | Availability | Tomato classes | Notes                                     |
|-------------------------|-------------|----------------|--------------------------------------------|
| PlantVillage (Kaggle)   | Public       | 10 classes, ~18k images | Lab-captured, uniform backgrounds       |
| PlantDoc                | Public       | Multiple crops, ~2.5k total | Field-like images, more realistic      |
| Custom field captures   | Team-collected | As captured  | Indian conditions; augments domain shift   |

### Class balance

- Aim for roughly equal representation per class (±20% of the mean count).
- If a class is under-represented, use augmentation to reach the minimum.
- Minimum **300 images per class** after augmentation for training.

### Splits

| Split       | Proportion | Purpose                                           |
|-------------|------------|---------------------------------------------------|
| Train       | 70%        | Model training                                    |
| Validation  | 15%        | Hyperparameter tuning, early stopping              |
| Test        | 15%        | Final evaluation only; **never** used during training or tuning |

### Leakage prevention

- Split at the **image source level**, not at the augmented-image level.
  All augmented variants of a single source image must stay in the same split.
- If multiple images were captured of the same leaf (burst/sequence), all
  belong to the same split. Tag bursts during data preparation.
- The test set is **frozen** after initial creation. No images may be moved
  out of or into the test set after the first evaluation.

### Augmentation (training set only)

| Transform             | Parameters                              |
|-----------------------|-----------------------------------------|
| Random horizontal flip | p = 0.5                                |
| Random rotation        | ±15°                                   |
| Random brightness/contrast | ±15%                              |
| Random crop + resize   | Scale 0.85–1.0, resize to 224 × 224   |
| Gaussian noise         | σ = 0.01 (light)                       |

No augmentation is applied to validation or test sets.

### Image filtering

Before inclusion in any split, an image must pass:

1. Minimum resolution: 224 × 224 px
2. Not a duplicate (perceptual hash deduplication)
3. Contains a visible leaf (manual spot-check per batch; automated gate in Phase 2)
4. Correct label verified by at least one reviewer

### Metadata documentation

For every dataset version, record:

- Source name and URL
- Download date
- License / terms of use
- Total image count per class (pre- and post-augmentation)
- Augmentation pipeline version
- Split assignments (reproducible random seed)

Store this in `ml/vision/data/dataset_manifest.json` (the actual image data
stays out of Git per `.gitignore` and the vision README policy).

---

## 7. Model requirements

These are requirements for the **future** model to be built in Phase 2.
Phase 1 does not train a model.

### Architecture constraints

- Must be a **lightweight CNN** suitable for edge inference on
  Raspberry Pi 4 / Jetson Nano class hardware.
- Recommended starting points: MobileNetV2 or EfficientNet-Lite with
  transfer learning from ImageNet.
- Input size: 224 × 224 × 3 (RGB).
- Output: softmax over the 5 disease classes.

### Reproducible training

- All training scripts live in `ml/vision/src/`.
- Fixed random seeds for Python, NumPy, and TensorFlow.
- Training configuration (learning rate, epochs, batch size) stored in a
  versioned config file, not in code comments.
- Each training run produces a log with: date, config hash, final
  train/val loss and accuracy, per-class precision/recall on validation set.

### Export and deployment

- Export to **TensorFlow Lite** (`.tflite`) for on-device inference.
- Exported models are saved to `ml/vision/models/` (gitignored).
- Each exported model is accompanied by a metadata sidecar:
  `model_metadata.json` containing class list, input shape, training config
  hash, and validation metrics.

### Evaluation requirements

- Report **per-class precision, recall, F1** on the frozen test set.
- Report **confusion matrix**.
- Report **overall accuracy** and **macro-averaged F1**.
- Minimum bar for Phase 1 deployment: macro-F1 ≥ 0.75 on the test set.
  Below this, the model is documented but not deployed.

### Inference performance

- Target inference latency: **< 500 ms** per image on Raspberry Pi 4
  (CPU, single-threaded TFLite interpreter).
- Model file size: **< 20 MB** (quantized `.tflite`).

### Safe low-confidence handling

- If the model's top-1 softmax probability is below the low-confidence
  threshold (currently 0.50), the inference adapter must report
  `label: "inconclusive"` regardless of the predicted class.
- The inference adapter, not the model itself, is responsible for this
  override. The raw softmax vector is logged for analysis but not exposed
  in the output contract.

---

## 8. Edge integration boundary

```text
┌──────────────┐     ┌──────────────────┐     ┌────────────────┐
│  Leaf Image   │────▶│  Crop Health AI   │────▶│ Structured     │
│  (camera /    │     │  (ml/vision/)     │     │ Result (JSON)  │
│   upload)     │     │                  │     │                │
└──────────────┘     └──────────────────┘     └───────┬────────┘
                                                       │
                                              POST /v1/crop-health
                                                       │
                                                       ▼
                                              ┌────────────────┐
                                              │  Edge API       │
                                              │  (services/     │
                                              │   edge-api/)    │
                                              └───────┬────────┘
                                                       │
                                              GET /v1/farm-state
                                                       │
                                    ┌──────────────────┼──────────────────┐
                                    ▼                                     ▼
                           ┌────────────────┐                    ┌────────────────┐
                           │  Farmer App     │                    │  Dashboard      │
                           │  (apps/         │                    │  (apps/         │
                           │   farmer-app/)  │                    │   dashboard/)   │
                           └────────────────┘                    └────────────────┘
```

### Boundary rules

1. **ML → Edge API only.** The Crop Health AI module sends its result to the
   Edge API via `POST /v1/crop-health` (new endpoint, Phase 2). It does **not**
   communicate directly with the mobile app, dashboard, or cloud API.

2. **Edge API is the integration point.** The Edge API receives crop-health
   results, stores them in the event history, feeds them into the advisory
   engine (`advisory.js`), and exposes them via the existing
   `GET /v1/farm-state` response.

3. **No irrigation/pesticide control.** The Crop Health AI produces a
   diagnostic signal, not an actuation command. Any treatment recommendation
   is the responsibility of the advisory layer (Workstream 03 / 05).

4. **No direct cloud dependency.** Inference runs locally. Cloud sync of
   results is a Workstream 05 concern.

5. **Contract is the interface.** The ML module and the Edge API agree only
   on the output contract (Section 5). The ML module may change its model
   architecture, training data, or inference runtime without requiring Edge
   API changes, as long as the contract is preserved.

---

## 9. Known limitations

| # | Limitation                                                         | Mitigation / plan                                         |
|---|--------------------------------------------------------------------|-----------------------------------------------------------|
| 1 | Single crop only (tomato)                                          | Extend to rice, wheat in Phase 2+                         |
| 2 | No crop-type detection — a non-tomato leaf may be misclassified    | Add crop-detection gate in Phase 2                        |
| 3 | Lab dataset bias (PlantVillage backgrounds ≠ field conditions)     | Augment with PlantDoc and field captures; track domain gap |
| 4 | No nutrient-deficiency classification                              | Deferred to Phase 2 with sensor fusion                    |
| 5 | Heuristic image quality gate (not learned)                         | Replace with learned quality model in Phase 2             |
| 6 | Confidence thresholds are not empirically calibrated               | Calibrate on held-out test set in Phase 2                 |
| 7 | No multi-disease detection (single label per image)                | Multi-label support is a Phase 3 consideration            |
| 8 | No temporal tracking (disease progression over time)               | Requires image series storage; Phase 3                    |

---

## 10. Phase 2 objectives

Phase 2 begins **after** this specification is approved and the dataset is
assembled. Phase 2 scope:

1. **Dataset assembly** — Download, filter, split, and version the tomato
   dataset per Section 6.
2. **Model training** — Train a MobileNetV2/EfficientNet-Lite classifier per
   Section 7.
3. **Evaluation** — Run the full evaluation suite; calibrate confidence
   thresholds against the frozen test set.
4. **TFLite export** — Produce a quantized `.tflite` artifact and metadata
   sidecar.
5. **Inference adapter** — Build the Python inference adapter in
   `ml/vision/src/` that loads the model, runs prediction, applies the
   confidence policy, and outputs the contract-format result.
6. **Edge API integration** — Add `POST /v1/crop-health` endpoint to the
   Edge API; wire results into `farm-state` and advisory generation.
7. **Image quality gate** — Implement the heuristic quality checks
   (blur, brightness, leaf presence).
8. **End-to-end test** — Leaf photo → inference → advisory → dashboard event.

---

## Appendix A: File and directory map

```text
ml/vision/
├── README.md                    # Module overview (existing)
├── requirements.txt             # Python deps (existing)
├── spec/
│   └── phase1-crop-health.md    # This specification
├── config/
│   └── confidence_thresholds.json  # Configurable confidence tiers (Phase 2)
├── data/
│   └── dataset_manifest.json    # Dataset version/split metadata (Phase 2)
├── models/                      # Exported .tflite artifacts (gitignored)
└── src/
    └── main.py                  # Entrypoint (existing; inference adapter in Phase 2)
```

## Appendix B: Contract TypeScript type (reference)

For teams consuming this in the JS/TS Edge API or mobile app:

```typescript
interface CropHealthResult {
  kind: "crop_health";
  crop: "tomato";
  label:
    | "healthy"
    | "early_blight"
    | "late_blight"
    | "leaf_spot"
    | "yellow_leaf_curl_virus"
    | "inconclusive"
    | "invalid_image";
  confidence: number;        // 0.0 – 1.0
  imageQuality: "acceptable" | "poor" | "invalid";
  limitation: string | null; // human-readable; ≤ 200 chars
}
```
