"""Evaluate a v1.1 candidate model on the frozen test set and compare with v1.0.

Usage:
    python -m src.evaluate_v11 --experiment A
"""

import argparse
import json
import time
from pathlib import Path

import numpy as np
import tensorflow as tf
from sklearn.metrics import classification_report, confusion_matrix

from src.dataset.config import CLASSES, MODEL_INPUT_SIZE, RANDOM_SEED
from src.train_v11 import FocalLoss

BATCH_SIZE = 32
TEST_DIR = Path("datasets") / "crop_health" / "test"
MODELS_DIR = Path("models")
V11_DIR = MODELS_DIR / "v11_experiments"

# v1.0 reference metrics (from Phase 6 reliability report)
V10_METRICS = {
    "overall_accuracy": 0.9533,
    "per_class": {
        "healthy":                  {"precision": 1.000, "recall": 1.000, "f1": 1.000, "support": 140},
        "early_blight":             {"precision": 0.903, "recall": 0.718, "f1": 0.800, "support": 78},
        "late_blight":              {"precision": 0.940, "recall": 0.940, "f1": 0.940, "support": 150},
        "leaf_spot":                {"precision": 0.873, "recall": 0.985, "f1": 0.926, "support": 133},
        "yellow_leaf_curl_virus":   {"precision": 0.996, "recall": 0.992, "f1": 0.994, "support": 248},
    },
    "high_confidence_errors": 18,
}


def load_test_set():
    """Load the frozen 749-image test set."""
    ds = tf.keras.utils.image_dataset_from_directory(
        TEST_DIR,
        labels="inferred",
        label_mode="categorical",
        class_names=CLASSES,
        color_mode="rgb",
        batch_size=BATCH_SIZE,
        image_size=(MODEL_INPUT_SIZE[0], MODEL_INPUT_SIZE[1]),
        shuffle=False,
    )
    return ds


def evaluate_model(model, test_ds):
    """Run inference and compute all metrics."""
    y_true = []
    y_pred_probs = []

    for images, labels in test_ds:
        preds = model.predict(images, verbose=0)
        y_pred_probs.extend(preds)
        y_true.extend(np.argmax(labels.numpy(), axis=-1))

    y_true = np.array(y_true)
    y_pred_probs = np.array(y_pred_probs)
    y_pred = np.argmax(y_pred_probs, axis=-1)
    y_conf = np.max(y_pred_probs, axis=-1)

    # Classification report
    report = classification_report(y_true, y_pred, target_names=CLASSES, output_dict=True)
    conf_mat = confusion_matrix(y_true, y_pred)

    # High-confidence errors
    wrong = y_pred != y_true
    high_conf_wrong = np.sum(wrong & (y_conf >= 0.80))

    # Confidence statistics
    correct_mask = ~wrong
    mean_correct_conf = float(np.mean(y_conf[correct_mask])) if correct_mask.any() else 0.0
    mean_wrong_conf = float(np.mean(y_conf[wrong])) if wrong.any() else 0.0

    return {
        "overall_accuracy": report["accuracy"],
        "macro_f1": report["macro avg"]["f1-score"],
        "weighted_f1": report["weighted avg"]["f1-score"],
        "per_class": {
            cls: {
                "precision": round(report[cls]["precision"], 4),
                "recall": round(report[cls]["recall"], 4),
                "f1": round(report[cls]["f1-score"], 4),
                "support": int(report[cls]["support"]),
            }
            for cls in CLASSES
        },
        "confusion_matrix": conf_mat.tolist(),
        "high_confidence_errors": int(high_conf_wrong),
        "mean_correct_confidence": round(mean_correct_conf, 4),
        "mean_wrong_confidence": round(mean_wrong_conf, 4),
        "total_errors": int(np.sum(wrong)),
    }


def measure_tflite_latency(model_path: str, num_runs: int = 50) -> float:
    """Measure average TFLite inference latency in ms."""
    interpreter = tf.lite.Interpreter(model_path=model_path)
    interpreter.allocate_tensors()
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()

    dummy = np.random.randint(0, 256,
        (1, MODEL_INPUT_SIZE[0], MODEL_INPUT_SIZE[1], 3)).astype(np.float32)

    # Warmup
    for _ in range(5):
        interpreter.set_tensor(input_details[0]["index"], dummy)
        interpreter.invoke()

    start = time.perf_counter()
    for _ in range(num_runs):
        interpreter.set_tensor(input_details[0]["index"], dummy)
        interpreter.invoke()
    elapsed = time.perf_counter() - start

    return (elapsed / num_runs) * 1000.0


