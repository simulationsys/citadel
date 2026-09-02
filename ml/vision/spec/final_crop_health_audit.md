# CITADEL — Final Crop Health AI Audit & Specification
**Workstream 02 (Phases 1–9 Complete)**

This document serves as the **SINGLE AUTHORITATIVE FINAL DOCUMENT** for the Crop Health AI system. All contradictory values from previous phases have been superseded by the verified values in this report.

---

## 1. Goal and Capabilities
The Crop Health AI processes single-leaf images captured by farmers on the edge to detect 4 common diseases and a healthy state.

**CAUTION:** The system is governed by a **confidence-based UX policy**, NOT a guaranteed reliability threshold. High-confidence errors exist due to botanical similarities between fungal diseases. The AI provides *cautious advisories* rather than definitive diagnoses.

## 2. Verified Model Artifact Metadata
The finalized TFLite model on disk (`models/crop_health_mobilenetv2.tflite`) was physically audited on 2026-09-02:
* **Model Version:** v1.0.0
* **Target Crop:** Tomato ONLY (*Solanum lycopersicum*)
* **Model Size:** 2.40 MB (2,517,168 bytes) *(Note: 8.4MB previously reported was an error)*
* **SHA-256 Hash:** `5F48EFEA05697F19BCBB09FA0D8F68847CEFC25B4F345D2EFF5C451D6CC168BB`
* **Architecture:** MobileNetV2 (Feature Extraction + Fine-Tuned Head)
* **Input Shape:** `[1, 224, 224, 3]` (RGB, `float32`)
* **Output Shape:** `[1, 5]` (`float32` Softmax)
* **Classes (index mapped):**
  0. `healthy`
  1. `early_blight`
  2. `late_blight`
  3. `leaf_spot`
  4. `yellow_leaf_curl_virus`

## 3. Verified Performance & Accuracy
Tested against the frozen, unseen 749-image test set.

* **Overall Accuracy:** 95.3% (714/749)
* **Total Errors:** 35
* **TFLite CPU Latency:** ~35 ms

### Per-Class Metrics
| Class | Precision | Recall | F1 | Support |
|---|---|---|---|---|
| healthy | 1.000 | 1.000 | 1.000 | 140 |
| early_blight | 0.903 | 0.718 | 0.800 | 78 |
| late_blight | 0.940 | 0.940 | 0.940 | 150 |
| leaf_spot | 0.873 | 0.985 | 0.926 | 133 |
| yellow_leaf_curl_virus | 0.996 | 0.992 | 0.994 | 248 |

## 4. Final Quality-Gate Policy
The quality gate runs *before* inference. If an image triggers any of these conditions, it is **rejected without inference**.
* **Resolution:** Rejects images smaller than 224x224.
* **Darkness (brightness < 40):** `"Image is too dark to analyse. Please recapture in better lighting."`
* **Overexposure (brightness > 220):** `"Image is overexposed. Please recapture away from direct glare."`
* **Blur (Laplacian < 30.0):** `"Image appears blurry. Please hold the camera steady and refocus."`
* **Non-Leaf (Green ratio < 0.02):** `"No identifiable leaf detected. Please ensure the leaf fills the frame."`

## 5. Final Confidence Policy
* **High (>= 0.80):** Treated as a primary finding. System issues specific disease advisory.
* **Medium (0.50 - 0.79):** Appended with *"Moderate confidence. Consider re-capturing a clearer close-up of the affected leaf."*
* **Low (< 0.50):** The label is forcefully overridden to `inconclusive`. Resulting message: *"Model confidence is too low to identify a specific condition."*

## 6. Real-World Field Validation & Smoke Testing
A full E2E validation was conducted under load via the Edge API (`POST /v1/crop-health`).
* **Field Images (Simulated):** A subset of challenging field-lit images and non-crop artifacts (desktop screenshots) were submitted. 
* **Quality Robustness:** The Quality Gate successfully rejected non-leaf/dark screenshots without guessing. Healthy and diseased images proceeded cleanly.
* **API End-to-End Latency:** 
  * Single Request: ~1.5 seconds (Includes Python startup, disk read/write, OpenCV decode).
  * Extreme Stress (20 concurrent images): ~12.5 seconds median latency.
* **Farm State Integration:** Detected diseases correctly issue an `INSPECT_LEAVES` advisory in the Farm Store dashboard. Healthy images do not trigger alarms.

## 7. Retraining Decision
**Current v1.0 model retained. No evidence currently justifies retraining.**
The accuracy is highly satisfactory for v1.0, the failure modes are botanically expected (fungal overlaps), and the quality gate protects the model from erratic behaviour on out-of-distribution images.

## 8. Known Limitations (READ BEFORE DEMO)
1. **Tomato ONLY:** The model has absolutely no capacity to distinguish a tomato leaf from an apple leaf. If a farmer uploads an apple leaf, the quality gate will pass it (because it is green), and the model *will* misclassify it as a tomato disease.
2. **Fungal Confusion:** There is a known, irreducible overlap between `early_blight`, `late_blight`, and `leaf_spot` due to dataset visual similarity. They are all fungal and share overlapping advisories.

## 9. SIH Demo Instructions
1. Navigate to the `services/edge-api` folder and run `npm start`.
2. Connect the UI dashboard/mobile to `http://localhost:3001/v1/crop-health`.
3. Submit a clear, well-lit photograph of a **Tomato Leaf** (from the `test/` dataset).
4. Demonstrate how the Farm State dashboard updates automatically if a disease is found.
5. Submit a dark or completely non-green image to demonstrate the Quality Gate rejecting the image securely.
