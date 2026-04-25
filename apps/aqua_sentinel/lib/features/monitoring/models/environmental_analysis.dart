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

  PreventionMeasure({
    required this.problemId,
    required this.action,
    required this.feasibility,
    required this.estimatedCost,
    required this.timeline,
  });

  factory PreventionMeasure.fromJson(Map<String, dynamic> json) {
    return PreventionMeasure(
      problemId: json['problem_id'] as String,
      action: json['action'] as String,
      feasibility: json['feasibility'] as String,
      estimatedCost: json['estimated_cost'] as String,
      timeline: json['timeline'] as String,
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
    id: 'lake-balaton',
    name: 'Lake Balaton',
    latitude: 46.85,
    longitude: 17.73,
  ),
  WaterBodyInfo(
    id: 'danube-delta',
    name: 'Danube Delta',
    latitude: 45.15,
    longitude: 29.65,
  ),
  WaterBodyInfo(
    id: 'lake-ohrid',
    name: 'Lake Ohrid',
    latitude: 41.02,
    longitude: 20.72,
  ),
  WaterBodyInfo(
    id: 'ebro-reservoir',
    name: 'Ebro Reservoir',
    latitude: 42.98,
    longitude: -3.98,
  ),
  WaterBodyInfo(
    id: 'maas-river',
    name: 'Maas River',
    latitude: 51.92,
    longitude: 4.47,
  ),
];
