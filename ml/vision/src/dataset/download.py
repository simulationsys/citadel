"""Download PlantVillage tomato images and organise into raw/ class folders.

Usage:
    python -m dataset.download
    python -m dataset.download --source-dir /path/to/existing/plantvillage

If --source-dir is provided, images are copied from a local PlantVillage
directory instead of downloading.  Otherwise the script downloads from the
public GitHub mirror (spMohanty/PlantVillage-Dataset).
"""

from __future__ import annotations

import argparse
import io
import json
import shutil
import sys
import urllib.error
import urllib.request
import zipfile
from datetime import datetime, timezone
from pathlib import Path

from .config import (
    CLASSES,
    METADATA_DIR,
    PLANTVILLAGE_CLASS_MAP,
    RAW_DIR,
    VALID_EXTENSIONS,
)

# -- GitHub download helpers -------------------------------------------------

_GITHUB_API = "https://api.github.com/repos/spMohanty/PlantVillage-Dataset"
_GITHUB_RAW = "https://raw.githubusercontent.com/spMohanty/PlantVillage-Dataset/master/raw/color"


def _github_list_files(pv_folder: str) -> list[str]:
    """List image file names inside a PlantVillage class folder via GitHub API."""
    url = f"{_GITHUB_API}/contents/raw/color/{pv_folder}"
    req = urllib.request.Request(url, headers={"Accept": "application/vnd.github.v3+json"})
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            entries = json.loads(resp.read().decode())
        return [e["name"] for e in entries if e["type"] == "file"]
    except urllib.error.URLError as exc:
        print(f"  [WARN] Could not list {pv_folder}: {exc}")
        return []


import urllib.parse

def _github_download_image(pv_folder: str, filename: str, dest: Path) -> bool:
    """Download a single image from the GitHub raw URL."""
    encoded_name = urllib.parse.quote(filename)
    url = f"{_GITHUB_RAW}/{pv_folder}/{encoded_name}"
    try:
        urllib.request.urlretrieve(url, str(dest))
        return True
    except (urllib.error.URLError, Exception):
        return False


# -- Kaggle download (if kagglehub is installed) ----------------------------

def _try_kaggle_download() -> Path | None:
    """Attempt to download PlantVillage via kagglehub.  Returns path or None."""
    try:
        import kagglehub  # type: ignore
        path = kagglehub.dataset_download("arjuntejaswi/plant-village")
        return Path(path)
    except Exception:
        return None


# -- Local copy --------------------------------------------------------------

def _copy_from_local(source_dir: Path) -> dict[str, int]:
    """Copy images from a local PlantVillage-style directory tree."""
    counts: dict[str, int] = {}
    for pv_folder, our_label in PLANTVILLAGE_CLASS_MAP.items():
        src = source_dir / pv_folder
        if not src.is_dir():
            # try without prefix
            src = source_dir / "raw" / "color" / pv_folder
        if not src.is_dir():
            print(f"  [WARN] Source folder not found: {pv_folder}")
            counts[our_label] = 0
            continue
        dest = RAW_DIR / our_label
        dest.mkdir(parents=True, exist_ok=True)
        n = 0
        for img_path in sorted(src.iterdir()):
            if img_path.suffix.lower() in VALID_EXTENSIONS:
                shutil.copy2(img_path, dest / img_path.name)
                n += 1
        counts[our_label] = n
        print(f"  {our_label}: {n} images copied")
    return counts


def _download_from_github() -> dict[str, int]:
    """Download tomato images from the GitHub PlantVillage mirror."""
    counts: dict[str, int] = {}
    for pv_folder, our_label in PLANTVILLAGE_CLASS_MAP.items():
        dest = RAW_DIR / our_label
        dest.mkdir(parents=True, exist_ok=True)
        print(f"  Listing {pv_folder} ...")
        files = _github_list_files(pv_folder)
        if not files:
            counts[our_label] = 0
            continue
        n = 0
        for fname in files:
            if Path(fname).suffix.lower() in VALID_EXTENSIONS:
                target = dest / fname
                if target.exists():
                    n += 1
                    continue
                if _github_download_image(pv_folder, fname, target):
                    n += 1
                    if n % 50 == 0:
                        print(f"    {our_label}: {n}/{len(files)} downloaded ...")
        counts[our_label] = n
        print(f"  {our_label}: {n} images downloaded")
    return counts


