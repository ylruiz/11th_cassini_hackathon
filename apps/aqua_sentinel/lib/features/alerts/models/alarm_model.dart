enum AlarmSeverity { low, medium, high, critical }

enum AlarmType { waterQuality, flood, environmental, anomaly }

enum AlarmStatus { active, acknowledged, resolved }

enum TriggerType { threshold, anomaly }

class AlarmLocation {
  const AlarmLocation({required this.latitude, required this.longitude});
  final double latitude;
  final double longitude;
}

class Alarm {
  const Alarm({
    required this.id,
    required this.type,
    required this.severity,
    required this.status,
    required this.location,
    required this.triggerType,
    required this.triggeredBy,
    required this.message,
    this.sourceDataId,
    required this.createdAt,
    this.acknowledgedAt,
    this.resolvedAt,
    this.municipality,
    this.populationAtRisk,
    this.impactStatement,
    this.recommendedAction,
  });

  final String id;
  final AlarmType type;
  final AlarmSeverity severity;
  final AlarmStatus status;
  final AlarmLocation location;
  final TriggerType triggerType;
  final String triggeredBy;
  final String message;
  final String? sourceDataId;
  final String createdAt;
  final String? acknowledgedAt;
  final String? resolvedAt;

  /// Human-readable location name (municipality / region).
  final String? municipality;

  /// Estimated people at risk from this specific event.
  final int? populationAtRisk;

  /// Plain-language sentence explaining what this alarm means in practice.
  final String? impactStatement;

  /// Suggested action for the operator (government / utility).
  final String? recommendedAction;

  factory Alarm.fromJson(Map<String, dynamic> json) {
    return Alarm(
      id: json['id'] as String,
      type: AlarmType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AlarmType.waterQuality,
      ),
      severity: AlarmSeverity.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => AlarmSeverity.medium,
      ),
      status: AlarmStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => AlarmStatus.active,
      ),
      location: AlarmLocation(
        latitude: (json['location']['latitude'] as num).toDouble(),
        longitude: (json['location']['longitude'] as num).toDouble(),
      ),
      triggerType: TriggerType.values.firstWhere(
        (e) => e.name == json['trigger_type'],
        orElse: () => TriggerType.threshold,
      ),
      triggeredBy: json['triggered_by'] as String,
      message: json['message'] as String,
      sourceDataId: json['source_data_id'] as String?,
      createdAt: json['created_at'] as String,
      acknowledgedAt: json['acknowledged_at'] as String?,
      resolvedAt: json['resolved_at'] as String?,
      municipality: json['municipality'] as String?,
      populationAtRisk: json['population_at_risk'] as int?,
      impactStatement: json['impact_statement'] as String?,
      recommendedAction: json['recommended_action'] as String?,
    );
  }

  Alarm copyWith({
    AlarmStatus? status,
    String? acknowledgedAt,
    String? resolvedAt,
    String? municipality,
    int? populationAtRisk,
    String? impactStatement,
    String? recommendedAction,
  }) {
    return Alarm(
      id: id,
      type: type,
      severity: severity,
      status: status ?? this.status,
      location: location,
      triggerType: triggerType,
      triggeredBy: triggeredBy,
      message: message,
      sourceDataId: sourceDataId,
      createdAt: createdAt,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      municipality: municipality ?? this.municipality,
      populationAtRisk: populationAtRisk ?? this.populationAtRisk,
      impactStatement: impactStatement ?? this.impactStatement,
      recommendedAction: recommendedAction ?? this.recommendedAction,
    );
  }
}

class AlarmResponse {
  const AlarmResponse({required this.alarms});
  final List<Alarm> alarms;

  factory AlarmResponse.fromJson(Map<String, dynamic> json) {
    return AlarmResponse(
      alarms: (json['alarms'] as List<dynamic>)
          .map((e) => Alarm.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
