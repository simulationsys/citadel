"""Crop-health inference: runtime selection, tensor contract, and the boundary
between an infrastructure fault and a legitimate low-confidence result.

No real .tflite is loaded here. A fake interpreter lets every branch run on any
machine, including CI without a TFLite runtime installed.
"""
import json
import os
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

import cv2
import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from src import inference  # noqa: E402


def leaf_image(path, size=(256, 256), green=True, brightness=140):
    """A synthetic image that passes the quality gate (textured + green)."""
    h, w = size
    img = np.zeros((h, w, 3), np.uint8)
    img[:, :, 1] = brightness                      # green channel dominant
    if not green:
        img[:, :] = brightness                     # grey: fails leaf suitability
    noise = np.random.default_rng(0).integers(0, 60, (h, w), dtype=np.uint8)
    img[:, :, 0] = np.clip(img[:, :, 0] + noise, 0, 255)  # texture beats the blur gate
    cv2.imwrite(str(path), img)
    return str(path)


class FakeInterpreter:
    """Minimal stand-in for tflite Interpreter."""

    def __init__(self, model_path=None, softmax=None, in_shape=(1, 224, 224, 3),
                 out_len=5, fail_invoke=False):
        self.model_path = model_path
        self._softmax = softmax if softmax is not None else [0.9, 0.04, 0.03, 0.02, 0.01]
        self._in_shape = in_shape
        self._out_len = out_len
        self._fail_invoke = fail_invoke
        self.allocated = False

    def allocate_tensors(self):
        self.allocated = True

    def get_input_details(self):
        return [{"index": 0, "shape": np.array(self._in_shape), "dtype": np.float32}]

    def get_output_details(self):
        return [{"index": 1, "shape": np.array([1, self._out_len]), "dtype": np.float32}]

    def set_tensor(self, index, data):
        self._input = data

    def invoke(self):
        if self._fail_invoke:
            raise RuntimeError("tensor arena allocation failed")

    def get_tensor(self, index):
        return np.array([self._softmax], dtype=np.float32)


def fake_class(**kwargs):
    return lambda model_path=None: FakeInterpreter(model_path=model_path, **kwargs)


class RuntimeSelectionTests(unittest.TestCase):
    def setUp(self):
        inference.reset_cache()

    def test_prefers_tflite_runtime_and_does_not_import_tensorflow(self):
        stub = mock.MagicMock()
        stub.Interpreter = FakeInterpreter
        with mock.patch.dict(sys.modules, {
            "tflite_runtime": mock.MagicMock(),
            "tflite_runtime.interpreter": stub,
        }):
            with mock.patch.dict(sys.modules, {"tensorflow": None}):
                cls, runtime = inference.load_interpreter_class()
        self.assertEqual(runtime, "tflite_runtime")
        self.assertIs(cls, FakeInterpreter)

    def test_falls_back_to_tensorflow_when_tflite_runtime_absent(self):
        lite = mock.MagicMock()
        lite.Interpreter = FakeInterpreter
        real_import = __import__

        def guard(name, *args, **kwargs):
            if name.startswith("tflite_runtime"):
                raise ImportError("no tflite_runtime")
            return real_import(name, *args, **kwargs)

        with mock.patch("builtins.__import__", side_effect=guard):
            with mock.patch.dict(sys.modules, {"tensorflow": mock.MagicMock(),
                                               "tensorflow.lite": lite}):
                cls, runtime = inference.load_interpreter_class()
        self.assertEqual(runtime, "tensorflow")

    def test_no_runtime_at_all_is_unavailable_not_a_diagnosis(self):
        real_import = __import__

        def guard(name, *args, **kwargs):
            if name.startswith(("tflite_runtime", "tensorflow")):
                raise ImportError(f"no {name}")
            return real_import(name, *args, **kwargs)

        with mock.patch("builtins.__import__", side_effect=guard):
            with self.assertRaises(inference.InferenceUnavailable) as ctx:
                inference.load_interpreter_class()
        self.assertIn("tflite-runtime", str(ctx.exception))


class TensorContractTests(unittest.TestCase):
    def setUp(self):
        inference.reset_cache()
        self.tmp = tempfile.TemporaryDirectory()
        self.model = Path(self.tmp.name) / "model.tflite"
        self.model.write_bytes(b"TFL3-not-a-real-model")

    def tearDown(self):
        self.tmp.cleanup()

    def test_missing_model_is_unavailable(self):
        with self.assertRaises(inference.InferenceUnavailable) as ctx:
            inference.get_interpreter(str(Path(self.tmp.name) / "absent.tflite"))
        self.assertIn("not found", str(ctx.exception))

    def test_unloadable_model_is_unavailable(self):
        def explode(model_path=None):
            raise ValueError("could not parse flatbuffer")
        with mock.patch.object(inference, "load_interpreter_class",
                               return_value=(explode, "tflite_runtime")):
            with self.assertRaises(inference.InferenceUnavailable) as ctx:
                inference.get_interpreter(str(self.model))
        self.assertIn("Failed to load model", str(ctx.exception))

    def test_class_count_mismatch_refuses_to_guess(self):
        with mock.patch.object(inference, "load_interpreter_class",
                               return_value=(fake_class(out_len=3), "tflite_runtime")):
            with self.assertRaises(inference.InferenceUnavailable) as ctx:
                inference.get_interpreter(str(self.model))
        self.assertIn("Refusing to guess", str(ctx.exception))

    def test_wrong_input_shape_is_rejected(self):
        with mock.patch.object(inference, "load_interpreter_class",
                               return_value=(fake_class(in_shape=(1, 128, 128, 3)),
                                             "tflite_runtime")):
            with self.assertRaises(inference.InferenceUnavailable) as ctx:
                inference.get_interpreter(str(self.model))
        self.assertIn("Unexpected input shape", str(ctx.exception))

    def test_interpreter_is_loaded_once_per_process(self):
        maker = mock.MagicMock(side_effect=fake_class())
        with mock.patch.object(inference, "load_interpreter_class",
                               return_value=(maker, "tflite_runtime")):
            first = inference.get_interpreter(str(self.model))
            second = inference.get_interpreter(str(self.model))
        self.assertIs(first["interpreter"], second["interpreter"])
        self.assertEqual(maker.call_count, 1)

    def test_real_shipped_model_metadata_matches_configured_classes(self):
        """The v1.1 sidecar is the authority; CLASSES must not have drifted."""
        sidecar = Path(inference.DEFAULT_MODEL).with_suffix(".json")
        if not sidecar.exists():
            self.skipTest("v1.1 metadata sidecar not present")
        classes = json.loads(sidecar.read_text())["output"]["classes"]
        self.assertEqual(classes, inference.CLASSES)


