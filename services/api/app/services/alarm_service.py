from app.models.alarms import (
    Alarm,
    AlarmThreshold,
    AlarmCreate,
    AlarmType,
    AlarmSeverity,
    AlarmStatus,
    TriggerType,
    AlarmLocation,
)
from app.routes.water_quality import WaterQualityReading
from app.routes.floods import FloodEvent


class AlarmService:
    def __init__(self):
        self._alarms: list[Alarm] = []
        self._id_counter = 1

    def get_all(self) -> list[Alarm]:
        return self._alarms.copy()

    def get_by_id(self, alarm_id: str) -> Alarm | None:
        for alarm in self._alarms:
            if alarm.id == alarm_id:
                return alarm
        return None

    def get_active(self) -> list[Alarm]:
        return [a for a in self._alarms if a.status == AlarmStatus.active]

    def create(self, data: AlarmCreate) -> Alarm:
        alarm_id = f"alarm-{self._id_counter:03d}"
        self._id_counter += 1
        alarm = Alarm(
            id=alarm_id,
            type=data.type,
            severity=data.severity,
            status=AlarmStatus.active,
            location=data.location,
            trigger_type=data.trigger_type,
            triggered_by=data.triggered_by,
            message=data.message,
            source_data_id=data.source_data_id,
            created_at=self._now_iso(),
        )
        self._alarms.append(alarm)
        return alarm

    def acknowledge(self, alarm_id: str) -> Alarm | None:
        alarm = self.get_by_id(alarm_id)
        if alarm and alarm.status == AlarmStatus.active:
            alarm.status = AlarmStatus.acknowledged
            alarm.acknowledged_at = self._now_iso()
            return alarm
        return None

    def resolve(self, alarm_id: str) -> Alarm | None:
        alarm = self.get_by_id(alarm_id)
        if alarm and alarm.status != AlarmStatus.resolved:
            alarm.status = AlarmStatus.resolved
            alarm.resolved_at = self._now_iso()
            return alarm
        return None

    def check_water_quality_reading(self, reading: WaterQualityReading) -> list[Alarm]:
        triggered = []
        reading_dict = reading.model_dump()
        
        for param, thresholds in self._get_thresholds().items():
            if param in reading_dict and reading_dict[param] is not None:
                value = reading_dict[param]
                for threshold in thresholds:
                    if self._check_threshold(value, threshold.operator, threshold.value):
                        alarm = self.create(AlarmCreate(
                            type=AlarmType.water_quality,
                            severity=threshold.severity,
                            location=AlarmLocation(
                                latitude=reading.latitude,
                                longitude=reading.longitude,
                            ),
                            trigger_type=TriggerType.threshold,
                            triggered_by=f"{param} {threshold.operator} {threshold.value}",
                            message=self._build_wq_message(param, value, threshold),
                            source_data_id=reading.station_id,
                        ))
                        triggered.append(alarm)
        
        return triggered

    def check_flood_event(self, event: FloodEvent) -> list[Alarm]:
        triggered = []
        
        if event.severity == "extreme":
            alarm = self.create(AlarmCreate(
                type=AlarmType.flood,
                severity=AlarmSeverity.critical,
                location=AlarmLocation(
                    latitude=event.latitude,
                    longitude=event.longitude,
                ),
                trigger_type=TriggerType.threshold,
                triggered_by=f"flood-severity:{event.severity}",
                message=f"Extreme flood event detected in {event.region} — immediate response required",
                source_data_id=event.id,
            ))
            triggered.append(alarm)
        elif event.severity == "high":
            alarm = self.create(AlarmCreate(
                type=AlarmType.flood,
                severity=AlarmSeverity.high,
                location=AlarmLocation(
                    latitude=event.latitude,
                    longitude=event.longitude,
                ),
                trigger_type=TriggerType.threshold,
                triggered_by=f"flood-severity:{event.severity}",
                message=f"High severity flood event detected in {event.region}",
                source_data_id=event.id,
            ))
            triggered.append(alarm)
        
        return triggered

    def _check_threshold(self, value: float, operator: str, threshold: float) -> bool:
        if operator == "gt":
            return value > threshold
        elif operator == "lt":
            return value < threshold
        elif operator == "gte":
            return value >= threshold
        elif operator == "lte":
            return value <= threshold
        elif operator == "eq":
            return value == threshold
        return False

    def _build_wq_message(self, param: str, value: float, threshold: AlarmThreshold) -> str:
        param_labels = {
            "ph": "pH",
            "turbidity_ntu": "turbidity",
            "nitrates_mg_l": "nitrates",
            "phosphates_mg_l": "phosphates",
            "dissolved_oxygen_mg_l": "dissolved oxygen",
        }
        label = param_labels.get(param, param)
        return f"{label} level {'exceeded' if threshold.operator == 'gt' else 'below'} safe threshold: {value} (limit: {threshold.value})"

    def _now_iso(self) -> str:
        from datetime import datetime, timezone
        return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

    def _get_thresholds(self) -> dict[str, list[AlarmThreshold]]:
        from app.models.alarms import _THRESHOLDS
        return _THRESHOLDS


alarm_service = AlarmService()