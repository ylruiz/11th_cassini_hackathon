enum IndicatorStatus { good, warning, danger }

class WaterIndicator {
  const WaterIndicator({
    required this.label,
    required this.value,
    required this.status,
    required this.plainDescription,
  });

  final String label;
  final String value;
  final IndicatorStatus status;
  final String plainDescription;
}

class WaterPollutionEvent {
  const WaterPollutionEvent({
    required this.location,
    required this.description,
    required this.status,
  });

  final String location;
  final String description;
  final IndicatorStatus status;
}

class WaterQualityData {
  const WaterQualityData({
    required this.indicators,
    required this.pollutionEvents,
    required this.trendLabel,
    required this.trendSpots,
  });

  final List<WaterIndicator> indicators;
  final List<WaterPollutionEvent> pollutionEvents;
  final String trendLabel;
  final List<(double day, double value)> trendSpots;
}
