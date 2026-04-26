enum ProblemType {
  eutrophication,
  chemicalPollution,
  flood,
  drought,
  temperatureAnomaly,
  invasiveSpecies,
  sedimentPollution,
  oxygenDepletion,
}

extension ProblemTypeExtension on ProblemType {
  String get displayName {
    switch (this) {
      case ProblemType.eutrophication:
        return 'Eutrophication';
      case ProblemType.chemicalPollution:
        return 'Chemical Pollution';
      case ProblemType.flood:
        return 'Flood';
      case ProblemType.drought:
        return 'Drought';
      case ProblemType.temperatureAnomaly:
        return 'Temperature Anomaly';
      case ProblemType.invasiveSpecies:
        return 'Invasive Species';
      case ProblemType.sedimentPollution:
        return 'Sediment Pollution';
      case ProblemType.oxygenDepletion:
        return 'Oxygen Depletion';
    }
  }

  String get apiValue {
    switch (this) {
      case ProblemType.eutrophication:
        return 'eutrophication';
      case ProblemType.chemicalPollution:
        return 'chemical_pollution';
      case ProblemType.flood:
        return 'flood';
      case ProblemType.drought:
        return 'drought';
      case ProblemType.temperatureAnomaly:
        return 'temperature_anomaly';
      case ProblemType.invasiveSpecies:
        return 'invasive_species';
      case ProblemType.sedimentPollution:
        return 'sediment_pollution';
      case ProblemType.oxygenDepletion:
        return 'oxygen_depletion';
    }
  }
}

ProblemType problemTypeFromString(String value) {
  switch (value) {
    case 'eutrophication':
      return ProblemType.eutrophication;
    case 'chemical_pollution':
      return ProblemType.chemicalPollution;
    case 'flood':
      return ProblemType.flood;
    case 'drought':
      return ProblemType.drought;
    case 'temperature_anomaly':
      return ProblemType.temperatureAnomaly;
    case 'invasive_species':
      return ProblemType.invasiveSpecies;
    case 'sediment_pollution':
      return ProblemType.sedimentPollution;
    case 'oxygen_depletion':
      return ProblemType.oxygenDepletion;
    default:
      return ProblemType.eutrophication;
  }
}

enum Severity {
  low,
  medium,
  high,
  critical,
}

extension SeverityExtension on Severity {
  String get displayName {
    switch (this) {
      case Severity.low:
        return 'Low';
      case Severity.medium:
        return 'Medium';
      case Severity.high:
        return 'High';
      case Severity.critical:
        return 'Critical';
    }
  }
}

Severity severityFromString(String value) {
  switch (value) {
    case 'low':
      return Severity.low;
    case 'medium':
      return Severity.medium;
    case 'high':
      return Severity.high;
    case 'critical':
      return Severity.critical;
    default:
      return Severity.medium;
  }
}

class ProblemLocation {
  final double latitude;
  final double longitude;
  final double radiusKm;

  ProblemLocation({
    required this.latitude,
    required this.longitude,
    required this.radiusKm,
  });

  factory ProblemLocation.fromJson(Map<String, dynamic> json) {
    return ProblemLocation(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radiusKm: (json['radius_km'] as num).toDouble(),
    );
  }
}

class EnvironmentalProblem {
  final String id;
  final ProblemType type;
  final Severity severity;
  final ProblemLocation location;
  final String detectedAt;
  final String source;
  final String description;

  EnvironmentalProblem({
    required this.id,
    required this.type,
    required this.severity,
    required this.location,
    required this.detectedAt,
    required this.source,
    required this.description,
  });

  factory EnvironmentalProblem.fromJson(Map<String, dynamic> json) {
    return EnvironmentalProblem(
      id: json['id'] as String,
      type: problemTypeFromString(json['type'] as String),
      severity: severityFromString(json['severity'] as String),
      location: ProblemLocation.fromJson(json['location']),
      detectedAt: json['detected_at'] as String,
      source: json['source'] as String,
      description: json['description'] as String,
    );
  }
}

class ProblemCause {
  final String problemId;
  final String primaryCause;
  final List<String> contributingFactors;
  final String sourceDetails;

  ProblemCause({
    required this.problemId,
    required this.primaryCause,
    required this.contributingFactors,
    required this.sourceDetails,
  });

