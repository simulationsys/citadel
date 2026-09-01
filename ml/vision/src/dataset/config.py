"""Shared constants for the Citadel crop-health dataset pipeline."""

from pathlib import Path

# -- Crop & classes (frozen in Phase 1) --------------------------------------
CROP = "tomato"

CLASSES: list[str] = [
    "healthy",
    "early_blight",
    "late_blight",
    "leaf_spot",
    "yellow_leaf_curl_virus",
]

CLASS_INDEX: dict[str, int] = {name: idx for idx, name in enumerate(CLASSES)}
NUM_CLASSES: int = len(CLASSES)

# PlantVillage folder name -> our label constant
PLANTVILLAGE_CLASS_MAP: dict[str, str] = {
    "Tomato___healthy": "healthy",
    "Tomato___Early_blight": "early_blight",
    "Tomato___Late_blight": "late_blight",
    "Tomato___Septoria_leaf_spot": "leaf_spot",
    "Tomato___Tomato_Yellow_Leaf_Curl_Virus": "yellow_leaf_curl_virus",
}

# -- Paths -------------------------------------------------------------------
VISION_ROOT = Path(__file__).resolve().parent.parent.parent   # ml/vision/
DATASET_ROOT = VISION_ROOT / "datasets" / "crop_health"
RAW_DIR = DATASET_ROOT / "raw"
PROCESSED_DIR = DATASET_ROOT / "processed"
TRAIN_DIR = DATASET_ROOT / "train"
VAL_DIR = DATASET_ROOT / "val"
TEST_DIR = DATASET_ROOT / "test"
METADATA_DIR = DATASET_ROOT / "metadata"

# -- Image requirements (from Phase 1 spec) ---------------------------------
MODEL_INPUT_SIZE: tuple[int, int] = (224, 224)  # (H, W)
MIN_RAW_RESOLUTION: tuple[int, int] = (64, 64)  # absolute floor for raw images
VALID_EXTENSIONS: set[str] = {".jpg", ".jpeg", ".png"}
MAX_FILE_SIZE_BYTES: int = 5 * 1024 * 1024  # 5 MB

# -- Split configuration ----------------------------------------------------
SPLIT_RATIOS: dict[str, float] = {"train": 0.70, "val": 0.15, "test": 0.15}
RANDOM_SEED: int = 42

# -- Preprocessing ----------------------------------------------------------
PIXEL_MEAN: tuple[float, float, float] = (0.485, 0.456, 0.406)  # ImageNet
PIXEL_STD: tuple[float, float, float] = (0.229, 0.224, 0.225)   # ImageNet
