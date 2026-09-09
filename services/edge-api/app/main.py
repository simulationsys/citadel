import os
import tempfile
from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI, File, HTTPException, Query, Response, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles

from . import db as store
from . import sync
from . import vision
from .advisories import build_advisories
from .schemas import (
    ActuatorCommandInput, FarmStateResponse, IrrigationApprovalInput,
    IrrigationRequestInput, IrrigationRequestResponse, ObservationInput,
    ObservationResponse, ReadingAck, SensorReadingInput, VisionResponse,
)

DEFAULT_ZONE = store.DEFAULT_ZONE
# Mirrors AppConstants.freshThreshold / staleThreshold (app_constants.dart:12-13).
FRESH_SEC, STALE_SEC = 120, 900


@asynccontextmanager
async def lifespan(app: FastAPI):
    store.init_db()
    sync_task = None
    if sync.cloud_url():
        import asyncio
        sync_task = asyncio.create_task(sync.push_loop())
    try:
        yield
    finally:
        if sync_task:
            sync_task.cancel()
            try:
                await sync_task
            except asyncio.CancelledError:
                pass



app = FastAPI(
    title="Citadel Edge API",
    description="Offline-first smart-farming edge service: readings, observations, "
                "advisories, actuator downlink, and the dashboard UI.",
    version="2.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], allow_credentials=True, allow_methods=["*"], allow_headers=["*"],
)


def _freshness(reading: dict | None) -> str:
    """Sensor age, computed server-side. A prompt response carrying hours-old data
    is not fresh data."""
    age = store.age_seconds(reading.get("receivedAt")) if reading else None
    if age is None:
        return "offline"
    return "live" if age <= FRESH_SEC else "stale" if age <= STALE_SEC else "offline"


def _farm_state(zone_id: str, relay_reported: str | None = None) -> dict:
    with store.db() as conn:
        actuator = store.reconcile(conn, zone_id, relay_reported)
        reading = store.get_latest_reading(zone_id, conn=conn)
    observations = store.get_observations(zone_id)
    latest_vision = store.get_latest_vision(zone_id)
    return {
        "status": "ok",
        "mode": "offline-first-edge",
        "zoneId": zone_id,
        "reading": reading,
        "freshness": _freshness(reading),
        "observations": observations,
        "advisories": build_advisories(reading, observations),
        "actuator": store.format_actuator(actuator),
        "pendingIrrigationRequests": store.pending_irrigation_requests(zone_id),
        # Deprecated dashboard fields. relayState is never null: index.html:258
        # calls .toLowerCase() on it unguarded.
        "relayState": actuator["desired_state"] or "OFF",
        "latestVision": latest_vision,
        "_command": store.desired_command(actuator),
    }


@app.get("/health")
def health_check():
    with store.db() as conn:
        actuator = store.reconcile(conn, DEFAULT_ZONE)
        last = conn.execute("SELECT MAX(received_at) FROM readings").fetchone()[0]
    return {
        "status": "ok",
        "service": "citadel-edge-api",
        "mode": "offline-first",
        "database": "sqlite",
        "lastDeviceContact": last,
        "modelStatus": {"cropHealth": vision.status(), "pest": {"available": False}},
        "pendingSyncCount": store.pending_sync_count(),
        "actuatorInSync": store.in_sync(actuator),
    }


@app.get("/v1/zones")
def list_zones():
    return {"zones": store.get_zones()}


@app.get("/v1/farm-state", response_model=FarmStateResponse)
def get_farm_state(zoneId: str = Query(default=DEFAULT_ZONE)):
    # An unknown or not-yet-reporting zone is 200 with reading=null, not 404:
    # "no data yet" is a state, not a missing resource.
    return _farm_state(zoneId)


@app.get("/v1/history")
def get_history(zoneId: str = Query(default=DEFAULT_ZONE), limit: int = 20):
    return {"zoneId": zoneId, "readings": store.get_readings_history(zoneId, limit)}


