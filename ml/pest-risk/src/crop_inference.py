"""Hardened TFLite crop-health inference shared by edge and backend APIs."""
from __future__ import annotations

import io
import os
import time
from dataclasses import dataclass
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter, ImageStat, UnidentifiedImageError

from .pest_inference import ModelUnavailable

CLASSES = ("healthy", "early_blight", "late_blight", "leaf_spot", "yellow_leaf_curl_virus")
MAX_IMAGE_BYTES = 5_000_000


def _interpreter(model_path: Path):
    try:
        from tflite_runtime.interpreter import Interpreter  # type: ignore
    except ImportError:
        try:
            from tensorflow import lite  # type: ignore
            Interpreter = lite.Interpreter
        except (ImportError, AttributeError) as error:
            raise ModelUnavailable("Install a compatible tflite-runtime or TensorFlow runtime.") from error
    try:
        runtime = Interpreter(model_path=str(model_path))
        runtime.allocate_tensors()
        return runtime
    except Exception as error:
        raise ModelUnavailable(f"Crop-health model could not be loaded: {error}") from error


@dataclass
class CropHealthClassifier:
    model_path: Path
    low_threshold: float = 0.50
    high_threshold: float = 0.80

    def __post_init__(self) -> None:
        if not self.model_path.is_file():
            raise ModelUnavailable("Crop-health model is not installed.")
        self.interpreter = _interpreter(self.model_path)
        inputs = self.interpreter.get_input_details()
        outputs = self.interpreter.get_output_details()
        if len(inputs) != 1 or len(outputs) != 1:
            raise ModelUnavailable("Crop-health model must have one input and one output tensor.")
        self.input = inputs[0]
        self.output = outputs[0]
        shape = tuple(int(value) for value in self.input["shape"])
        if len(shape) != 4 or shape[0] != 1 or shape[3] != 3:
            raise ModelUnavailable(f"Unsupported crop-health input shape: {shape}.")

    def analyze_bytes(self, image_bytes: bytes) -> dict:
        if not image_bytes:
            raise ValueError("Image is empty.")
        if len(image_bytes) > MAX_IMAGE_BYTES:
            raise ValueError("Image exceeds the 5 MB limit.")
        try:
            image = Image.open(io.BytesIO(image_bytes))
            image.verify()
            image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
        except (UnidentifiedImageError, OSError, Image.DecompressionBombError) as error:
            raise ValueError("Image must be a valid JPEG or PNG.") from error

        quality, limitation = self._quality(image)
        if quality != "acceptable":
            return self._result("invalid_image", 0.0, quality, limitation, 0.0)

        height, width = (int(self.input["shape"][1]), int(self.input["shape"][2]))
        pixels = np.asarray(image.resize((width, height)), dtype=np.float32)
        dtype = self.input["dtype"]
        if dtype != np.float32:
            pixels = pixels.astype(dtype)
        started = time.perf_counter()
        self.interpreter.set_tensor(self.input["index"], np.expand_dims(pixels, axis=0))
        self.interpreter.invoke()
        scores = np.asarray(self.interpreter.get_tensor(self.output["index"])[0], dtype=float)
        if scores.size != len(CLASSES) or not np.all(np.isfinite(scores)):
            raise ValueError("Model returned an invalid prediction tensor.")
        index = int(np.argmax(scores))
        confidence = float(scores[index])
        label = CLASSES[index]
        limitation = None
        if confidence < self.low_threshold:
            label = "inconclusive"
            limitation = "Confidence is too low; capture a clearer close-up of one tomato leaf."
        elif confidence < self.high_threshold:
            limitation = "Moderate confidence; confirm with another clear leaf image."
        return self._result(label, confidence, quality, limitation, (time.perf_counter() - started) * 1000)

    @staticmethod
    def _quality(image: Image.Image) -> tuple[str, str | None]:
        width, height = image.size
        if min(width, height) < 224:
            return "invalid", f"Image resolution {width}x{height} is below 224x224."
        gray = image.convert("L")
        brightness = ImageStat.Stat(gray).mean[0]
        if brightness < 40:
            return "invalid", "Image is too dark; recapture in better light."
        if brightness > 220:
            return "invalid", "Image is overexposed; recapture without glare."
        edges = gray.filter(ImageFilter.FIND_EDGES)
        if ImageStat.Stat(edges).var[0] < 30:
            return "poor", "Image appears blurry; hold the camera steady and refocus."
        sample = np.asarray(image.resize((128, 128)), dtype=np.int16)
        red, green, blue = sample[..., 0], sample[..., 1], sample[..., 2]
        if float(np.mean((green > red + 10) & (green > blue + 10))) < 0.02:
            return "poor", "No identifiable leaf detected; photograph one tomato leaf."
        return "acceptable", None

    @staticmethod
    def _result(label: str, confidence: float, quality: str, limitation: str | None, latency_ms: float) -> dict:
        return {"kind": "crop_health", "crop": "tomato", "label": label, "confidence": confidence,
                "imageQuality": quality, "limitation": limitation, "modelVersion": "v1.1.0",
                "latencyMs": round(latency_ms, 2)}


def load_default_classifier() -> CropHealthClassifier:
    default = Path(__file__).resolve().parents[2] / "vision" / "models" / "crop_health_mobilenetv2_v1.1.tflite"
    return CropHealthClassifier(Path(os.getenv("CITADEL_CROP_MODEL", default)))
