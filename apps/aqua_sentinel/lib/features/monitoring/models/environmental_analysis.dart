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