def print_comparison(v10, v11):
    """Print a formatted v1.0 vs v1.1 comparison table."""

    def arrow(old, new, higher_better=True):
        if new > old:
            return "[+] Better" if higher_better else "[-] Worse"
        elif new < old:
            return "[-] Worse" if higher_better else "[+] Better"
        return "[=] Same"

    print("\n" + "=" * 70)
    print("v1.0 vs v1.1 COMPARISON")
    print("=" * 70)
    header = f"{'Metric':<30} {'v1.0':>10} {'v1.1':>10} {'Verdict':>12}"
    print(header)
    print("-" * 70)

    rows = [
        ("Overall Accuracy",
         v10["overall_accuracy"], v11["overall_accuracy"], True),
        ("Macro F1",
         None, v11["macro_f1"], True),
        ("Early Blight Recall",
         v10["per_class"]["early_blight"]["recall"],
         v11["per_class"]["early_blight"]["recall"], True),
        ("Early Blight F1",
         v10["per_class"]["early_blight"]["f1"],
         v11["per_class"]["early_blight"]["f1"], True),
        ("Late Blight F1",
         v10["per_class"]["late_blight"]["f1"],
         v11["per_class"]["late_blight"]["f1"], True),
        ("Leaf Spot F1",
         v10["per_class"]["leaf_spot"]["f1"],
         v11["per_class"]["leaf_spot"]["f1"], True),
        ("Healthy F1",
         v10["per_class"]["healthy"]["f1"],
         v11["per_class"]["healthy"]["f1"], True),
        ("YLCV F1",
         v10["per_class"]["yellow_leaf_curl_virus"]["f1"],
         v11["per_class"]["yellow_leaf_curl_virus"]["f1"], True),
        ("High-Conf Errors (>=0.80)",
         v10["high_confidence_errors"],
         v11["high_confidence_errors"], False),
    ]

    for label, old, new, hb in rows:
        old_s = f"{old:.4f}" if old is not None else "N/A"
        new_s = f"{new:.4f}" if isinstance(new, float) else str(new)
        verdict = arrow(old, new, hb) if old is not None else ""
        print(f"{label:<30} {old_s:>10} {new_s:>10} {verdict:>12}")


def main():
    parser = argparse.ArgumentParser(description="v1.1 Frozen Test Evaluation")
    parser.add_argument("--experiment", type=str, required=True,
                        choices=["A", "B", "C", "D"],
                        help="Experiment ID to evaluate")
    args = parser.parse_args()

    exp_dir = V11_DIR / f"exp_{args.experiment}"
    checkpoint = exp_dir / "best.keras"
    if not checkpoint.exists():
        raise FileNotFoundError(f"Checkpoint not found: {checkpoint}")

    print(f"Loading v1.1 candidate from {checkpoint} ...")
    model = tf.keras.models.load_model(checkpoint, compile=False)

    print("Loading frozen test set (749 images) ...")
    test_ds = load_test_set()

    print("Evaluating ...")
    v11_metrics = evaluate_model(model, test_ds)

    print_comparison(V10_METRICS, v11_metrics)

    # Save detailed comparison
    comparison = {
        "experiment_id": args.experiment,
        "v1.0": V10_METRICS,
        "v1.1": v11_metrics,
        "early_blight_recall_delta": round(
            v11_metrics["per_class"]["early_blight"]["recall"] -
            V10_METRICS["per_class"]["early_blight"]["recall"], 4),
        "high_conf_error_delta":
            v11_metrics["high_confidence_errors"] -
            V10_METRICS["high_confidence_errors"],
    }

    out_path = exp_dir / "frozen_test_comparison.json"
    out_path.write_text(json.dumps(comparison, indent=2))
    print(f"\n[OK] Comparison saved to {out_path}")


if __name__ == "__main__":
    main()
