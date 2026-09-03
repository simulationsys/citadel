"""Validate and clean raw images -- remove corrupt, wrong-format, and undersized files.

Usage:
    python -m dataset.clean

Produces a cleaning report at metadata/cleaning_report.json.
Questionable images are moved to raw/_quarantine/ rather than deleted.
"""

from __future__ import annotations

import json
import shutil
from datetime import datetime, timezone
from pathlib import Path

from PIL import Image

from .config import (
    CLASSES,
    METADATA_DIR,
    MIN_RAW_RESOLUTION,
    RAW_DIR,
    VALID_EXTENSIONS,
    MAX_FILE_SIZE_BYTES,
)


def _is_valid_image(path: Path) -> tuple[bool, str]:
    """Check if an image file is valid.  Returns (ok, reason)."""
    # Extension check
    if path.suffix.lower() not in VALID_EXTENSIONS:
        return False, f"invalid_extension:{path.suffix}"

    # File size check
    size = path.stat().st_size
    if size == 0:
        return False, "empty_file"
    if size > MAX_FILE_SIZE_BYTES:
        return False, f"oversized:{size}"

    # Readability check
    try:
        with Image.open(path) as img:
            img.verify()
    except Exception as exc:
        return False, f"corrupt:{exc}"

    # Re-open after verify (PIL requires this)
    try:
        with Image.open(path) as img:
            w, h = img.size
            mode = img.mode
    except Exception as exc:
        return False, f"unreadable:{exc}"

    # Resolution check
    if w < MIN_RAW_RESOLUTION[1] or h < MIN_RAW_RESOLUTION[0]:
        return False, f"too_small:{w}x{h}"

    # Must be RGB-convertible
    if mode not in ("RGB", "RGBA", "L"):
        return False, f"unsupported_mode:{mode}"

    return True, "ok"


def main() -> None:
    print("=" * 60)
    print("Citadel -- Dataset Cleaning")
    print("=" * 60)

    quarantine = RAW_DIR / "_quarantine"
    quarantine.mkdir(parents=True, exist_ok=True)

    report: dict = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "classes": {},
        "total_valid": 0,
        "total_quarantined": 0,
        "quarantine_reasons": {},
    }

    for cls in CLASSES:
        cls_dir = RAW_DIR / cls
        if not cls_dir.is_dir():
            print(f"  [WARN] Missing class directory: {cls}")
            report["classes"][cls] = {"valid": 0, "quarantined": 0}
            continue

        valid = 0
        quarantined = 0
        for img_path in sorted(cls_dir.iterdir()):
            if not img_path.is_file():
                continue
            ok, reason = _is_valid_image(img_path)
            if ok:
                valid += 1
            else:
                # Move to quarantine, preserving class info in filename
                q_name = f"{cls}__{img_path.name}"
                shutil.move(str(img_path), str(quarantine / q_name))
                quarantined += 1
                report["quarantine_reasons"][reason] = report["quarantine_reasons"].get(reason, 0) + 1

        report["classes"][cls] = {"valid": valid, "quarantined": quarantined}
        report["total_valid"] += valid
        report["total_quarantined"] += quarantined
        status = "[OK]" if quarantined == 0 else f"[WARN] {quarantined} quarantined"
        print(f"  {cls}: {valid} valid, {status}")

    # Write report
    METADATA_DIR.mkdir(parents=True, exist_ok=True)
    report_path = METADATA_DIR / "cleaning_report.json"
    report_path.write_text(json.dumps(report, indent=2))
    print(f"\n  Cleaning report: {report_path}")
    print(f"  Total valid: {report['total_valid']}")
    print(f"  Total quarantined: {report['total_quarantined']}")

    if report["total_quarantined"] > 0:
        print(f"\n  Quarantined images are in: {quarantine}")
        print("  Review manually if needed -- nothing was permanently deleted.")


if __name__ == "__main__":
    main()
