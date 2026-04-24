enum AlertSeverity { high, medium, low }

class AlertModel {
  const AlertModel({
    required this.region,
    required this.issueType,
    required this.severity,
    required this.source,
    required this.timestamp,
    required this.description,
  });

  final String region;
  final String issueType;
  final AlertSeverity severity;
  final String source;
  final String timestamp;
  final String description;
}
