"""Local FastAPI surface for the pest/risk intelligence service."""
from __future__ import annotations

import base64
from functools import lru_cache

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

from .pest_inference import ModelUnavailable, load_default_detector
from .profiles import PROFILES, get_profile
from .risk_engine import evaluate
from .schemas import PestObservation, SensorReading

app = FastAPI(title="Citadel Pest & Risk Intelligence", version="0.1.0")


class ReadingPayload(BaseModel):
    deviceId: str = Field(min_length=1)
    zoneId: str = "zone-a"
    soilMoisturePct: float = Field(ge=0, le=100)
    temperatureC: float
    humidityPct: float = Field(ge=0, le=100)
    rainfallMm: float = Field(default=0, ge=0)
    waterLevelPct: float = Field(default=0, ge=0, le=100)


class PestPayload(BaseModel):
    label: str = Field(min_length=1)
    confidence: float = Field(ge=0, le=1)
    count: int = Field(default=1, ge=0)


class RiskRequest(BaseModel):
    reading: ReadingPayload
    pests: list[PestPayload] = Field(default_factory=list)
    profile: str = "tomato-demo"


class ImageRequest(BaseModel):
    imageBase64: str = Field(min_length=1, description="Base64-encoded JPEG/PNG bytes; omit data-URI prefix.")


class FarmStateRequest(RiskRequest, ImageRequest):
    pass


def evaluate_request(request: RiskRequest) -> dict:
    try:
        reading = SensorReading.from_dict(request.reading.model_dump())
        pests = [PestObservation.from_dict(item.model_dump()) for item in request.pests]
        profile = get_profile(request.profile)
    except ValueError as error:
        raise HTTPException(status_code=422, detail=str(error)) from error
    return {"profile": profile.name, "reading": request.reading.model_dump(), "pests": [item.__dict__ for item in pests], "advisories": [item.as_api_dict() for item in evaluate(reading, pests, profile)]}


@lru_cache(maxsize=1)
def detector():
    return load_default_detector()


@app.get("/health")
def health() -> dict:
    try:
        detector()
        model = "ready"
    except ModelUnavailable:
        model = "not_ready"
    return {"status": "ok", "service": "citadel-pest-risk", "model": model, "profiles": list(PROFILES)}


@app.get("/v1/profiles")
def profiles() -> dict:
    return {name: profile.__dict__ for name, profile in PROFILES.items()}


@app.post("/v1/risk/evaluate")
def evaluate_risk(request: RiskRequest) -> dict:
    return evaluate_request(request)


@app.post("/v1/pest/analyze")
def analyze_pest(request: ImageRequest) -> dict:
    try:
        image_bytes = base64.b64decode(request.imageBase64, validate=True)
        observations = detector().analyze_bytes(image_bytes)
    except ModelUnavailable as error:
        raise HTTPException(status_code=503, detail={"code": "model_not_ready", "message": str(error)}) from error
    except (ValueError, OSError) as error:
        raise HTTPException(status_code=422, detail={"code": "invalid_image", "message": str(error)}) from error
    return {"observations": [item.__dict__ for item in observations]}


@app.post("/v1/farm-state")
def farm_state(request: FarmStateRequest) -> dict:
    risk = evaluate_request(request)
    try:
        image_bytes = base64.b64decode(request.imageBase64, validate=True)
        observations = detector().analyze_bytes(image_bytes)
    except ModelUnavailable as error:
        raise HTTPException(status_code=503, detail={"code": "model_not_ready", "message": str(error)}) from error
    risk["pests"] = [item.__dict__ for item in observations]
    reading = SensorReading.from_dict(request.reading.model_dump())
    risk["advisories"] = [item.as_api_dict() for item in evaluate(reading, observations, get_profile(request.profile))]
    return risk
