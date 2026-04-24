enum WaterIssueType { pollution, flooding, drought, heatStress }

class ScenarioIndicator {
  const ScenarioIndicator({
    required this.label,
    required this.value,
    required this.isPositive,
  });

  final String label;
  final String value;
  final bool isPositive;
}

class WaterIssueScenario {
  const WaterIssueScenario({
    required this.type,
    required this.causeTitle,
    required this.causeText,
    required this.causeFact,
    required this.nowTitle,
    required this.nowText,
    required this.nowIndicators,
    required this.whatIfTitle,
    required this.whatIfText,
    required this.whatIfImpacts,
    required this.source,
  });

  final WaterIssueType type;
  final String causeTitle;
  final String causeText;
  final String causeFact;
  final String nowTitle;
  final String nowText;
  final List<ScenarioIndicator> nowIndicators;
  final String whatIfTitle;
  final String whatIfText;
  final List<String> whatIfImpacts;
  final String source;
}
