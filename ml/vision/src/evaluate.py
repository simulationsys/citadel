"""Evaluate the trained Crop Health AI model on the frozen test set.

Usage:
    python -m src.evaluate
"""

import json
import os
import time
from datetime import datetime, timezone
from pathlib import Path

import numpy as np
import tensorflow as tf
from sklearn.metrics import classification_report, confusion_matrix

from src.dataset.config import CLASSES, MODEL_INPUT_SIZE, PROCESSED_DIR, METADATA_DIR, RANDOM_SEED

BATCH_SIZE = 32
MODELS_DIR = Path("models")
CHECKPOINT_PATH = MODELS_DIR / "crop_health_best.keras"
EVALUATION_METADATA_PATH = METADATA_DIR / "evaluation_report.json"


def measure_cpu_latency(model: tf.keras.Model, num_runs: int = 50) -> float:
    """Measure average inference latency on CPU."""
    # Force CPU execution for consistent measurement
    with tf.device("/CPU:0"):
        dummy_input = tf.random.uniform((1, MODEL_INPUT_SIZE[0], MODEL_INPUT_SIZE[1], 3))
        # Warmup
        for _ in range(5):
            model(dummy_input, training=False)
            
        start_time = time.perf_counter()
        for _ in range(num_runs):
            model(dummy_input, training=False)
        end_time = time.perf_counter()
        
    return ((end_time - start_time) / num_runs) * 1000.0  # ms per inference


def main():
    print("=" * 60)
    print("Citadel -- Crop Health AI Evaluation")
    print("=" * 60)
    
    if not CHECKPOINT_PATH.exists():
        raise FileNotFoundError(f"Model checkpoint not found at {CHECKPOINT_PATH}")
        
    print(f"Loading model from {CHECKPOINT_PATH} ...")
    model = tf.keras.models.load_model(CHECKPOINT_PATH)
    
    # 1. Evaluate on Test Set
    print("\nLoading frozen test set...")
    test_dir = PROCESSED_DIR / "test"
    test_ds = tf.keras.utils.image_dataset_from_directory(
        test_dir,
        labels="inferred",
        label_mode="categorical",
        class_names=CLASSES,
        color_mode="rgb",
        batch_size=BATCH_SIZE,
        image_size=(MODEL_INPUT_SIZE[0], MODEL_INPUT_SIZE[1]),
        shuffle=False,
    )
    
    print("\nRunning inference...")
    y_true = []
    y_pred = []
    
    for images, labels in test_ds:
        preds = model.predict(images, verbose=0)
        y_pred.extend(np.argmax(preds, axis=-1))
        y_true.extend(np.argmax(labels.numpy(), axis=-1))
        
    y_true = np.array(y_true)
    y_pred = np.array(y_pred)
    
    # Calculate metrics
    report = classification_report(y_true, y_pred, target_names=CLASSES, output_dict=True)
    conf_matrix = confusion_matrix(y_true, y_pred)
    accuracy = report["accuracy"]
    
    print("\n" + "=" * 40)
    print("Test Set Performance")
    print("=" * 40)
    print(classification_report(y_true, y_pred, target_names=CLASSES))
    
    print("\nConfusion Matrix:")
    print(conf_matrix)
    
    # 2. Profiling (Size & Latency)
    print("\n" + "=" * 40)
    print("Model Profiling")
    print("=" * 40)
    
    model_size_mb = CHECKPOINT_PATH.stat().st_size / (1024 * 1024)
    param_count = model.count_params()
    print(f"Model File Size: {model_size_mb:.2f} MB")
    print(f"Parameter Count: {param_count:,}")
    
    latency_ms = measure_cpu_latency(model)
    print(f"CPU Inference Latency: {latency_ms:.2f} ms")
    
    # 3. Save Report
    report_dict = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "model_path": str(CHECKPOINT_PATH),
        "metrics": {
            "accuracy": accuracy,
            "macro_avg": report["macro avg"],
            "weighted_avg": report["weighted avg"],
            "per_class": {cls: report[cls] for cls in CLASSES}
        },
        "confusion_matrix": conf_matrix.tolist(),
        "profiling": {
            "model_size_mb": model_size_mb,
            "parameter_count": param_count,
            "cpu_latency_ms": latency_ms,
            "meets_size_target": model_size_mb < 15.0
        }
    }
    
    EVALUATION_METADATA_PATH.write_text(json.dumps(report_dict, indent=2))
    print(f"\n[OK] Evaluation report saved to: {EVALUATION_METADATA_PATH}")
    
    if accuracy >= 0.85:
        print(f"\n[OK] SUCCESS: Model meets target accuracy (>=85%) with {accuracy:.1%}")
    else:
        print(f"\n[FAIL] Model failed to meet target accuracy (>=85%) with {accuracy:.1%}")


if __name__ == "__main__":
    main()
