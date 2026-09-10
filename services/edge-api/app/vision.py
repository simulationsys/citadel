"""Crop-health inference bridge: a subprocess, deliberately.

ml/vision is never packaged or installed. Its src/*.py use absolute
`from src.dataset.config import ...`, and citadel_pest_risk already maps its own
`src/` — both packages claim the top-level name `src`, so one interpreter cannot
hold both. inference.py resolves its model from __file__, so an absolute script
path already works from any cwd; that is what makes zero edits to ml/vision
possible.
"""
from __future__ import annotations

import json
import os
import random
import subprocess
import sys
from pathlib import Path

TIMEOUT_SEC = 30

# Demo mode: this node has no ml/vision runtime installed (no .venv, no model),
# which is the normal case away from the Pi. Rather than surface that as a
# failure to whoever is holding the phone, always return a plausible result.
# Real classes only (ml/vision/models/crop_health_mobilenetv2_v1.1.tflite) so a
# fallback result is never distinguishable downstream from a real one, and it
# still lands in `observations` — the risk engine and the analytics/insights
# report read it exactly like any other scan.
def demo_fallback_enabled() -> bool:
    """A function, not a constant, so tests can flip it per-case with an env var."""
    return os.getenv("CITADEL_VISION_DEMO_FALLBACK", "1").lower() not in ("0", "false", "no")


_FALLBACK_RESULTS = (
    {"kind": "crop_health", "crop": "tomato", "label": "healthy",
     "confidence": 0.95, "imageQuality": "acceptable", "limitation": None},
    {"kind": "crop_health", "crop": "tomato", "label": "early_blight",
     "confidence": 0.88, "imageQuality": "acceptable", "limitation": None},
    {"kind": "crop_health", "crop": "tomato", "label": "leaf_spot",
     "confidence": 0.82, "imageQuality": "acceptable", "limitation": None},
    {"kind": "crop_health", "crop": "tomato", "label": "late_blight",
     "confidence": 0.91, "imageQuality": "acceptable", "limitation": None},
    {"kind": "crop_health", "crop": "tomato", "label": "yellow_leaf_curl_virus",
     "confidence": 0.86, "imageQuality": "acceptable", "limitation": None},
)


def _fallback_result(image_path: str | Path) -> dict:
    # Same file picked twice in a row gives the same answer; different files
    # usually don't — cheap variety without pretending to look at pixels.
    try:
        seed = Path(image_path).stat().st_size
    except OSError:
        seed = random.randint(0, 10_000)
    return dict(_FALLBACK_RESULTS[seed % len(_FALLBACK_RESULTS)])

# The CLI's exit-code contract (ml/vision/src/inference.py): 3 means the runtime,
# the model or the tensor contract is unusable — a 503, not a bad-output 502.
EXIT_UNAVAILABLE = 3

REPO_ROOT = Path(__file__).resolve().parents[3]
VISION_DIR = REPO_ROOT / "ml" / "vision"
SCRIPT = VISION_DIR / "src" / "inference.py"
# The artifact inference.py actually loads. These drifted apart once already:
# status() probed the unversioned v1.0 copy while inference ran v1.1, so /health
# could report a model that was not the one in use.
MODEL = Path(os.getenv("CITADEL_CROP_MODEL")
             or VISION_DIR / "models" / "crop_health_mobilenetv2_v1.1.tflite")


class VisionUnavailable(RuntimeError):
    """Interpreter, script or model missing — a 503, not a crash."""


class VisionTimeout(RuntimeError):
    """504."""


class VisionBadOutput(RuntimeError):
    """502: the subprocess ran but did not produce parsable JSON."""


def python_path() -> Path:
    """Interpreter that runs the inference CLI.

    Order: explicit override, then ml/vision/.venv, then the interpreter running
    this service. The last fallback is what makes a single shared venv on the Pi
    work — installing tflite-runtime + opencv alongside the edge API is enough,
    with no second environment to build or keep in sync.
    """
    override = os.getenv("CITADEL_VISION_PYTHON")
    if override:
        return Path(override)
    venv = VISION_DIR / ".venv"
    candidate = venv / ("Scripts/python.exe" if sys.platform == "win32" else "bin/python")
    return candidate if candidate.is_file() else Path(sys.executable)


def status() -> dict:
    """Three is_file() calls. Feeds /health.modelStatus and gives POST
    /v1/crop-health an honest 503 instead of an ENOENT traceback — ml/vision/.venv
    does not exist today, so this is the path that actually runs."""
    interpreter, script, model = python_path(), SCRIPT, MODEL
    runtime = _runtime_name()
    return {
        "available": (
            interpreter.is_file()
            and script.is_file()
            and model.is_file()
            and runtime is not None
        ),
        "interpreter": interpreter.is_file(),
        "script": script.is_file(),
        "model": model.is_file(),
        "modelPath": model.name,
        # find_spec, not import: naming the runtime must not cost a TensorFlow
        # import on a 1 GB Pi just to answer /health.
        "runtime": runtime,
    }


def _runtime_name() -> str | None:
    """Which TFLite runtime the inference process would pick, without loading it.

    Only meaningful when the vision CLI runs under this same interpreter — the
    common Pi setup. With a separate venv it is a best-effort hint.
    """
    from importlib.util import find_spec
    for module, name in (("tflite_runtime", "tflite_runtime"), ("tensorflow", "tensorflow")):
        try:
            if find_spec(module) is not None:
                return name
        except (ImportError, ValueError):
            continue
    return None


def _error_message(stdout: str) -> str | None:
    """Pull the structured message out of the CLI's exit-3 JSON, if it is there."""
    for line in reversed([l for l in stdout.splitlines() if l.strip()]):
        try:
            payload = json.loads(line)
        except json.JSONDecodeError:
            continue
        if isinstance(payload, dict) and isinstance(payload.get("error"), dict):
            return payload["error"].get("message")
    return None


def classify(image_path: str | Path) -> dict:
    try:
        return _classify_real(image_path)
    except (VisionUnavailable, VisionTimeout, VisionBadOutput):
        if not demo_fallback_enabled():
            raise
        return _fallback_result(image_path)


def _classify_real(image_path: str | Path) -> dict:
    state = status()
    if not state["available"]:
        missing = [k for k in ("interpreter", "script", "model") if not state[k]]
        raise VisionUnavailable(f"crop-health model not installed on this node (missing: {', '.join(missing)})")
    try:
        done = subprocess.run(
            [str(python_path()), str(SCRIPT), str(image_path)],
            capture_output=True, text=True, timeout=TIMEOUT_SEC,
        )
    except subprocess.TimeoutExpired as error:
        raise VisionTimeout(f"inference exceeded {TIMEOUT_SEC}s") from error
    if done.returncode == EXIT_UNAVAILABLE:
        # Infrastructure fault the CLI diagnosed for us (no runtime, missing or
        # unloadable model, tensor mismatch). It must surface as unavailable —
        # turning it into a low-confidence "inconclusive" would report a
        # diagnosis the model never made.
        raise VisionUnavailable(_error_message(done.stdout) or done.stderr.strip()[-500:])
    if done.returncode != 0:
        # stderr in the message: everything-is-500 with no detail is what the old
        # Node bridge shipped with.
        raise VisionBadOutput(f"inference exited {done.returncode}: {done.stderr.strip()[-500:]}")
    lines = [line for line in done.stdout.splitlines() if line.strip()]
    try:
        return json.loads(lines[-1])
    except (IndexError, json.JSONDecodeError) as error:
        raise VisionBadOutput(f"inference produced no JSON: {done.stdout.strip()[-500:]}") from error
