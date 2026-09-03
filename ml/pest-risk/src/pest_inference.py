"""On-device TensorFlow Lite SSD-style pest detector adapter."""
from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path

import numpy as np
from PIL import Image

from .schemas import PestObservation


class ModelUnavailable(RuntimeError):
    """The service is healthy but no verified model has been deployed."""


@dataclass
class PestDetector:
    model_path: Path
    labels_path: Path
    score_threshold: float = 0.65

    def __post_init__(self) -> None:
        if not self.model_path.is_file() or not self.labels_path.is_file():
            raise ModelUnavailable("Pest model or labels are not installed.")
        try:
            from tflite_runtime.interpreter import Interpreter  # type: ignore
        except ImportError:
            try:
                from tensorflow.lite import Interpreter  # type: ignore
            except ImportError as error:
                raise ModelUnavailable("Install tensorflow or tflite-runtime to use pest inference.") from error
        self.interpreter = Interpreter(model_path=str(self.model_path))
        self.interpreter.allocate_tensors()
        self.input_details = self.interpreter.get_input_details()[0]
        self.output_details = self.interpreter.get_output_details()
        self.labels = [line.strip() for line in self.labels_path.read_text(encoding="utf-8").splitlines() if line.strip()]

    def analyze_bytes(self, image_bytes: bytes) -> list[PestObservation]:
        input_height, input_width = self.input_details["shape"][1:3]
        image = Image.open(__import__("io").BytesIO(image_bytes)).convert("RGB").resize((input_width, input_height))
        pixels = np.asarray(image)
        input_dtype = self.input_details["dtype"]
        prepared = (pixels.astype(np.float32) / 255.0) if input_dtype == np.float32 else pixels.astype(input_dtype)
        self.interpreter.set_tensor(self.input_details["index"], np.expand_dims(prepared, axis=0))
        self.interpreter.invoke()
        tensors = [self.interpreter.get_tensor(item["index"])[0] for item in self.output_details]
        return self._decode_ssd_outputs(tensors)

    def _decode_ssd_outputs(self, tensors: list[np.ndarray]) -> list[PestObservation]:
        """Decode the common SSD output sequence: boxes, classes, scores, detection count."""
        if len(tensors) < 3:
            raise ValueError("Unsupported model: expected SSD boxes, classes, and scores outputs.")
        classes, scores = tensors[1].astype(int), tensors[2].astype(float)
        counts: dict[str, tuple[float, int]] = {}
        for class_id, score in zip(classes, scores):
            if score < self.score_threshold:
                continue
            label = self.labels[class_id] if 0 <= class_id < len(self.labels) else f"class_{class_id}"
            highest, count = counts.get(label, (0.0, 0))
            counts[label] = (max(highest, float(score)), count + 1)
        return [PestObservation(label=label, confidence=confidence, count=count) for label, (confidence, count) in counts.items()]


def load_default_detector() -> PestDetector:
    root = Path(__file__).resolve().parents[1]
    model_path = Path(os.getenv("CITADEL_PEST_MODEL", root / "models" / "pest_detector.tflite"))
    labels_path = Path(os.getenv("CITADEL_PEST_LABELS", root / "models" / "labels.txt"))
    return PestDetector(model_path=model_path, labels_path=labels_path)
