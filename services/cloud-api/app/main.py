"""Citadel Cloud API FastAPI service."""
from __future__ import annotations

from contextlib import asynccontextmanager
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

from . import db as store
from .schemas import SyncBatchRequest, SyncBatchResponse


@asynccontextmanager
async def lifespan(app: FastAPI):
    store.init_db()
    yield


app = FastAPI(
    title="Citadel Cloud API",
    description="Multi-farm aggregation and replica service for Citadel.",
    version="1.0.0",
    lifespan=lifespan,
)

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
        "service": "citadel-cloud-api",
        "database": "sqlite",
    }


@app.post("/v1/sync/batch", response_model=SyncBatchResponse)
def sync_batch(payload: SyncBatchRequest):
    data = payload.model_dump()
    accepted, rejected = store.ingest_batch(
        farm_id=data["farmId"],
        readings=data.get("readings", []),
        observations=data.get("observations", []),
        irrigation_requests=data.get("irrigationRequests", []),
        actuator_logs=data.get("actuatorLogs", []),
    )
    return SyncBatchResponse(status="ok", accepted=accepted, rejected=rejected)

