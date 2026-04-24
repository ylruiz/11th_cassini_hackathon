import 'package:latlong2/latlong.dart';

class WaterBody {
  const WaterBody({
    required this.id,
    required this.name,
    required this.center,
    required this.areaKm2,
    required this.country,
    this.accessIndex,
  });

  final String id;
  final String name;
  final LatLng center;
  final double areaKm2;
  final String country;
  /// 0–1: fraction of nearby population with safe water access (Copernicus/SDG)
  final double? accessIndex;

  factory WaterBody.fromJson(Map<String, dynamic> json) => WaterBody(
        id: json['id'] as String,
        name: json['name'] as String,
        center: LatLng(
          (json['latitude'] as num).toDouble(),
          (json['longitude'] as num).toDouble(),
        ),
        areaKm2: (json['area_km2'] as num).toDouble(),
        country: json['country'] as String,
        accessIndex: json['access_index'] != null
            ? (json['access_index'] as num).toDouble()
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'latitude': center.latitude,
        'longitude': center.longitude,
        'area_km2': areaKm2,
        'country': country,
        if (accessIndex != null) 'access_index': accessIndex,
      };
}
