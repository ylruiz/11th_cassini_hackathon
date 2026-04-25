import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/environmental_analysis.dart';

final snowCoverDioProvider = Provider<Dio>((ref) {
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

final snowCoverProvider = FutureProvider<List<SnowArea>>((ref) async {
  final dio = ref.watch(snowCoverDioProvider);

  try {
    final response = await dio.get('/api/v1/environmental/snow-cover');
    final areas = (response.data['snow_areas'] as List)
        .map((e) => SnowArea.fromJson(e))
        .toList();
    return areas;
  } on DioException catch (e) {
    if (e.response?.statusCode == 404) {
      return snowAreas;
    }
    rethrow;
  }
});

final selectedSnowAreaProvider = StateProvider<SnowArea?>((ref) => null);

final snowCoverForRiverProvider =
    FutureProvider.family<List<SnowArea>, String>((ref, riverId) async {
  final snowAreasAsync = ref.watch(snowCoverProvider);

  return snowAreasAsync.when(
    data: (areas) => areas.where((s) => s.feedsRiver == riverId).toList(),
    loading: () => [],
    error: (_, __) => snowAreas.where((s) => s.feedsRiver == riverId).toList(),
  );
});

final activeSnowMeltZonesProvider = Provider<List<SnowArea>>((ref) {
  final snowAreasAsync = ref.watch(snowCoverProvider);

  return snowAreasAsync.when(
    data: (areas) => areas
        .where((s) => s.meltRate == MeltRate.fast || s.coveragePct > 50)
        .toList(),
    loading: () => [],
    error: (_, __) => snowAreas
        .where((s) => s.meltRate == MeltRate.fast || s.coveragePct > 50)
        .toList(),
  );
});