class QualityGateTests(unittest.TestCase):
    def setUp(self):
        inference.reset_cache()
        self.tmp = tempfile.TemporaryDirectory()

    def tearDown(self):
        self.tmp.cleanup()

    def test_low_resolution_rejected_before_any_runtime_is_touched(self):
        path = leaf_image(Path(self.tmp.name) / "small.png", size=(64, 64))
        with mock.patch.object(inference, "load_interpreter_class",
                               side_effect=AssertionError("runtime must not load")):
            result = inference.classify(path)
        self.assertEqual(result["label"], "invalid_image")
        self.assertEqual(result["imageQuality"], "invalid")

    def test_dark_image_rejected(self):
        path = leaf_image(Path(self.tmp.name) / "dark.png", brightness=5)
        result = inference.classify(path)
        self.assertEqual(result["imageQuality"], "invalid")
        self.assertIn("dark", result["limitation"].lower())

    def test_non_leaf_is_poor_quality(self):
        path = leaf_image(Path(self.tmp.name) / "grey.png", green=False)
        result = inference.classify(path)
        self.assertEqual(result["imageQuality"], "poor")

    def test_missing_file_is_invalid_image(self):
        result = inference.classify(str(Path(self.tmp.name) / "nope.png"))
        self.assertEqual(result["label"], "invalid_image")


class InferenceOutcomeTests(unittest.TestCase):
    def setUp(self):
        inference.reset_cache()
        self.tmp = tempfile.TemporaryDirectory()
        self.model = Path(self.tmp.name) / "model.tflite"
        self.model.write_bytes(b"TFL3")
        self.image = leaf_image(Path(self.tmp.name) / "leaf.png")

    def tearDown(self):
        self.tmp.cleanup()

    def _classify(self, **kwargs):
        with mock.patch.object(inference, "load_interpreter_class",
                               return_value=(fake_class(**kwargs), "tflite_runtime")):
            return inference.classify(self.image, path=str(self.model))

    def test_confident_prediction_uses_metadata_class_order(self):
        result = self._classify(softmax=[0.02, 0.93, 0.02, 0.02, 0.01])
        self.assertEqual(result["label"], "early_blight")
        self.assertAlmostEqual(result["confidence"], 0.93, places=5)
        self.assertIsNone(result["limitation"])

    def test_medium_confidence_carries_a_caveat_but_keeps_the_label(self):
        result = self._classify(softmax=[0.0, 0.0, 0.65, 0.35, 0.0])
        self.assertEqual(result["label"], "late_blight")
        self.assertIn("Moderate confidence", result["limitation"])

    def test_low_confidence_is_inconclusive(self):
        result = self._classify(softmax=[0.30, 0.25, 0.20, 0.15, 0.10])
        self.assertEqual(result["label"], "inconclusive")
        self.assertLess(result["confidence"], inference.LOW_THRESHOLD)

    def test_invoke_failure_is_unavailable_not_inconclusive(self):
        """The distinction the whole contract rests on."""
        with self.assertRaises(inference.InferenceUnavailable):
            self._classify(fail_invoke=True)

    def test_result_reports_which_runtime_ran(self):
        result = self._classify()
        self.assertEqual(result["_runtime"], "tflite_runtime")


class CliContractTests(unittest.TestCase):
    """The exit codes services/edge-api/app/vision.py maps to 503 / 502."""

    def setUp(self):
        inference.reset_cache()
        self.tmp = tempfile.TemporaryDirectory()

    def tearDown(self):
        self.tmp.cleanup()

    def test_unavailable_exits_three_with_structured_error(self):
        image = leaf_image(Path(self.tmp.name) / "leaf.png")
        with mock.patch.object(inference, "get_interpreter",
                               side_effect=inference.InferenceUnavailable("no runtime")):
            with mock.patch("sys.stdout") as out:
                code = inference.main(["inference.py", image])
        self.assertEqual(code, inference.EXIT_UNAVAILABLE)
        written = "".join(c.args[0] for c in out.write.call_args_list if c.args)
        self.assertIn("model_unavailable", written)

    def test_quality_rejection_still_exits_zero(self):
        """A bad photo is a normal answer, not an infrastructure failure."""
        image = leaf_image(Path(self.tmp.name) / "small.png", size=(64, 64))
        with mock.patch("sys.stdout"):
            code = inference.main(["inference.py", image])
        self.assertEqual(code, inference.EXIT_OK)


if __name__ == "__main__":
    unittest.main()
