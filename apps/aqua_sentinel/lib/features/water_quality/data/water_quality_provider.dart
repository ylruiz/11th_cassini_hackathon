import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/water_quality_data.dart';

// Replace this provider body with Copernicus / Sentinel-2 API data once available.
final waterQualityProvider = Provider<WaterQualityData>((ref) => _mockData);

const _mockData = WaterQualityData(
  indicators: [
    WaterIndicator(
      label: 'pH Level',
      value: '7.2',
      status: IndicatorStatus.good,
      plainDescription: 'Neutral — safe for drinking and aquatic life.',
    ),
    WaterIndicator(
      label: 'Turbidity',
      value: '2.1 NTU',
      status: IndicatorStatus.good,
      plainDescription: 'Clear water — very low sediment or particles.',
    ),
    WaterIndicator(
      label: 'Nitrates',
      value: '48 mg/L',
      status: IndicatorStatus.warning,
      plainDescription: 'Above safe limit. Likely from nearby farm runoff.',
    ),
  ],
  pollutionEvents: [
    WaterPollutionEvent(
      location: 'Rhine Basin',
      description: 'Elevated phosphorus — upstream industrial discharge detected.',
      status: IndicatorStatus.warning,
    ),
    WaterPollutionEvent(
      location: 'Danube Delta',
      description: 'Agricultural runoff — nitrates and pesticide traces found.',
      status: IndicatorStatus.danger,
    ),
    WaterPollutionEvent(
      location: 'Baltic Sea',
      description: 'All indicators within safe limits — no action needed.',
      status: IndicatorStatus.good,
    ),
  ],
  trendLabel: 'Nitrate level over the last 30 days (mg/L)',
  trendSpots: [
    (0, 40),
    (5, 42),
    (10, 45),
    (15, 48),
    (20, 47),
    (25, 50),
    (30, 48),
  ],
);
