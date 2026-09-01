"""Citadel vision workspace: keep training separate from edge inference export."""

# Phase 1 frozen constants — see spec/phase1-crop-health.md
CROP = "tomato"
CLASSES = [
    "healthy",
    "early_blight",
    "late_blight",
    "leaf_spot",
    "yellow_leaf_curl_virus",
]


def main() -> None:
    print(f"Crop: {CROP}")
    print(f"Classes ({len(CLASSES)}): {CLASSES}")
    print("Next: assemble dataset under datasets/, train classifier, export TFLite to models/.")


if __name__ == "__main__":
    main()