def _download_from_kaggle() -> dict[str, int]:
    """Download via kagglehub and copy relevant classes."""
    kaggle_path = _try_kaggle_download()
    if kaggle_path is None:
        return {}
    print(f"  Kaggle dataset at: {kaggle_path}")

    # The kaggle dataset may have various structures; search for class folders
    counts: dict[str, int] = {}
    for pv_folder, our_label in PLANTVILLAGE_CLASS_MAP.items():
        dest = RAW_DIR / our_label
        dest.mkdir(parents=True, exist_ok=True)
        # Search for the folder recursively
        matches = list(kaggle_path.rglob(pv_folder))
        if not matches:
            counts[our_label] = 0
            continue
        src = matches[0]
        n = 0
        for img_path in sorted(src.iterdir()):
            if img_path.suffix.lower() in VALID_EXTENSIONS:
                shutil.copy2(img_path, dest / img_path.name)
                n += 1
        counts[our_label] = n
        print(f"  {our_label}: {n} images")
    return counts


# -- Manifest ----------------------------------------------------------------

def _write_download_manifest(source: str, counts: dict[str, int]) -> None:
    """Write download metadata."""
    METADATA_DIR.mkdir(parents=True, exist_ok=True)
    manifest = {
        "download_date": datetime.now(timezone.utc).isoformat(),
        "source": source,
        "crop": "tomato",
        "classes": CLASSES,
        "raw_image_counts": counts,
        "total_raw_images": sum(counts.values()),
    }
    path = METADATA_DIR / "download_manifest.json"
    path.write_text(json.dumps(manifest, indent=2))
    print(f"\n  Manifest written to {path}")


# -- Main --------------------------------------------------------------------

def main(source_dir: str | None = None) -> None:
    print("=" * 60)
    print("Citadel -- PlantVillage Dataset Download")
    print("=" * 60)

    RAW_DIR.mkdir(parents=True, exist_ok=True)

    # Check if data already exists
    existing = sum(1 for _ in RAW_DIR.rglob("*") if _.is_file() and _.suffix.lower() in VALID_EXTENSIONS)
    if existing > 100:
        print(f"\n  Raw data already contains {existing} images. Skipping download.")
        print("  Delete datasets/crop_health/raw/ to re-download.")
        return

    if source_dir:
        print(f"\n  Copying from local directory: {source_dir}")
        counts = _copy_from_local(Path(source_dir))
        _write_download_manifest(f"local:{source_dir}", counts)
        return

    # Strategy 1: Try kagglehub (fastest if available)
    print("\n  Strategy 1: Trying kagglehub ...")
    counts = _download_from_kaggle()
    if counts and sum(counts.values()) > 100:
        _write_download_manifest("kagglehub:arjuntejaswi/plant-village", counts)
        return
    
    # Strategy 2: Download from GitHub (always available, but slower)
    print("\n  Strategy 2: Downloading from GitHub mirror ...")
    counts = _download_from_github()
    if sum(counts.values()) > 0:
        _write_download_manifest("github:spMohanty/PlantVillage-Dataset", counts)
    else:
        print("\n  [FAIL] All download strategies failed.")
        print("  Manual download instructions:")
        print("    1. Download from https://www.kaggle.com/datasets/arjuntejaswi/plant-village")
        print("    2. Extract to a local directory")
        print("    3. Re-run: python -m dataset.download --source-dir /path/to/extracted")
        sys.exit(1)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Download PlantVillage tomato dataset")
    parser.add_argument("--source-dir", type=str, default=None,
                        help="Path to an already-downloaded PlantVillage directory")
    args = parser.parse_args()
    main(source_dir=args.source_dir)
