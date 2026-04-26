from pydantic import BaseModel
from datetime import datetime


class SatelliteIndicator(BaseModel):
    label: str
    value: str
    unit: str
    status: str  # good, warning, danger
    description: str
    trend_label: str | None = None
    source: str


class SatelliteHealthEvent(BaseModel):
    location: str
    description: str
    status: str
    affected_population: str | None = None
    recommended_action: str | None = None


class SatelliteHealthImpact(BaseModel):
    sector_name: str
    headline: str
    detail: str
    status: str
    action_required: bool = False


class SatelliteHealthData(BaseModel):
    water_body_id: str
    water_body_name: str
    overall_status: str
    overall_status_label: str
    month_delta_label: str
    last_updated: str
    data_source: str
    indicators: list[SatelliteIndicator]
    events: list[SatelliteHealthEvent]
    sector_impacts: list[SatelliteHealthImpact]
    trend_label: str
    trend_spots: list[tuple[float, float]]
