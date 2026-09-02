import sys
import json
import os
import time

# Suppress TF logging before import
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'
import cv2
import numpy as np
import tensorflow as tf

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
GREEN_RATIO_THRESHOLD = 0.02   # Minimum ratio of green-dominant pixels for leaf suitability

CLASSES = [
    "healthy",
    "early_blight",
    "late_blight",
    "leaf_spot",
    "yellow_leaf_curl_virus"
]


def build_result(label, confidence, image_quality, limitation=None):
    """Build the Phase 1 output contract."""
    return {
        "kind": "crop_health",
        "crop": "tomato",
        "label": label,
        "confidence": float(confidence),
        "imageQuality": image_quality,
        "limitation": limitation
    }


def _invalid(limitation):
    """Shorthand for an invalid-image result."""
    return build_result("invalid_image", 0.0, "invalid", limitation)


def _poor(limitation):
    """Shorthand for a poor-quality result (no inference run)."""
    return build_result("invalid_image", 0.0, "poor", limitation)


# ---------------------------------------------------------------------------
# Quality Gate
# ---------------------------------------------------------------------------
def assess_quality(img):
    """Run all heuristic quality checks on a decoded BGR image.

    Returns:
        (quality_state, limitation_message)
        quality_state is one of: "acceptable", "poor", "invalid"
    """
    h, w = img.shape[:2]

    # --- Resolution check ---
    if h < MIN_RESOLUTION or w < MIN_RESOLUTION:
        return ("invalid",
                f"Image resolution ({w}x{h}) is below the minimum {MIN_RESOLUTION}x{MIN_RESOLUTION}.")

    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

    # --- Brightness / exposure check ---
    mean_brightness = float(np.mean(gray))
    if mean_brightness < DARK_THRESHOLD:
        return ("invalid",
                "Image is too dark to analyse. Please recapture in better lighting.")
    if mean_brightness > BRIGHT_THRESHOLD:
        return ("invalid",
                "Image is overexposed. Please recapture without direct flash or glare.")

    # --- Blur check (Laplacian variance) ---
    laplacian_var = float(cv2.Laplacian(gray, cv2.CV_64F).var())
    if laplacian_var < BLUR_THRESHOLD:
        return ("poor",
                "Image appears blurry. Please hold the camera steady and refocus.")

    # --- Leaf suitability (green-channel dominance heuristic) ---
    # A tomato leaf image should contain a meaningful proportion of green-ish
    # pixels.  We count pixels where the green channel exceeds both red and blue
    # by a small margin.  This is intentionally lenient — it catches completely
    # unsuitable inputs (text screenshots, solid colours, indoor objects) without
    # rejecting real field photos that have brown/yellow diseased areas.
    b, g, r = cv2.split(img)
    green_dominant = (g > r.astype(np.int16) + 10) & (g > b.astype(np.int16) + 10)
    green_ratio = float(np.sum(green_dominant)) / (h * w)
    if green_ratio < GREEN_RATIO_THRESHOLD:
        return ("poor",
                "No identifiable leaf detected. Please photograph a single tomato leaf.")

    return ("acceptable", None)


# ---------------------------------------------------------------------------
# Main entry point
# ---------------------------------------------------------------------------
def main():
    # --- Argument validation ---
    if len(sys.argv) < 2:
        print(json.dumps(_invalid("No image path provided.")))
        return

    image_path = sys.argv[1]
    if not os.path.exists(image_path):
        print(json.dumps(_invalid("Image file does not exist.")))
        return

    # --- Decode image ---
    img = cv2.imread(image_path)
    if img is None:
        print(json.dumps(_invalid("Could not decode image. File may be corrupt or unsupported.")))
        return

    # --- Quality gate (runs BEFORE inference) ---
    quality_state, limitation = assess_quality(img)

    if quality_state == "invalid":
        print(json.dumps(_invalid(limitation)))
        return

    if quality_state == "poor":
        print(json.dumps(_poor(limitation)))
        return

    # --- Preprocess for model ---
    img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    img_resized = cv2.resize(img_rgb, (224, 224))
    input_data = np.expand_dims(img_resized, axis=0).astype(np.float32)

    # --- Load TFLite model ---
    model_path = os.path.join(os.path.dirname(__file__), "..", "models",
                              "crop_health_mobilenetv2.tflite")
    model_path = os.path.abspath(model_path)

    if not os.path.exists(model_path):
        print(json.dumps(_invalid("Model artifact not found.")))
        return

    try:
        interpreter = tf.lite.Interpreter(model_path=model_path)
        interpreter.allocate_tensors()
    except Exception as e:
        print(json.dumps(_invalid(f"Failed to load model: {str(e)}")))
        return

    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()

    # --- Run inference with latency benchmark ---
    start_time = time.time()
    interpreter.set_tensor(input_details[0]['index'], input_data)
    interpreter.invoke()
    output_data = interpreter.get_tensor(output_details[0]['index'])[0]
    latency_ms = (time.time() - start_time) * 1000

    # --- Extract prediction ---
    max_idx = int(np.argmax(output_data))
    confidence = float(output_data[max_idx])
    predicted_label = CLASSES[max_idx]

    # --- Confidence policy ---
    if confidence < LOW_THRESHOLD:
        predicted_label = "inconclusive"
        limitation = "Model confidence is too low to identify a specific condition."

    res = build_result(predicted_label, confidence, "acceptable", limitation)
    res["_latency_ms"] = round(latency_ms, 2)
    print(json.dumps(res))


if __name__ == "__main__":
    main()
