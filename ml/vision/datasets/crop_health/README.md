# Crop Health Dataset — Tomato

> **Workstream 02 — Crop Health AI**
> Phase 2: Dataset pipeline

## Overview

This dataset contains labelled tomato leaf images for training a lightweight
crop health classifier. It is built from the PlantVillage public dataset,
cleaned, deduplicated, and split into reproducible train/val/test partitions.

## Supported classes

| Index | Label constant           | Source class (PlantVillage)         |
|-------|--------------------------|-------------------------------------|
| 0     | `healthy`                | Tomato___healthy                    |
| 1     | `early_blight`           | Tomato___Early_blight               |
| 2     | `late_blight`            | Tomato___Late_blight                |
| 3     | `leaf_spot`              | Tomato___Septoria_leaf_spot         |
| 4     | `yellow_leaf_curl_virus` | Tomato___Tomato_Yellow_Leaf_Curl_Virus |

## Dataset sources

| Source       | URL                                                             | License            |
|--------------|-----------------------------------------------------------------|--------------------|
| PlantVillage | https://github.com/spMohanty/PlantVillage-Dataset               | CC0 / public use   |
| PlantVillage (Kaggle) | https://www.kaggle.com/datasets/arjuntejaswi/plant-village | CC BY-SA 4.0     |

The PlantVillage dataset was created by David P. Hughes and Marcel Salathe
(2015).  Images are lab-captured with relatively uniform backgrounds.

## Directory structure

```text
datasets/crop_health/
├── raw/                    # Original downloaded images, by class
│   ├── healthy/
│   ├── early_blight/
│   ├── late_blight/
│   ├── leaf_spot/
│   ├── yellow_leaf_curl_virus/
│   └── _quarantine/        # Images removed during cleaning/dedup
├── processed/              # Resized (224×224) images, by split and class
│   ├── train/{class}/
│   ├── val/{class}/
│   └── test/{class}/
├── train/                  # Split source images (pre-resize)
│   └── {class}/
├── val/
│   └── {class}/
├── test/                   # FROZEN — do not modify
│   └── {class}/
└── metadata/               # Pipeline reports and manifests
    ├── download_manifest.json
    ├── cleaning_report.json
    ├── dedup_report.json
    ├── split_report.json
    ├── preprocessing_report.json
    ├── augmentation_report.json
    ├── frozen_test_set.json
    └── verification_report.json
```

## Split strategy

| Split      | Ratio | Purpose                        |
|------------|-------|--------------------------------|
| Train      | 70%   | Model training + augmentation  |
| Validation | 15%   | Hyperparameter tuning, early stopping |
| Test       | 15%   | Final evaluation only          |

- **Random seed:** 42
- **Split unit:** individual image files (all augmented variants inherit the
  source image's split assignment)
- **Leakage prevention:** filenames are checked across splits; no source image
  appears in more than one split

## Cleaning rules

1. Images must be readable by PIL and pass `verify()`
2. Minimum resolution: 64×64 px
3. Valid formats: `.jpg`, `.jpeg`, `.png`
4. File size: ≤ 5 MB
5. Colour mode: RGB, RGBA, or L (greyscale) — all converted to RGB
6. Empty or zero-byte files are quarantined

Cleaned-out images are moved to `raw/_quarantine/` — never silently deleted.

## Deduplication

- Perceptual hashing (average hash, 64-bit)
- Intra-class near-duplicates (hamming distance ≤ 8): moved to quarantine
- Cross-class near-duplicates: flagged for manual review, not removed

## Preprocessing

Applied to all splits:

| Step       | Detail                                    |
|------------|-------------------------------------------|
| Resize     | 224 × 224 px (bilinear interpolation)     |
| Colour     | BGR → RGB                                 |
| Format     | Saved as JPEG (quality 95)                |
| Normalisation | ImageNet mean (0.485, 0.456, 0.406), std (0.229, 0.224, 0.225) — applied at model input time, not in saved files |

## Augmentation policy

Applied to **training set only**. Not applied to validation or test.

| Transform               | Parameters                    |
|--------------------------|-------------------------------|
| Horizontal flip          | p = 0.5                       |
| Rotation                 | ±15°, reflect border, p = 0.5 |
| Brightness/contrast      | ±15%, p = 0.5                 |
| Random resized crop      | scale 0.85–1.0, p = 0.4      |
| Gaussian noise           | σ = 0.01–0.03, p = 0.3       |

Under-represented classes receive additional augmentation copies (up to 5×)
to improve class balance.

**Excluded transforms:** vertical flip (leaves don't normally appear flipped),
colour inversion, cutout/erasing (risks hiding symptoms), heavy distortion.

## Limitations

1. **Lab images only** — PlantVillage backgrounds are uniform; field images
   will have more varied backgrounds (soil, sky, other plants)
2. **No field-captured images** — domain gap between lab and field is expected
3. **Single source** — all images from one dataset; diversity is limited
4. **No nutrient deficiency images** — out of scope for Phase 1

## Reproducibility

To reproduce the dataset from scratch:

```bash
cd ml/vision/
.venv/Scripts/activate        # Windows
# source .venv/bin/activate   # Linux/Mac

python -m src.dataset.pipeline
```

Or to use a locally downloaded PlantVillage directory:

```bash
python -m src.dataset.pipeline --source-dir /path/to/plantvillage
```

All random operations use seed 42.  The pipeline is deterministic given the
same input data.

## Pipeline scripts

| Script                       | Purpose                           |
|------------------------------|-----------------------------------|
| `src/dataset/config.py`      | Shared constants and paths        |
| `src/dataset/download.py`    | Download and organise raw data    |
| `src/dataset/clean.py`       | Validate and quarantine bad images|
| `src/dataset/deduplicate.py` | Perceptual hash deduplication     |
| `src/dataset/split.py`       | Reproducible train/val/test split |
| `src/dataset/preprocess.py`  | Resize and format images          |
| `src/dataset/augment.py`     | Training-only augmentation        |
| `src/dataset/verify.py`      | Comprehensive verification        |
| `src/dataset/pipeline.py`    | Run all steps in sequence         |
