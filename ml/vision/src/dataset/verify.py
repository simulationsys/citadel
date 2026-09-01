"""Comprehensive dataset verification.

Usage:
    python -m dataset.verify

Checks all requirements from the Phase 1 specification:
  [OK] All classes present in train, val, test
  [OK] Image counts per class per split
  [OK] No zero-count classes
  [OK] Image dimensions are consistent (224x224)
  [OK] No corrupt/unreadable images in final splits
  [OK] No data leakage between splits (filename overlap)
  [OK] Test set matches the frozen manifest
  [OK] Class balance within acceptable range
  [OK] No augmentation in val/test

Exits with code 1 if any CRITICAL check fails.
Report: metadata/verification_report.json
"""

from __future__ import annotations

import json
import sys
from datetime import datetime, timezone
from pathlib import Path

import cv2
import numpy as np

from .config import (
    CLASSES,
    METADATA_DIR,
    MODEL_INPUT_SIZE,
    PROCESSED_DIR,
    TEST_DIR,
    TRAIN_DIR,
    VAL_DIR,
    VALID_EXTENSIONS,
)


class VerificationResult:
    """Accumulate pass/fail checks."""

    def __init__(self) -> None:
        self.checks: list[dict] = []
        self.critical_failures: int = 0
        self.warnings: int = 0

    def check(self, name: str, passed: bool, detail: str = "", critical: bool = True) -> None:
        status = "PASS" if passed else ("FAIL" if critical else "WARN")
        self.checks.append({"name": name, "status": status, "detail": detail})
        if not passed:
            if critical:
                self.critical_failures += 1
            else:
                self.warnings += 1
        icon = "[OK]" if passed else ("[FAIL]" if critical else "[WARN]")
        print(f"  {icon} {name}: {detail}" if detail else f"  {icon} {name}")


def _count_images(directory: Path, cls: str) -> int:
    """Count image files in a class directory."""
    cls_dir = directory / cls
    if not cls_dir.is_dir():
        return 0
    return sum(1 for p in cls_dir.iterdir()
               if p.is_file() and p.suffix.lower() in VALID_EXTENSIONS)


def _list_filenames(directory: Path, cls: str) -> set[str]:
    """List base filenames (without augmentation suffix) for leakage check."""
    cls_dir = directory / cls
    if not cls_dir.is_dir():
        return set()
    names = set()
    for p in cls_dir.iterdir():
        if p.is_file() and p.suffix.lower() in VALID_EXTENSIONS:
            # Strip _aug{N} suffix to get the source filename
            stem = p.stem
            for i in range(10):
                stem = stem.replace(f"_aug{i}", "")
            names.add(stem)
    return names


def _check_dimensions(directory: Path, cls: str, expected: tuple[int, int]) -> tuple[int, int]:
    """Check image dimensions.  Returns (correct_count, wrong_count)."""
    cls_dir = directory / cls
    if not cls_dir.is_dir():
        return 0, 0
    correct = 0
    wrong = 0
    for p in cls_dir.iterdir():
        if not p.is_file() or p.suffix.lower() not in VALID_EXTENSIONS:
            continue
        img = cv2.imread(str(p))
        if img is None:
            wrong += 1
            continue
        h, w = img.shape[:2]
        if (h, w) == expected:
            correct += 1
        else:
            wrong += 1
    return correct, wrong


