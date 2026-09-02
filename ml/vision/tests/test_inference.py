"""
Phase 5: Image Quality & Robustness — Test Suite

Tests the quality gate (blur, brightness, resolution, leaf suitability)
and the full inference pipeline end-to-end.

Run from ml/vision:
    .venv\Scripts\python.exe tests/test_inference.py
"""
import subprocess
import json
import os
import sys
import tempfile
import struct

import cv2
import numpy as np

PYTHON = os.path.join(".venv", "Scripts", "python.exe") if sys.platform == "win32" else os.path.join(".venv", "bin", "python")
PASSED = 0
FAILED = 0


def _run_inference(image_path):
    """Call inference as a subprocess and return parsed JSON."""
    result = subprocess.run(
        [PYTHON, "-m", "src.inference", image_path],
        capture_output=True, text=True
    )
    assert result.returncode == 0, f"Process failed: {result.stderr}"
    lines = result.stdout.strip().split('\n')
    return json.loads(lines[-1])


def _save_temp_image(img, suffix=".jpg"):
    """Write a cv2 image to a temp file and return its path."""
    fd, path = tempfile.mkstemp(suffix=suffix)
    os.close(fd)
    cv2.imwrite(path, img)
    return path


def _report(name, passed, detail=""):
    global PASSED, FAILED
    if passed:
        PASSED += 1
        print(f"  [PASS] {name}")
    else:
        FAILED += 1
        print(f"  [FAIL] {name}  — {detail}")


# -----------------------------------------------------------------------
# Test: Valid clear image (existing dataset)
# -----------------------------------------------------------------------
def test_valid_clear_image():
    sample = "datasets/crop_health/test/healthy/06040967-7b02-43b5-a3fc-4490a9a7ded6___RS_HL 0508.JPG"
    if not os.path.exists(sample):
        _report("valid_clear_image", False, "Sample image not found — skipped")
        return
    data = _run_inference(sample)
    _report("valid_clear_image: kind",        data["kind"] == "crop_health")
    _report("valid_clear_image: quality",     data["imageQuality"] == "acceptable")
    _report("valid_clear_image: confidence",  data["confidence"] > 0.5)
    _report("valid_clear_image: label",       data["label"] in [
        "healthy", "early_blight", "late_blight", "leaf_spot",
        "yellow_leaf_curl_virus", "inconclusive"
    ])


# -----------------------------------------------------------------------
# Test: Blurry image
# -----------------------------------------------------------------------
def test_blurry_image():
    # Create a heavily blurred synthetic leaf-like image
    img = np.zeros((300, 300, 3), dtype=np.uint8)
    img[:, :, 1] = 120  # green channel
    img = cv2.GaussianBlur(img, (51, 51), 30)  # extreme blur
    path = _save_temp_image(img)
    try:
        data = _run_inference(path)
        _report("blurry_image: quality",    data["imageQuality"] in ("poor", "invalid"))
        _report("blurry_image: no_diag",    data["label"] == "invalid_image")
        _report("blurry_image: conf_zero",  data["confidence"] == 0.0)
    finally:
        os.remove(path)


# -----------------------------------------------------------------------
# Test: Dark image
# -----------------------------------------------------------------------
def test_dark_image():
    img = np.full((300, 300, 3), 10, dtype=np.uint8)  # near-black
    path = _save_temp_image(img)
    try:
        data = _run_inference(path)
        _report("dark_image: quality",   data["imageQuality"] == "invalid")
        _report("dark_image: label",     data["label"] == "invalid_image")
    finally:
        os.remove(path)


# -----------------------------------------------------------------------
# Test: Overexposed image
# -----------------------------------------------------------------------
def test_overexposed_image():
    img = np.full((300, 300, 3), 245, dtype=np.uint8)  # near-white
    path = _save_temp_image(img)
    try:
        data = _run_inference(path)
        _report("overexposed_image: quality",  data["imageQuality"] == "invalid")
        _report("overexposed_image: label",    data["label"] == "invalid_image")
    finally:
        os.remove(path)


