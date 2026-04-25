enum IndicatorStatus { good, warning, danger }

class WaterIndicator {
  const WaterIndicator({
    required this.label,
    required this.value,
    required this.status,
    required this.plainDescription,
    this.affectedGroups,
    this.trendLabel,
  });

  final String label;
  final String value;
  final IndicatorStatus status;

  /// One sentence a non-expert can understand.
  final String plainDescription;

  /// Who is most affected if this indicator is outside safe range.
  final String? affectedGroups;

  /// Short trend note, e.g. "Up 18% vs last month".
  final String? trendLabel;
}

class WaterPollutionEvent {
  const WaterPollutionEvent({
    required this.location,
    required this.description,
    required this.status,
    this.affectedPopulation,
    this.recommendedAction,
  });

  final String location;
  final String description;
  final IndicatorStatus status;

  /// Human-readable population impact string.
  final String? affectedPopulation;

  /// Suggested action for operators.
  final String? recommendedAction;
}

class WaterQualitySectorImpact {
  const WaterQualitySectorImpact({
    required this.sectorName,
    required this.headline,
    required this.detail,
    required this.status,
    this.actionRequired = false,
  });

  final String sectorName;
  final String headline;
  final String detail;
  final IndicatorStatus status;
  final bool actionRequired;
}

class WaterQualityData {
  const WaterQualityData({
    required this.indicators,
    required this.pollutionEvents,
    required this.trendLabel,
    required this.trendSpots,
    this.overallStatusLabel = '',
    this.monthDeltaLabel = '',
    this.sectorImpacts = const [],
  });

  final List<WaterIndicator> indicators;
  final List<WaterPollutionEvent> pollutionEvents;
  final String trendLabel;
  final List<(double day, double value)> trendSpots;

  /// Plain-language summary of overall quality status.
  final String overallStatusLabel;

  /// Short trend vs last month, e.g. "Nitrates up +18% vs last month".
  final String monthDeltaLabel;

  /// Sector-by-sector impact breakdown.
  final List<WaterQualitySectorImpact> sectorImpacts;
}
