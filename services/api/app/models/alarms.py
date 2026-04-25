from pydantic import BaseModel
from enum import Enum
from datetime import datetime, timezone


class AlarmType(str, Enum):
    water_quality = "water_quality"
    flood = "flood"
    environmental = "environmental"
    anomaly = "anomaly"


class AlarmStatus(str, Enum):
    active = "active"
    acknowledged = "acknowledged"
    resolved = "resolved"


class AlarmSeverity(str, Enum):
    low = "low"
    medium = "medium"
    high = "high"
    critical = "critical"


class TriggerType(str, Enum):
    threshold = "threshold"
    anomaly = "anomaly"


class AlarmLocation(BaseModel):
    latitude: float
    longitude: float


class Alarm(BaseModel):
    id: str
    type: AlarmType
    severity: AlarmSeverity
    status: AlarmStatus
    location: AlarmLocation
    trigger_type: TriggerType
    triggered_by: str
    message: str
    source_data_id: str | None = None
    created_at: str
    acknowledged_at: str | None = None
    resolved_at: str | None = None


class AlarmResponse(BaseModel):
    alarms: list[Alarm]


class AlarmCreate(BaseModel):
    type: AlarmType
    severity: AlarmSeverity
    location: AlarmLocation
    trigger_type: TriggerType
    triggered_by: str
    message: str
    source_data_id: str | None = None


class AlarmThreshold(BaseModel):
    parameter: str
    operator: str
    value: float
    severity: AlarmSeverity


_THRESHOLDS: dict[str, list[AlarmThreshold]] = {
    "ph": [
        AlarmThreshold(parameter="ph", operator="lt", value=6.0, severity=AlarmSeverity.high),
        AlarmThreshold(parameter="ph", operator="gt", value=9.0, severity=AlarmSeverity.high),
        AlarmThreshold(parameter="ph", operator="lt", value=5.0, severity=AlarmSeverity.critical),
        AlarmThreshold(parameter="ph", operator="gt", value=10.0, severity=AlarmSeverity.critical),
    ],
    "turbidity_ntu": [
        AlarmThreshold(parameter="turbidity_ntu", operator="gt", value=10.0, severity=AlarmSeverity.high),
        AlarmThreshold(parameter="turbidity_ntu", operator="gt", value=50.0, severity=AlarmSeverity.critical),
    ],
    "nitrates_mg_l": [
        AlarmThreshold(parameter="nitrates_mg_l", operator="gt", value=50.0, severity=AlarmSeverity.high),
        AlarmThreshold(parameter="nitrates_mg_l", operator="gt", value=100.0, severity=AlarmSeverity.critical),
    ],
    "phosphates_mg_l": [
        AlarmThreshold(parameter="phosphates_mg_l", operator="gt", value=0.5, severity=AlarmSeverity.high),
        AlarmThreshold(parameter="phosphates_mg_l", operator="gt", value=1.0, severity=AlarmSeverity.critical),
    ],
    "dissolved_oxygen_mg_l": [
        AlarmThreshold(parameter="dissolved_oxygen_mg_l", operator="lt", value=4.0, severity=AlarmSeverity.high),
        AlarmThreshold(parameter="dissolved_oxygen_mg_l", operator="lt", value=2.0, severity=AlarmSeverity.critical),
    ],
}

_ALARMS: list[Alarm] = [
    Alarm(
        id="alarm-001",
        type=AlarmType.water_quality,
        severity=AlarmSeverity.high,
        status=AlarmStatus.active,
        location=AlarmLocation(latitude=45.15, longitude=29.65),
        trigger_type=TriggerType.threshold,
        triggered_by="nitrates_mg_l > 50.0",
        message="Nitrate levels exceeded safe threshold in Danube Delta station ST-002",
        source_data_id="ST-002",
        created_at="2026-04-24T18:30:00Z",
    ),
    Alarm(
        id="alarm-002",
        type=AlarmType.flood,
        severity=AlarmSeverity.critical,
        status=AlarmStatus.acknowledged,
        location=AlarmLocation(latitude=45.20, longitude=29.80),
        trigger_type=TriggerType.threshold,
        triggered_by="flood-severity:critical",
        message="Critical flood event detected in Danube Delta — 340 km² affected",
        source_data_id="flood-001",
        created_at="2026-04-24T06:00:00Z",
        acknowledged_at="2026-04-24T07:00:00Z",
    ),
    Alarm(
        id="alarm-003",
        type=AlarmType.water_quality,
        severity=AlarmSeverity.medium,
        status=AlarmStatus.active,
        location=AlarmLocation(latitude=42.98, longitude=-3.98),
        trigger_type=TriggerType.anomaly,
        triggered_by="turbidity_z_score > 2.5",
        message="Anomalous turbidity pattern detected in Ebro Reservoir — possible sediment intrusion",
        source_data_id="ST-003",
        created_at="2026-04-24T15:00:00Z",
    ),
]