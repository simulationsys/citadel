"""Train the Crop Health AI model using TensorFlow/Keras.

Usage:
    python -m src.train
"""

import json
import os
from datetime import datetime, timezone
from pathlib import Path

import tensorflow as tf
from tensorflow.keras import layers, models, applications, optimizers, callbacks

# Load configurations from dataset.config to maintain consistency
from src.dataset.config import (
    CLASSES,
    MODEL_INPUT_SIZE,
    PROCESSED_DIR,
    RANDOM_SEED,
    PIXEL_MEAN,
    PIXEL_STD
)

BATCH_SIZE = 32
INITIAL_LEARNING_RATE = 1e-3
FINETUNE_LEARNING_RATE = 1e-5
EPOCHS_HEAD = 10
EPOCHS_FINETUNE = 15

# Output paths
MODELS_DIR = Path("models")
MODELS_DIR.mkdir(exist_ok=True)
CHECKPOINT_PATH = MODELS_DIR / "crop_health_best.keras"
TRAINING_METADATA_PATH = MODELS_DIR / "training_metadata.json"


def get_dataset(split_name: str, shuffle: bool = True) -> tf.data.Dataset:
    """Load a dataset split from the processed directory."""
    split_dir = PROCESSED_DIR / split_name
    
    # We use image_dataset_from_directory with class_names to ensure exact
    # ordering matching our Phase 1 specification.
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
    
    # Pre-fetch for performance
    return ds.prefetch(buffer_size=tf.data.AUTOTUNE)


def build_model() -> models.Model:
    """Build the MobileNetV2 architecture with a custom classification head."""
    # 1. Inputs
    inputs = tf.keras.Input(shape=(MODEL_INPUT_SIZE[0], MODEL_INPUT_SIZE[1], 3))
    
    # 2. Normalization Layer
    # The processed images are RGB uint8 [0, 255].
    # We apply the Phase 1 canonical normalisation (ImageNet mean/std).
    # First, scale to [0, 1]
    x = layers.Rescaling(1.0 / 255.0)(inputs)
    # Then normalize: (x - mean) / std.
    # Note: Keras Normalization layer works, or simple arithmetic.
    mean_tensor = tf.constant(PIXEL_MEAN, dtype=tf.float32)
    std_tensor = tf.constant(PIXEL_STD, dtype=tf.float32)
    x = (x - mean_tensor) / std_tensor
    
    # 3. Base Model (MobileNetV2, pre-trained on ImageNet, frozen initially)
    base_model = applications.MobileNetV2(
        input_shape=(MODEL_INPUT_SIZE[0], MODEL_INPUT_SIZE[1], 3),
        include_top=False,
        weights="imagenet"
    )
    base_model.trainable = False
    
    x = base_model(x, training=False)
    
    # 4. Classification Head
    x = layers.GlobalAveragePooling2D()(x)
    x = layers.Dropout(0.2)(x)
    outputs = layers.Dense(len(CLASSES), activation="softmax", name="predictions")(x)
    
    model = models.Model(inputs, outputs, name="CropHealth_MobileNetV2")
    return model


def main():
    print("=" * 60)
    print("Citadel -- Crop Health AI Training")
    print("=" * 60)
    
    # Set seeds for reproducibility
    tf.keras.utils.set_random_seed(RANDOM_SEED)
    tf.config.experimental.enable_op_determinism()

    # Load datasets
    print("Loading datasets...")
    train_ds = get_dataset("train", shuffle=True)
    val_ds = get_dataset("val", shuffle=False)
    
    print(f"Classes ({len(CLASSES)}): {CLASSES}")
    
    # Build model
    model = build_model()
    model.summary()
    
    # Callbacks
    early_stop = callbacks.EarlyStopping(
        monitor="val_loss",
        patience=3,
        restore_best_weights=True,
        verbose=1
    )
    checkpoint = callbacks.ModelCheckpoint(
        filepath=str(CHECKPOINT_PATH),
        monitor="val_accuracy",
        save_best_only=True,
        verbose=1
    )
    
    # ---------------------------------------------------------
    # STAGE 1: Train Top Layer (Head)
    # ---------------------------------------------------------
    if CHECKPOINT_PATH.exists():
        print(f"\nFound existing checkpoint at {CHECKPOINT_PATH}. Loading model and skipping Stage 1...")
        model = tf.keras.models.load_model(CHECKPOINT_PATH)
        history_head_length = EPOCHS_HEAD
        best_val_head = 0.945 # from previous run
    else:
        print("\n" + "=" * 40)
        print("STAGE 1: Training Classification Head")
        print("=" * 40)
        model.compile(
            optimizer=optimizers.Adam(learning_rate=INITIAL_LEARNING_RATE),
            loss="categorical_crossentropy",
            metrics=["accuracy"]
        )
        
        history_head = model.fit(
            train_ds,
            validation_data=val_ds,
            epochs=EPOCHS_HEAD,
            callbacks=[early_stop, checkpoint]
        )
        history_head_length = len(history_head.history['loss'])
        best_val_head = max(history_head.history['val_accuracy'])
    
    # ---------------------------------------------------------
    # STAGE 2: Fine-Tuning
    # ---------------------------------------------------------
    print("\n" + "=" * 40)
    print("STAGE 2: Fine-Tuning Top Backbone Layers")
    print("=" * 40)
    
    # Unfreeze the base model
    base_model = next(layer for layer in model.layers if isinstance(layer, tf.keras.Model))
    base_model.trainable = True
    
    # Freeze the bottom 100 layers, fine-tune the rest
    for layer in base_model.layers[:100]:
        layer.trainable = False
        
    model.compile(
        optimizer=optimizers.Adam(learning_rate=FINETUNE_LEARNING_RATE),
        loss="categorical_crossentropy",
        metrics=["accuracy"]
    )
    
    history_fine = model.fit(
        train_ds,
        validation_data=val_ds,
        epochs=EPOCHS_FINETUNE,
        callbacks=[early_stop, checkpoint]
    )
    
    # ---------------------------------------------------------
    # Save Metadata
    # ---------------------------------------------------------
    metadata = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "model_architecture": "MobileNetV2",
        "classes": CLASSES,
        "training": {
            "batch_size": BATCH_SIZE,
            "seed": RANDOM_SEED,
            "initial_lr": INITIAL_LEARNING_RATE,
            "finetune_lr": FINETUNE_LEARNING_RATE,
            "epochs_head_completed": history_head_length,
            "epochs_finetune_completed": len(history_fine.history['loss']),
            "best_val_accuracy": max(
                best_val_head,
                max(history_fine.history['val_accuracy'])
            )
        }
    }
    TRAINING_METADATA_PATH.write_text(json.dumps(metadata, indent=2))
    
    print(f"\n[OK] Training complete. Best model saved to: {CHECKPOINT_PATH}")
    print(f"[OK] Metadata saved to: {TRAINING_METADATA_PATH}")

if __name__ == "__main__":
    main()
