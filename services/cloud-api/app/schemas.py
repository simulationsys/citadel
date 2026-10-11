from __future__ import annotations

from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field


class CloudBatchReading(BaseModel):
    eventId: str
    deviceId: str
    zoneId: str
    soilMoisturePct: Optional[float] = None
    temperatureC: Optional[float] = None
    humidityPct: Optional[float] = None
    rainfallMm: Optional[float] = None
    waterLevelPct: Optional[float] = None
    relayReported: Optional[str] = None
    capturedAt: str
    receivedAt: str


class CloudBatchObservation(BaseModel):
    eventId: str
    kind: str
    zoneId: str
    crop: Optional[str] = None
    label: str
    confidence: float
    count: Optional[int] = 1
    imageQuality: Optional[str] = None
    limitation: Optional[str] = None
    readingId: Optional[int] = None
    capturedAt: str
    receivedAt: str


class CloudBatchIrrigationRequest(BaseModel):
    id: str
    zoneId: str
    requestedBy: str
    status: str
    approvedBy: Optional[str] = None
    createdAt: str
    approvedAt: Optional[str] = None
    maxRuntimeSec: Optional[int] = None


class CloudBatchActuatorLog(BaseModel):
    eventId: str
    actuatorId: str
    zoneId: str
    action: str
    status: str
    requestedBy: str
    timestamp: str


class SyncBatchRequest(BaseModel):
    farmId: str = Field(..., description="Unique farm identifier")
    readings: List[CloudBatchReading] = Field(default_factory=list)
    observations: List[CloudBatchObservation] = Field(default_factory=list)
    irrigationRequests: List[CloudBatchIrrigationRequest] = Field(default_factory=list)
    actuatorLogs: List[CloudBatchActuatorLog] = Field(default_factory=list)


class SyncBatchResponse(BaseModel):
    status: str = "ok"
    accepted: List[str] = Field(default_factory=list)
    rejected: List[str] = Field(default_factory=list)

