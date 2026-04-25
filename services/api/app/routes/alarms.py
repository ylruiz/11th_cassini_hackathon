from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from app.models.alarms import (
    Alarm,
    AlarmResponse,
    AlarmCreate,
    AlarmStatus,
    AlarmType,
)
from app.services.alarm_service import alarm_service


router = APIRouter()


@router.get("", response_model=AlarmResponse)
async def get_alarms(
    status: AlarmStatus | None = None,
    type: AlarmType | None = None,
) -> AlarmResponse:
    alarms = alarm_service.get_all()
    if status:
        alarms = [a for a in alarms if a.status == status]
    if type:
        alarms = [a for a in alarms if a.type == type]
    return AlarmResponse(alarms=alarms)


@router.get("/active", response_model=AlarmResponse)
async def get_active_alarms() -> AlarmResponse:
    return AlarmResponse(alarms=alarm_service.get_active())


@router.get("/{alarm_id}", response_model=Alarm)
async def get_alarm(alarm_id: str) -> Alarm:
    alarm = alarm_service.get_by_id(alarm_id)
    if not alarm:
        raise HTTPException(status_code=404, detail="Alarm not found")
    return alarm


@router.post("", response_model=Alarm)
async def create_alarm(data: AlarmCreate) -> Alarm:
    return alarm_service.create(data)


@router.post("/{alarm_id}/acknowledge", response_model=Alarm)
async def acknowledge_alarm(alarm_id: str) -> Alarm:
    alarm = alarm_service.acknowledge(alarm_id)
    if not alarm:
        raise HTTPException(status_code=404, detail="Active alarm not found")
    return alarm


@router.post("/{alarm_id}/resolve", response_model=Alarm)
async def resolve_alarm(alarm_id: str) -> Alarm:
    alarm = alarm_service.resolve(alarm_id)
    if not alarm:
        raise HTTPException(status_code=404, detail="Alarm not found")
    return alarm


class TriggerCheckRequest(BaseModel):
    type: str
    data: dict


class TriggerCheckResponse(BaseModel):
    alarms_triggered: list[Alarm]


@router.post("/trigger", response_model=TriggerCheckResponse)
async def trigger_alarm_check(request: TriggerCheckRequest) -> TriggerCheckResponse:
    from app.routes.water_quality import WaterQualityReading
    from app.routes.floods import FloodEvent
    triggered = []
    
    if request.type == "water_quality":
        reading = WaterQualityReading(**request.data)
        triggered = alarm_service.check_water_quality_reading(reading)
    elif request.type == "flood":
        event = FloodEvent(**request.data)
        triggered = alarm_service.check_flood_event(event)
    
    return TriggerCheckResponse(alarms_triggered=triggered)