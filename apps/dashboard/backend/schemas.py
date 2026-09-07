from pydantic import BaseModel, Field
from typing import Optional, List

class SensorReadingInput(BaseModel):
    deviceId: Optional[str] = "field-node-01"
    zoneId: Optional[str] = "zone-a"
    soilMoisturePct: float = Field(..., ge=0, le=100)
    temperatureC: float
    humidityPct: float = Field(..., ge=0, le=100)
    rainfallMm: Optional[float] = 0.0
    waterLevelPct: Optional[float] = 0.0
    capturedAt: Optional[str] = None

class SensorReadingResponse(BaseModel):
    id: Optional[int] = None
    deviceId: str
    zoneId: str
    soilMoisturePct: float
    temperatureC: float
    humidityPct: float
    rainfallMm: float
    waterLevelPct: float
    capturedAt: str

class VisionResultInput(BaseModel):
    kind: Optional[str] = "crop_health"
    crop: Optional[str] = "tomato"
    label: str
    confidence: float = Field(..., ge=0.0, le=1.0)
    imageQuality: Optional[str] = "acceptable"
    capturedAt: Optional[str] = None

class VisionResultResponse(BaseModel):
    id: Optional[int] = None
    kind: str
    crop: str
    label: str
    confidence: float
    imageQuality: str
    capturedAt: str

class Advisory(BaseModel):
    type: str
    severity: str  # 'info', 'warning', 'critical'
    title: str
    message: str
    action: str

class ActuatorCommandInput(BaseModel):
    actuatorId: Optional[str] = "pump-relay-01"
    action: str  # 'START_IRRIGATION', 'STOP_IRRIGATION', 'TOGGLE'
    requestedBy: Optional[str] = "dashboard-user"

class FarmStateResponse(BaseModel):
    status: str = "ok"
    mode: str = "offline-first-edge"
    reading: SensorReadingResponse
    advisories: List[Advisory]
    relayState: str
    latestVision: Optional[VisionResultResponse] = None
