"""Crop-health inference.

Runtime selection is deliberate: `tflite_runtime` first, full TensorFlow only as
a development fallback. A Raspberry Pi 3B+ has 1 GB of RAM, and importing
TensorFlow to reach an interpreter it already ships standalone is what makes the
crop-health path unusable there.

Two entry points, one code path:
  * `classify(path)` — in-process. Caches the interpreter, so repeated calls pay
    the load cost once.
  * `python -m src.inference <image>` / `python src/inference.py <image>` — the
    CLI the edge API's subprocess bridge invokes. Preserved deliberately; see
    services/edge-api/app/vision.py for why one interpreter cannot hold both
    this package and citadel_pest_risk.

Failure vocabulary matters here. An *infrastructure* failure (no runtime, no
model, unloadable model, wrong tensor shape) raises `InferenceUnavailable` and
exits 3. It must never be reported as `inconclusive`, which means one specific
thing: the model ran and was not confident enough.
"""

import json
import os
import sys
import time

os.environ.setdefault("TF_CPP_MIN_LOG_LEVEL", "3")  # only read if TF is the fallback

import cv2
import numpy as np

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
LOW_THRESHOLD = 0.50
MEDIUM_MAX = 0.79

# Quality gate thresholds (documented for calibration)
BLUR_THRESHOLD = 30.0          # Laplacian variance; below = blurry
DARK_THRESHOLD = 40             # Mean brightness; below = too dark
BRIGHT_THRESHOLD = 220          # Mean brightness; above = overexposed
MIN_RESOLUTION = 224            # Minimum width and height in pixels
GREEN_RATIO_THRESHOLD = 0.02   # Minimum ratio of green-dominant pixels

CLASSES = [
    "healthy",
    "early_blight",
    "late_blight",
    "leaf_spot",
    "yellow_leaf_curl_virus",
]

_MODELS_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "models"))
DEFAULT_MODEL = os.path.join(_MODELS_DIR, "crop_health_mobilenetv2_v1.1.tflite")

# Exit codes for the CLI contract. app/vision.py maps 3 -> 503.
EXIT_OK = 0
EXIT_ERROR = 1
EXIT_UNAVAILABLE = 3


class InferenceUnavailable(RuntimeError):
    """Infrastructure fault: runtime, model, or tensor contract. Never a diagnosis."""


def model_path() -> str:
    """Env override exists so tests can point at a fixture without moving files."""
    return os.getenv("CITADEL_CROP_MODEL") or DEFAULT_MODEL


# ---------------------------------------------------------------------------
# Runtime selection
# ---------------------------------------------------------------------------
def load_interpreter_class():
    """Return (InterpreterClass, runtime_name).

    tflite_runtime is tried first and TensorFlow is never imported when it
    succeeds — that import alone is hundreds of MB of RSS on a 1 GB Pi.
    """
    try:
        from tflite_runtime.interpreter import Interpreter
        return Interpreter, "tflite_runtime"
    except ImportError:
        pass
    try:
        from tensorflow.lite import Interpreter
        return Interpreter, "tensorflow"
    except ImportError as error:
        raise InferenceUnavailable(
            "No TFLite runtime available. Install 'tflite-runtime' (preferred on "
            f"Raspberry Pi) or 'tensorflow' (development): {error}"
        ) from error


def _metadata_classes(path: str):
    """Class order comes from the model's own sidecar when present; CLASSES is
    only the fallback. A silently reordered export is otherwise undetectable."""
    sidecar = os.path.splitext(path)[0] + ".json"
    if not os.path.exists(sidecar):
        return None
    try:
        with open(sidecar, "r", encoding="utf-8") as handle:
            return json.load(handle).get("output", {}).get("classes") or None
    except (OSError, json.JSONDecodeError):
        return None


# Cached per process: (interpreter, runtime, classes, input_details, output_details)
_CACHE = {}


def get_interpreter(path: str | None = None):
    """Load, allocate and validate once per process, per model path."""
    path = path or model_path()
    if path in _CACHE:
        return _CACHE[path]

    if not os.path.exists(path):
        raise InferenceUnavailable(f"Model artifact not found at {path}")

    interpreter_cls, runtime = load_interpreter_class()
    started = time.time()
    try:
        interpreter = interpreter_cls(model_path=path)
        interpreter.allocate_tensors()
    except Exception as error:
        raise InferenceUnavailable(f"Failed to load model {path}: {error}") from error
    load_ms = (time.time() - started) * 1000

    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    if not input_details or not output_details:
        raise InferenceUnavailable("Model exposes no input or output tensors.")

    in_shape = list(input_details[0]["shape"])
    if len(in_shape) != 4 or in_shape[1:3] != [224, 224] or in_shape[3] != 3:
        raise InferenceUnavailable(
            f"Unexpected input shape {in_shape}; expected [1, 224, 224, 3].")

    classes = _metadata_classes(path) or CLASSES
    out_shape = list(output_details[0]["shape"])
    n_out = int(out_shape[-1])
    if n_out != len(classes):
        raise InferenceUnavailable(
            f"Model outputs {n_out} classes but {len(classes)} labels are configured "
            f"({classes}). Refusing to guess the mapping.")

    entry = {
        "interpreter": interpreter,
        "runtime": runtime,
        "classes": classes,
        "input_details": input_details,
        "output_details": output_details,
        "input_dtype": input_details[0]["dtype"],
        "load_ms": round(load_ms, 2),
        "model_path": path,
    }
    _CACHE[path] = entry
    return entry


