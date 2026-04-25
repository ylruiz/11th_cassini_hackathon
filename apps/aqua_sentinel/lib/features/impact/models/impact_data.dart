enum RiskTier { low, moderate, high, critical }

enum ImpactSector { drinkingWater, agriculture, energy, environment }

extension RiskTierX on RiskTier {
  String get displayName {
    switch (this) {
      case RiskTier.low:
        return 'LOW RISK';
      case RiskTier.moderate:
        return 'MODERATE';
      case RiskTier.high:
        return 'HIGH RISK';
      case RiskTier.critical:
        return 'CRITICAL';
    }
  }
}

extension ImpactSectorX on ImpactSector {
  String get displayName {
    switch (this) {
      case ImpactSector.drinkingWater:
        return 'Drinking Water';
      case ImpactSector.agriculture:
        return 'Agriculture';
      case ImpactSector.energy:
        return 'Energy';
      case ImpactSector.environment:
        return 'Environment';
    }
  }
}

class SectorImpact {
  const SectorImpact({
    required this.sector,
    required this.headline,
    required this.detail,
    required this.actionRequired,
  });

  final ImpactSector sector;
  final String headline;
  final String detail;
  final bool actionRequired;
}

class WaterBodyRiskScore {
  const WaterBodyRiskScore({
    required this.waterBodyId,
    required this.waterBodyName,
    required this.country,
    required this.riskScore,
    required this.tier,
    required this.populationAtRisk,
    required this.economicImpactEurM,
    required this.primaryThreat,
    required this.dataSource,
    required this.lastUpdated,
    required this.sectorImpacts,
  });

  final String waterBodyId;
  final String waterBodyName;
  final String country;

  /// 0–100 composite risk score derived from satellite readings.
  final int riskScore;
  final RiskTier tier;

  /// Estimated people at risk if current trend continues unaddressed.
  final int populationAtRisk;

  /// Estimated economic damage in millions of euros if unaddressed.
  final double economicImpactEurM;

  final String primaryThreat;
  final String dataSource;
  final String lastUpdated;
  final List<SectorImpact> sectorImpacts;
}

class ImpactSummary {
  const ImpactSummary({
    required this.watershedsAtRisk,
    required this.totalPopulationAtRisk,
    required this.totalEconomicImpactEurM,
    required this.criticalCount,
    required this.highCount,
  });

  /// Water bodies with riskScore > 60.
  final int watershedsAtRisk;
  final int totalPopulationAtRisk;
  final double totalEconomicImpactEurM;
  final int criticalCount;
  final int highCount;
}
