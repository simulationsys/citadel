"""Export the best v1.1 candidate to TFLite.

Usage:
    python -m src.export_v11 --experiment A
"""

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path

import tensorflow as tf

from src.dataset.config import CLASSES, MODEL_INPUT_SIZE

MODELS_DIR = Path("models")
V11_DIR = MODELS_DIR / "v11_experiments"


def main():
    parser = argparse.ArgumentParser(description="v1.1 TFLite Export")
    parser.add_argument("--experiment", type=str, required=True,
                        choices=["A", "B", "C", "D"])
    args = parser.parse_args()

    exp_dir = V11_DIR / f"exp_{args.experiment}"
    checkpoint = exp_dir / "best.keras"
    if not checkpoint.exists():
        raise FileNotFoundError(f"No checkpoint at {checkpoint}")

    print(f"Loading model from {checkpoint} ...")
    model = tf.keras.models.load_model(checkpoint, compile=False)

    print("Converting to TFLite ...")
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    tflite_model = converter.convert()

    # Save v1.1 TFLite
    out_path = MODELS_DIR / "crop_health_mobilenetv2_v1.1.tflite"
    out_path.write_bytes(tflite_model)
    size_mb = out_path.stat().st_size / (1024 * 1024)

    print(f"Saved to {out_path}")
    print(f"Size: {size_mb:.2f} MB")

    if size_mb >= 15.0:
        print("[WARN] Model exceeds 15 MB limit!")
    else:
        print(f"[OK] Model is within 15 MB limit ({size_mb:.2f} MB)")

    # Verify shapes
    interpreter = tf.lite.Interpreter(model_path=str(out_path))
    interpreter.allocate_tensors()
    inp = interpreter.get_input_details()[0]
    out = interpreter.get_output_details()[0]

    print(f"\nInput shape:  {inp['shape'].tolist()}")
    print(f"Input dtype:  {inp['dtype'].__name__}")
    print(f"Output shape: {out['shape'].tolist()}")
    print(f"Output dtype: {out['dtype'].__name__}")

    # Save metadata
    meta = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "model_version": "v1.1.0",
        "source_experiment": args.experiment,
        "contract": {"kind": "crop_health", "crop": "tomato"},
        "input": {
            "size": list(MODEL_INPUT_SIZE),
            "channels": 3,
            "format": "RGB",
            "preprocessing": {
                "type": "internal",
                "notes": "Normalization embedded in model graph. Pass raw uint8 RGB [0,255]."
            }
        },
        "output": {"type": "softmax", "classes": CLASSES},
        "model_size_mb": round(size_mb, 2),
    }
    meta_path = MODELS_DIR / "crop_health_mobilenetv2_v1.1.json"
    meta_path.write_text(json.dumps(meta, indent=2))
    print(f"[OK] Metadata: {meta_path}")


if __name__ == "__main__":
    main()
