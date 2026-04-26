import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/water_issue_scenario.dart';

// Replace with Copernicus / Galileo / EGNOS data once API access is confirmed.
final waterScenariosProvider =
    Provider<List<WaterIssueScenario>>((ref) => _scenarios);

const _scenarios = [
  WaterIssueScenario(
    type: WaterIssueType.pollution,
    causeTitle: 'What caused water pollution?',
    causeText:
        'For decades, factories and farms released chemicals into rivers with little oversight. '
        "In the 1980s, Europe's most iconic waterways were so contaminated they could barely support life.",
    causeFact: '70 % of EU rivers had critical chemical loads in 1985',
    nowTitle: "What's happening right now?",
    nowText:
        'Satellites detect elevated nitrates and phosphorus in nearly 40 % of European rivers today. '
        'Most of it comes from fertilisers washing off farm fields after rainfall.',
    nowIndicators: [
      ScenarioIndicator(
          label: 'Nitrate level', value: '48 mg/L', isPositive: false),
      ScenarioIndicator(
          label: 'Phosphorus', value: '0.4 mg/L', isPositive: false),
      ScenarioIndicator(
          label: 'River health score', value: '62 / 100', isPositive: true),
    ],
    whatIfTitle: 'What if farms reduce chemical use by 20 %?',
    whatIfText:
        'Rivers could naturally recover within 5 years. Fish populations would return, and communities '
        'downstream would spend far less purifying their drinking water.',
    whatIfImpacts: [
      '35 % lower nitrates in rivers',
      'Fish return within 5 years',
      'Save €2 B/yr in water treatment',
    ],
    source: 'Copernicus Sentinel-2 / EEA',
  ),
  WaterIssueScenario(
    type: WaterIssueType.flooding,
    causeTitle: 'Why are floods getting worse?',
    causeText:
        'As cities expanded, natural floodplains were paved over and rivers were straightened. '
        'This removed the wetlands and riverside forests that used to slow and absorb excess water.',
    causeFact: 'Europe has lost 80 % of its natural floodplains since 1900',
    nowTitle: "What's happening right now?",
    nowText: 'Climate change is intensifying rainfall events across Europe. '
        'Copernicus satellites currently detect 2 active flood zones in the Balkans and Po Valley.',
    nowIndicators: [
      ScenarioIndicator(
          label: 'River level above normal',
          value: '+2.4 m',
          isPositive: false),
      ScenarioIndicator(
          label: 'Flooded area', value: '340 km²', isPositive: false),
      ScenarioIndicator(
          label: 'People affected', value: '12,000', isPositive: false),
    ],
    whatIfTitle: 'What if we restore riverside wetlands?',
    whatIfText:
        'Restoring natural floodplains along 30 % of at-risk riverbanks could absorb up to 40 % more '
        'floodwater — the difference between a manageable wet season and a disaster.',
    whatIfImpacts: [
      '40 % less flood damage',
      '500 k people better protected',
      'Wildlife habitats restored',
    ],
    source: 'Copernicus EMS / Sentinel-1',
  ),
  WaterIssueScenario(
    type: WaterIssueType.drought,
    causeTitle: 'How did droughts become so severe?',
    causeText:
        'Decades of intensive irrigation and rising temperatures have slowly drained underground water reserves. '
        'The Ebro and Tagus basins have lost 20 % of their average river flow since 1970.',
    causeFact: 'Mediterranean groundwater dropped 1 m per decade since 1980',
    nowTitle: "What's happening right now?",
    nowText:
        'Soil moisture across the Iberian Peninsula is 18 % below seasonal average. '
        'Southern Spain reservoirs sit at 42 % capacity — confirmed by Copernicus C3S climate data.',
    nowIndicators: [
      ScenarioIndicator(
          label: 'Soil moisture vs. average',
          value: '−18 %',
          isPositive: false),
      ScenarioIndicator(
          label: 'Reservoir capacity', value: '42 %', isPositive: false),
      ScenarioIndicator(
          label: 'River flow vs. normal', value: '0.6 ×', isPositive: false),
    ],
    whatIfTitle: 'What if farms switch to smarter irrigation?',
    whatIfText:
        'Switching to drip irrigation on half of all irrigated farmland could save enough water each year '
        'to supply 2 million households. Small farming changes create big wins for rivers.',
    whatIfImpacts: [
      '30 % less water consumed',
      'Rivers recover faster',
      '2 M households supplied',
    ],
    source: 'Copernicus C3S / Galileo',
  ),
  WaterIssueScenario(
    type: WaterIssueType.heatStress,
    causeTitle: 'Why are rivers warming up?',
    causeText:
        'Rivers absorb heat from air and sun. As global temperatures rise and riverside shade trees disappear, '
        'water temperature has climbed steadily — stressing fish, insects, and all aquatic life.',
    causeFact: 'European river temperatures have risen 1.5 °C since 1980',
    nowTitle: "What's happening right now?",
    nowText:
        '3 major rivers in southern Europe are at or above critical temperature thresholds. '
        'Warm water holds less oxygen, which suffocates fish and triggers harmful algae blooms.',
    nowIndicators: [
      ScenarioIndicator(
          label: 'Water temperature', value: '24 °C', isPositive: false),
      ScenarioIndicator(
          label: 'Dissolved oxygen', value: '5.8 mg/L', isPositive: false),
      ScenarioIndicator(
          label: 'Algae bloom risk', value: 'HIGH', isPositive: false),
    ],
    whatIfTitle: 'What if we plant trees along riverbanks?',
    whatIfText:
        'Natural riverside shade can drop water temperature by 2–3 °C — enough to bring most rivers back '
        'within safe limits for native species and restore the food web from the bottom up.',
    whatIfImpacts: [
      '2–3 °C cooler water',
      'Oxygen levels restored',
      'Native fish return',
    ],
    source: 'Copernicus Sentinel-3 / EEA',
  ),
  WaterIssueScenario(
    type: WaterIssueType.snowMelt,
    causeTitle: 'How does snow melt affect rivers?',
    causeText:
        'Mountain snowpacks act as natural water reservoirs. When snow melts rapidly, '
        'it releases large volumes of water into rivers downstream, causing floods. '
        'Less snow also means less water during summer dry seasons.',
    causeFact: 'Alps have lost 30 % of snow volume since 1980',
    nowTitle: "What's happening right now?",
    nowText:
        'Current snow coverage in European mountain ranges ranges from 25-90%. '
        'Melt rates are accelerating in the Alps and Pyrenees due to warmer spring temperatures. '
        'Fast-melt zones detected in Southern Alps and Pyrenees.',
    nowIndicators: [
      ScenarioIndicator(
          label: 'Alps snow coverage', value: '68 %', isPositive: false),
      ScenarioIndicator(
          label: 'Fast melt zones', value: '3 active', isPositive: false),
      ScenarioIndicator(
          label: 'Downstream river level', value: '+1.8 m', isPositive: false),
    ],
    whatIfTitle: 'What if snow melts 2 weeks earlier + less winter snow?',
    whatIfText:
        'Earlier snowmelt combined with reduced snowpack creates a double impact: '
        'immediate flooding risk followed by summer drought. Rivers could see 40% less flow '
        'by late summer, affecting water supply, agriculture, and ecosystems.',
    whatIfImpacts: [
      'Spring flood risk +40%',
      'Summer drought severity +35%',
      'Water supply for 15 M at risk',
    ],
    source: 'Copernicus Sentinel-1 / Sentinel-2',
  ),
];
