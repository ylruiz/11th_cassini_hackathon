from fastapi import APIRouter
from pydantic import BaseModel
from enum import Enum

router = APIRouter()


class Severity(str, Enum):
    low = "low"
    medium = "medium"
    high = "high"
    extreme = "extreme"


class FloodEvent(BaseModel):
    id: str
    region: str
    latitude: float
    longitude: float
    severity: Severity
    source: str
    detected_at: str
    affected_area_km2: float | None = None


class FloodsResponse(BaseModel):
    events: list[FloodEvent]


_SAMPLE_FLOODS: list[FloodEvent] = [
    FloodEvent(
        id="flood-001",
        region="Balkans — Bosnia & Herzegovina",
        latitude=44.20, longitude=17.91,
        severity=Severity.high,
        source="Copernicus EMS / Sentinel-1",
        detected_at="2026-04-24T18:30:00Z",
        affected_area_km2=340,
    ),
    FloodEvent(
        id="flood-002",
        region="Iberian Peninsula — Ebro Basin",
        latitude=41.65, longitude=-0.88,
        severity=Severity.medium,
        source="Copernicus C3S",
        detected_at="2026-04-24T12:00:00Z",
        affected_area_km2=120,
    ),
    FloodEvent(
        id="flood-003",
        region="Northern Italy — Po Valley",
        latitude=44.90, longitude=10.30,
        severity=Severity.low,
        source="Copernicus EMS",
        detected_at="2026-04-23T09:00:00Z",
        affected_area_km2=55,
    ),
]


@router.get("", response_model=FloodsResponse)
async def get_floods(severity: Severity | None = None) -> FloodsResponse:
    events = _SAMPLE_FLOODS
    if severity:
        events = [e for e in events if e.severity == severity]
    return FloodsResponse(events=events)


@router.get("/{event_id}", response_model=FloodEvent)
async def get_flood(event_id: str) -> FloodEvent:
    for event in _SAMPLE_FLOODS:
        if event.id == event_id:
            return event
    from fastapi import HTTPException
    raise HTTPException(status_code=404, detail="Flood event not found")
