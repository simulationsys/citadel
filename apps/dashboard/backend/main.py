import json
import os
import subprocess
import sys
import tempfile
from contextlib import asynccontextmanager
from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse

from .database import (
    init_db, get_latest_reading, save_reading,
    get_latest_vision, save_vision_result,
    get_relay_state, update_relay_state, get_readings_history
)
from .schemas import (
    SensorReadingInput, SensorReadingResponse,
    VisionResultInput, VisionResultResponse,
    ActuatorCommandInput, FarmStateResponse
)
from .advisory_engine import build_advisories

@asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()
    yield

app = FastAPI(
    title="Citadel Edge & Dashboard API",
    description="Offline-first Smart Farming Edge API with SQLite & Dashboard UI",
    version="1.0.0",
    lifespan=lifespan
)

# Enable CORS for local app and dashboard integration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
def health_check():
    return {
        "status": "ok",
        "service": "citadel-edge-dashboard-api",
        "mode": "offline-first",
        "database": "sqlite"
    }

@app.get("/v1/farm-state", response_model=FarmStateResponse)
def get_farm_state():
    reading = get_latest_reading()
    if not reading:
        raise HTTPException(status_code=404, detail="No sensor readings recorded yet.")
    
    latest_vision = get_latest_vision()
    relay_state = get_relay_state()
    advisories = build_advisories(reading, latest_vision)
    
    return {
        "status": "ok",
        "mode": "offline-first-edge",
        "reading": reading,
        "advisories": advisories,
        "relayState": relay_state,
        "latestVision": latest_vision
    }

@app.post("/v1/readings", response_model=FarmStateResponse, status_code=201)
def record_reading(payload: SensorReadingInput):
    saved_reading = save_reading(payload.model_dump(exclude_unset=True))
    latest_vision = get_latest_vision()
    relay_state = get_relay_state()
    advisories = build_advisories(saved_reading, latest_vision)
    
    return {
        "status": "ok",
        "mode": "offline-first-edge",
        "reading": saved_reading,
        "advisories": advisories,
        "relayState": relay_state,
        "latestVision": latest_vision
    }

@app.post("/v1/vision-results", response_model=VisionResultResponse, status_code=201)
def record_vision_result(payload: VisionResultInput):
    saved_vision = save_vision_result(payload.model_dump(exclude_unset=True))
    return saved_vision

# Repo root: apps/dashboard/backend -> apps/dashboard -> apps -> repo root
REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
VISION_INFERENCE_SCRIPT = os.path.join(REPO_ROOT, "ml", "vision", "src", "inference.py")

@app.post("/v1/crop-health")
async def crop_health(request: Request, zoneId: str = "zone-a"):
    """Runs a farmer-submitted leaf photo through the crop-health AI model.

    Accepts raw JPEG bytes (matches the farmer app's HttpFarmStateRepository,
    which POSTs `image/jpeg` bytes directly, not a multipart form).
    """
    image_bytes = await request.body()
    if not image_bytes:
        raise HTTPException(status_code=400, detail="No image bytes in request body.")

    tmp_path = None
    try:
        with tempfile.NamedTemporaryFile(suffix=".jpg", delete=False) as tmp:
            tmp.write(image_bytes)
            tmp_path = tmp.name

        proc = subprocess.run(
            [sys.executable, VISION_INFERENCE_SCRIPT, tmp_path],
            capture_output=True, text=True, timeout=60,
        )

        if proc.returncode != 0:
            # Model/dependency failure (e.g. TF not installed) — degrade
            # gracefully instead of a 500 so the app's scan flow still works.
            result = {
                "kind": "crop_health", "crop": "unknown", "label": "inconclusive",
                "confidence": 0.0, "imageQuality": "poor",
                "limitation": f"Vision inference unavailable: {proc.stderr.strip()[-300:]}",
            }
        else:
            result = json.loads(proc.stdout.strip().splitlines()[-1])
    except (subprocess.TimeoutExpired, json.JSONDecodeError, IndexError) as e:
        result = {
            "kind": "crop_health", "crop": "unknown", "label": "inconclusive",
            "confidence": 0.0, "imageQuality": "poor",
            "limitation": f"Vision inference failed: {e}",
        }
    finally:
        if tmp_path and os.path.exists(tmp_path):
            os.remove(tmp_path)

    # Persist real, successful diagnoses so they show as "latestVision" on
    # the dashboard/farm-state too. Don't persist inconclusive/error results.
    if result.get("label") not in ("inconclusive", "invalid_image"):
        save_vision_result(result)

    return result

@app.post("/v1/actuator-command")
def trigger_actuator(payload: ActuatorCommandInput):
    current_state = get_relay_state()
    action = payload.action.upper()
    
    new_state = current_state
    if action in ["START_IRRIGATION", "ON"]:
        new_state = "ON"
    elif action in ["STOP_IRRIGATION", "OFF"]:
        new_state = "OFF"
    elif action in ["TOGGLE"]:
        new_state = "OFF" if current_state == "ON" else "ON"
    else:
        raise HTTPException(status_code=400, detail=f"Invalid action '{payload.action}'. Use START_IRRIGATION, STOP_IRRIGATION, or TOGGLE.")
        
    result = update_relay_state(new_state, requested_by=payload.requestedBy or "user")
    return {
        "status": "success",
        "actuatorId": payload.actuatorId,
        "actionExecuted": action,
        "relayState": new_state,
        "updatedAt": result["updatedAt"]
    }

@app.get("/v1/history")
def get_history(limit: int = 20):
    return {
        "history": get_readings_history(limit=limit)
    }

# Mount static folder for dashboard UI
STATIC_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "static")

if os.path.exists(STATIC_DIR):
    app.mount("/static", StaticFiles(directory=STATIC_DIR), name="static")

@app.get("/", include_in_schema=False)
def serve_dashboard():
    index_path = os.path.join(STATIC_DIR, "index.html")
    if os.path.exists(index_path):
        return FileResponse(index_path)
    return {"message": "Citadel Edge API running. Static dashboard template coming soon."}
