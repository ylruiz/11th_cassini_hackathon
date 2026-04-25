import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/water_quality_data.dart';

// Replace provider bodies with Copernicus Sentinel-2/3 + CMEMS API calls per water body.
final selectedQualityBodyProvider =
    StateProvider<String>((ref) => 'guadalquivir-river');

final waterQualityProvider =
    Provider.family<WaterQualityData, String>((ref, waterBodyId) {
  return _mockByBody[waterBodyId] ?? _mockByBody['inn-river']!;
});

final _mockByBody = <String, WaterQualityData>{
  'inn-river': WaterQualityData(
    overallStatusLabel:
        'Water quality is CAUTION — elevated water temperature due to reduced glacial flow',
    monthDeltaLabel: 'Temperature up +2.8°C vs seasonal average · Sentinel-3',
    indicators: const [
      WaterIndicator(
        label: 'pH Level',
        value: '7.9',
        status: IndicatorStatus.good,
        plainDescription:
            'Slightly alkaline. Normal for Alpine rivers with limestone geology.',
        trendLabel: 'Stable',
      ),
      WaterIndicator(
        label: 'Water Clarity',
        value: '2.1 NTU',
        status: IndicatorStatus.good,
        plainDescription:
            'Excellent clarity — low suspended particles. Mountain snowmelt provides clean water.',
        affectedGroups: 'Recreational users, drinking water providers',
      ),
      WaterIndicator(
        label: 'Nitrates',
        value: '8 mg/L',
        status: IndicatorStatus.good,
        plainDescription:
            'Very low. Limited agriculture in the high Alpine catchment area.',
        affectedGroups: 'Drinking water consumers',
      ),
      WaterIndicator(
        label: 'Water Temperature',
        value: '14.2°C',
        status: IndicatorStatus.warning,
        plainDescription:
            '2.8°C above seasonal average. Reduced glacial melt is warming the river.',
        affectedGroups: 'Trout and grayling populations',
        trendLabel: 'Up +2.8°C — glaciers retreat reducing cold water inputs',
      ),
      WaterIndicator(
        label: 'Dissolved Oxygen',
        value: '9.2 mg/L',
        status: IndicatorStatus.good,
        plainDescription:
            'High oxygenation due to fast flow and high altitude. Excellent for cold-water species.',
        affectedGroups: 'Fish populations',
      ),
    ],
    pollutionEvents: const [
      WaterPollutionEvent(
        location: 'Innsbruck Industrial Zone — km 312',
        description:
            'Sediment plume from construction activity. Turbidity 4x normal but within acceptable limits.',
        status: IndicatorStatus.warning,
        affectedPopulation: 'Downstream water users',
        recommendedAction:
            'Monitor construction site erosion controls. No immediate public health risk.',
      ),
    ],
    trendLabel: 'Water temperature (°C) over the last 30 days',
    trendSpots: const [
      (0, 11.4),
      (5, 11.8),
      (10, 12.2),
      (15, 12.8),
      (20, 13.4),
      (25, 13.9),
      (30, 14.2),
    ],
    sectorImpacts: const [
      WaterQualitySectorImpact(
        sectorName: 'Drinking Water',
        headline: 'Quality remains excellent',
        detail:
            'High-altitude source water requires minimal treatment. Alpine catchment provides consistently good quality.',
        status: IndicatorStatus.good,
        actionRequired: false,
      ),
      WaterQualitySectorImpact(
        sectorName: 'Tourism & Recreation',
        headline: 'Whitewater conditions affected',
        detail:
            'Reduced glacial melt is lowering water levels. Some rafting and kayaking routes may be affected.',
        status: IndicatorStatus.warning,
        actionRequired: false,
      ),
      WaterQualitySectorImpact(
        sectorName: 'Environment',
        headline: 'Cold-water species under stress',
        detail:
            'Rising temperatures stress brown trout and grayling. Spawning success may decline if warming continues.',
        status: IndicatorStatus.warning,
        actionRequired: false,
      ),
    ],
  ),
  'danube-delta': WaterQualityData(
    overallStatusLabel:
        'Water quality is UNSAFE — nitrate contamination near safe limit, flooding active',
    monthDeltaLabel: 'Nitrates up +18% vs last month · Copernicus EMS',
    indicators: const [
      WaterIndicator(
        label: 'pH Level',
        value: '6.9',
        status: IndicatorStatus.good,
        plainDescription:
            'Slightly acidic but within the acceptable drinking water range.',
        trendLabel: 'Stable',
      ),
      WaterIndicator(
        label: 'Water Clarity',
        value: '12.4 NTU',
        status: IndicatorStatus.warning,
        plainDescription:
            'Elevated sediment load from flooding. Water appears brown and is not safe for direct use.',
        affectedGroups: 'Fishing communities, rural water users',
        trendLabel:
            'Up sharply — flooding carrying sediment from upstream fields',
      ),
      WaterIndicator(
        label: 'Nitrates',
        value: '48 mg/L',
        status: IndicatorStatus.warning,
        plainDescription:
            'At 96% of the WHO safe limit of 50 mg/L. Flooding is washing fertilisers from farm fields into the water.',
        affectedGroups:
            'Private well users, infants and pregnant women most at risk',
        trendLabel: 'Up +18% over 30 days — rising with flood waters',
      ),
      WaterIndicator(
        label: 'Dissolved Oxygen',
        value: '5.2 mg/L',
        status: IndicatorStatus.warning,
        plainDescription:
            'Stress level for fish. Organic matter carried by floods is decomposing and consuming oxygen.',
        affectedGroups: 'Fish populations, commercial fisheries',
        trendLabel: 'Down -22% — worsening as flood debris decomposes',
      ),
    ],
    pollutionEvents: const [
      WaterPollutionEvent(
        location: 'Tulcea Monitoring Station ST-002',
        description:
            'Nitrate levels at 96% of the safe limit. Agricultural runoff from flooded fields is the primary source.',
        status: IndicatorStatus.warning,
        affectedPopulation: '12,000 residents on private wells most at risk',
        recommendedAction:
            'Issue advisory for private well users. Do not use well water for drinking, cooking, or infant formula until levels drop below 25 mg/L.',
      ),
      WaterPollutionEvent(
        location: 'Sulina Channel — km 64',
        description:
            'Extreme turbidity from flood-carried sediment. Water is brown and unsuitable for any direct use.',
        status: IndicatorStatus.danger,
        affectedPopulation: 'Fishing communities along 40 km of channel',
        recommendedAction:
            'Suspend commercial fishing in this stretch. Monitor daily until turbidity returns below 5 NTU.',
      ),
    ],
    trendLabel: 'Nitrates over the last 30 days (mg/L)',
    trendSpots: const [
      (0, 30),
      (5, 32),
      (10, 35),
      (15, 38),
      (20, 44),
      (25, 47),
      (30, 48),
    ],
    sectorImpacts: const [
      WaterQualitySectorImpact(
        sectorName: 'Drinking Water',
        headline: 'Nitrate contamination alert',
        detail: 'Nitrates are approaching the 50 mg/L WHO limit. '
            '12,000 residents relying on private wells are most at risk — especially infants and pregnant women. '
            'Municipal supply is currently treated and safe.',
        status: IndicatorStatus.danger,
        actionRequired: true,
      ),
      WaterQualitySectorImpact(
        sectorName: 'Agriculture',
        headline: '8,400 ha of cropland flooded',
        detail:
            'Soybean and sunflower fields in Tulcea county have been inundated. '
            'Estimated crop loss: €2.1M. Farmers should not use floodwater for irrigation.',
        status: IndicatorStatus.danger,
        actionRequired: true,
      ),
      WaterQualitySectorImpact(
        sectorName: 'Environment',
        headline: 'UNESCO wetland at risk',
        detail:
            'Sediment displacement is disturbing Pelican breeding grounds in the Ramsar-protected delta zone. '
            'Ecosystem recovery is expected to take 2–3 months after flood waters recede.',
        status: IndicatorStatus.warning,
        actionRequired: false,
      ),
    ],
  ),
  'lake-ohrid': WaterQualityData(
    overallStatusLabel:
        'Water quality is SAFE — all indicators within normal limits',
    monthDeltaLabel: 'No significant change vs last month · Sentinel-2',
    indicators: const [
      WaterIndicator(
        label: 'pH Level',
        value: '7.4',
        status: IndicatorStatus.good,
        plainDescription:
            'Ideal neutral range. Excellent for drinking, swimming, and the endemic species that live here.',
        trendLabel: 'Stable — consistent over 6 months',
      ),
      WaterIndicator(
        label: 'Water Clarity',
        value: '1.1 NTU',
        status: IndicatorStatus.good,
        plainDescription:
            'Exceptional clarity — one of Europe\'s cleanest lakes. Sediment levels are near zero.',
        affectedGroups: 'Tourism, drinking water consumers',
      ),
      WaterIndicator(
        label: 'Nitrates',
        value: '5.2 mg/L',
        status: IndicatorStatus.good,
        plainDescription:
            'Very low — minimal agricultural impact on this lake. Well within all guidelines.',
        trendLabel: 'Stable',
      ),
      WaterIndicator(
        label: 'Phosphates',
        value: '0.02 mg/L',
        status: IndicatorStatus.good,
        plainDescription:
            'Trace levels only. No eutrophication risk. The lake\'s natural filtration system is functioning well.',
        affectedGroups: 'Aquatic ecosystem',
      ),
    ],
    pollutionEvents: const [],
    trendLabel: 'pH stability over the last 30 days',
    trendSpots: const [
      (0, 7.3),
      (5, 7.4),
      (10, 7.4),
      (15, 7.4),
      (20, 7.5),
      (25, 7.4),
      (30, 7.4),
    ],
    sectorImpacts: const [
      WaterQualitySectorImpact(
        sectorName: 'Drinking Water',
        headline: 'Excellent quality',
        detail: 'All parameters meet and exceed WHO drinking water standards. '
            'The lake provides clean drinking water to over 18,000 residents without the need for heavy chemical treatment.',
        status: IndicatorStatus.good,
        actionRequired: false,
      ),
      WaterQualitySectorImpact(
        sectorName: 'Environment',
        headline: 'Endemic species thriving',
        detail:
            'Lake Ohrid is home to over 200 endemic species, including the Ohrid trout. '
            'Satellite water clarity and temperature data suggest the ecosystem is in good health.',
        status: IndicatorStatus.good,
        actionRequired: false,
      ),
    ],
  ),
  'guadalquivir-river': WaterQualityData(
    overallStatusLabel:
        'Water quality is CRITICAL — severe drought and agricultural runoff',
    monthDeltaLabel: 'River flow at 18% of average · Copernicus C3S',
    indicators: const [
      WaterIndicator(
        label: 'pH Level',
        value: '8.1',
        status: IndicatorStatus.warning,
        plainDescription:
            'Slightly alkaline due to evaporation concentrating minerals.',
        trendLabel: 'Rising with drought intensification',
      ),
      WaterIndicator(
        label: 'Water Clarity',
        value: '22 NTU',
        status: IndicatorStatus.danger,
        plainDescription:
            'Very high turbidity from agricultural runoff and sediment mobilization.',
        affectedGroups: 'Water treatment plants, fishing communities',
        trendLabel: 'Up +45% — worsening with heavy rainfall events',
      ),
      WaterIndicator(
        label: 'Nitrates',
        value: '42 mg/L',
        status: IndicatorStatus.warning,
        plainDescription:
            '84% of WHO limit. Intensive greenhouse agriculture is the primary source.',
        affectedGroups: 'Drinking water consumers, infants',
        trendLabel: 'Up +22% over 30 days',
      ),
      WaterIndicator(
        label: 'Chlorophyll-a',
        value: '65 µg/L',
        status: IndicatorStatus.danger,
        plainDescription:
            'Severe algal bloom in estuarine marshes. Satellite imagery shows extensive green coverage.',
        affectedGroups: 'Wetland wildlife, tourism',
        trendLabel: 'Critical — swimming advisories issued',
      ),
      WaterIndicator(
        label: 'Dissolved Oxygen',
        value: '4.8 mg/L',
        status: IndicatorStatus.warning,
        plainDescription:
            'Low oxygen from algal decomposition. Fish stress levels detected.',
        affectedGroups: 'Fish populations, commercial fisheries',
        trendLabel: 'Down -18% — worsening at night',
      ),
    ],
    pollutionEvents: const [
      WaterPollutionEvent(
        location: 'Doñana Marshes — km 85',
        description:
            'Severe algal bloom threatening Doñana National Park wetlands. Chlorophyll-a at 65 µg/L.',
        status: IndicatorStatus.danger,
        affectedPopulation: 'Endangered species, 500,000+ migratory birds',
        recommendedAction:
            'Activate emergency wetland protection protocol. Reduce agricultural water intake to increase flow.',
      ),
      WaterPollutionEvent(
        location: 'Sanlúcar de Barrameda',
        description:
            'Beach advisory in effect due to algal bloom and high turbidity. Swimming not recommended.',
        status: IndicatorStatus.warning,
        affectedPopulation: 'Beach visitors, local tourism businesses',
        recommendedAction:
            'Maintain beach advisories. Monitor for improvement as flow increases.',
      ),
    ],
    trendLabel: 'Chlorophyll-a (µg/L) over the last 30 days',
    trendSpots: const [
      (0, 28),
      (5, 35),
      (10, 42),
      (15, 48),
      (20, 55),
      (25, 60),
      (30, 65),
    ],
    sectorImpacts: const [
      WaterQualitySectorImpact(
        sectorName: 'Environment',
        headline: 'Doñana wetlands at risk',
        detail:
            'Algal bloom threatens one of Europe\'s most important wetlands. 500,000+ migratory birds depend on this ecosystem.',
        status: IndicatorStatus.danger,
        actionRequired: true,
      ),
      WaterQualitySectorImpact(
        sectorName: 'Tourism & Recreation',
        headline: 'Beach advisories in effect',
        detail:
            'Sanlúcar and nearby beaches have swimming advisories. Peak tourist season经济损失重大.',
        status: IndicatorStatus.warning,
        actionRequired: false,
      ),
      WaterQualitySectorImpact(
        sectorName: 'Agriculture',
        headline: 'Irrigation water quality declining',
        detail:
            'High nitrates and turbidity make water unsuitable for some crops without treatment.',
        status: IndicatorStatus.warning,
        actionRequired: false,
      ),
    ],
  ),
  'maas-river': WaterQualityData(
    overallStatusLabel:
        'Water quality is UNSAFE — PFAS chemical contamination above health guidelines',
    monthDeltaLabel: 'PFAS contamination up +40% vs last month · RIVM',
    indicators: const [
      WaterIndicator(
        label: 'pH Level',
        value: '7.6',
        status: IndicatorStatus.good,
        plainDescription:
            'Normal range. The chemical contamination has not affected pH.',
        trendLabel: 'Stable',
      ),
      WaterIndicator(
        label: 'Water Clarity',
        value: '4.8 NTU',
        status: IndicatorStatus.warning,
        plainDescription:
            'Slightly above normal. Possible sediment disturbance from upstream industrial activity.',
        trendLabel: 'Elevated vs historical average',
      ),
      WaterIndicator(
        label: 'Nitrates',
        value: '28 mg/L',
        status: IndicatorStatus.good,
        plainDescription:
            'Within limits, though elevated due to upstream agricultural land use.',
        affectedGroups: 'Drinking water consumers',
      ),
      WaterIndicator(
        label: 'PFAS Level',
        value: '2.3× limit',
        status: IndicatorStatus.danger,
        plainDescription:
            'PFAS "forever chemicals" detected at 2.3 times the EFSA health guideline. '
            'These chemicals do not break down and accumulate in the body over time.',
        affectedGroups: 'Drinking water consumers, farmers, fish consumers',
        trendLabel: 'Up +40% over 30 days — source investigation underway',
      ),
    ],
    pollutionEvents: const [
      WaterPollutionEvent(
        location: 'Rotterdam Water Intake, km 997',
        description: 'PFAS at 230 ng/L — more than double the EFSA safe limit. '
            'Enhanced filtration is now active and water is safe to drink, but the source must be identified.',
        status: IndicatorStatus.danger,
        affectedPopulation: '95,000 residents in Rotterdam Noord area',
        recommendedAction:
            'Water is safe — enhanced filtration is active. Commission urgent upstream source investigation. '
            'Notify downstream utilities and prepare public communication.',
      ),
      WaterPollutionEvent(
        location: 'Agricultural Zone — km 985 to km 997',
        description:
            'PFAS accumulating in soil and crops within 25 km of the intake. '
            'Irrigation with river water may contaminate produce.',
        status: IndicatorStatus.warning,
        affectedPopulation: 'Farmers and consumers of local produce',
        recommendedAction:
            'Issue irrigation advisory to farmers in the affected zone. '
            'Consider soil testing for fields irrigated in the last 30 days.',
      ),
    ],
    trendLabel: 'PFAS level (× EFSA guideline) over the last 30 days',
    trendSpots: const [
      (0, 0.8),
      (5, 0.9),
      (10, 1.1),
      (15, 1.4),
      (20, 1.8),
      (25, 2.1),
      (30, 2.3),
    ],
    sectorImpacts: const [
      WaterQualitySectorImpact(
        sectorName: 'Drinking Water',
        headline: 'Rotterdam intake at risk',
        detail:
            'PFAS levels exceed EFSA health guidelines. Drinking water for 95,000 residents is sourced here. '
            'Enhanced filtration is now active — water is currently safe — but this is a costly emergency measure, not a long-term solution.',
        status: IndicatorStatus.danger,
        actionRequired: true,
      ),
      WaterQualitySectorImpact(
        sectorName: 'Agriculture',
        headline: 'Irrigation advisory issued',
        detail:
            'Farmers within 25 km of the intake should avoid using river water for irrigation. '
            'PFAS accumulates in crops and soil and cannot be reversed once absorbed.',
        status: IndicatorStatus.warning,
        actionRequired: true,
      ),
      WaterQualitySectorImpact(
        sectorName: 'Environment',
        headline: 'PFAS bioaccumulation in fish',
        detail: 'Fish tissue sampling is underway in the affected stretch. '
            'Commercial fishing licence holders have been notified. Results expected within 5 days.',
        status: IndicatorStatus.warning,
        actionRequired: false,
      ),
    ],
  ),
  'maritsa-river': WaterQualityData(
    overallStatusLabel:
        'Water quality is CRITICAL — heavy metal contamination from mining',
    monthDeltaLabel: 'Lead 5x above limits · Sentinel-2 MSI',
    indicators: const [
      WaterIndicator(
        label: 'pH Level',
        value: '6.2',
        status: IndicatorStatus.warning,
        plainDescription:
            'Acidic from mine drainage. Below ideal range for most aquatic life.',
        trendLabel: 'Stable but concerning',
      ),
      WaterIndicator(
        label: 'Water Clarity',
        value: '35 NTU',
        status: IndicatorStatus.danger,
        plainDescription:
            'Very high turbidity from mining activities and sediment resuspension.',
        affectedGroups: 'Downstream water users',
      ),
      WaterIndicator(
        label: 'Lead',
        value: '52 µg/L',
        status: IndicatorStatus.danger,
        plainDescription:
            '5x above EU limit. Mining discharge is the confirmed source.',
        affectedGroups: 'Drinking water consumers, fishermen',
        trendLabel: 'Critical — source investigation ongoing',
      ),
      WaterIndicator(
        label: 'Cadmium',
        value: '8.5 µg/L',
        status: IndicatorStatus.danger,
        plainDescription: '3x above EU limit. Bioaccumulates in fish tissue.',
        affectedGroups: 'Fish consumers, pregnant women',
      ),
    ],
    pollutionEvents: const [
      WaterPollutionEvent(
        location: 'Pazardzhik Mining Zone — km 245',
        description:
            'Heavy metal plume detected. Lead at 52 µg/L, cadmium at 8.5 µg/L. Source: active mining discharge.',
        status: IndicatorStatus.danger,
        affectedPopulation: '180,000 residents downstream',
        recommendedAction:
            'Issue drinking water advisory. Install emergency filtration at intake. Investigate mine discharge permits.',
      ),
    ],
    trendLabel: 'Lead concentration (µg/L) over the last 30 days',
    trendSpots: const [
      (0, 28),
      (5, 32),
      (10, 38),
      (15, 42),
      (20, 46),
      (25, 50),
      (30, 52),
    ],
    sectorImpacts: const [
      WaterQualitySectorImpact(
        sectorName: 'Drinking Water',
        headline: 'Treatment plants overwhelmed',
        detail:
            'Lead exceeds safe levels at 3 downstream treatment plants. Bottled water being distributed to 45,000 residents.',
        status: IndicatorStatus.danger,
        actionRequired: true,
      ),
      WaterQualitySectorImpact(
        sectorName: 'Agriculture',
        headline: 'Irrigation water unsafe',
        detail:
            'Farmers advised not to use river water for irrigation. Crop contamination risk confirmed.',
        status: IndicatorStatus.danger,
        actionRequired: true,
      ),
      WaterQualitySectorImpact(
        sectorName: 'Environment',
        headline: 'Aquatic ecosystem damaged',
        detail:
            'Fish kills reported. Heavy metals accumulating in sediment will take decades to remediate.',
        status: IndicatorStatus.danger,
        actionRequired: false,
      ),
    ],
  ),
  'glomma-river': WaterQualityData(
    overallStatusLabel:
        'Water quality is CAUTION — low flow affecting oxygen levels',
    monthDeltaLabel: 'Dissolved oxygen down -15% · Sentinel-3 OLCI',
    indicators: const [
      WaterIndicator(
        label: 'pH Level',
        value: '7.1',
        status: IndicatorStatus.good,
        plainDescription: 'Normal range for Norwegian rivers. No concerns.',
        trendLabel: 'Stable',
      ),
      WaterIndicator(
        label: 'Water Clarity',
        value: '8.2 NTU',
        status: IndicatorStatus.warning,
        plainDescription:
            'Elevated from forestry operations in upper catchment.',
        affectedGroups: 'Salmon spawning areas',
        trendLabel: 'Up due to logging activities',
      ),
      WaterIndicator(
        label: 'Dissolved Oxygen',
        value: '7.8 mg/L',
        status: IndicatorStatus.warning,
        plainDescription:
            'Below optimal for salmonids. Low flow from hydro regulation is the cause.',
        affectedGroups: 'Atlantic salmon, sea trout',
        trendLabel: 'Down -15% due to reduced flow',
      ),
    ],
    pollutionEvents: const [
      WaterPollutionEvent(
        location: 'Sarpsfossen — km 45',
        description:
            'Low oxygen levels detected. Hydro operations reducing downstream flow below ecological minimum.',
        status: IndicatorStatus.warning,
        affectedPopulation: 'Salmon and sea trout populations',
        recommendedAction:
            'Request environmental flow release from hydro operators. Monitor fish populations.',
      ),
    ],
    trendLabel: 'Dissolved oxygen (mg/L) over the last 30 days',
    trendSpots: const [
      (0, 9.2),
      (5, 9.0),
      (10, 8.8),
      (15, 8.5),
      (20, 8.2),
      (25, 8.0),
      (30, 7.8),
    ],
    sectorImpacts: const [
      WaterQualitySectorImpact(
        sectorName: 'Environment',
        headline: 'Salmon populations at risk',
        detail:
            'Low oxygen stress on Atlantic salmon and sea trout. Spawning success may be affected this season.',
        status: IndicatorStatus.warning,
        actionRequired: false,
      ),
      WaterQualitySectorImpact(
        sectorName: 'Fisheries',
        headline: 'Commercial fishing impacted',
        detail:
            'Reduced catch rates reported by commercial fishers. Tourism fishing may be affected.',
        status: IndicatorStatus.warning,
        actionRequired: false,
      ),
    ],
  ),
  'tisza-river': WaterQualityData(
    overallStatusLabel:
        'Water quality is UNSAFE — flooding and salt contamination',
    monthDeltaLabel: 'Flooding active · Conductivity 4,200 µS/cm',
    indicators: const [
      WaterIndicator(
        label: 'pH Level',
        value: '7.8',
        status: IndicatorStatus.good,
        plainDescription:
            'Normal range. Flooding has not affected pH significantly.',
        trendLabel: 'Stable',
      ),
      WaterIndicator(
        label: 'Water Clarity',
        value: '28 NTU',
        status: IndicatorStatus.warning,
        plainDescription:
            'High sediment load from flood waters. Brown discoloration observed.',
        affectedGroups: 'Drinking water utilities',
        trendLabel: 'Elevated due to flooding',
      ),
      WaterIndicator(
        label: 'Conductivity',
        value: '4,200 µS/cm',
        status: IndicatorStatus.danger,
        plainDescription:
            'Very high — 8x normal. Salt contamination from mining brine discharge.',
        affectedGroups: 'Fish, agriculture, drinking water',
        trendLabel: 'Critical — source under investigation',
      ),
      WaterIndicator(
        label: 'Nitrates',
        value: '38 mg/L',
        status: IndicatorStatus.warning,
        plainDescription:
            '76% of limit. Agricultural runoff entering floodwaters.',
        affectedGroups: 'Private well users',
      ),
    ],
    pollutionEvents: const [
      WaterPollutionEvent(
        location: 'Tokaj — km 178',
        description:
            'High salinity plume detected (conductivity 4,200 µS/cm). Mining brine suspected source.',
        status: IndicatorStatus.danger,
        affectedPopulation: '85,000 residents in floodplain',
        recommendedAction:
            'Issue flood and contamination advisory. Monitor salt levels at all drinking water intakes.',
      ),
    ],
    trendLabel: 'Conductivity (µS/cm) over the last 30 days',
    trendSpots: const [
      (0, 520),
      (5, 680),
      (10, 1200),
      (15, 2200),
      (20, 3100),
      (25, 3800),
      (30, 4200),
    ],
    sectorImpacts: const [
      WaterQualitySectorImpact(
        sectorName: 'Agriculture',
        headline: 'Cropland flooded',
        detail:
            '18,000 ha of agricultural land under water. Salt contamination may affect soil for years.',
        status: IndicatorStatus.danger,
        actionRequired: true,
      ),
      WaterQualitySectorImpact(
        sectorName: 'Environment',
        headline: 'Fish kills reported',
        detail:
            'Low oxygen combined with high salinity causing fish mortality. Dead fish observed along 30 km.',
        status: IndicatorStatus.danger,
        actionRequired: false,
      ),
    ],
  ),
  'vistula-river': WaterQualityData(
    overallStatusLabel:
        'Water quality is CAUTION — flood conditions and nutrient loading',
    monthDeltaLabel: 'Flooding 420 km² · Nitrates up +18%',
    indicators: const [
      WaterIndicator(
        label: 'pH Level',
        value: '7.2',
        status: IndicatorStatus.good,
        plainDescription:
            'Normal range. Flood conditions have not significantly affected pH.',
        trendLabel: 'Stable',
      ),
      WaterIndicator(
        label: 'Water Clarity',
        value: '24 NTU',
        status: IndicatorStatus.warning,
        plainDescription:
            'High sediment load from flooding. Agricultural fields contributing to turbidity.',
        affectedGroups: 'Water treatment plants',
      ),
      WaterIndicator(
        label: 'Nitrates',
        value: '44 mg/L',
        status: IndicatorStatus.warning,
        plainDescription:
            '88% of limit. Flooding is washing fertilizers from agricultural fields.',
        affectedGroups: 'Private well users, infants',
        trendLabel: 'Up +18% — rising with flood peaks',
      ),
      WaterIndicator(
        label: 'Chlorophyll-a',
        value: '55 µg/L',
        status: IndicatorStatus.warning,
        plainDescription:
            'Elevated algae growth in lower Vistula. Warm temperatures and high nutrients promoting blooms.',
        affectedGroups: 'Recreational users, ecosystem',
      ),
    ],
    pollutionEvents: const [
      WaterPollutionEvent(
        location: 'Toruń — km 260',
        description:
            'Major flood event. 420 km² of floodplain inundated. Water levels 4.5m above normal.',
        status: IndicatorStatus.warning,
        affectedPopulation: '35,000 residents in flood zone',
        recommendedAction:
            'Continue flood monitoring. Advise private well users to boil water until levels stabilize.',
      ),
    ],
    trendLabel: 'Nitrates (mg/L) over the last 30 days',
    trendSpots: const [
      (0, 28),
      (5, 32),
      (10, 35),
      (15, 38),
      (20, 40),
      (25, 42),
      (30, 44),
    ],
    sectorImpacts: const [
      WaterQualitySectorImpact(
        sectorName: 'Agriculture',
        headline: '24,000 ha cropland flooded',
        detail:
            'Significant crop losses expected in flood-affected areas. Insurance claims being processed.',
        status: IndicatorStatus.warning,
        actionRequired: true,
      ),
      WaterQualitySectorImpact(
        sectorName: 'Environment',
        headline: 'Wetland habitat expanded',
        detail:
            'Floodplain wetlands receiving beneficial sediment and nutrient loads. Positive for long-term ecology.',
        status: IndicatorStatus.good,
        actionRequired: false,
      ),
    ],
  ),
  'po-river': WaterQualityData(
    overallStatusLabel:
        'Water quality is CRITICAL — severe drought and industrial pollution',
    monthDeltaLabel: 'River flow at 15% of average · Copernicus C3S',
    indicators: const [
      WaterIndicator(
        label: 'pH Level',
        value: '8.2',
        status: IndicatorStatus.warning,
        plainDescription: 'Alkaline from evaporation concentrating minerals.',
        trendLabel: 'Rising with drought',
      ),
      WaterIndicator(
        label: 'Water Clarity',
        value: '32 NTU',
        status: IndicatorStatus.warning,
        plainDescription:
            'High turbidity from low flow and sediment resuspension.',
        affectedGroups: 'Water treatment plants',
      ),
      WaterIndicator(
        label: 'Dissolved Oxygen',
        value: '5.8 mg/L',
        status: IndicatorStatus.warning,
        plainDescription:
            'Below optimal. Warm temperatures and low flow reducing oxygenation.',
        affectedGroups: 'Fish populations',
        trendLabel: 'Down -20% — critical for fish',
      ),
      WaterIndicator(
        label: 'Ammonia',
        value: '0.8 mg/L',
        status: IndicatorStatus.danger,
        plainDescription:
            'Above safe limit. Industrial discharge not adequately diluted due to low flow.',
        affectedGroups: 'Drinking water, aquatic life',
        trendLabel: 'Up due to reduced dilution',
      ),
    ],
    pollutionEvents: const [
      WaterPollutionEvent(
        location: 'Milan — km 252',
        description:
            'Multiple industrial contaminants detected downstream of Milan metropolitan area.',
        status: IndicatorStatus.danger,
        affectedPopulation: '1.2 million residents downstream',
        recommendedAction:
            'Increase monitoring at all drinking water intakes. Investigate industrial discharge permits.',
      ),
      WaterPollutionEvent(
        location: 'Piacenza — km 290',
        description:
            'Fish kill reported. Low oxygen and industrial discharge combined to cause mortality.',
        status: IndicatorStatus.danger,
        affectedPopulation: 'Fisheries, ecosystem',
        recommendedAction:
            'Continue oxygen monitoring. Enforce industrial discharge limits. Assess fish population damage.',
      ),
    ],
    trendLabel: 'Dissolved oxygen (mg/L) over the last 30 days',
    trendSpots: const [
      (0, 7.2),
      (5, 7.0),
      (10, 6.7),
      (15, 6.4),
      (20, 6.2),
      (25, 6.0),
      (30, 5.8),
    ],
    sectorImpacts: const [
      WaterQualitySectorImpact(
        sectorName: 'Drinking Water',
        headline: 'Supply under stress',
        detail:
            'Low flow and contamination risk threaten drinking water for millions. Treatment costs increasing.',
        status: IndicatorStatus.danger,
        actionRequired: true,
      ),
      WaterQualitySectorImpact(
        sectorName: 'Agriculture',
        headline: 'Irrigation severely restricted',
        detail:
            'Water allocation cuts affecting 120,000 ha of farmland. Crop losses mounting.',
        status: IndicatorStatus.danger,
        actionRequired: true,
      ),
      WaterQualitySectorImpact(
        sectorName: 'Environment',
        headline: 'Ecosystem under severe stress',
        detail:
            'Fish kills, low oxygen, and contamination creating ecological crisis. Recovery will take years.',
        status: IndicatorStatus.danger,
        actionRequired: false,
      ),
    ],
  ),
};
