import 'package:latlong2/latlong.dart';

/// Represents a high-accuracy position fix from Galileo / EGNOS.
class GalileoPosition {
  const GalileoPosition({
    required this.location,
    required this.altitudeM,
    required this.horizontalAccuracyM,
    required this.verticalAccuracyM,
    required this.timestamp,
    this.egnosAugmented = false,
  });

  final LatLng location;
  final double altitudeM;
  /// Horizontal accuracy in metres (typical Galileo: <1 m, EGNOS: <3 m)
  final double horizontalAccuracyM;
  final double verticalAccuracyM;
  final DateTime timestamp;
  /// True when the fix has been augmented by EGNOS SBAS corrections
  final bool egnosAugmented;

  bool get isHighAccuracy => horizontalAccuracyM <= 1.0;

  factory GalileoPosition.fromJson(Map<String, dynamic> json) =>
      GalileoPosition(
        location: LatLng(
          (json['latitude'] as num).toDouble(),
          (json['longitude'] as num).toDouble(),
        ),
        altitudeM: (json['altitude_m'] as num).toDouble(),
        horizontalAccuracyM:
            (json['horizontal_accuracy_m'] as num).toDouble(),
        verticalAccuracyM: (json['vertical_accuracy_m'] as num).toDouble(),
        timestamp: DateTime.parse(json['timestamp'] as String),
        egnosAugmented: json['egnos_augmented'] as bool? ?? false,
      );
}
