import 'package:dio/dio.dart';

import '../models/flood_event.dart';
import '../models/water_quality_reading.dart';
import '../models/water_body.dart';

/// Thin client for the AquaSentinel backend, which proxies Copernicus services.
class CopernicusClient {
  CopernicusClient({required this.dio});

  final Dio dio;

  Future<List<WaterBody>> getWaterBodies() async {
    final response = await dio.get<Map<String, dynamic>>('/api/v1/water-bodies');
    final data = response.data!;
    return (data['items'] as List)
        .map((e) => WaterBody.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<FloodEvent>> getActiveFloodEvents() async {
    final response = await dio.get<Map<String, dynamic>>('/api/v1/floods');
    final data = response.data!;
    return (data['events'] as List)
        .map((e) => FloodEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<WaterQualityReading>> getWaterQualityReadings({
    String? stationId,
    DateTime? since,
  }) async {
    final response = await dio.get<Map<String, dynamic>>(
      '/api/v1/water-quality',
      queryParameters: {
        if (stationId != null) 'station_id': stationId,
        if (since != null) 'since': since.toIso8601String(),
      },
    );
    final data = response.data!;
    return (data['readings'] as List)
        .map((e) => WaterQualityReading.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Returns a Copernicus WMS tile URL for a given layer.
  /// Layers: "NDWI" (water index), "TRUE_COLOR", "FALSE_COLOR"
  String wmsLayerUrl({
    required String layer,
    String service = 'WMS',
    String version = '1.3.0',
  }) {
    return 'https://services.sentinel-hub.com/ogc/wms'
        '?SERVICE=$service'
        '&VERSION=$version'
        '&REQUEST=GetMap'
        '&LAYERS=$layer'
        '&STYLES='
        '&FORMAT=image/png'
        '&TRANSPARENT=true'
        '&WIDTH=256&HEIGHT=256'
        '&CRS=EPSG:3857'
        '&BBOX={bbox-epsg-3857}';
  }
}
