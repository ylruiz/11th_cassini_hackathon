import 'package:fl_chart/fl_chart.dart';

import '../../models/water_issue_scenario.dart';

class ChartData {
  const ChartData({
    required this.metricLabel,
    required this.unit,
    required this.historical,
    required this.noAction,
    required this.withAction,
    required this.minY,
    required this.maxY,
  });

  final String metricLabel;
  final String unit;
  final List<FlSpot> historical;
  final List<FlSpot> noAction;
  final List<FlSpot> withAction;
  final double minY;
  final double maxY;
}

ChartData chartDataFor(WaterIssueType issue) => switch (issue) {
      WaterIssueType.pollution => const ChartData(
          metricLabel: 'Nitrate Level',
          unit: 'mg/L',
          historical: [
            FlSpot(-9, 65),
            FlSpot(-6, 58),
            FlSpot(-3, 52),
            FlSpot(0, 48),
          ],
          noAction: [
            FlSpot(0, 48),
            FlSpot(3, 55),
            FlSpot(6, 63),
            FlSpot(10, 74),
          ],
          withAction: [
            FlSpot(0, 48),
            FlSpot(3, 40),
            FlSpot(6, 32),
            FlSpot(10, 22),
          ],
          minY: 0,
          maxY: 85,
        ),
      WaterIssueType.flooding => const ChartData(
          metricLabel: 'Flooded Area',
          unit: 'km²',
          historical: [
            FlSpot(-9, 120),
            FlSpot(-6, 190),
            FlSpot(-3, 260),
            FlSpot(0, 340),
          ],
          noAction: [
            FlSpot(0, 340),
            FlSpot(3, 410),
            FlSpot(6, 490),
            FlSpot(10, 590),
          ],
          withAction: [
            FlSpot(0, 340),
            FlSpot(3, 290),
            FlSpot(6, 230),
            FlSpot(10, 170),
          ],
          minY: 0,
          maxY: 650,
        ),
      WaterIssueType.drought => const ChartData(
          metricLabel: 'Reservoir Capacity',
          unit: '%',
          historical: [
            FlSpot(-9, 72),
            FlSpot(-6, 64),
            FlSpot(-3, 55),
            FlSpot(0, 42),
          ],
          noAction: [
            FlSpot(0, 42),
            FlSpot(3, 34),
            FlSpot(6, 25),
            FlSpot(10, 15),
          ],
          withAction: [
            FlSpot(0, 42),
            FlSpot(3, 50),
            FlSpot(6, 60),
            FlSpot(10, 72),
          ],
          minY: 0,
          maxY: 100,
        ),
      WaterIssueType.heatStress => const ChartData(
          metricLabel: 'Water Temperature',
          unit: '°C',
          historical: [
            FlSpot(-9, 20.0),
            FlSpot(-6, 21.5),
            FlSpot(-3, 23.0),
            FlSpot(0, 24.0),
          ],
          noAction: [
            FlSpot(0, 24.0),
            FlSpot(3, 25.5),
            FlSpot(6, 27.0),
            FlSpot(10, 29.0),
          ],
          withAction: [
            FlSpot(0, 24.0),
            FlSpot(3, 23.0),
            FlSpot(6, 22.0),
            FlSpot(10, 21.0),
          ],
          minY: 14,
          maxY: 32,
        ),
      WaterIssueType.snowMelt => const ChartData(
          metricLabel: 'River Flow',
          unit: 'm³/s',
          historical: [
            FlSpot(-9, 180),
            FlSpot(-6, 220),
            FlSpot(-3, 280),
            FlSpot(0, 340),
          ],
          noAction: [
            FlSpot(0, 340),
            FlSpot(3, 380),
            FlSpot(6, 290),
            FlSpot(10, 180),
          ],
          withAction: [
            FlSpot(0, 340),
            FlSpot(3, 320),
            FlSpot(6, 280),
            FlSpot(10, 240),
          ],
          minY: 100,
          maxY: 450,
        ),
    };