def reset_cache() -> None:
    """Tests only — the process-wide cache would otherwise leak between cases."""
    _CACHE.clear()


# ---------------------------------------------------------------------------
# Result contract
# ---------------------------------------------------------------------------
def build_result(label, confidence, image_quality, limitation=None):
    return {
        "kind": "crop_health",
        "crop": "tomato",
        "label": label,
        "confidence": float(confidence),
        "imageQuality": image_quality,
        "limitation": limitation,
    }


def _invalid(limitation):
    return build_result("invalid_image", 0.0, "invalid", limitation)


def _poor(limitation):
    return build_result("invalid_image", 0.0, "poor", limitation)


# ---------------------------------------------------------------------------
# Quality Gate
# ---------------------------------------------------------------------------
def assess_quality(img):
    """Heuristic checks on a decoded BGR image, run before any inference.

    Returns (quality_state, limitation) where quality_state is
    "acceptable" | "poor" | "invalid".
    """
    h, w = img.shape[:2]

    if h < MIN_RESOLUTION or w < MIN_RESOLUTION:
        return ("invalid",
                f"Image resolution ({w}x{h}) is below the minimum {MIN_RESOLUTION}x{MIN_RESOLUTION}.")

    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

    mean_brightness = float(np.mean(gray))
    if mean_brightness < DARK_THRESHOLD:
        return ("invalid",
                "Image is too dark to analyse. Please recapture in better lighting.")
    if mean_brightness > BRIGHT_THRESHOLD:
        return ("invalid",
                "Image is overexposed. Please recapture without direct flash or glare.")

    laplacian_var = float(cv2.Laplacian(gray, cv2.CV_64F).var())
    if laplacian_var < BLUR_THRESHOLD:
        return ("poor",
                "Image appears blurry. Please hold the camera steady and refocus.")

    # Leaf suitability: intentionally lenient — catches screenshots and solid
    # colours without rejecting field photos with brown/yellow diseased areas.
    b, g, r = cv2.split(img)
    green_dominant = (g > r.astype(np.int16) + 10) & (g > b.astype(np.int16) + 10)
    green_ratio = float(np.sum(green_dominant)) / (h * w)
    if green_ratio < GREEN_RATIO_THRESHOLD:
        return ("poor",
                "No identifiable leaf detected. Please photograph a single tomato leaf.")

    return ("acceptable", None)


# ---------------------------------------------------------------------------
# Inference
# ---------------------------------------------------------------------------
def classify(image_path: str, path: str | None = None) -> dict:
    """Full pipeline for one image.

    Raises InferenceUnavailable for infrastructure faults. Returns a result dict
    for every *image* outcome, including a legitimate low-confidence
    "inconclusive".
    """
    if not os.path.exists(image_path):
        return _invalid("Image file does not exist.")

    img = cv2.imread(image_path)
    if img is None:
        return _invalid("Could not decode image. File may be corrupt or unsupported.")

    quality_state, limitation = assess_quality(img)
    if quality_state == "invalid":
        return _invalid(limitation)
    if quality_state == "poor":
        return _poor(limitation)

    # Load before preprocessing so a runtime fault is not attributed to the image.
    entry = get_interpreter(path)
    interpreter = entry["interpreter"]

    img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    img_resized = cv2.resize(img_rgb, (224, 224))
    input_data = np.expand_dims(img_resized, axis=0).astype(entry["input_dtype"])

    started = time.time()
    try:
        interpreter.set_tensor(entry["input_details"][0]["index"], input_data)
        interpreter.invoke()
        output_data = interpreter.get_tensor(entry["output_details"][0]["index"])[0]
    except Exception as error:
        raise InferenceUnavailable(f"Inference failed: {error}") from error
    latency_ms = (time.time() - started) * 1000

    classes = entry["classes"]
    max_idx = int(np.argmax(output_data))
    confidence = float(output_data[max_idx])
    predicted_label = classes[max_idx]

    # Confidence policy (calibrated in Phase 6):
    #   >= 0.80 normal · 0.50-0.79 cautious · < 0.50 inconclusive
    limitation = None
    if confidence < LOW_THRESHOLD:
        predicted_label = "inconclusive"
        limitation = "Model confidence is too low to identify a specific condition."
    elif confidence <= MEDIUM_MAX:
        limitation = ("Moderate confidence. Consider re-capturing a clearer close-up "
                      "of the affected leaf.")

    result = build_result(predicted_label, confidence, "acceptable", limitation)
    result["_latency_ms"] = round(latency_ms, 2)
    result["_runtime"] = entry["runtime"]
    result["_model_load_ms"] = entry["load_ms"]
    return result


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------
def main(argv=None):
    argv = sys.argv if argv is None else argv
    if len(argv) < 2:
        print(json.dumps(_invalid("No image path provided.")))
        return EXIT_OK
    try:
        print(json.dumps(classify(argv[1])))
        return EXIT_OK
    except InferenceUnavailable as error:
        # stdout so the caller gets structured detail; exit 3 so it can tell this
        # apart from a crash and answer 503 rather than 502.
        print(json.dumps({"error": {"code": "model_unavailable", "message": str(error)}}))
        print(f"crop-health unavailable: {error}", file=sys.stderr)
        return EXIT_UNAVAILABLE


if __name__ == "__main__":
    sys.exit(main())
