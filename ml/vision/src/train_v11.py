"""Crop Health AI v1.1 — Controlled Experiments.

Usage:
    python -m src.train_v11 --experiment A
    python -m src.train_v11 --experiment B
    python -m src.train_v11 --experiment C
    python -m src.train_v11 --experiment D

Each experiment saves its own checkpoint and metadata under
models/v11_experiments/<experiment_id>/.
"""

import argparse
import json
import os
import time
from datetime import datetime, timezone
from pathlib import Path

import numpy as np
import tensorflow as tf
from tensorflow.keras import layers, models, applications, optimizers, callbacks

from src.dataset.config import (
    CLASSES,
    MODEL_INPUT_SIZE,
    PROCESSED_DIR,
    RANDOM_SEED,
    PIXEL_MEAN,
    PIXEL_STD,
)

# ---------------------------------------------------------------------------
# Shared constants
# ---------------------------------------------------------------------------
BATCH_SIZE = 32
MODELS_DIR = Path("models") / "v11_experiments"


# ---------------------------------------------------------------------------
# Focal Loss
# ---------------------------------------------------------------------------
class FocalLoss(tf.keras.losses.Loss):
    """Focal loss for multi-class classification.

    Reduces the relative loss for well-classified examples, focusing on hard
    misclassifications.  When gamma=0 this is standard cross-entropy.
    """

    def __init__(self, gamma=2.0, class_weights=None, label_smoothing=0.0,
                 name="focal_loss"):
        super().__init__(name=name)
        self.gamma = gamma
        self.class_weights = class_weights
        self.label_smoothing = label_smoothing

    def call(self, y_true, y_pred):
        y_pred = tf.clip_by_value(y_pred, 1e-7, 1.0 - 1e-7)

        if self.label_smoothing > 0:
            num_classes = tf.cast(tf.shape(y_true)[-1], tf.float32)
            y_true = y_true * (1.0 - self.label_smoothing) + \
                     self.label_smoothing / num_classes

        cross_entropy = -y_true * tf.math.log(y_pred)
        weight = tf.pow(1.0 - y_pred, self.gamma)
        focal = weight * cross_entropy

        if self.class_weights is not None:
            cw = tf.constant(self.class_weights, dtype=tf.float32)
            focal = focal * cw

        return tf.reduce_sum(focal, axis=-1)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
def compute_class_weights(train_dir: Path) -> list[float]:
    """Compute inverse-frequency class weights from the training directory."""
    counts = []
    for cls in CLASSES:
        cls_dir = train_dir / cls
        n = sum(1 for f in cls_dir.iterdir()
                if f.is_file() and f.suffix.lower() in {".jpg", ".jpeg", ".png"})
        counts.append(n)
    total = sum(counts)
    n_classes = len(counts)
    weights = [total / (n_classes * c) for c in counts]
    return weights


def get_dataset(split_dir: Path, shuffle: bool = True) -> tf.data.Dataset:
    """Load a dataset split."""
    ds = tf.keras.utils.image_dataset_from_directory(
        split_dir,
        labels="inferred",
        label_mode="categorical",
        class_names=CLASSES,
        color_mode="rgb",
        batch_size=BATCH_SIZE,
        image_size=(MODEL_INPUT_SIZE[0], MODEL_INPUT_SIZE[1]),
        shuffle=shuffle,
        seed=RANDOM_SEED if shuffle else None,
    )
    return ds.prefetch(buffer_size=tf.data.AUTOTUNE)


