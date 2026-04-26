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

final riskTimelineProvider =
    FutureProvider.family<RiskTimeline?, String>((ref, waterBodyId) async {
  final dio = ref.watch(dioProvider);

  try {
    final response =
        await dio.get('/api/v1/environmental/risk-timeline/$waterBodyId');
    return RiskTimeline.fromJson(response.data);
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
