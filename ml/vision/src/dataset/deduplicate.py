"""Detect near-duplicate images using perceptual hashing.

Usage:
    python -m dataset.deduplicate

Flags duplicates and cross-class duplicates.  Moves exact duplicates within
the same class to quarantine.  Cross-class duplicates are flagged but kept
(they may indicate labelling errors requiring manual review).

Report: metadata/dedup_report.json
"""

from __future__ import annotations

import json
import shutil
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path

import imagehash
from PIL import Image

from .config import CLASSES, METADATA_DIR, RAW_DIR, VALID_EXTENSIONS


# Hash difference threshold: images with hamming distance  this are
# considered near-duplicates.  8 is conservative for 64-bit average hashes.
HASH_THRESHOLD = 8


def _compute_hashes(cls: str) -> list[tuple[Path, imagehash.ImageHash]]:
    """Compute average perceptual hashes for all images in a class folder."""
    cls_dir = RAW_DIR / cls
    results = []
    if not cls_dir.is_dir():
        return results
    for img_path in sorted(cls_dir.iterdir()):
        if not img_path.is_file() or img_path.suffix.lower() not in VALID_EXTENSIONS:
            continue
        try:
            with Image.open(img_path) as img:
                h = imagehash.average_hash(img, hash_size=8)
            results.append((img_path, h))
        except Exception:
            pass  # corrupt images already handled by clean step
    return results


def main() -> None:
    print("=" * 60)
    print("Citadel -- Duplicate Detection")
    print("=" * 60)

    quarantine = RAW_DIR / "_quarantine"
    quarantine.mkdir(parents=True, exist_ok=True)

    # Phase 1: collect all hashes
    all_hashes: dict[str, list[tuple[Path, imagehash.ImageHash]]] = {}
    for cls in CLASSES:
        hashes = _compute_hashes(cls)
        all_hashes[cls] = hashes
        print(f"  {cls}: {len(hashes)} hashes computed")

    # Phase 2: intra-class deduplication
    intra_dupes_removed = 0
    intra_groups: dict[str, list[list[str]]] = {}

    for cls in CLASSES:
        hashes = all_hashes[cls]
        seen: list[tuple[Path, imagehash.ImageHash]] = []
        groups: list[list[str]] = []
        for path, h in hashes:
            duplicate_of = None
            for seen_path, seen_h in seen:
                if abs(h - seen_h) <= HASH_THRESHOLD:
                    duplicate_of = seen_path
                    break
            if duplicate_of is not None:
                q_name = f"dup_{cls}__{path.name}"
                shutil.move(str(path), str(quarantine / q_name))
                intra_dupes_removed += 1
                groups.append([str(duplicate_of.name), str(path.name)])
            else:
                seen.append((path, h))
        intra_groups[cls] = groups

    print(f"\n  Intra-class duplicates removed: {intra_dupes_removed}")

    # Phase 3: cross-class duplicate detection (flag only, do not remove)
    cross_dupes: list[dict] = []
    flat: list[tuple[str, Path, imagehash.ImageHash]] = []
    for cls in CLASSES:
        # Re-compute remaining hashes after intra-class dedup
        for path, h in _compute_hashes(cls):
            flat.append((cls, path, h))

    for i in range(len(flat)):
        for j in range(i + 1, len(flat)):
            cls_a, path_a, h_a = flat[i]
            cls_b, path_b, h_b = flat[j]
            if cls_a != cls_b and abs(h_a - h_b) <= HASH_THRESHOLD:
                cross_dupes.append({
                    "class_a": cls_a,
                    "file_a": path_a.name,
                    "class_b": cls_b,
                    "file_b": path_b.name,
                    "hamming_distance": int(abs(h_a - h_b)),
                })

    if cross_dupes:
        print(f"  [WARN] Cross-class near-duplicates found: {len(cross_dupes)}")
        print("    These may indicate labelling errors -- review manually.")
    else:
        print("  [OK] No cross-class duplicates detected.")

    # Write report
    METADATA_DIR.mkdir(parents=True, exist_ok=True)
    report = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "hash_threshold": HASH_THRESHOLD,
        "intra_class_duplicates_removed": intra_dupes_removed,
        "intra_class_groups": intra_groups,
        "cross_class_duplicates_flagged": len(cross_dupes),
        "cross_class_details": cross_dupes[:50],  # cap for readability
    }
    report_path = METADATA_DIR / "dedup_report.json"
    report_path.write_text(json.dumps(report, indent=2))
    print(f"\n  Dedup report: {report_path}")


if __name__ == "__main__":
    main()