@app.post("/v1/readings", response_model=ReadingAck, status_code=201)
def record_reading(payload: SensorReadingInput, response: Response):
    data = payload.model_dump(exclude_unset=True)
    reading, duplicate = store.save_reading(data)
    # A replay is 200, never 409 — and it still carries the current command,
    # because the node retried precisely because it lost that command.
    response.status_code = 200 if duplicate else 201
    state = _farm_state(reading["zoneId"], relay_reported=data.get("relayReported"))
    # The relay never turns ON here — only an approval or an explicit override
    # does that. This response merely re-states the standing command.
    return {**state, "reading": reading, "duplicate": duplicate, "command": state["_command"]}


@app.post("/v1/observations", response_model=ObservationResponse, status_code=201)
def record_observation(payload: ObservationInput):
    return store.save_observation(payload.model_dump(exclude_unset=True))


@app.post("/v1/vision-results", response_model=VisionResponse, status_code=201,
          include_in_schema=False, deprecated=True)
def record_vision_result(payload: ObservationInput):
    """Deprecated alias. Sole consumer: the 'Simulate Vision AI Leaf Blight' demo
    button, static/index.html:322."""
    observation = store.save_observation(payload.model_dump(exclude_unset=True))
    return store.format_vision({
        "id": observation["id"], "kind": observation["kind"], "crop": observation["crop"],
        "label": observation["label"], "confidence": observation["confidence"],
        "image_quality": observation["imageQuality"], "captured_at": observation["capturedAt"],
    })


# `def`, not `async def`: a 2-4s subprocess in an async handler blocks the event
# loop and freezes the dashboard's 5s poll. FastAPI runs this in a threadpool.
@app.post("/v1/crop-health")
def analyse_crop_health(zoneId: str = Query(default=DEFAULT_ZONE), image: UploadFile = File(...)):
    suffix = Path(image.filename or "upload.jpg").suffix or ".jpg"
    handle, tmp_path = tempfile.mkstemp(suffix=suffix)
    try:
        with os.fdopen(handle, "wb") as out:
            out.write(image.file.read())
        try:
            result = vision.classify(tmp_path)
        except vision.VisionUnavailable as error:
            raise HTTPException(503, {"code": "vision_unavailable", "message": str(error)})
        except vision.VisionTimeout as error:
            raise HTTPException(504, {"code": "vision_timeout", "message": str(error)})
        except vision.VisionBadOutput as error:
            raise HTTPException(502, {"code": "vision_bad_output", "message": str(error)})
    finally:
        Path(tmp_path).unlink(missing_ok=True)

    observation = None
    if result.get("label") and result.get("label") != "invalid_image":
        observation = store.save_observation({
            "kind": "crop_health", "zoneId": zoneId, "crop": result.get("crop"),
            "label": result["label"], "confidence": float(result.get("confidence", 0.0)),
            "imageQuality": result.get("imageQuality") or result.get("image_quality"),
            "limitation": result.get("limitation"),
        })
    return {"result": result, "observation": observation, "state": _farm_state(zoneId)}


@app.post("/v1/pest/analyze")
def analyse_pest(image: UploadFile = File(...)):
    # Lazy import: pest_inference pulls numpy and PIL at module top, and there is
    # no pest .tflite anywhere, so importing it at module scope would force both
    # into the edge requirements for a path that can only 503.
    # The 503 body mirrors ml/pest-risk/src/api.py:89 exactly, so both services
    # give the app one shape to handle.
    try:
        from citadel_pest_risk.pest_inference import ModelUnavailable, load_default_detector
        load_default_detector()
    except ModuleNotFoundError as error:
        raise HTTPException(503, {
            "code": "model_not_ready",
            "message": f"Pest inference dependencies are not installed on this node ({error})."})
    except Exception as error:  # ModelUnavailable and anything else it raises
        raise HTTPException(503, {"code": "model_not_ready", "message": str(error)})
    # There is no pest .tflite anywhere in the repo; if one ever lands, this is
    # where the analysis goes. Until then the honest answer is 503, not a fake result.
    raise HTTPException(503, {
        "code": "model_not_ready",
        "message": "No pest detection model is installed on this node.",
    })


