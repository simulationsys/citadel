"""Export the trained Crop Health AI model to TFLite format.

Usage:
    python -m src.export
"""

import json
from datetime import datetime, timezone
from pathlib import Path

import tensorflow as tf

from src.dataset.config import CLASSES, MODEL_INPUT_SIZE, PIXEL_MEAN, PIXEL_STD

MODELS_DIR = Path("models")
CHECKPOINT_PATH = MODELS_DIR / "crop_health_best.keras"
TFLITE_MODEL_PATH = MODELS_DIR / "crop_health_mobilenetv2.tflite"
TFLITE_METADATA_PATH = MODELS_DIR / "crop_health_mobilenetv2.json"


def main():
    print("=" * 60)
    print("Citadel -- Crop Health AI TFLite Export")
    print("=" * 60)
    
    if not CHECKPOINT_PATH.exists():
        raise FileNotFoundError(f"Model checkpoint not found at {CHECKPOINT_PATH}")
        
    print(f"Loading Keras model from {CHECKPOINT_PATH} ...")
    model = tf.keras.models.load_model(CHECKPOINT_PATH)
    
    # 1. Convert to TFLite
    print("\nConverting model to TFLite...")
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    
    # Enable standard post-training quantization for size reduction
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    
    tflite_model = converter.convert()
    
    # 2. Save TFLite model
    print(f"Saving TFLite model to {TFLITE_MODEL_PATH} ...")
    TFLITE_MODEL_PATH.write_bytes(tflite_model)
    
    size_mb = TFLITE_MODEL_PATH.stat().st_size / (1024 * 1024)
    print(f"TFLite Model Size: {size_mb:.2f} MB")
    
    if size_mb >= 15.0:
        print("[WARN] Model exceeds 15MB edge deployment limit!")
    else:
        print("[OK] Model is within the 15MB limit.")
        
    # 3. Generate Integration Metadata
    # This metadata defines how the Edge API Node.js service should use the model.
    print("\nGenerating model metadata sidecar...")
    metadata = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "model_version": "v1.0.0",
        "contract": {
            "kind": "crop_health",
            "crop": "tomato"
        },
        "input": {
            "size": list(MODEL_INPUT_SIZE),
            "channels": 3,
            "format": "RGB",
            "preprocessing": {
                "type": "internal",
                "notes": "Normalization is embedded in the model graph. Pass raw uint8 RGB [0,255] resized to input size."
            }
        },
        "output": {
            "type": "softmax",
            "classes": CLASSES
        }
    }
    
    TFLITE_METADATA_PATH.write_text(json.dumps(metadata, indent=2))
    print(f"[OK] Metadata saved to: {TFLITE_METADATA_PATH}")
    print("\n[OK] Export complete! Ready for Phase 4 deployment.")

if __name__ == "__main__":
    main()
