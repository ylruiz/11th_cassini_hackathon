from datetime import datetime, timezone
from fastapi import APIRouter, Query
from pydantic import BaseModel

router = APIRouter()


class WaterQualityReading(BaseModel):
    station_id: str
    latitude: float
    longitude: float
    measured_at: str
    ph: float
    turbidity_ntu: float
    nitrates_mg_l: float
    phosphates_mg_l: float | None = None
    dissolved_oxygen_mg_l: float | None = None
    conductivity_us_cm: float | None = None


class WaterQualityResponse(BaseModel):
    readings: list[WaterQualityReading]


_SAMPLE_READINGS: list[WaterQualityReading] = [
    WaterQualityReading(
        station_id="ST-001", latitude=46.85, longitude=17.73,
        measured_at="2026-04-24T18:00:00Z",
        ph=7.2, turbidity_ntu=2.1, nitrates_mg_l=32.0,
        phosphates_mg_l=0.12, dissolved_oxygen_mg_l=8.5,
    ),
    WaterQualityReading(
        station_id="ST-002", latitude=45.15, longitude=29.65,
        measured_at="2026-04-24T18:00:00Z",
        ph=6.8, turbidity_ntu=8.4, nitrates_mg_l=48.0,
        phosphates_mg_l=0.87, dissolved_oxygen_mg_l=6.2,
    ),
    WaterQualityReading(
        station_id="ST-003", latitude=42.98, longitude=-3.98,
        measured_at="2026-04-24T18:00:00Z",
        ph=7.5, turbidity_ntu=1.2, nitrates_mg_l=18.0,
        phosphates_mg_l=0.05, dissolved_oxygen_mg_l=9.1,
    ),
]


@router.get("", response_model=WaterQualityResponse)
async def get_water_quality(
    station_id: str | None = Query(None),
    since: str | None = Query(None),
) -> WaterQualityResponse:
    readings = _SAMPLE_READINGS
    if station_id:
        readings = [r for r in readings if r.station_id == station_id]
    return WaterQualityResponse(readings=readings)
