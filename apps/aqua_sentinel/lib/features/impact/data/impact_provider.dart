import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/impact_data.dart';

// Replace provider bodies with Copernicus EMS + Sentinel-2/3 + CMEMS API calls.
final waterBodyRiskProvider =
    Provider<List<WaterBodyRiskScore>>((ref) => _mockRiskData);

final impactSummaryProvider = Provider<ImpactSummary>((ref) {
  final scores = ref.watch(waterBodyRiskProvider);
  final atRisk = scores.where((s) => s.riskScore > 60).toList();
  return ImpactSummary(
    watershedsAtRisk: atRisk.length,
    totalPopulationAtRisk: atRisk.fold(0, (sum, s) => sum + s.populationAtRisk),
    totalEconomicImpactEurM:
        atRisk.fold(0.0, (sum, s) => sum + s.economicImpactEurM),
    criticalCount: scores.where((s) => s.tier == RiskTier.critical).length,
    highCount: scores.where((s) => s.tier == RiskTier.high).length,
  );
});

const _mockRiskData = [
  WaterBodyRiskScore(
    waterBodyId: 'inn-river',
    waterBodyName: 'Inn River',
    country: 'Austria',
    riskScore: 35,
    tier: RiskTier.moderate,
    populationAtRisk: 45000,
    economicImpactEurM: 2.8,
    primaryThreat: 'Rising water temperature — 2.8°C above seasonal average',
    dataSource: 'Sentinel-3 SLSTR',
    lastUpdated: 'Apr 25 · 06:00 UTC',
    sectorImpacts: [
      SectorImpact(
        sector: ImpactSector.environment,
        headline: 'Cold-water species under stress',
        detail:
            'Brown trout and grayling populations are stressed by rising temperatures. Reduced glacial melt is the cause.',
        actionRequired: false,
      ),
      SectorImpact(
        sector: ImpactSector.environment,
        headline: 'Whitewater conditions affected',
        detail:
            'Lower water levels are affecting rafting and kayaking routes. Some operators reporting reduced bookings.',
        actionRequired: false,
      ),
    ],
  ),
  WaterBodyRiskScore(
    waterBodyId: 'lake-ohrid',
    waterBodyName: 'Lake Ohrid',
    country: 'N. Macedonia / Albania',
    riskScore: 22,
    tier: RiskTier.low,
    populationAtRisk: 18000,
    economicImpactEurM: 1.2,
    primaryThreat: 'Temperature anomaly — surface 2.5°C above seasonal average',
    dataSource: 'Sentinel-3 SLSTR',
    lastUpdated: 'Apr 25 · 10:00 UTC',
    sectorImpacts: [
      SectorImpact(
        sector: ImpactSector.drinkingWater,
        headline: 'Quality remains excellent',
        detail:
            'All water quality parameters meet or exceed standards. 18,000 residents receive clean drinking water.',
        actionRequired: false,
      ),
      SectorImpact(
        sector: ImpactSector.environment,
        headline: 'Endemic species at risk',
        detail:
            'Rising temperatures may affect Ohrid trout spawning. Monitoring recommended.',
        actionRequired: false,
      ),
    ],
  ),
  WaterBodyRiskScore(
    waterBodyId: 'maritsa-river',
    waterBodyName: 'Maritsa River',
    country: 'Bulgaria',
    riskScore: 78,
    tier: RiskTier.critical,
    populationAtRisk: 180000,
    economicImpactEurM: 15.5,
    primaryThreat: 'Heavy metal contamination — lead 5x above EU limits',
    dataSource: 'Sentinel-2 MSI',
    lastUpdated: 'Apr 24 · 14:00 UTC',
    sectorImpacts: [
      SectorImpact(
        sector: ImpactSector.drinkingWater,
        headline: 'Treatment plants overwhelmed',
        detail:
            'Lead exceeds safe levels at 3 downstream plants. Bottled water being distributed to 45,000 residents.',
        actionRequired: true,
      ),
      SectorImpact(
        sector: ImpactSector.agriculture,
        headline: 'Irrigation water unsafe',
        detail:
            'Farmers advised not to use river water. Crop contamination risk confirmed in affected zone.',
        actionRequired: true,
      ),
      SectorImpact(
        sector: ImpactSector.environment,
        headline: 'Aquatic ecosystem damaged',
        detail:
            'Fish kills confirmed. Heavy metals in sediment will take decades to remediate.',
        actionRequired: false,
      ),
    ],
  ),
  WaterBodyRiskScore(
    waterBodyId: 'glomma-river',
    waterBodyName: 'Glomma River',
    country: 'Norway',
    riskScore: 48,
    tier: RiskTier.moderate,
    populationAtRisk: 85000,
    economicImpactEurM: 3.2,
    primaryThreat:
        'Low dissolved oxygen — 15% below normal due to hydro regulation',
    dataSource: 'Sentinel-3 OLCI',
    lastUpdated: 'Apr 25 · 08:00 UTC',
    sectorImpacts: [
      SectorImpact(
        sector: ImpactSector.environment,
        headline: 'Salmon populations stressed',
        detail:
            'Atlantic salmon and sea trout affected by low oxygen. Spawning success may decline this season.',
        actionRequired: false,
      ),
      SectorImpact(
        sector: ImpactSector.agriculture,
        headline: 'Fishing impacted',
        detail:
            'Commercial and sport fishing catch rates declining. Tourism revenue affected.',
        actionRequired: false,
      ),
    ],
  ),
  WaterBodyRiskScore(
    waterBodyId: 'tisza-river',
    waterBodyName: 'Tisza River',
    country: 'Hungary',
    riskScore: 68,
    tier: RiskTier.high,
    populationAtRisk: 85000,
    economicImpactEurM: 9.8,
    primaryThreat:
        'Flooding and salt contamination — 180 km² flooded, conductivity 4,200 µS/cm',
    dataSource: 'Sentinel-1 SAR',
    lastUpdated: 'Apr 24 · 16:00 UTC',
    sectorImpacts: [
      SectorImpact(
        sector: ImpactSector.agriculture,
        headline: '18,000 ha cropland flooded',
        detail:
            'Significant crop losses expected. Salt contamination may affect soil productivity for years.',
        actionRequired: true,
      ),
      SectorImpact(
        sector: ImpactSector.environment,
        headline: 'Fish kills reported',
        detail:
            'Combined low oxygen and high salinity causing fish mortality along 30 km stretch.',
        actionRequired: false,
      ),
      SectorImpact(
        sector: ImpactSector.drinkingWater,
        headline: 'Water supply at risk',
        detail:
            'High conductivity at drinking water intakes. Monitoring increased at all treatment plants.',
        actionRequired: true,
      ),
    ],
  ),
  WaterBodyRiskScore(
    waterBodyId: 'vistula-river',
    waterBodyName: 'Vistula River',
    country: 'Poland',
    riskScore: 65,
    tier: RiskTier.high,
    populationAtRisk: 35000,
    economicImpactEurM: 7.2,
    primaryThreat:
        'Major flooding — 420 km² inundated, water levels 4.5m above normal',
    dataSource: 'Sentinel-1 SAR',
    lastUpdated: 'Apr 24 · 12:00 UTC',
    sectorImpacts: [
      SectorImpact(
        sector: ImpactSector.agriculture,
        headline: '24,000 ha cropland flooded',
        detail:
            'Significant crop losses in Toruń region. Insurance claims being processed.',
        actionRequired: true,
      ),
      SectorImpact(
        sector: ImpactSector.environment,
        headline: 'Wetland habitat expanded',
        detail:
            'Floodplain receiving beneficial sediment loads. Long-term positive for wetland ecology.',
        actionRequired: false,
      ),
      SectorImpact(
        sector: ImpactSector.drinkingWater,
        headline: 'Nitrate levels rising',
        detail:
            'Agricultural runoff increasing nitrates. Private well users advised to test water.',
        actionRequired: true,
      ),
    ],
  ),
  WaterBodyRiskScore(
    waterBodyId: 'po-river',
    waterBodyName: 'Po River',
    country: 'Italy',
    riskScore: 82,
    tier: RiskTier.critical,
    populationAtRisk: 1200000,
    economicImpactEurM: 45.0,
    primaryThreat:
        'Severe drought — river flow at 15% of average plus industrial pollution',
    dataSource: 'Copernicus C3S / Sentinel-2',
    lastUpdated: 'Apr 25 · 04:00 UTC',
    sectorImpacts: [
      SectorImpact(
        sector: ImpactSector.drinkingWater,
        headline: 'Supply under severe stress',
        detail:
            'Low flow and industrial contamination threaten drinking water for millions in Lombardy.',
        actionRequired: true,
      ),
      SectorImpact(
        sector: ImpactSector.agriculture,
        headline: 'Irrigation severely restricted',
        detail:
            '120,000 ha of farmland facing water cuts. Crop losses mounting. Estimated €35M damage.',
        actionRequired: true,
      ),
      SectorImpact(
        sector: ImpactSector.environment,
        headline: 'Ecological crisis',
        detail:
            'Fish kills, low oxygen, and contamination creating severe ecosystem damage. Years of recovery needed.',
        actionRequired: false,
      ),
    ],
  ),
  WaterBodyRiskScore(
    waterBodyId: 'maas-river',
    waterBodyName: 'Maas River',
    country: 'Netherlands',
    riskScore: 64,
    tier: RiskTier.high,
    populationAtRisk: 95000,
    economicImpactEurM: 11.3,
    primaryThreat:
        'Chemical pollution — PFAS detected at 2.3× guideline limit upstream of Rotterdam intake',
    dataSource: 'Sentinel-2 / RIVM',
    lastUpdated: 'Apr 24 · 22:00 UTC',
    sectorImpacts: [
      SectorImpact(
        sector: ImpactSector.drinkingWater,
        headline: 'Rotterdam intake at risk',
        detail:
            'PFAS levels exceed EFSA health guidelines. Drinking water for 95,000 residents is sourced here. '
            'Enhanced filtration is now active — water is safe to drink but infrastructure costs are rising.',
        actionRequired: true,
      ),
      SectorImpact(
        sector: ImpactSector.agriculture,
        headline: 'Irrigation advisory issued',
        detail:
            'Farmers within 25 km of the intake should avoid using river water for irrigation until contamination is cleared. '
            'PFAS accumulates in crops and soil.',
        actionRequired: true,
      ),
      SectorImpact(
        sector: ImpactSector.environment,
        headline: 'PFAS bioaccumulation risk',
        detail:
            'Fish tissue sampling is underway. Commercial fishing licence holders in the affected stretch have been notified. '
            'Results expected within 5 days.',
        actionRequired: false,
      ),
    ],
  ),
  WaterBodyRiskScore(
    waterBodyId: 'danube-delta',
    waterBodyName: 'Danube Delta',
    country: 'Romania',
    riskScore: 72,
    tier: RiskTier.high,
    populationAtRisk: 42000,
    economicImpactEurM: 8.7,
    primaryThreat:
        'Flash flooding — 340 km² inundated, river levels 2.4 m above normal',
    dataSource: 'Copernicus EMS / Sentinel-1',
    lastUpdated: 'Apr 24 · 18:30 UTC',
    sectorImpacts: [
      SectorImpact(
        sector: ImpactSector.drinkingWater,
        headline: 'Nitrate contamination alert',
        detail:
            'Flooding is mobilising agricultural runoff. Nitrates are at 48 mg/L — 96% of the WHO safe limit. '
            '12,000 residents on private wells are most at risk.',
        actionRequired: true,
      ),
      SectorImpact(
        sector: ImpactSector.agriculture,
        headline: '8,400 ha cropland flooded',
        detail:
            'Soybean and sunflower fields in Tulcea county have been inundated. '
            'Estimated crop loss: €2.1M. Farmers should not use floodwater for irrigation.',
        actionRequired: true,
      ),
      SectorImpact(
        sector: ImpactSector.environment,
        headline: 'UNESCO wetland disrupted',
        detail:
            'Sediment displacement is affecting Pelican breeding grounds in the Ramsar-protected delta zone. '
            'Ecosystem recovery may take 2–3 months.',
        actionRequired: false,
      ),
    ],
  ),
  WaterBodyRiskScore(
    waterBodyId: 'guadalquivir-river',
    waterBodyName: 'Guadalquivir River',
    country: 'Spain',
    riskScore: 75,
    tier: RiskTier.high,
    populationAtRisk: 500000,
    economicImpactEurM: 22.0,
    primaryThreat: 'Severe drought and algal bloom threatening Doñana wetlands',
    dataSource: 'Copernicus C3S / Sentinel-2',
    lastUpdated: 'Apr 25 · 06:30 UTC',
    sectorImpacts: [
      SectorImpact(
        sector: ImpactSector.environment,
        headline: 'Doñana wetlands at critical risk',
        detail:
            'Algal bloom threatens one of Europe\'s most important wetlands. 500,000+ migratory birds dependent on this ecosystem.',
        actionRequired: true,
      ),
      SectorImpact(
        sector: ImpactSector.environment,
        headline: 'Beach advisories affecting tourism',
        detail:
            'Sanlúcar and nearby beaches under swimming advisories during peak tourist season.',
        actionRequired: false,
      ),
      SectorImpact(
        sector: ImpactSector.agriculture,
        headline: 'Irrigation water quality declining',
        detail:
            'High nitrates and turbidity make water unsuitable for many crops. Agricultural losses mounting.',
        actionRequired: true,
      ),
    ],
  ),
];
