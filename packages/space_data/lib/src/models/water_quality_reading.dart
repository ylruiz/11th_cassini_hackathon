import 'package:latlong2/latlong.dart';

enum QualityStatus { good, acceptable, poor, critical }

class WaterQualityReading {
  const WaterQualityReading({
    required this.stationId,
    required this.location,
    required this.measuredAt,
    required this.ph,
    required this.turbidityNtu,
    required this.nitratesMgL,
    this.phosphatesMgL,
    this.dissolvedOxygenMgL,
    this.conductivityUsCm,
  });

  final String stationId;
  final LatLng location;
  final DateTime measuredAt;
  final double ph;
  final double turbidityNtu;
  final double nitratesMgL;
  final double? phosphatesMgL;
  final double? dissolvedOxygenMgL;
  final double? conductivityUsCm;

  QualityStatus get status {
    if (ph < 6.0 || ph > 9.0) return QualityStatus.critical;
    if (nitratesMgL > 50) return QualityStatus.poor;
    if (turbidityNtu > 10) return QualityStatus.acceptable;
    return QualityStatus.good;
  }

  factory WaterQualityReading.fromJson(Map<String, dynamic> json) =>
      WaterQualityReading(
        stationId: json['station_id'] as String,
        location: LatLng(
          (json['latitude'] as num).toDouble(),
          (json['longitude'] as num).toDouble(),
        ),
        measuredAt: DateTime.parse(json['measured_at'] as String),
        ph: (json['ph'] as num).toDouble(),
        turbidityNtu: (json['turbidity_ntu'] as num).toDouble(),
        nitratesMgL: (json['nitrates_mg_l'] as num).toDouble(),
        phosphatesMgL: json['phosphates_mg_l'] != null
            ? (json['phosphates_mg_l'] as num).toDouble()
            : null,
        dissolvedOxygenMgL: json['dissolved_oxygen_mg_l'] != null
            ? (json['dissolved_oxygen_mg_l'] as num).toDouble()
            : null,
        conductivityUsCm: json['conductivity_us_cm'] != null
            ? (json['conductivity_us_cm'] as num).toDouble()
            : null,
      );
}