  factory ProblemCause.fromJson(Map<String, dynamic> json) {
    return ProblemCause(
      problemId: json['problem_id'] as String,
      primaryCause: json['primary_cause'] as String,
      contributingFactors: List<String>.from(json['contributing_factors']),
      sourceDetails: json['source_details'] as String,
    );
  }
}

class PreventionMeasure {
  final String problemId;
  final String action;
  final String feasibility;
  final String estimatedCost;
  final String timeline;
  final String costIfNothingDone;

  PreventionMeasure({
    required this.problemId,
    required this.action,
    required this.feasibility,
    required this.estimatedCost,
    required this.timeline,
    required this.costIfNothingDone,
  });

  factory PreventionMeasure.fromJson(Map<String, dynamic> json) {
    return PreventionMeasure(
      problemId: json['problem_id'] as String,
      action: json['action'] as String,
      feasibility: json['feasibility'] as String,
      estimatedCost: json['estimated_cost'] as String,
      timeline: json['timeline'] as String,
      costIfNothingDone: json['cost_if_nothing_done'] as String,
    );
  }
}

class EcosystemImpact {
  final String problemId;
  final List<String> affectedSpecies;
  final String habitatImpact;
  final String duration;
  final String recoveryPotential;

  EcosystemImpact({
    required this.problemId,
    required this.affectedSpecies,
    required this.habitatImpact,
    required this.duration,
    required this.recoveryPotential,
  });

  factory EcosystemImpact.fromJson(Map<String, dynamic> json) {
    return EcosystemImpact(
      problemId: json['problem_id'] as String,
      affectedSpecies: List<String>.from(json['affected_species']),
      habitatImpact: json['habitat_impact'] as String,
      duration: json['duration'] as String,
      recoveryPotential: json['recovery_potential'] as String,
    );
  }
}

class AreaAnalysis {
  final String? waterBodyId;
  final String? waterBodyName;
  final double latitude;
  final double longitude;
  final List<EnvironmentalProblem> problems;
  final List<ProblemCause> causes;
  final List<PreventionMeasure> preventionMeasures;
  final List<EcosystemImpact> ecosystemImpacts;

  AreaAnalysis({
    this.waterBodyId,
    this.waterBodyName,
    required this.latitude,
    required this.longitude,
    required this.problems,
    required this.causes,
    required this.preventionMeasures,
    required this.ecosystemImpacts,
  });

  factory AreaAnalysis.fromJson(Map<String, dynamic> json) {
    return AreaAnalysis(
      waterBodyId: json['water_body_id'] as String?,
      waterBodyName: json['water_body_name'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      problems: (json['problems'] as List)
          .map((e) => EnvironmentalProblem.fromJson(e))
          .toList(),
      causes: (json['causes'] as List)
          .map((e) => ProblemCause.fromJson(e))
          .toList(),
      preventionMeasures: (json['prevention_measures'] as List)
          .map((e) => PreventionMeasure.fromJson(e))
          .toList(),
      ecosystemImpacts: (json['ecosystem_impacts'] as List)
          .map((e) => EcosystemImpact.fromJson(e))
          .toList(),
    );
  }

  static AreaAnalysis empty() {
    return AreaAnalysis(
      latitude: 0,
      longitude: 0,
      problems: [],
      causes: [],
      preventionMeasures: [],
      ecosystemImpacts: [],
    );
  }
}

class RiskSignal {
  final String label;
  final String value;
  final Severity severity;
  final String source;
  final String summary;

  RiskSignal({
    required this.label,
    required this.value,
    required this.severity,
    required this.source,
    required this.summary,
  });

  factory RiskSignal.fromJson(Map<String, dynamic> json) {
    return RiskSignal(
      label: json['label'] as String,
      value: json['value'] as String,
      severity: severityFromString(json['severity'] as String),
      source: json['source'] as String,
      summary: json['summary'] as String,
    );
  }
}

class RiskDriver {
  final String id;
  final String label;
  final String status;
  final String trend;
  final String detail;
  final String source;

  RiskDriver({
    required this.id,
    required this.label,
    required this.status,
    required this.trend,
    required this.detail,
    required this.source,
  });

