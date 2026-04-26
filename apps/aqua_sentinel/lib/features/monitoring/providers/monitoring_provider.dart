import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/environmental_analysis.dart';
import '../../simulator/models/water_issue_scenario.dart';

final dioProvider = Provider<Dio>((ref) {
  final baseUrl = dotenv.get('API_BASE_URL', fallback: 'http://localhost:8000');
  return Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ),
  );
});

final selectedWaterBodyProvider = StateProvider<WaterBodyInfo?>((ref) => null);

final selectedAoiProvider = StateProvider<AoiSelection?>((ref) => null);

enum ViewMode { monitor, simulate }

final viewModeProvider = StateProvider<ViewMode>((ref) => ViewMode.monitor);

final selectedIssueTypeProvider =
    StateProvider<WaterIssueType>((ref) => WaterIssueType.pollution);

final environmentalAnalysisProvider =
    FutureProvider.family<AreaAnalysis, String>((ref, waterBodyId) async {
  final dio = ref.watch(dioProvider);

  try {
    final response =
        await dio.get('/api/v1/environmental/analysis/water-body/$waterBodyId');
    return AreaAnalysis.fromJson(response.data);
  } on DioException catch (e) {
    if (e.response?.statusCode == 404) {
      return AreaAnalysis.empty();
    }
    rethrow;
  }
});

final riskWeightsProvider =
    StateProvider<RiskWeights>((ref) => RiskWeights.defaults);

final riskTimelineProvider =
    FutureProvider.family<RiskTimeline?, String>((ref, waterBodyId) async {
  final dio = ref.watch(dioProvider);
  final weights = ref.watch(riskWeightsProvider);

  final query = weights.isDefault
      ? null
      : <String, dynamic>{
          'weight_snow': weights.snow,
          'weight_surface_water': weights.surfaceWater,
          'weight_vegetation': weights.vegetation,
          'weight_hydrology': weights.hydrology,
        };

  try {
    final response = await dio.get(
      '/api/v1/environmental/risk-timeline/$waterBodyId',
      queryParameters: query,
    );
    return RiskTimeline.fromJson(response.data);
  } on DioException catch (e) {
    if (e.response?.statusCode == 404) {
      return null;
    }
    rethrow;
  }
});

final aoiRiskTimelineProvider =
    FutureProvider.family<RiskTimeline, AoiSelection>((ref, selection) async {
  final dio = ref.watch(dioProvider);
  final weights = ref.watch(riskWeightsProvider);

  try {
    final response = await dio.post(
      '/api/v1/environmental/risk-timeline/aoi',
      data: selection.toRiskTimelineRequest(weights: weights),
    );
    return RiskTimeline.fromJson(response.data);
  } on DioException catch (_) {
    return RiskTimeline.empty();
  }
});

final aoiHistoryProvider =
    FutureProvider.family<AoiHistory?, String>((ref, label) async {
  final dio = ref.watch(dioProvider);

  try {
    final response = await dio.get(
      '/api/v1/environmental/risk-timeline/aoi/history',
      queryParameters: {'label': label},
    );
    return AoiHistory.fromJson(response.data);
  } on DioException catch (e) {
    if (e.response?.statusCode == 404) {
      return null;
    }
    rethrow;
  }
});

final availableWaterBodiesProvider = FutureProvider<List<String>>((ref) async {
  final dio = ref.watch(dioProvider);

  try {
    final response =
        await dio.get('/api/v1/environmental/analysis/water-bodies');
    return List<String>.from(response.data);
  } catch (e) {
    return waterBodies.map((e) => e.id).toList();
  }
});
