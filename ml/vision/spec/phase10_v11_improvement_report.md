# Phase 10: Crop Health AI v1.1 Model Improvement Report

## 1. Error Analysis & Dataset Audit

### The Problem
During Phase 6 evaluation on the 749-image frozen test set, `early_blight` recall was only **71.8%** (56/78 correct). The confusion matrix showed that 63.6% of early blight errors were misclassified as `leaf_spot` and 31.8% as `late_blight`.

### The Root Cause
A dataset audit revealed a severe structural class imbalance.
- **early_blight**: 362 original images
- **yellow_leaf_curl_virus**: 1,155 original images (3.19x more)

Even after augmenting `early_blight` 4x, it remained the smallest class in the training set. The standard `categorical_crossentropy` loss treated all samples equally, causing the model to optimize heavily for the majority classes while under-learning the subtle fungal distinctions. Furthermore, without label smoothing or confidence penalties, the model generated 18 high-confidence errors (≥ 0.80) on these hard cases.

---

## 2. Experiments Conducted

We designed two targeted experiments to address the structural imbalance without adding external data:

### Experiment A: Class-Weighted Loss
- **Approach:** Applied inverse-frequency class weights to standard categorical crossentropy. `early_blight` received ~3.2x the weight of `yellow_leaf_curl_virus`.
- **Validation Results:** Reached 97.46% val accuracy (loss: 0.0816) after 15 fine-tuning epochs.

### Experiment C: Focal Loss (Selected)
- **Approach:** Replaced crossentropy with Focal Loss (γ=2.0) combined with inverse-frequency class weights. Focal loss inherently down-weights "easy" well-classified examples and applies a strong gradient penalty to hard misclassifications, directly targeting the fungal confusion cluster.
- **Validation Results:** Reached 97.06% val accuracy (loss: 0.0439) after 15 fine-tuning epochs.

*(Experiments B - Enhanced Augmentation and D - Deeper Fine Tuning were deprioritized as A and C showed immediate, strong validation performance).*

---

## 3. v1.0 vs v1.1 Evaluation

The top candidate (Experiment C - Focal Loss) was evaluated ONCE against the frozen 749-image test set.

| Metric | v1.0 | v1.1 (Exp C) | Verdict |
|---|---|---|---|
| **Overall Accuracy** | 0.9533 | 0.9559 | [+] Better |
| **Macro F1** | N/A | 0.9372 | |
| **Early Blight Recall** | 0.7180 | 0.7821 | [+] Better |
| **Early Blight F1** | 0.8000 | 0.8188 | [+] Better |
| **Late Blight F1** | 0.9400 | 0.9360 | [-] Worse |
| **Leaf Spot F1** | 0.9260 | 0.9353 | [+] Better |
| **Healthy F1** | 1.0000 | 1.0000 | [=] Same |
| **YLCV F1** | 0.9940 | 0.9960 | [+] Better |
| **High-Conf Errors (≥0.80)** | 18 | 13 | [+] Better |

### Analysis of Results
Experiment C successfully improved `early_blight` recall by **6.4%** while slightly increasing overall accuracy. Crucially, the focal loss mechanism reduced the number of dangerous high-confidence mistakes from **18 to 13**, fulfilling the core Phase 10 objective of making the model more trustworthy.

---

## 4. Final Decision Record

**DECISION: PROMOTE v1.1 TO PRODUCTION**

- **Model Artifact:** `crop_health_mobilenetv2_v1.1.tflite`
- **Size:** 2.40 MB (Well under 15 MB limit)
- **Latency:** ~38 ms (Tested via inference pipeline)

The v1.1 artifact has been deployed to the `models/` directory, and the inference pipeline (`src/inference.py`) has been updated to use the new model. The original v1.0 model has been preserved as `crop_health_mobilenetv2_v1.0.tflite` for archival and rollback purposes.
