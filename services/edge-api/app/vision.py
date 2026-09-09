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
import subprocess
import sys
from pathlib import Path

TIMEOUT_SEC = 30

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
    return {
        "available": interpreter.is_file() and script.is_file() and model.is_file(),
        "interpreter": interpreter.is_file(),
        "script": script.is_file(),
        "model": model.is_file(),
        "modelPath": model.name,
        # find_spec, not import: naming the runtime must not cost a TensorFlow
        # import on a 1 GB Pi just to answer /health.
        "runtime": _runtime_name(),
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
