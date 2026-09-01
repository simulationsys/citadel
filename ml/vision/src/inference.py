import sys
import json
import os
import time

# Suppress TF logging
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'
import cv2
import numpy as np
import tensorflow as tf

LOW_THRESHOLD = 0.50
MEDIUM_MAX = 0.79

CLASSES = [
    "healthy",
    "early_blight",
    "late_blight",
    "leaf_spot",
    "yellow_leaf_curl_virus"
]

def build_result(label, confidence, image_quality, limitation=None):
    return {
        "kind": "crop_health",
        "crop": "tomato",
        "label": label,
        "confidence": float(confidence),
        "imageQuality": image_quality,
        "limitation": limitation
    }

def main():
    if len(sys.argv) < 2:
        print(json.dumps(build_result("invalid_image", 0.0, "invalid", "No image path provided.")))
        return

    image_path = sys.argv[1]
    if not os.path.exists(image_path):
        print(json.dumps(build_result("invalid_image", 0.0, "invalid", "Image file does not exist.")))
        return

    # 1. Read Image with OpenCV
    img = cv2.imread(image_path)
    if img is None:
        print(json.dumps(build_result("invalid_image", 0.0, "invalid", "Could not decode image.")))
        return

    # 2. Heuristic Quality Check (Blur & Brightness)
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    laplacian_var = cv2.Laplacian(gray, cv2.CV_64F).var()
    mean_brightness = np.mean(gray)

    image_quality = "acceptable"
    limitation = None

    if laplacian_var < 50.0:
        image_quality = "poor"
        limitation = "Image is blurry; result may be unreliable."
    elif mean_brightness < 40:
        image_quality = "poor"
        limitation = "Image is too dark; result may be unreliable."
    elif mean_brightness > 220:
        image_quality = "poor"
        limitation = "Image is too bright or overexposed; result may be unreliable."

    # 3. Preprocess for Model
    img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    img_resized = cv2.resize(img_rgb, (224, 224))
    input_data = np.expand_dims(img_resized, axis=0).astype(np.float32)

    # 4. Load Model and Run Inference
    model_path = os.path.join(os.path.dirname(__file__), "..", "models", "crop_health_mobilenetv2.tflite")
    model_path = os.path.abspath(model_path)
    
    if not os.path.exists(model_path):
        print(json.dumps(build_result("invalid_image", 0.0, "invalid", "Model artifact not found.")))
        return

    try:
        interpreter = tf.lite.Interpreter(model_path=model_path)
        interpreter.allocate_tensors()
    except Exception as e:
        print(json.dumps(build_result("invalid_image", 0.0, "invalid", f"Failed to load model: {str(e)}")))
        return

    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    
    # Benchmarking
    start_time = time.time()
    
    interpreter.set_tensor(input_details[0]['index'], input_data)
    interpreter.invoke()
    output_data = interpreter.get_tensor(output_details[0]['index'])[0]

    end_time = time.time()
    latency_ms = (end_time - start_time) * 1000

    # 5. Extract Confidence
    max_idx = np.argmax(output_data)
    confidence = output_data[max_idx]
    predicted_label = CLASSES[max_idx]

    # 6. Apply Confidence Rules
    if image_quality == "poor":
        confidence = min(confidence, MEDIUM_MAX)

    if confidence < LOW_THRESHOLD:
        predicted_label = "inconclusive"
        if not limitation:
            limitation = "Model confidence is too low to identify a specific condition."

    # Return Result
    res = build_result(predicted_label, confidence, image_quality, limitation)
    res["_latency_ms"] = round(latency_ms, 2)
    print(json.dumps(res))

if __name__ == "__main__":
    main()