def build_model(unfreeze_from: int = 100, dropout: float = 0.2) -> models.Model:
    """Build the MobileNetV2 model with in-graph normalisation."""
    inputs = tf.keras.Input(shape=(MODEL_INPUT_SIZE[0], MODEL_INPUT_SIZE[1], 3))

    # In-graph normalisation (ImageNet stats)
    x = layers.Rescaling(1.0 / 255.0)(inputs)
    mean_tensor = tf.constant(PIXEL_MEAN, dtype=tf.float32)
    std_tensor = tf.constant(PIXEL_STD, dtype=tf.float32)
    x = (x - mean_tensor) / std_tensor

    base_model = applications.MobileNetV2(
        input_shape=(MODEL_INPUT_SIZE[0], MODEL_INPUT_SIZE[1], 3),
        include_top=False,
        weights="imagenet",
    )
    # All layers trainable initially; we freeze selectively below
    base_model.trainable = True
    for layer in base_model.layers[:unfreeze_from]:
        layer.trainable = False

    x = base_model(x, training=False)
    x = layers.GlobalAveragePooling2D()(x)
    x = layers.Dropout(dropout)(x)
    outputs = layers.Dense(len(CLASSES), activation="softmax", name="predictions")(x)

    return models.Model(inputs, outputs, name="CropHealth_MobileNetV2_v11")


# ---------------------------------------------------------------------------
# Experiment configurations
# ---------------------------------------------------------------------------
EXPERIMENT_CONFIGS = {
    "A": {
        "description": "Class-weighted categorical crossentropy",
        "loss": "weighted_cce",
        "label_smoothing": 0.0,
        "unfreeze_from": 100,
        "dropout": 0.2,
        "lr_head": 1e-3,
        "lr_finetune": 1e-5,
        "epochs_head": 10,
        "epochs_finetune": 15,
        "augmented_data": False,
    },
    "B": {
        "description": "Enhanced augmentation (run augment_v11.py first)",
        "loss": "cce",
        "label_smoothing": 0.0,
        "unfreeze_from": 100,
        "dropout": 0.2,
        "lr_head": 1e-3,
        "lr_finetune": 1e-5,
        "epochs_head": 10,
        "epochs_finetune": 15,
        "augmented_data": True,
    },
    "C": {
        "description": "Focal loss (gamma=2.0) with class weights",
        "loss": "focal",
        "label_smoothing": 0.0,
        "unfreeze_from": 100,
        "dropout": 0.2,
        "lr_head": 1e-3,
        "lr_finetune": 1e-5,
        "epochs_head": 10,
        "epochs_finetune": 15,
        "augmented_data": False,
    },
    "D": {
        "description": "Deeper fine-tuning (layer 80) + label smoothing 0.1",
        "loss": "weighted_cce",
        "label_smoothing": 0.1,
        "unfreeze_from": 80,
        "dropout": 0.3,
        "lr_head": 1e-3,
        "lr_finetune": 5e-6,
        "epochs_head": 10,
        "epochs_finetune": 20,
        "augmented_data": False,
    },
}


