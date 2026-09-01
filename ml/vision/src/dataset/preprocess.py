"""Preprocessing pipeline: resize, normalise, and save processed images.

Usage:
    python -m dataset.preprocess

Processes train/, val/, and test/ splits into processed/ with consistent
dimensions and pixel value normalisation.  The same pipeline is used at
inference time to ensure train-serve parity.

The preprocessing is intentionally deterministic and reproducible.
"""

from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path

import cv2
import numpy as np

from .config import (
    CLASSES,
    DATASET_ROOT,
    METADATA_DIR,
    MODEL_INPUT_SIZE,
    PIXEL_MEAN,
    PIXEL_STD,
    PROCESSED_DIR,
    TEST_DIR,
    TRAIN_DIR,
    VAL_DIR,
    VALID_EXTENSIONS,
)


def preprocess_image(img_path: Path) -> np.ndarray:
    """Load, resize, and normalise a single image.

    Returns a float32 array of shape (H, W, 3) with ImageNet normalisation.
    This function is the canonical preprocessing step -- use it in both
    dataset preparation and model inference.
    """
    img = cv2.imread(str(img_path))
    if img is None:
        raise ValueError(f"Cannot read image: {img_path}")

    # Convert BGR -> RGB
    img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)

    # Resize to model input size (bilinear interpolation)
    img = cv2.resize(img, (MODEL_INPUT_SIZE[1], MODEL_INPUT_SIZE[0]),
                     interpolation=cv2.INTER_LINEAR)

    # Normalise to [0, 1] then apply ImageNet mean/std
    img = img.astype(np.float32) / 255.0
    img = (img - np.array(PIXEL_MEAN, dtype=np.float32)) / np.array(PIXEL_STD, dtype=np.float32)

    return img


def preprocess_image_uint8(img_path: Path) -> np.ndarray:
    """Load and resize only -- no normalisation.  Returns uint8 (H, W, 3) RGB.

    Useful for saving preprocessed images as files and for augmentation
    (which operates on uint8 images).
    """
    img = cv2.imread(str(img_path))
    if img is None:
        raise ValueError(f"Cannot read image: {img_path}")
    img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    img = cv2.resize(img, (MODEL_INPUT_SIZE[1], MODEL_INPUT_SIZE[0]),
                     interpolation=cv2.INTER_LINEAR)
    return img


def _process_split(split_name: str, split_dir: Path) -> dict[str, int]:
    """Process all images in a split directory."""
    counts: dict[str, int] = {}
    for cls in CLASSES:
        src = split_dir / cls
        if not src.is_dir():
            counts[cls] = 0
            continue

        dest = PROCESSED_DIR / split_name / cls
        dest.mkdir(parents=True, exist_ok=True)

        n = 0
        for img_path in sorted(src.iterdir()):
            if not img_path.is_file() or img_path.suffix.lower() not in VALID_EXTENSIONS:
                continue
            try:
                img = preprocess_image_uint8(img_path)
                # Save as JPEG (uint8, resized, RGB->BGR for cv2)
                out_path = dest / img_path.with_suffix(".jpg").name
                cv2.imwrite(str(out_path), cv2.cvtColor(img, cv2.COLOR_RGB2BGR),
                            [cv2.IMWRITE_JPEG_QUALITY, 95])
                n += 1
            except Exception as exc:
                print(f"    [WARN] Failed to process {img_path.name}: {exc}")
        counts[cls] = n
    return counts


def main() -> None:
    print("=" * 60)
    print("Citadel -- Image Preprocessing")
    print("=" * 60)
    print(f"  Target size: {MODEL_INPUT_SIZE[0]}x{MODEL_INPUT_SIZE[1]}")
    print(f"  Normalisation: ImageNet mean={PIXEL_MEAN}, std={PIXEL_STD}")

    all_counts: dict[str, dict[str, int]] = {}
    for split_name, split_dir in [("train", TRAIN_DIR), ("val", VAL_DIR), ("test", TEST_DIR)]:
        print(f"\n  Processing {split_name}/ ...")
        counts = _process_split(split_name, split_dir)
        all_counts[split_name] = counts
        total = sum(counts.values())
        print(f"    {split_name}: {total} images processed")

    # Write preprocessing report
    METADATA_DIR.mkdir(parents=True, exist_ok=True)
    report = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "model_input_size": list(MODEL_INPUT_SIZE),
        "normalisation": {"mean": list(PIXEL_MEAN), "std": list(PIXEL_STD)},
        "image_counts": all_counts,
    }
    report_path = METADATA_DIR / "preprocessing_report.json"
    report_path.write_text(json.dumps(report, indent=2))
    print(f"\n  Preprocessing report: {report_path}")


if __name__ == "__main__":
    main()
