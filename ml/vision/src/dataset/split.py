"""Split cleaned raw images into train / val / test sets.

Usage:
    python -m dataset.split

Leakage prevention:
- Split is done on raw source filenames with a fixed random seed.
- All augmented variants of a source image inherit its split assignment.
- The test set is frozen after creation and must never be modified.

Report: metadata/split_report.json
"""

from __future__ import annotations

import json
import shutil
from datetime import datetime, timezone
from pathlib import Path

from sklearn.model_selection import train_test_split

from .config import (
    CLASSES,
    METADATA_DIR,
    RANDOM_SEED,
    RAW_DIR,
    SPLIT_RATIOS,
    TEST_DIR,
    TRAIN_DIR,
    VAL_DIR,
    VALID_EXTENSIONS,
)


def _collect_images(cls: str) -> list[Path]:
    """Collect all valid image paths for a class from raw/."""
    cls_dir = RAW_DIR / cls
    if not cls_dir.is_dir():
        return []
    return sorted(
        p for p in cls_dir.iterdir()
        if p.is_file() and p.suffix.lower() in VALID_EXTENSIONS
    )


def main() -> None:
    print("=" * 60)
    print("Citadel -- Dataset Splitting")
    print("=" * 60)
    print(f"  Seed: {RANDOM_SEED}")
    print(f"  Ratios: train={SPLIT_RATIOS['train']}, val={SPLIT_RATIOS['val']}, test={SPLIT_RATIOS['test']}")

    report: dict = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "random_seed": RANDOM_SEED,
        "split_ratios": SPLIT_RATIOS,
        "classes": {},
        "totals": {"train": 0, "val": 0, "test": 0},
    }

    for split_dir in (TRAIN_DIR, VAL_DIR, TEST_DIR):
        for cls in CLASSES:
            (split_dir / cls).mkdir(parents=True, exist_ok=True)

    for cls in CLASSES:
        images = _collect_images(cls)
        n = len(images)
        if n < 3:
            print(f"  [WARN] {cls}: only {n} images -- cannot split, skipping")
            report["classes"][cls] = {"train": 0, "val": 0, "test": 0, "total": n}
            continue

        # Two-stage split: first isolate test, then split remainder into train/val
        test_ratio = SPLIT_RATIOS["test"]
        val_ratio_of_remainder = SPLIT_RATIOS["val"] / (SPLIT_RATIOS["train"] + SPLIT_RATIOS["val"])

        train_val, test_imgs = train_test_split(
            images, test_size=test_ratio, random_state=RANDOM_SEED, shuffle=True
        )
        train_imgs, val_imgs = train_test_split(
            train_val, test_size=val_ratio_of_remainder, random_state=RANDOM_SEED, shuffle=True
        )

        # Copy images to split directories
        for img_path in train_imgs:
            shutil.copy2(img_path, TRAIN_DIR / cls / img_path.name)
        for img_path in val_imgs:
            shutil.copy2(img_path, VAL_DIR / cls / img_path.name)
        for img_path in test_imgs:
            shutil.copy2(img_path, TEST_DIR / cls / img_path.name)

        counts = {
            "train": len(train_imgs),
            "val": len(val_imgs),
            "test": len(test_imgs),
            "total": n,
        }
        report["classes"][cls] = counts
        report["totals"]["train"] += counts["train"]
        report["totals"]["val"] += counts["val"]
        report["totals"]["test"] += counts["test"]

        print(f"  {cls}: train={counts['train']}, val={counts['val']}, test={counts['test']} (total={n})")

    print(f"\n  Totals: train={report['totals']['train']}, "
          f"val={report['totals']['val']}, test={report['totals']['test']}")

    # Write report
    METADATA_DIR.mkdir(parents=True, exist_ok=True)
    report_path = METADATA_DIR / "split_report.json"
    report_path.write_text(json.dumps(report, indent=2))
    print(f"  Split report: {report_path}")

    # Write frozen test manifest
    test_manifest: dict[str, list[str]] = {}
    for cls in CLASSES:
        test_cls_dir = TEST_DIR / cls
        if test_cls_dir.is_dir():
            test_manifest[cls] = sorted(p.name for p in test_cls_dir.iterdir() if p.is_file())
    frozen_path = METADATA_DIR / "frozen_test_set.json"
    frozen_path.write_text(json.dumps({
        "frozen_at": datetime.now(timezone.utc).isoformat(),
        "warning": "DO NOT modify. This test set must remain isolated.",
        "files": test_manifest,
    }, indent=2))
    print(f"  Frozen test manifest: {frozen_path}")


if __name__ == "__main__":
    main()
