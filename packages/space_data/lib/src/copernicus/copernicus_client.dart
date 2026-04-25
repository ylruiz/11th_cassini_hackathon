import 'package:dio/dio.dart';

import '../models/flood_event.dart';
import '../models/water_quality_reading.dart';
import '../models/water_body.dart';
import '../galileo/galileo_position.dart';

/// Thin client for the AquaSentinel backend, which proxies Copernicus services.
class CopernicusClient {
  CopernicusClient({required this.dio});

  final Dio dio;

  Future<List<WaterBody>> getWaterBodies() async {
    final response =
        await dio.get<Map<String, dynamic>>('/api/v1/water-bodies');
    final data = response.data!;
    return (data['items'] as List)
        .map((e) => WaterBody.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<WaterBody>> getWaterBodiesAccurate() async {
    final response =
        await dio.get<Map<String, dynamic>>('/api/v1/water-bodies/accurate');
    final data = response.data!;
    return (data['items'] as List)
        .map((e) => WaterBody.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SnowCoverData> getSnowCover(String riverId) async {
    final response = await dio
        .get<Map<String, dynamic>>('/api/v1/water-bodies/snow/$riverId');
    final data = response.data!;
    return SnowCoverData.fromJson(data);
  }

  Future<List<WaterQualityObs>> getWaterQualityObservations() async {
    final response = await dio
        .get<Map<String, dynamic>>('/api/v1/water-bodies/observations');
    final data = response.data as List;
    return data
        .map((e) => WaterQualityObs.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<RiverForecast>> getRiverForecasts({String? riverId}) async {
    final response = await dio.get<Map<String, dynamic>>(
      '/api/v1/water-bodies/forecasts',
      queryParameters: {
        if (riverId != null) 'river_id': riverId,
      },
    );
    final data = response.data as List;
    return data
        .map((e) => RiverForecast.fromJson(e as Map<String, dynamic>))
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

  /// Generate a demonstration Galileo high-accuracy position for a water body.
  /// In production, this would come from Galileo HAS receiver.
  GalileoPosition getGalileoDemoPosition(WaterBody body) {
    final accuracy =
        body.id.contains('danube') || body.id.contains('ohrid') ? 0.8 : 1.2;
    return GalileoPosition(
      location: body.center,
      altitudeM: 120.0,
      horizontalAccuracyM: accuracy,
      verticalAccuracyM: accuracy * 1.5,
      timestamp: DateTime.now(),
      egnosAugmented: accuracy < 1.0,
    );
  }
}

class SnowCoverData {
  final String riverId;
  final double snowCoverPercent;
  final DateTime lastUpdated;
  final String source;

  SnowCoverData({
    required this.riverId,
    required this.snowCoverPercent,
    required this.lastUpdated,
    required this.source,
  });

  factory SnowCoverData.fromJson(Map<String, dynamic> json) => SnowCoverData(
        riverId: json['river_id'] as String,
        snowCoverPercent: (json['snow_cover_percent'] as num).toDouble(),
        lastUpdated: DateTime.parse(json['last_updated'] as String),
        source: json['source'] as String,
      );
}

class WaterQualityObs {
  final String riverId;
  final double? chlorophyllMgM3;
  final double? suspendedSedimentMgL;
  final double? waterTemperatureC;
  final DateTime lastUpdated;
  final String source;

  WaterQualityObs({
    required this.riverId,
    this.chlorophyllMgM3,
    this.suspendedSedimentMgL,
    this.waterTemperatureC,
    required this.lastUpdated,
    required this.source,
  });

  factory WaterQualityObs.fromJson(Map<String, dynamic> json) =>
      WaterQualityObs(
        riverId: json['river_id'] as String,
        chlorophyllMgM3: (json['chlorophyll_mg_m3'] as num?)?.toDouble(),
        suspendedSedimentMgL:
            (json['suspended_sediment_mg_l'] as num?)?.toDouble(),
        waterTemperatureC: (json['water_temperature_c'] as num?)?.toDouble(),
        lastUpdated: DateTime.parse(json['last_updated'] as String),
        source: json['source'] as String,
      );
}

class RiverForecast {
  final String riverId;
  final double dischargeM3S;
  final DateTime forecastDate;
  final int leadDays;
  final String model;

  RiverForecast({
    required this.riverId,
    required this.dischargeM3S,
    required this.forecastDate,
    required this.leadDays,
    required this.model,
  });

  factory RiverForecast.fromJson(Map<String, dynamic> json) => RiverForecast(
        riverId: json['river_id'] as String,
        dischargeM3S: (json['discharge_m3_s'] as num).toDouble(),
        forecastDate: DateTime.parse(json['forecast_date'] as String),
        leadDays: json['lead_days'] as int,
        model: json['model'] as String,
      );
}
