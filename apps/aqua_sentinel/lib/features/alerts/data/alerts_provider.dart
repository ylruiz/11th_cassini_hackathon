import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/alert_model.dart';

// Replace this provider body with an API call once Copernicus EMS data is available.
final alertsProvider = Provider<List<AlertModel>>((ref) => _mockAlerts);

const _mockAlerts = [
  AlertModel(
    region: 'Balkans — Bosnia & Herzegovina',
    issueType: 'Flash Flood',
    severity: AlertSeverity.high,
    source: 'Copernicus EMS / Sentinel-1',
    timestamp: 'Apr 24 · 18:30 UTC',
    description:
        'Heavy rainfall has triggered flash flooding in river valleys. Low-lying communities should follow local evacuation guidance.',
    latitude: 43.85,
    longitude: 18.35,
  ),
  AlertModel(
    region: 'Iberian Peninsula — Ebro Basin',
    issueType: 'Drought Alert',
    severity: AlertSeverity.medium,
    source: 'Copernicus C3S',
    timestamp: 'Apr 24 · 12:00 UTC',
    description:
        'Reservoir levels have fallen below critical thresholds for the third consecutive month. Water-saving restrictions are in effect.',
    latitude: 41.98,
    longitude: -3.98,
  ),
  AlertModel(
    region: 'Northern Italy — Po Valley',
    issueType: 'Flood Watch',
    severity: AlertSeverity.low,
    source: 'Copernicus EMS',
    timestamp: 'Apr 23 · 09:00 UTC',
    description:
        'Spring snowmelt combined with recent rainfall is raising river levels. Situation is stable but under active monitoring.',
    latitude: 45.48,
    longitude: 10.35,
  ),
];
