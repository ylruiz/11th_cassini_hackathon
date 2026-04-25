import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/alarm_model.dart';

final _dioProvider = Provider<Dio>((ref) {
  final baseUrl = dotenv.get('API_BASE_URL', fallback: 'http://localhost:8000');
  return Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
  ));
});

final soundEnabledProvider = StateProvider<bool>((ref) => true);

final alarmsProvider =
    AsyncNotifierProvider<AlarmsNotifier, List<Alarm>>(AlarmsNotifier.new);

class AlarmsNotifier extends AsyncNotifier<List<Alarm>> {
  static const _pollInterval = Duration(seconds: 30);
  Timer? _timer;
  Set<String> _knownAlarmIds = {};

  @override
  Future<List<Alarm>> build() async {
    ref.onDispose(() => _timer?.cancel());
    _timer?.cancel();
    _timer = Timer.periodic(_pollInterval, (_) => _refresh());
    return _fetchAlarms();
  }

  Future<void> _refresh() async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchAlarms());
  }

  Future<List<Alarm>> _fetchAlarms() async {
    try {
      final dio = ref.read(_dioProvider);
      final response = await dio.get('/api/v1/alarms');
      final data = AlarmResponse.fromJson(response.data);
      final alarms = data.alarms;

      final newAlarms =
          alarms.where((a) => !_knownAlarmIds.contains(a.id)).toList();
      if (newAlarms.isNotEmpty) {
        _knownAlarmIds = alarms.map((a) => a.id).toSet();
        _newAlarmsStreamController.add(newAlarms);
      }

      return alarms;
    } catch (e) {
      return _mockAlarms;
    }
  }

  Future<void> acknowledge(String alarmId) async {
    try {
      final dio = ref.read(_dioProvider);
      await dio.post('/api/v1/alarms/$alarmId/acknowledge');
      await _refresh();
    } catch (e) {
      _mockAcknowledge(alarmId);
    }
  }

  Future<void> resolve(String alarmId) async {
    try {
      final dio = ref.read(_dioProvider);
      await dio.post('/api/v1/alarms/$alarmId/resolve');
      await _refresh();
    } catch (e) {
      _mockResolve(alarmId);
    }
  }

  void _mockAcknowledge(String alarmId) {
    state.whenData((alarms) {
      final updated = alarms.map((a) {
        if (a.id == alarmId) {
          return a.copyWith(
            status: AlarmStatus.acknowledged,
            acknowledgedAt: DateTime.now().toUtc().toIso8601String(),
          );
        }
        return a;
      }).toList();
      state = AsyncData(updated);
    });
  }

  void _mockResolve(String alarmId) {
    state.whenData((alarms) {
      final updated = alarms.map((a) {
        if (a.id == alarmId) {
          return a.copyWith(
            status: AlarmStatus.resolved,
            resolvedAt: DateTime.now().toUtc().toIso8601String(),
          );
        }
        return a;
      }).toList();
      state = AsyncData(updated);
    });
  }

  static const _mockAlarms = [
    Alarm(
      id: 'alarm-001',
      type: AlarmType.waterQuality,
      severity: AlarmSeverity.high,
      status: AlarmStatus.active,
      location: AlarmLocation(latitude: 45.15, longitude: 29.65),
      triggerType: TriggerType.threshold,
      triggeredBy: 'Sentinel-2 nitrate proxy exceeds 50 mg/L',
      message: 'Nitrate levels near safe limit in Danube Delta',
      sourceDataId: 'ST-002',
      createdAt: '2026-04-24T18:30:00Z',
      municipality: 'Tulcea, Romania',
      populationAtRisk: 12000,
      impactStatement:
          'Residents on private wells are most at risk. Municipal supply not yet affected but close to threshold.',
      recommendedAction:
          'Issue advisory for private well users. Request sampling from local health authority.',
    ),
    Alarm(
      id: 'alarm-002',
      type: AlarmType.flood,
      severity: AlarmSeverity.critical,
      status: AlarmStatus.acknowledged,
      location: AlarmLocation(latitude: 45.20, longitude: 29.80),
      triggerType: TriggerType.threshold,
      triggeredBy: 'Copernicus EMS activation EMSR-724',
      message: 'Critical flood — 340 km² inundated in Danube Delta',
      sourceDataId: 'flood-001',
      createdAt: '2026-04-24T06:00:00Z',
      acknowledgedAt: '2026-04-24T07:00:00Z',
      municipality: 'Tulcea County, Romania',
      populationAtRisk: 42000,
      impactStatement:
          'Farmland, roads, and low-lying homes affected. Crop losses estimated at €2.1M. Flood waters mobilising agricultural nitrates.',
      recommendedAction:
          'Coordinate with regional emergency services. Issue evacuation guidance for flood zones A and B.',
    ),
    Alarm(
      id: 'alarm-003',
      type: AlarmType.anomaly,
      severity: AlarmSeverity.medium,
      status: AlarmStatus.active,
      location: AlarmLocation(latitude: 42.98, longitude: -3.98),
      triggerType: TriggerType.anomaly,
      triggeredBy: 'Sentinel-2 turbidity anomaly z-score > 2.5',
      message: 'Anomalous turbidity in Ebro Reservoir — sediment intrusion',
      sourceDataId: 'ST-003',
      createdAt: '2026-04-24T15:00:00Z',
      municipality: 'Zaragoza Province, Spain',
      populationAtRisk: 280000,
      impactStatement:
          'Reservoir at 38% capacity. Elevated turbidity is compounding the drought emergency — drinking water supply at risk if contamination persists.',
      recommendedAction:
          'Increase monitoring frequency to 6-hour intervals. Brief regional water utility on contingency supply plans.',
    ),
    Alarm(
      id: 'alarm-004',
      type: AlarmType.environmental,
      severity: AlarmSeverity.high,
      status: AlarmStatus.active,
      location: AlarmLocation(latitude: 51.92, longitude: 4.47),
      triggerType: TriggerType.threshold,
      triggeredBy: 'PFAS concentration > EFSA guideline × 2',
      message: 'PFAS contamination detected upstream of Rotterdam water intake',
      sourceDataId: 'maas-001',
      createdAt: '2026-04-24T22:00:00Z',
      municipality: 'Rotterdam Noord, Netherlands',
      populationAtRisk: 95000,
      impactStatement:
          'PFAS "forever chemicals" at 2.3× safe limit. Enhanced filtration is now active — water is safe to drink, but infrastructure costs are rising.',
      recommendedAction:
          'Notify downstream utilities. Commission urgent source investigation. Prepare public communication about filtration measures.',
    ),
    Alarm(
      id: 'alarm-005',
      type: AlarmType.waterQuality,
      severity: AlarmSeverity.low,
      status: AlarmStatus.active,
      location: AlarmLocation(latitude: 46.85, longitude: 17.73),
      triggerType: TriggerType.anomaly,
      triggeredBy: 'Sentinel-3 Chl-a > 30 µg/L for 5 consecutive days',
      message: 'Algae bloom forming on Lake Balaton — southern shore',
      sourceDataId: 'balaton-001',
      createdAt: '2026-04-25T06:00:00Z',
      municipality: 'Keszthely–Siófok, Hungary',
      populationAtRisk: 120000,
      impactStatement:
          'Early-stage bloom covering 12 km² of the southern shore. If Chl-a exceeds 50 µg/L, swimming bans will be required at 4 beaches.',
      recommendedAction:
          'Increase water sampling at public beaches. Prepare public advisory for beach operators.',
    ),
  ];
}

final _newAlarmsStreamController = StreamController<List<Alarm>>.broadcast();
final _newAlarmsStream = _newAlarmsStreamController;

Stream<List<Alarm>> get newAlarmsStream => _newAlarmsStreamController.stream;

final activeAlarmsProvider = Provider<List<Alarm>>((ref) {
  final alarms = ref.watch(alarmsProvider);
  return alarms.when(
    data: (list) => list.where((a) => a.status == AlarmStatus.active).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

final activeAlarmCountProvider = Provider<int>((ref) {
  return ref.watch(activeAlarmsProvider).length;
});

final criticalAlarmCountProvider = Provider<int>((ref) {
  return ref
      .watch(activeAlarmsProvider)
      .where((a) => a.severity == AlarmSeverity.critical)
      .length;
});
