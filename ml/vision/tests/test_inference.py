import subprocess
import json
import os
import tempfile

def test_inference_valid_image():
    # Since we can't guarantee where the test is run from, we'll try to find a sample image
    # Assuming tests are run from ml/vision
    sample_img = "datasets/crop_health/test/healthy/06040967-7b02-43b5-a3fc-4490a9a7ded6___RS_HL 0508.JPG"
    
    if not os.path.exists(sample_img):
        print("Warning: Sample image not found. Skipping valid image test.")
        return

    result = subprocess.run([".venv\\Scripts\\python.exe", "-m", "src.inference", sample_img], capture_output=True, text=True)
    assert result.returncode == 0
    
    # stdout may contain TF logs if not suppressed, parse the last line
    output = result.stdout.strip().split('\n')[-1]
    data = json.loads(output)
    
    assert data["kind"] == "crop_health"
    assert data["crop"] == "tomato"
    assert "label" in data
    assert data["confidence"] > 0.0

def test_inference_invalid_image():
    with tempfile.NamedTemporaryFile(suffix=".txt", delete=False) as f:
        f.write(b"This is not an image")
        f.close()
        try:
            result = subprocess.run([".venv\\Scripts\\python.exe", "-m", "src.inference", f.name], capture_output=True, text=True)
            assert result.returncode == 0
            
            output = result.stdout.strip().split('\n')[-1]
            data = json.loads(output)
            
            assert data["kind"] == "crop_health"
            assert data["label"] == "invalid_image"
            assert data["imageQuality"] == "invalid"
            assert data["confidence"] == 0.0
        finally:
            os.remove(f.name)

def test_inference_missing_image():
    result = subprocess.run([".venv\\Scripts\\python.exe", "-m", "src.inference", "does_not_exist.jpg"], capture_output=True, text=True)
    assert result.returncode == 0
    
    output = result.stdout.strip().split('\n')[-1]
    data = json.loads(output)
    
    assert data["label"] == "invalid_image"

if __name__ == "__main__":
    test_inference_valid_image()
    test_inference_invalid_image()
    test_inference_missing_image()
    print("All inference tests passed!")