  factory RiskDriver.fromJson(Map<String, dynamic> json) {
    return RiskDriver(
      id: json['id'] as String,
      label: json['label'] as String,
      status: json['status'] as String,
      trend: json['trend'] as String,
      detail: json['detail'] as String,
      source: json['source'] as String,
    );
  }
}

class RiskProjection {
  final int horizonYears;
  final String label;
  final Severity floodRisk;
  final Severity landslideRisk;
  final double dischargeChangePercent;
  final double floodProneAreaChangePercent;
  final String summary;

  RiskProjection({
    required this.horizonYears,
    required this.label,
    required this.floodRisk,
    required this.landslideRisk,
    required this.dischargeChangePercent,
    required this.floodProneAreaChangePercent,
    required this.summary,
  });

  factory RiskProjection.fromJson(Map<String, dynamic> json) {
    return RiskProjection(
      horizonYears: json['horizon_years'] as int,
      label: json['label'] as String,
      floodRisk: severityFromString(json['flood_risk'] as String),
      landslideRisk: severityFromString(json['landslide_risk'] as String),
      dischargeChangePercent:
          (json['discharge_change_percent'] as num).toDouble(),
      floodProneAreaChangePercent:
          (json['flood_prone_area_change_percent'] as num).toDouble(),
      summary: json['summary'] as String,
    );
  }
}

class RiskImpact {
  final String category;
  final String metric;
  final String value;
  final String detail;

  RiskImpact({
    required this.category,
    required this.metric,
    required this.value,
    required this.detail,
  });

  factory RiskImpact.fromJson(Map<String, dynamic> json) {
    return RiskImpact(
      category: json['category'] as String,
      metric: json['metric'] as String,
      value: json['value'] as String,
      detail: json['detail'] as String,
    );
  }
}

class RiskAction {
  final String priority;
  final String title;
  final String timeline;
  final String expectedEffect;
  final String estimatedCost;

  RiskAction({
    required this.priority,
    required this.title,
    required this.timeline,
    required this.expectedEffect,
    required this.estimatedCost,
  });

  factory RiskAction.fromJson(Map<String, dynamic> json) {
    return RiskAction(
      priority: json['priority'] as String,
      title: json['title'] as String,
      timeline: json['timeline'] as String,
      expectedEffect: json['expected_effect'] as String,
      estimatedCost: json['estimated_cost'] as String,
    );
  }
}

class RiskEvidenceMetric {
  final String label;
  final double value;
  final String unit;
  final double fraction;
  final String interpretation;
  final String source;

  RiskEvidenceMetric({
    required this.label,
    required this.value,
    required this.unit,
    required this.fraction,
    required this.interpretation,
    required this.source,
  });

  factory RiskEvidenceMetric.fromJson(Map<String, dynamic> json) {
    return RiskEvidenceMetric(
      label: json['label'] as String,
      value: (json['value'] as num).toDouble(),
      unit: json['unit'] as String,
      fraction: (json['fraction'] as num).toDouble(),
      interpretation: json['interpretation'] as String,
      source: json['source'] as String,
    );
  }
}

class Settlement {
  final String name;
  final double latitude;
  final double longitude;
  final int population;
  final String kind;
  final String region;
  final double distanceKm;

  const Settlement({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.population,
    required this.kind,
    required this.region,
    required this.distanceKm,
  });

  factory Settlement.fromJson(Map<String, dynamic> json) {
    return Settlement(
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      population: (json['population'] as num).toInt(),
      kind: json['kind'] as String,
      region: json['region'] as String,
      distanceKm: (json['distance_km'] as num).toDouble(),
    );
  }
}

class SettlementExposure {
  final int totalSettlements;
  final int totalPopulation;
  final int insideAoi;
  final int withinBuffer;
  final double bufferKm;
  final List<Settlement> settlements;

  const SettlementExposure({
    required this.totalSettlements,
    required this.totalPopulation,
    required this.insideAoi,
    required this.withinBuffer,
    required this.bufferKm,
    required this.settlements,
  });