# -----------------------------------------------------------------------
# Test: Tiny / low-resolution image
# -----------------------------------------------------------------------
def test_tiny_image():
    img = np.zeros((50, 50, 3), dtype=np.uint8)
    img[:, :, 1] = 100
    path = _save_temp_image(img)
    try:
        data = _run_inference(path)
        _report("tiny_image: quality",  data["imageQuality"] == "invalid")
        _report("tiny_image: label",    data["label"] == "invalid_image")
        _report("tiny_image: limitation", "resolution" in (data.get("limitation") or "").lower())
    finally:
        os.remove(path)


# -----------------------------------------------------------------------
# Test: Corrupt / unreadable file
# -----------------------------------------------------------------------
def test_corrupt_image():
    fd, path = tempfile.mkstemp(suffix=".jpg")
    os.write(fd, b"THIS IS NOT A VALID JPEG FILE AT ALL")
    os.close(fd)
    try:
        data = _run_inference(path)
        _report("corrupt_image: quality",  data["imageQuality"] == "invalid")
        _report("corrupt_image: label",    data["label"] == "invalid_image")
    finally:
        os.remove(path)


# -----------------------------------------------------------------------
# Test: Unsupported format (BMP bytes renamed .jpg)
# -----------------------------------------------------------------------
def test_unsupported_format():
    fd, path = tempfile.mkstemp(suffix=".xyz")
    os.write(fd, struct.pack('<2sIHHI', b'BM', 70, 0, 0, 54))  # minimal BMP header bytes
    os.close(fd)
    try:
        data = _run_inference(path)
        _report("unsupported_format: quality",  data["imageQuality"] == "invalid")
        _report("unsupported_format: label",    data["label"] == "invalid_image")
    finally:
        os.remove(path)


# -----------------------------------------------------------------------
# Test: Missing image
# -----------------------------------------------------------------------
def test_missing_image():
    data = _run_inference("this_file_does_not_exist_at_all.jpg")
    _report("missing_image: quality",  data["imageQuality"] == "invalid")
    _report("missing_image: label",    data["label"] == "invalid_image")


# -----------------------------------------------------------------------
# Test: No leaf (unsuitable subject — red square)
# -----------------------------------------------------------------------
def test_no_leaf():
    img = np.zeros((300, 300, 3), dtype=np.uint8)
    img[:, :, 2] = 180  # pure red — no green at all
    img[:, :, 0] = 60
    path = _save_temp_image(img)
    try:
        data = _run_inference(path)
        _report("no_leaf: quality",  data["imageQuality"] == "poor")
        _report("no_leaf: label",    data["label"] == "invalid_image")
    finally:
        os.remove(path)


# -----------------------------------------------------------------------
# Test: Existing inference path still works (disease class)
# -----------------------------------------------------------------------
def test_disease_class():
    sample_dir = "datasets/crop_health/test/late_blight"
    if not os.path.isdir(sample_dir):
        _report("disease_class", False, "late_blight test dir not found — skipped")
        return
    files = os.listdir(sample_dir)
    if not files:
        _report("disease_class", False, "No files in late_blight test dir")
        return
    path = os.path.join(sample_dir, files[0])
    data = _run_inference(path)
    _report("disease_class: runs",          data["kind"] == "crop_health")
    _report("disease_class: acceptable",    data["imageQuality"] == "acceptable")
    _report("disease_class: has_label",     data["label"] != "invalid_image")


# =======================================================================
# Run all tests
# =======================================================================
if __name__ == "__main__":
    print("=" * 60)
    print("Phase 5 — Image Quality & Robustness Tests")
    print("=" * 60)

    test_valid_clear_image()
    test_blurry_image()
    test_dark_image()
    test_overexposed_image()
    test_tiny_image()
    test_corrupt_image()
    test_unsupported_format()
    test_missing_image()
    test_no_leaf()
    test_disease_class()

    print("=" * 60)
    print(f"Results: {PASSED} passed, {FAILED} failed out of {PASSED + FAILED}")
    print("=" * 60)
    sys.exit(1 if FAILED else 0)
