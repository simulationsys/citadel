import io
import sys
import unittest
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from src.crop_inference import CropHealthClassifier


class CropQualityTests(unittest.TestCase):
    @staticmethod
    def image_bytes(color, size=(224, 224)):
        output = io.BytesIO()
        Image.new("RGB", size, color).save(output, format="PNG")
        return output.getvalue()

    def classifier_without_model(self):
        return object.__new__(CropHealthClassifier)

    def test_rejects_empty_and_corrupt_images(self):
        classifier = self.classifier_without_model()
        with self.assertRaisesRegex(ValueError, "empty"):
            classifier.analyze_bytes(b"")
        with self.assertRaisesRegex(ValueError, "valid JPEG or PNG"):
            classifier.analyze_bytes(b"not an image")

    def test_rejects_low_resolution_before_inference(self):
        classifier = self.classifier_without_model()
        result = classifier.analyze_bytes(self.image_bytes((30, 150, 30), (100, 100)))
        self.assertEqual(result["label"], "invalid_image")
        self.assertEqual(result["imageQuality"], "invalid")

    def test_rejects_overexposed_image_before_inference(self):
        classifier = self.classifier_without_model()
        result = classifier.analyze_bytes(self.image_bytes((255, 255, 255)))
        self.assertEqual(result["label"], "invalid_image")
        self.assertIn("overexposed", result["limitation"])


if __name__ == "__main__":
    unittest.main()