  factory SettlementExposure.fromJson(Map<String, dynamic> json) {
    return SettlementExposure(
      totalSettlements: (json['total_settlements'] as num).toInt(),
      totalPopulation: (json['total_population'] as num).toInt(),
      insideAoi: (json['inside_aoi'] as num).toInt(),
      withinBuffer: (json['within_buffer'] as num).toInt(),
      bufferKm: (json['buffer_km'] as num).toDouble(),
      settlements: (json['settlements'] as List? ?? [])
          .map((e) => Settlement.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class RiskWeights {
  final double snow;
  final double surfaceWater;
  final double vegetation;
  final double hydrology;

  const RiskWeights({
    this.snow = 1.0,
    this.surfaceWater = 1.0,
    this.vegetation = 1.0,
    this.hydrology = 1.0,
  });

  static const RiskWeights defaults = RiskWeights();

  bool get isDefault =>
      (snow - 1.0).abs() < 1e-9 &&
      (surfaceWater - 1.0).abs() < 1e-9 &&
      (vegetation - 1.0).abs() < 1e-9 &&
      (hydrology - 1.0).abs() < 1e-9;

  RiskWeights copyWith({
    double? snow,
    double? surfaceWater,
    double? vegetation,
    double? hydrology,
  }) {
    return RiskWeights(
      snow: snow ?? this.snow,
      surfaceWater: surfaceWater ?? this.surfaceWater,
      vegetation: vegetation ?? this.vegetation,
      hydrology: hydrology ?? this.hydrology,
    );
  }

  Map<String, dynamic> toJson() => {
        'snow': snow,
        'surface_water': surfaceWater,
        'vegetation': vegetation,
        'hydrology': hydrology,
      };

  factory RiskWeights.fromJson(Map<String, dynamic> json) {
    return RiskWeights(
      snow: (json['snow'] as num?)?.toDouble() ?? 1.0,
      surfaceWater: (json['surface_water'] as num?)?.toDouble() ?? 1.0,
      vegetation: (json['vegetation'] as num?)?.toDouble() ?? 1.0,
      hydrology: (json['hydrology'] as num?)?.toDouble() ?? 1.0,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is RiskWeights &&
      other.snow == snow &&
      other.surfaceWater == surfaceWater &&
      other.vegetation == vegetation &&
      other.hydrology == hydrology;

  @override
  int get hashCode => Object.hash(snow, surfaceWater, vegetation, hydrology);
}

class HistoryPoint {
  final String month;
  final double ndsiSnowFraction;
  final double efasAnomalyPercent;

  const HistoryPoint({
    required this.month,
    required this.ndsiSnowFraction,
    required this.efasAnomalyPercent,
  });

  factory HistoryPoint.fromJson(Map<String, dynamic> json) {
    return HistoryPoint(
      month: json['month'] as String,
      ndsiSnowFraction: (json['ndsi_snow_fraction'] as num).toDouble(),
      efasAnomalyPercent: (json['efas_anomaly_percent'] as num).toDouble(),
    );
  }
}

class AoiHistory {
  final String label;
  final String source;
  final String provenance;
  final List<HistoryPoint> points;

  const AoiHistory({
    required this.label,
    required this.source,
    required this.provenance,
    required this.points,
  });

  factory AoiHistory.fromJson(Map<String, dynamic> json) {
    return AoiHistory(
      label: json['label'] as String,
      source: json['source'] as String,
      provenance: json['provenance'] as String,
      points: (json['points'] as List? ?? [])
          .map((e) => HistoryPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class RiskTimeline {
  final String waterBodyId;
  final String waterBodyName;
  final String generatedAt;
  final int analysisPeriodDays;
  final double aoiAreaKm2;
  final String confidenceLabel;
  final String confidence;
  final String methodologyNote;
  final List<String> observedDataSources;
  final List<String> scenarioAssumptions;
  final List<String> missingOperationalLayers;
  final RiskSignal currentSignal;
  final List<RiskDriver> drivers;
  final List<RiskProjection> projections;
  final List<RiskImpact> impacts;
  final List<RiskAction> actions;
  final List<RiskEvidenceMetric> evidence;
  final SettlementExposure? settlementExposure;
  final RiskWeights? weights;

  RiskTimeline({
    required this.waterBodyId,
    required this.waterBodyName,
    required this.generatedAt,
    required this.analysisPeriodDays,
    required this.aoiAreaKm2,
    required this.confidenceLabel,
    required this.confidence,
    required this.methodologyNote,
    required this.observedDataSources,
    required this.scenarioAssumptions,
    required this.missingOperationalLayers,
    required this.currentSignal,
    required this.drivers,
    required this.projections,
    required this.impacts,
    required this.actions,
    required this.evidence,
    this.settlementExposure,
    this.weights,
  });

  factory RiskTimeline.fromJson(Map<String, dynamic> json) {
    return RiskTimeline(
      waterBodyId: json['water_body_id'] as String,
      waterBodyName: json['water_body_name'] as String,
      generatedAt: json['generated_at'] as String,
      analysisPeriodDays: json['analysis_period_days'] as int? ?? 30,
      aoiAreaKm2: (json['aoi_area_km2'] as num?)?.toDouble() ?? 0,
      confidenceLabel: json['confidence_label'] as String? ?? 'Medium',
      confidence: json['confidence'] as String,
      methodologyNote: json['methodology_note'] as String? ?? '',
      observedDataSources:
          List<String>.from(json['observed_data_sources'] ?? []),
      scenarioAssumptions:
          List<String>.from(json['scenario_assumptions'] ?? []),
      missingOperationalLayers:
          List<String>.from(json['missing_operational_layers'] ?? []),
      currentSignal: RiskSignal.fromJson(json['current_signal']),
      drivers:
          (json['drivers'] as List).map((e) => RiskDriver.fromJson(e)).toList(),
      projections: (json['projections'] as List)
          .map((e) => RiskProjection.fromJson(e))
          .toList(),
      impacts:
          (json['impacts'] as List).map((e) => RiskImpact.fromJson(e)).toList(),
      actions:
          (json['actions'] as List).map((e) => RiskAction.fromJson(e)).toList(),
      evidence: (json['evidence'] as List? ?? [])
          .map((e) => RiskEvidenceMetric.fromJson(e))
          .toList(),
      settlementExposure: json['settlement_exposure'] == null
          ? null
          : SettlementExposure.fromJson(
              json['settlement_exposure'] as Map<String, dynamic>),
      weights: json['weights'] == null
          ? null
          : RiskWeights.fromJson(json['weights'] as Map<String, dynamic>),
    );
  }
}

class AoiBounds {
  final double west;
  final double south;
  final double east;
  final double north;

  const AoiBounds({
    required this.west,
    required this.south,
    required this.east,
    required this.north,
  });

  Map<String, dynamic> toJson() {
    return {
      'west': west,
      'south': south,
      'east': east,
      'north': north,
    };
  }
}

class AoiSelection {
  final String label;
  final AoiBounds bbox;

  const AoiSelection({
    required this.label,
    required this.bbox,
  });

  double get latitude => (bbox.south + bbox.north) / 2;
  double get longitude => (bbox.west + bbox.east) / 2;

  Map<String, dynamic> toRiskTimelineRequest({RiskWeights? weights}) {
    final body = <String, dynamic>{
      'label': label,
      'bbox': bbox.toJson(),
    };
    if (weights != null && !weights.isDefault) {
      body['weights'] = weights.toJson();
    }
    return body;
  }
}

class WaterBodyInfo {
  final String id;
  final String name;
  final double latitude;
  final double longitude;

  const WaterBodyInfo({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });
}

const waterBodies = [
  WaterBodyInfo(
    id: 'inn-river',
    name: 'Inn River',
    latitude: 48.57,
    longitude: 13.48,
  ),
  WaterBodyInfo(
    id: 'lake-ohrid',
    name: 'Lake Ohrid',
    latitude: 41.04,
    longitude: 20.72,
  ),
  WaterBodyInfo(
    id: 'maritsa-river',
    name: 'Maritsa River',
    latitude: 41.52,
    longitude: 26.04,
  ),
  WaterBodyInfo(
    id: 'glomma-river',
    name: 'Glomma River',
    latitude: 59.18,
    longitude: 10.87,
  ),
  WaterBodyInfo(
    id: 'tisza-river',
    name: 'Tisza River',
    latitude: 45.14,
    longitude: 20.16,
  ),
  WaterBodyInfo(
    id: 'vistula-river',
    name: 'Vistula River',
    latitude: 52.38,
    longitude: 20.09,
  ),
  WaterBodyInfo(
    id: 'po-river',
    name: 'Po River',
    latitude: 45.04,
    longitude: 10.05,
  ),
  WaterBodyInfo(
    id: 'maas-river',
    name: 'Maas River',
    latitude: 50.87,
    longitude: 5.70,
  ),
  WaterBodyInfo(
    id: 'danube-delta',
    name: 'Danube Delta',
    latitude: 44.90,
    longitude: 29.23,
  ),
  WaterBodyInfo(
    id: 'guadalquivir-river',
    name: 'Guadalquivir River',
    latitude: 37.94,
    longitude: -4.48,
  ),
];

enum MeltRate {
  slow,
  medium,
  fast,
}

extension MeltRateExtension on MeltRate {
  String get displayName {
    switch (this) {
      case MeltRate.slow:
        return 'Slow';
      case MeltRate.medium:
        return 'Medium';
      case MeltRate.fast:
        return 'Fast';
    }
  }
}

MeltRate meltRateFromString(String value) {
  switch (value) {
    case 'slow':
      return MeltRate.slow;
    case 'medium':
      return MeltRate.medium;
    case 'fast':
      return MeltRate.fast;
    default:
      return MeltRate.medium;
  }
}

class SnowArea {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double coveragePct;
  final MeltRate meltRate;
  final String feedsRiver;
  final String lastUpdated;

  const SnowArea({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.coveragePct,
    required this.meltRate,
    required this.feedsRiver,
    required this.lastUpdated,
  });

  factory SnowArea.fromJson(Map<String, dynamic> json) {
    return SnowArea(
      id: json['id'] as String,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      coveragePct: (json['coverage_pct'] as num).toDouble(),
      meltRate: meltRateFromString(json['melt_rate'] as String),
      feedsRiver: json['feeds_river'] as String,
      lastUpdated: json['last_updated'] as String,
    );
  }
}

const snowAreas = [
  SnowArea(
    id: 'snow-alps-north',
    name: 'Alps North',
    latitude: 46.5,
    longitude: 10.0,
    coveragePct: 78,
    meltRate: MeltRate.medium,
    feedsRiver: 'inn-river',
    lastUpdated: '2025-04-25',
  ),
  SnowArea(
    id: 'snow-alps-south',
    name: 'Alps South',
    latitude: 45.8,
    longitude: 10.5,
    coveragePct: 65,
    meltRate: MeltRate.fast,
    feedsRiver: 'po-river',
    lastUpdated: '2025-04-25',
  ),
  SnowArea(
    id: 'snow-pyrenees-east',
    name: 'Pyrenees East',
    latitude: 42.5,
    longitude: 2.0,
    coveragePct: 45,
    meltRate: MeltRate.fast,
    feedsRiver: 'guadalquivir-river',
    lastUpdated: '2025-04-25',
  ),
  SnowArea(
    id: 'snow-carpathians',
    name: 'Carpathians',
    latitude: 47.5,
    longitude: 25.0,
    coveragePct: 82,
    meltRate: MeltRate.slow,
    feedsRiver: 'tisza-river',
    lastUpdated: '2025-04-25',
  ),
  SnowArea(
    id: 'snow-balkans',
    name: 'Balkans',
    latitude: 42.0,
    longitude: 21.0,
    coveragePct: 35,
    meltRate: MeltRate.medium,
    feedsRiver: 'maritsa-river',
    lastUpdated: '2025-04-25',
  ),
  SnowArea(
    id: 'snow-scandinavia',
    name: 'Scandinavia',
    latitude: 62.0,
    longitude: 12.0,
    coveragePct: 90,
    meltRate: MeltRate.slow,
    feedsRiver: 'glomma-river',
    lastUpdated: '2025-04-25',
  ),
  SnowArea(
    id: 'snow-peaks-iberian',
    name: 'Iberian Peaks',
    latitude: 40.5,
    longitude: -5.0,
    coveragePct: 25,
    meltRate: MeltRate.fast,
    feedsRiver: 'guadalquivir-river',
    lastUpdated: '2025-04-25',
  ),
  SnowArea(
    id: 'snow-massif-central',
    name: 'Massif Central',
    latitude: 45.5,
    longitude: 3.5,
    coveragePct: 30,
    meltRate: MeltRate.medium,
    feedsRiver: 'maas-river',
    lastUpdated: '2025-04-25',
  ),
];
