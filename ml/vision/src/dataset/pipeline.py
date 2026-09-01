"""Run the full dataset pipeline: download > clean > dedup > split > preprocess > augment > verify.

Usage:
    python -m dataset.pipeline
    python -m dataset.pipeline --source-dir /path/to/plantvillage
    python -m dataset.pipeline --skip-download   # if raw/ is already populated
"""

from __future__ import annotations

import argparse
import sys

from . import download, clean, deduplicate, split, preprocess, augment, verify


def main() -> None:
    parser = argparse.ArgumentParser(description="Run full Citadel dataset pipeline")
    parser.add_argument("--source-dir", type=str, default=None,
                        help="Path to an already-downloaded PlantVillage directory")
    parser.add_argument("--skip-download", action="store_true",
                        help="Skip the download step (raw/ must already contain images)")
    args = parser.parse_args()

    steps = [
        ("1/7 Download",     lambda: download.main(source_dir=args.source_dir)),
        ("2/7 Clean",        clean.main),
        ("3/7 Deduplicate",  deduplicate.main),
        ("4/7 Split",        split.main),
        ("5/7 Preprocess",   preprocess.main),
        ("6/7 Augment",      augment.main),
        ("7/7 Verify",       verify.main),
    ]

    if args.skip_download:
        steps = steps[1:]

    for label, fn in steps:
        print(f"\n{'=' * 60}")
        print(f"  STEP {label}")
        print(f"{'=' * 60}")
        try:
            fn()
        except SystemExit as exc:
            if exc.code != 0:
                print(f"\n  [FAIL] Pipeline stopped at step: {label}")
                sys.exit(1)
        except Exception as exc:
            print(f"\n  [FAIL] Error in step {label}: {exc}")
            sys.exit(1)

    print(f"\n{'=' * 60}")
    print("  [OK] PIPELINE COMPLETE -- dataset is ready for model training")
    print(f"{'=' * 60}")


if __name__ == "__main__":
    main()
