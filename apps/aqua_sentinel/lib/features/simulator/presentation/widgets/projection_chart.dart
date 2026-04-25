import 'package:aqua_sentinel/features/simulator/presentation/widgets/chart_data.dart';
import 'package:aqua_sentinel/features/simulator/presentation/widgets/legend_dot.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/water_issue_scenario.dart';

class ProjectionChart extends StatelessWidget {
  const ProjectionChart({
    super.key,
    required this.issue,
    required this.accentColor,
  });

  final WaterIssueType issue;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final data = chartDataFor(issue);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.fromLTRB(12, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'PROJECTION — ${data.metricLabel.toUpperCase()}',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white54,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              LegendDot(color: Colors.white38, label: 'No action'),
              const SizedBox(width: 10),
              LegendDot(color: accentColor, label: 'With action'),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 170,
            child: LineChart(
              LineChartData(
                minX: -9,
                maxX: 10,
                minY: data.minY,
                maxY: data.maxY,
                clipData: const FlClipData.all(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  verticalInterval: 3,
                  horizontalInterval: (data.maxY - data.minY) / 4,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.white.withValues(alpha: 0.06),
                    strokeWidth: 1,
                  ),
                  getDrawingVerticalLine: (v) => FlLine(
                    color: v == 0
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.04),
                    strokeWidth: v == 0 ? 1.5 : 1,
                    dashArray: v == 0 ? null : [4, 4],
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      interval: (data.maxY - data.minY) / 4,
                      getTitlesWidget: (v, _) => Text(
                        v.toInt().toString(),
                        style: GoogleFonts.spaceGrotesk(
                            color: Colors.white30, fontSize: 9),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 3,
                      getTitlesWidget: (v, _) {
                        if (v == 0) {
                          return Text(
                            'NOW',
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white54,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                            ),
                          );
                        }
                        return Text(
                          (2024 + v.toInt()).toString(),
                          style: GoogleFonts.spaceGrotesk(
                              color: Colors.white24, fontSize: 8),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                extraLinesData: ExtraLinesData(
                  verticalLines: [
                    VerticalLine(
                      x: 0,
                      color: Colors.white.withValues(alpha: 0.25),
                      strokeWidth: 1.5,
                    ),
                  ],
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: data.historical,
                    isCurved: true,
                    color: Colors.white38,
                    barWidth: 2,
                    dotData: FlDotData(
                      show: true,
                      checkToShowDot: (spot, _) => spot.x == 0,
                      getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                          radius: 4, color: Colors.white, strokeWidth: 0),
                    ),
                    belowBarData: BarAreaData(show: false),
                  ),
                  LineChartBarData(
                    spots: data.noAction,
                    isCurved: true,
                    color: const Color(0xFFFF6B6B).withValues(alpha: 0.7),
                    barWidth: 2,
                    dashArray: [5, 5],
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFFFF6B6B).withValues(alpha: 0.05),
                    ),
                  ),
                  LineChartBarData(
                    spots: data.withAction,
                    isCurved: true,
                    color: accentColor,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          accentColor.withValues(alpha: 0.18),
                          accentColor.withValues(alpha: 0.02),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              '← past  ·  ${data.unit}  ·  future →',
              style: GoogleFonts.inter(color: Colors.white24, fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }
}
