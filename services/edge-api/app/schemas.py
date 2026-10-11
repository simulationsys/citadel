from __future__ import annotations

from typing import List, Literal, Optional, get_args

from pydantic import BaseModel, Field

from .advisories import ADVISORY_TYPES

# A bare `str` publishes {"type":"string"} in openapi.json, constraining nothing.
AdvisoryType = Literal["flood", "irrigation", "heat", "disease_risk", "pest"]
# Tripwire: the vocabulary is owned by risk_engine; this is only a mirror.
assert set(get_args(AdvisoryType)) == set(ADVISORY_TYPES), "advisory vocabulary drifted"

Severity = Literal["info", "warning", "critical"]


class SensorReadingInput(BaseModel):
    """Every sensor optional: an ESP32 with no thermometer must not 422, and
    `{"waterLevelPct":82,"rainfallMm":32}` (docs/demo.md:8) must work."""
    eventId: Optional[str] = None          # stable across device retries
    deviceId: Optional[str] = "field-node-01"
    zoneId: Optional[str] = "zone-a"
    soilMoisturePct: Optional[float] = Field(default=None, ge=0, le=100)
    temperatureC: Optional[float] = None
    humidityPct: Optional[float] = Field(default=None, ge=0, le=100)
    rainfallMm: Optional[float] = Field(default=None, ge=0)
    waterLevelPct: Optional[float] = Field(default=None, ge=0, le=100)
    relayReported: Optional[str] = None    # the node's ack of its own relay
    capturedAt: Optional[str] = None


class ReadingResponse(BaseModel):
    id: Optional[int] = None
    eventId: Optional[str] = None
    deviceId: str
    zoneId: str
    soilMoisturePct: Optional[float] = None
    temperatureC: Optional[float] = None
    humidityPct: Optional[float] = None
    rainfallMm: Optional[float] = None
    waterLevelPct: Optional[float] = None
    relayReported: Optional[str] = None
    capturedAt: str
    receivedAt: Optional[str] = None


class ObservationInput(BaseModel):
    eventId: Optional[str] = None
    kind: Literal["crop_health", "pest"] = "crop_health"
    zoneId: Optional[str] = "zone-a"
    crop: Optional[str] = "tomato"
    label: str
    confidence: float = Field(..., ge=0.0, le=1.0)
    count: Optional[int] = 1
    imageQuality: Optional[str] = "acceptable"
    limitation: Optional[str] = None
    capturedAt: Optional[str] = None


class ObservationResponse(BaseModel):
    id: Optional[int] = None
    eventId: Optional[str] = None
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
    receivedAt: Optional[str] = None


class VisionResponse(BaseModel):
    """Deprecated shape kept for static/index.html:262-264."""
    id: Optional[int] = None
    kind: str
    crop: str
    label: str
    confidence: float
    imageQuality: str
    capturedAt: str


class Advisory(BaseModel):
    type: AdvisoryType
    severity: Severity
    title: str
    message: str
    action: str
    evidence: dict = {}


class ActuatorResponse(BaseModel):
    actuatorId: str
    zoneId: str
    desiredState: str
    reportedState: Optional[str] = None
    desiredAt: str
    reportedAt: Optional[str] = None
    maxRuntimeSec: Optional[int] = None
    inSync: bool


class RelayCommand(BaseModel):
    actuatorId: str
    relayState: str
    maxRuntimeSec: int


class ActuatorCommandInput(BaseModel):
    actuatorId: Optional[str] = "pump-relay-01"
    action: str  # START_IRRIGATION | STOP_IRRIGATION | ON | OFF | TOGGLE
    zoneId: Optional[str] = "zone-a"
    requestedBy: Optional[str] = "dashboard-user"
    maxRuntimeSec: Optional[int] = None


class IrrigationRequestInput(BaseModel):
    zoneId: Optional[str] = "zone-a"
    requestedBy: Optional[str] = "farmer"
    maxRuntimeSec: Optional[int] = None


class IrrigationApprovalInput(BaseModel):
    approvedBy: Optional[str] = "farmer"
    maxRuntimeSec: Optional[int] = None


class IrrigationRequestResponse(BaseModel):
    id: str
    zoneId: str
    requestedBy: str
    status: str
    approvedBy: Optional[str] = None
    createdAt: str
    approvedAt: Optional[str] = None
    maxRuntimeSec: Optional[int] = None


class FarmStateResponse(BaseModel):
    status: str = "ok"
    mode: str = "offline-first-edge"
    zoneId: str
    # None on cold start. index.html:239 reads reading.capturedAt unguarded, so a
    # null throws inside the page's own try and renders "Edge Node Offline" —
    # identical to the 404 this used to return, with no edits to the page.
    reading: Optional[ReadingResponse] = None
    freshness: str = "offline"
    observations: List[ObservationResponse] = []
    advisories: List[Advisory] = []
    actuator: ActuatorResponse
    pendingIrrigationRequests: List[IrrigationRequestResponse] = []
    # Deprecated, dashboard-only. Sole consumers: index.html:258 (unguarded
    # .toLowerCase(), so never null) and index.html:261-264.
    relayState: str = "OFF"
    latestVision: Optional[VisionResponse] = None


class ReadingAck(FarmStateResponse):
    """POST /v1/readings: the farm state plus the downlink the node came for."""
    duplicate: bool = False
    command: RelayCommand


class AssistantQuestion(BaseModel):
    question: str = Field(..., min_length=2, max_length=500)
    zoneId: str = Field(default="zone-a", min_length=1, max_length=100)
    language: Literal["English", "Hindi", "Haryanvi", "Punjabi"] = "English"