def main() -> None:
    print("=" * 60)
    print("Citadel -- Dataset Verification")
    print("=" * 60)

    v = VerificationResult()

    # -- 1. Check raw split directories exist ------------------------------
    print("\n  [Split structure]")
    for name, d in [("train", TRAIN_DIR), ("val", VAL_DIR), ("test", TEST_DIR)]:
        v.check(f"{name}/ exists", d.is_dir())

    # -- 2. Class counts per split -----------------------------------------
    print("\n  [Class counts -- raw splits]")
    split_counts: dict[str, dict[str, int]] = {}
    for split_name, split_dir in [("train", TRAIN_DIR), ("val", VAL_DIR), ("test", TEST_DIR)]:
        counts = {}
        for cls in CLASSES:
            n = _count_images(split_dir, cls)
            counts[cls] = n
        split_counts[split_name] = counts
        total = sum(counts.values())
        v.check(f"{split_name} total > 0", total > 0, f"{total} images")
        for cls in CLASSES:
            v.check(f"{split_name}/{cls} > 0", counts[cls] > 0,
                    f"{counts[cls]} images", critical=True)

    # -- 3. Processed splits -----------------------------------------------
    print("\n  [Processed splits]")
    processed_counts: dict[str, dict[str, int]] = {}
    for split_name in ["train", "val", "test"]:
        counts = {}
        for cls in CLASSES:
            n = _count_images(PROCESSED_DIR / split_name, cls)
            counts[cls] = n
        processed_counts[split_name] = counts
        total = sum(counts.values())
        v.check(f"processed/{split_name} total > 0", total > 0, f"{total} images")

    # -- 4. Data leakage check ---------------------------------------------
    print("\n  [Leakage check]")
    for cls in CLASSES:
        train_names = _list_filenames(TRAIN_DIR, cls)
        val_names = _list_filenames(VAL_DIR, cls)
        test_names = _list_filenames(TEST_DIR, cls)

        train_val_leak = train_names & val_names
        train_test_leak = train_names & test_names
        val_test_leak = val_names & test_names

        v.check(f"{cls}: train_AND_val = empty", len(train_val_leak) == 0,
                f"{len(train_val_leak)} shared filenames" if train_val_leak else "")
        v.check(f"{cls}: train_AND_test = empty", len(train_test_leak) == 0,
                f"{len(train_test_leak)} shared filenames" if train_test_leak else "")
        v.check(f"{cls}: val_AND_test = empty", len(val_test_leak) == 0,
                f"{len(val_test_leak)} shared filenames" if val_test_leak else "")

    # -- 5. Dimension consistency (processed) ------------------------------
    print("\n  [Dimension check -- processed]")
    expected_dim = MODEL_INPUT_SIZE
    for split_name in ["train", "val", "test"]:
        for cls in CLASSES:
            correct, wrong = _check_dimensions(PROCESSED_DIR / split_name, cls, expected_dim)
            v.check(f"processed/{split_name}/{cls} dims={expected_dim[0]}x{expected_dim[1]}",
                    wrong == 0, f"{correct} correct, {wrong} wrong" if wrong else f"{correct} images")

    # -- 6. No augmentation in val/test ------------------------------------
    print("\n  [No augmentation in val/test]")
    for split_name in ["val", "test"]:
        for cls in CLASSES:
            split_dir = PROCESSED_DIR / split_name / cls
            if not split_dir.is_dir():
                continue
            aug_files = [p for p in split_dir.iterdir() if "_aug" in p.stem]
            v.check(f"processed/{split_name}/{cls}: no augmented files",
                    len(aug_files) == 0,
                    f"{len(aug_files)} augmented files found" if aug_files else "")

    # -- 7. Test set frozen manifest check ---------------------------------
    print("\n  [Frozen test set integrity]")
    frozen_path = METADATA_DIR / "frozen_test_set.json"
    if frozen_path.exists():
        frozen = json.loads(frozen_path.read_text())
        for cls in CLASSES:
            expected_files = set(frozen.get("files", {}).get(cls, []))
            actual_files = set(
                p.name for p in (TEST_DIR / cls).iterdir()
                if p.is_file() and p.suffix.lower() in VALID_EXTENSIONS
            ) if (TEST_DIR / cls).is_dir() else set()
            v.check(f"test/{cls} matches frozen manifest",
                    expected_files == actual_files,
                    f"expected={len(expected_files)}, actual={len(actual_files)}")
    else:
        v.check("frozen_test_set.json exists", False, "file not found")

    # -- 8. Class balance --------------------------------------------------
    print("\n  [Class balance -- train (raw, before augmentation)]")
    train_raw_counts = split_counts.get("train", {})
    if train_raw_counts:
        values = [c for c in train_raw_counts.values() if c > 0]
        if values:
            mean_count = np.mean(values)
            for cls in CLASSES:
                c = train_raw_counts[cls]
                deviation = abs(c - mean_count) / mean_count if mean_count > 0 else 0
                v.check(f"train/{cls} balance",
                        deviation <= 0.5,
                        f"{c} images ({deviation:.0%} from mean={mean_count:.0f})",
                        critical=False)

    # -- Summary -----------------------------------------------------------
    print("\n" + "=" * 60)
    total_checks = len(v.checks)
    passed = sum(1 for c in v.checks if c["status"] == "PASS")
    print(f"  Results: {passed}/{total_checks} passed, "
          f"{v.critical_failures} failures, {v.warnings} warnings")

    # Write report
    METADATA_DIR.mkdir(parents=True, exist_ok=True)
    report = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "summary": {
            "total_checks": total_checks,
            "passed": passed,
            "critical_failures": v.critical_failures,
            "warnings": v.warnings,
        },
        "split_counts_raw": split_counts,
        "split_counts_processed": processed_counts,
        "checks": v.checks,
    }
    report_path = METADATA_DIR / "verification_report.json"
    report_path.write_text(json.dumps(report, indent=2))
    print(f"\n  Verification report: {report_path}")

    if v.critical_failures > 0:
        print(f"\n  [FAIL] DATASET VERIFICATION FAILED ({v.critical_failures} critical failures)")
        sys.exit(1)
    else:
        print("\n  [OK] DATASET VERIFICATION PASSED")
        sys.exit(0)


if __name__ == "__main__":
    main()
