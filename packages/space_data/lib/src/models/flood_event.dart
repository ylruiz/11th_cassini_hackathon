import 'package:latlong2/latlong.dart';

enum FloodSeverity { low, medium, high, extreme }

class FloodEvent {
  const FloodEvent({
    required this.id,
    required this.region,
    required this.center,
    required this.severity,
    required this.source,
    required this.detectedAt,
    this.affectedAreaKm2,
  });

  final String id;
  final String region;
  final LatLng center;
  final FloodSeverity severity;
  /// Satellite or service that detected the event (e.g. "Sentinel-1", "Copernicus EMS")
  final String source;
  final DateTime detectedAt;
  final double? affectedAreaKm2;

  factory FloodEvent.fromJson(Map<String, dynamic> json) => FloodEvent(
        id: json['id'] as String,
        region: json['region'] as String,
        center: LatLng(
          (json['latitude'] as num).toDouble(),
          (json['longitude'] as num).toDouble(),
        ),
        severity: FloodSeverity.values.byName(json['severity'] as String),
        source: json['source'] as String,
        detectedAt: DateTime.parse(json['detected_at'] as String),
        affectedAreaKm2: json['affected_area_km2'] != null
            ? (json['affected_area_km2'] as num).toDouble()
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'region': region,
        'latitude': center.latitude,
        'longitude': center.longitude,
        'severity': severity.name,
        'source': source,
        'detected_at': detectedAt.toIso8601String(),
        if (affectedAreaKm2 != null) 'affected_area_km2': affectedAreaKm2,
      };
}