# ---------------------------------------------------------------------------
# Training loop
# ---------------------------------------------------------------------------
def run_experiment(exp_id: str):
    cfg = EXPERIMENT_CONFIGS[exp_id]
    exp_dir = MODELS_DIR / f"exp_{exp_id}"
    exp_dir.mkdir(parents=True, exist_ok=True)
    checkpoint_path = exp_dir / "best.keras"

    print("=" * 60)
    print(f"Experiment {exp_id}: {cfg['description']}")
    print("=" * 60)

    # Reproducibility
    tf.keras.utils.set_random_seed(RANDOM_SEED)
    tf.config.experimental.enable_op_determinism()

    # --- Datasets ---
    train_split = PROCESSED_DIR / "train"
    val_split = PROCESSED_DIR / "val"

    train_ds = get_dataset(train_split, shuffle=True)
    val_ds = get_dataset(val_split, shuffle=False)

    # --- Class weights ---
    cw = compute_class_weights(train_split)
    print(f"Class weights: {dict(zip(CLASSES, [round(w, 3) for w in cw]))}")

    # --- Loss ---
    if cfg["loss"] == "weighted_cce":
        loss_fn = tf.keras.losses.CategoricalCrossentropy(
            label_smoothing=cfg["label_smoothing"]
        )
        class_weight_dict = {i: w for i, w in enumerate(cw)}
    elif cfg["loss"] == "focal":
        loss_fn = FocalLoss(gamma=2.0, class_weights=cw,
                            label_smoothing=cfg["label_smoothing"])
        class_weight_dict = None  # weights baked into the loss
    else:  # plain cce
        loss_fn = tf.keras.losses.CategoricalCrossentropy(
            label_smoothing=cfg["label_smoothing"]
        )
        class_weight_dict = None

    # --- Build model ---
    model = build_model(unfreeze_from=100, dropout=cfg["dropout"])

    # --- Stage 1: Train head only ---
    print("\n--- Stage 1: Head Training ---")
    # Freeze backbone for stage 1
    base = next(l for l in model.layers if isinstance(l, tf.keras.Model))
    base.trainable = False

    model.compile(
        optimizer=optimizers.Adam(learning_rate=cfg["lr_head"]),
        loss=loss_fn,
        metrics=["accuracy"],
    )

    early_stop = callbacks.EarlyStopping(
        monitor="val_loss", patience=3, restore_best_weights=True, verbose=1
    )
    checkpoint_cb = callbacks.ModelCheckpoint(
        filepath=str(checkpoint_path),
        monitor="val_accuracy",
        save_best_only=True,
        verbose=1,
    )

    t0 = time.time()
    h1 = model.fit(
        train_ds,
        validation_data=val_ds,
        epochs=cfg["epochs_head"],
        callbacks=[early_stop, checkpoint_cb],
        class_weight=class_weight_dict,
    )
    stage1_time = time.time() - t0

    # --- Stage 2: Fine-tune ---
    print(f"\n--- Stage 2: Fine-Tuning (unfreeze from layer {cfg['unfreeze_from']}) ---")
    base.trainable = True
    for layer in base.layers[:cfg["unfreeze_from"]]:
        layer.trainable = False

    model.compile(
        optimizer=optimizers.Adam(learning_rate=cfg["lr_finetune"]),
        loss=loss_fn,
        metrics=["accuracy"],
    )

    early_stop_ft = callbacks.EarlyStopping(
        monitor="val_loss", patience=3, restore_best_weights=True, verbose=1
    )
    checkpoint_ft = callbacks.ModelCheckpoint(
        filepath=str(checkpoint_path),
        monitor="val_accuracy",
        save_best_only=True,
        verbose=1,
    )

    t0 = time.time()
    h2 = model.fit(
        train_ds,
        validation_data=val_ds,
        epochs=cfg["epochs_finetune"],
        callbacks=[early_stop_ft, checkpoint_ft],
        class_weight=class_weight_dict,
    )
    stage2_time = time.time() - t0

    # --- Validation metrics ---
    best_val_acc = max(
        max(h1.history["val_accuracy"]),
        max(h2.history["val_accuracy"]),
    )
    best_val_loss = min(
        min(h1.history["val_loss"]),
        min(h2.history["val_loss"]),
    )

    # --- Save experiment metadata ---
    meta = {
        "experiment_id": exp_id,
        "description": cfg["description"],
        "config": cfg,
        "seed": RANDOM_SEED,
        "class_weights": dict(zip(CLASSES, cw)),
        "training": {
            "stage1_epochs": len(h1.history["loss"]),
            "stage2_epochs": len(h2.history["loss"]),
            "stage1_time_s": round(stage1_time, 1),
            "stage2_time_s": round(stage2_time, 1),
            "best_val_accuracy": round(best_val_acc, 5),
            "best_val_loss": round(best_val_loss, 5),
        },
        "checkpoint_path": str(checkpoint_path),
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }
    meta_path = exp_dir / "experiment_meta.json"
    meta_path.write_text(json.dumps(meta, indent=2))

    print(f"\n[OK] Experiment {exp_id} complete.")
    print(f"     Best val accuracy: {best_val_acc:.4f}")
    print(f"     Best val loss:     {best_val_loss:.4f}")
    print(f"     Checkpoint: {checkpoint_path}")
    print(f"     Metadata:   {meta_path}")

    return meta


def main():
    parser = argparse.ArgumentParser(description="v1.1 Training Experiments")
    parser.add_argument("--experiment", type=str, required=True,
                        choices=list(EXPERIMENT_CONFIGS.keys()),
                        help="Experiment ID to run (A, B, C, or D)")
    args = parser.parse_args()
    run_experiment(args.experiment)


if __name__ == "__main__":
    main()