@app.post("/v1/irrigation/requests", response_model=IrrigationRequestResponse, status_code=201)
def create_irrigation_request(payload: IrrigationRequestInput):
    """Records intent. This is not a pump command — approval is."""
    return store.create_irrigation_request(
        payload.zoneId or DEFAULT_ZONE, payload.requestedBy or "farmer", payload.maxRuntimeSec)


@app.post("/v1/irrigation/requests/{request_id}/approve")
def approve_irrigation_request(request_id: str, payload: IrrigationApprovalInput):
    with store.db() as conn:
        row = store.get_irrigation_request(conn, request_id)
        if row is None:
            raise HTTPException(404, "Irrigation request not found.")
        if row["status"] != "pending":
            raise HTTPException(409, f"Request is already {row['status']}.")
        approved_by = payload.approvedBy or "farmer"
        conn.execute(
            "UPDATE irrigation_requests SET status='approved', approved_by=?, approved_at=?,"
            " max_runtime_sec=COALESCE(?, max_runtime_sec) WHERE id=?",
            (approved_by, store.now_iso(), payload.maxRuntimeSec, request_id))
        # THE ONLY PLACE the pump is turned on, besides the explicit override
        # below. Not in the advisory engine, not on POST /v1/readings. The pump
        # runs because a human said yes.
        actuator = store.set_desired_state(
            conn, row["zone_id"], "ON", approved_by,
            payload.maxRuntimeSec or row["max_runtime_sec"])
        request = store.format_irrigation_request(
            dict(store.get_irrigation_request(conn, request_id)))
    return {"request": request, "actuator": store.format_actuator(actuator),
            "command": store.desired_command(actuator),
            "note": "Approval is recorded. The node acknowledges the physical pump action "
                    "on its next reading."}


@app.post("/v1/irrigation/requests/{request_id}/decline")
def decline_irrigation_request(request_id: str, payload: IrrigationApprovalInput):
    with store.db() as conn:
        row = store.get_irrigation_request(conn, request_id)
        if row is None:
            raise HTTPException(404, "Irrigation request not found.")
        if row["status"] != "pending":
            raise HTTPException(409, f"Request is already {row['status']}.")
        conn.execute(
            "UPDATE irrigation_requests SET status='declined', approved_by=?, approved_at=?"
            " WHERE id=?", (payload.approvedBy or "farmer", store.now_iso(), request_id))
        request = store.format_irrigation_request(
            dict(store.get_irrigation_request(conn, request_id)))
    return {"request": request, "note": "Declined. The pump was not commanded."}


@app.post("/v1/actuator-command")
def trigger_actuator(payload: ActuatorCommandInput):
    """Manual override, always audited. Body contract unchanged, so the
    dashboard's {action:'TOGGLE'} keeps working."""
    zone_id = payload.zoneId or DEFAULT_ZONE
    action = payload.action.upper()
    with store.db() as conn:
        current = store.reconcile(conn, zone_id)
        if action in ("START_IRRIGATION", "ON"):
            new_state = "ON"
        elif action in ("STOP_IRRIGATION", "OFF"):
            new_state = "OFF"
        elif action == "TOGGLE":
            new_state = "OFF" if current["desired_state"] == "ON" else "ON"
        else:
            raise HTTPException(
                400, f"Invalid action '{payload.action}'. "
                     "Use START_IRRIGATION, STOP_IRRIGATION, or TOGGLE.")
        actuator = store.set_desired_state(
            conn, zone_id, new_state, payload.requestedBy or "user", payload.maxRuntimeSec)
    return {
        "status": "success",
        "actuatorId": actuator["actuator_id"],
        "actionExecuted": action,
        "relayState": new_state,
        "updatedAt": actuator["desired_at"],
        "command": store.desired_command(actuator),
    }


# The dashboard is served same-origin, so index.html's
# `API_BASE = window.location.origin` needs no edit.
STATIC_DIR = Path(__file__).resolve().parents[1] / "static"

if STATIC_DIR.is_dir():
    app.mount("/static", StaticFiles(directory=STATIC_DIR), name="static")


@app.get("/", include_in_schema=False)
def serve_dashboard():
    index_path = STATIC_DIR / "index.html"
    if index_path.is_file():
        return FileResponse(index_path)
    return {"message": "Citadel Edge API running. Static dashboard template missing."}
