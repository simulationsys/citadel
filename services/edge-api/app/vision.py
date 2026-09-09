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

REPO_ROOT = Path(__file__).resolve().parents[3]
VISION_DIR = REPO_ROOT / "ml" / "vision"
SCRIPT = VISION_DIR / "src" / "inference.py"
MODEL = VISION_DIR / "models" / "crop_health_mobilenetv2.tflite"


class VisionUnavailable(RuntimeError):
    """Interpreter, script or model missing — a 503, not a crash."""


class VisionTimeout(RuntimeError):
    """504."""


class VisionBadOutput(RuntimeError):
    """502: the subprocess ran but did not produce parsable JSON."""


def python_path() -> Path:
    override = os.getenv("CITADEL_VISION_PYTHON")
    if override:
        return Path(override)
    venv = VISION_DIR / ".venv"
    return venv / ("Scripts/python.exe" if sys.platform == "win32" else "bin/python")


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
    }


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
    if done.returncode != 0:
        # stderr in the message: everything-is-500 with no detail is what the old
        # Node bridge shipped with.
        raise VisionBadOutput(f"inference exited {done.returncode}: {done.stderr.strip()[-500:]}")
    lines = [line for line in done.stdout.splitlines() if line.strip()]
    try:
        return json.loads(lines[-1])
    except (IndexError, json.JSONDecodeError) as error:
        raise VisionBadOutput(f"inference produced no JSON: {done.stdout.strip()[-500:]}") from error
