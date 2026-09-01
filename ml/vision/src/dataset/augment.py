"""Training-only data augmentation.

Usage:
    python -m dataset.augment

Applies augmentations ONLY to the training set.  Validation and test sets
are never augmented.

The augmentations are conservative and plant-appropriate:
- No colour inversion (unrealistic leaf appearance)
- No extreme distortion (would create fake symptoms)
- Rotations limited to 15 (leaves don't flip upside down in typical images)

Augmented images are saved alongside originals in processed/train/ with
an `_aug{N}` suffix.
"""

from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path

import albumentations as A
import cv2
import numpy as np

from .config import (
    CLASSES,
    METADATA_DIR,
    MODEL_INPUT_SIZE,
    PROCESSED_DIR,
    RANDOM_SEED,
    VALID_EXTENSIONS,
)

# -- Augmentation pipeline --------------------------------------------------

AUGMENTATION_PIPELINE = A.Compose([
    A.HorizontalFlip(p=0.5),
    A.Rotate(limit=15, border_mode=cv2.BORDER_REFLECT_101, p=0.5),
    A.RandomBrightnessContrast(brightness_limit=0.15, contrast_limit=0.15, p=0.5),
    A.RandomResizedCrop(
        size=(MODEL_INPUT_SIZE[0], MODEL_INPUT_SIZE[1]),
        scale=(0.85, 1.0),
        ratio=(0.95, 1.05),
        p=0.4,
    ),
    A.GaussNoise(std_range=(0.01, 0.03), p=0.3),
])

# Number of augmented copies per original image.  This can be adjusted
# to address class imbalance -- under-represented classes may get more copies.
DEFAULT_AUGMENTS_PER_IMAGE = 2


def _augment_class(cls: str, n_augments: int) -> int:
    """Apply augmentation to all training images of one class."""
    src_dir = PROCESSED_DIR / "train" / cls
    if not src_dir.is_dir():
        return 0

    originals = sorted(
        p for p in src_dir.iterdir()
        if p.is_file() and p.suffix.lower() in VALID_EXTENSIONS and "_aug" not in p.stem
    )

    rng = np.random.RandomState(RANDOM_SEED)
    created = 0

    for img_path in originals:
        img = cv2.imread(str(img_path))
        if img is None:
            continue
        img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)

        for aug_idx in range(n_augments):
            # Seed each augmentation deterministically
            seed = rng.randint(0, 2**31)
            np.random.seed(seed)
            augmented = AUGMENTATION_PIPELINE(image=img_rgb)["image"]
            aug_name = f"{img_path.stem}_aug{aug_idx}{img_path.suffix}"
            out_path = src_dir / aug_name
            cv2.imwrite(str(out_path), cv2.cvtColor(augmented, cv2.COLOR_RGB2BGR),
                        [cv2.IMWRITE_JPEG_QUALITY, 95])
            created += 1

    return created


def main() -> None:
    print("=" * 60)
    print("Citadel -- Training Augmentation")
    print("=" * 60)
    print(f"  Augmentations per image: {DEFAULT_AUGMENTS_PER_IMAGE}")
    print(f"  Random seed: {RANDOM_SEED}")
    print(f"  Applied to: processed/train/ ONLY")

    # Count originals per class to determine augmentation multiplier
    class_counts: dict[str, int] = {}
    for cls in CLASSES:
        src_dir = PROCESSED_DIR / "train" / cls
        if src_dir.is_dir():
            count = sum(1 for p in src_dir.iterdir()
                        if p.is_file() and p.suffix.lower() in VALID_EXTENSIONS)
            class_counts[cls] = count
        else:
            class_counts[cls] = 0

    max_count = max(class_counts.values()) if class_counts else 0

    report_details: dict[str, dict] = {}
    total_created = 0

    for cls in CLASSES:
        orig_count = class_counts[cls]
        if orig_count == 0:
            report_details[cls] = {"originals": 0, "augmented_created": 0, "multiplier": 0}
            continue

        # Use more augmentations for under-represented classes
        if max_count > 0 and orig_count < max_count * 0.8:
            n_aug = max(DEFAULT_AUGMENTS_PER_IMAGE, int(np.ceil(max_count / orig_count)) - 1)
            n_aug = min(n_aug, 5)  # cap to avoid excessive augmentation
        else:
            n_aug = DEFAULT_AUGMENTS_PER_IMAGE

        print(f"\n  {cls} ({orig_count} originals, x{n_aug} augments) ...")
        created = _augment_class(cls, n_aug)
        total_created += created
        report_details[cls] = {
            "originals": orig_count,
            "augmented_created": created,
            "multiplier": n_aug,
            "total_after_augmentation": orig_count + created,
        }
        print(f"    -> {created} augmented images created (total: {orig_count + created})")

    # Write report
    METADATA_DIR.mkdir(parents=True, exist_ok=True)
    report = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "augmentation_pipeline": [
            "HorizontalFlip(p=0.5)",
            "Rotate(limit=15, p=0.5)",
            "RandomBrightnessContrast(brightness=0.15, contrast=0.15, p=0.5)",
            "RandomResizedCrop(scale=0.85-1.0, p=0.4)",
            "GaussNoise(std=0.01-0.03, p=0.3)",
        ],
        "applied_to": "train only",
        "random_seed": RANDOM_SEED,
        "classes": report_details,
        "total_augmented_created": total_created,
    }
    report_path = METADATA_DIR / "augmentation_report.json"
    report_path.write_text(json.dumps(report, indent=2))
    print(f"\n  Total augmented images created: {total_created}")
    print(f"  Augmentation report: {report_path}")


if __name__ == "__main__":
    main()
