import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../models/environmental_analysis.dart';
import '../../providers/monitoring_provider.dart';
import 'analysis_shared.dart';

class SimulateTab extends ConsumerWidget {
  const SimulateTab({super.key, this.riskTimeline});

  final RiskTimeline? riskTimeline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeline = riskTimeline;
    if (timeline == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Future risk timeline is available for Inn River in this MVP.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const _WeightsKnobsCard(),
        const SizedBox(height: 12),
        _HistoryTrendCard(label: timeline.waterBodyName),
        const SizedBox(height: 12),
        _HydrologyContextCard(evidence: timeline.evidence),
        const SizedBox(height: 12),
        _ScenarioTimelineCard(projections: timeline.projections),
        const SizedBox(height: 12),
        const _ScenarioCaveatCard(),
      ],
    );
  }
}

class _HistoryTrendCard extends ConsumerWidget {
  const _HistoryTrendCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(aoiHistoryProvider(label));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF081525),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF74B9FF).withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const PhosphorIcon(
                PhosphorIconsRegular.chartLine,
                color: Color(0xFF74B9FF),
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '24-MONTH HISTORY',
                  style: GoogleFonts.spaceGrotesk(
                    color: const Color(0xFF74B9FF),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Past snowmelt and EFAS discharge anomaly feeding the projections.',
            style: GoogleFonts.inter(
              color: Colors.white60,
              fontSize: 10,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          historyAsync.when(
            data: (history) {
              if (history == null || history.points.isEmpty) {
                return _historyEmpty(
                  'No baked history for this AOI yet. Use the Inn Valley or '
                  'Oetztal Alps presets to see the trend.',
                );
              }
              return _HistoryChart(history: history);
            },
            loading: () => const SizedBox(
              height: 180,
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF74B9FF)),
              ),
            ),
            error: (_, __) => _historyEmpty(
              'Could not load history. Backend may still be warming up.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyEmpty(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        message,
        style: GoogleFonts.inter(
          color: Colors.white38,
          fontSize: 11,
          height: 1.4,
        ),
      ),
    );
  }
}

class _HistoryChart extends StatelessWidget {
  const _HistoryChart({required this.history});

  final AoiHistory history;

  static const Color _snowColor = Color(0xFF74B9FF);
  static const Color _efasColor = Color(0xFF00D4FF);
  static const int _projectionMonths = 24;

  @override
  Widget build(BuildContext context) {
    final points = history.points;

    // Linear regression on observed series. We project the trend forward by
    // _projectionMonths to give the user a "where is this heading?" cue and
    // tie the past-data plot directly into the 10/20/50-year scenario cards.
    final snowFit = _linearFit(
      [for (var i = 0; i < points.length; i++) i.toDouble()],
      [for (final p in points) p.ndsiSnowFraction],
    );
    final efasFit = _linearFit(
      [for (var i = 0; i < points.length; i++) i.toDouble()],
      [for (final p in points) p.efasAnomalyPercent],
    );

    // Project EFAS values up front so the y-axis can absorb them without
    // clipping the dashed forecast line.
    final projectedEfas = <double>[];
    for (var j = 1; j <= _projectionMonths; j++) {
      final x = (points.length - 1 + j).toDouble();
      projectedEfas.add(efasFit.intercept + efasFit.slope * x);
    }

    final efasObservedMin = points
        .map((p) => p.efasAnomalyPercent)
        .reduce((a, b) => a < b ? a : b);
    final efasObservedMax = points
        .map((p) => p.efasAnomalyPercent)
        .reduce((a, b) => a > b ? a : b);
    final efasMinAll = [efasObservedMin, ...projectedEfas]
        .reduce((a, b) => a < b ? a : b);
    final efasMaxAll = [efasObservedMax, ...projectedEfas]
        .reduce((a, b) => a > b ? a : b);
    final efasRange =
        (efasMaxAll - efasMinAll).abs() < 1e-6 ? 1.0 : (efasMaxAll - efasMinAll);
    final efasPad = efasRange * 0.15;
    final yMin = efasMinAll - efasPad;
    final yMax = efasMaxAll + efasPad;

    final snowSpots = <FlSpot>[];
    final efasSpots = <FlSpot>[];
    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      // Map NDSI 0-1 onto the EFAS y-axis range so both series share an axis,
      // while the legend below makes both scales explicit.
      final snowMapped = yMin + p.ndsiSnowFraction * (yMax - yMin);
      snowSpots.add(FlSpot(i.toDouble(), snowMapped));
      efasSpots.add(FlSpot(i.toDouble(), p.efasAnomalyPercent));
    }

    // Anchor each projection at the last observed point so the dashed line
    // visually peels off the historical curve.
    final lastObservedX = (points.length - 1).toDouble();
    final lastPoint = points.last;
    final snowProjSpots = <FlSpot>[
      FlSpot(lastObservedX, yMin + lastPoint.ndsiSnowFraction * (yMax - yMin)),
    ];
    final efasProjSpots = <FlSpot>[
      FlSpot(lastObservedX, lastPoint.efasAnomalyPercent),
    ];
    for (var j = 1; j <= _projectionMonths; j++) {
      final x = (points.length - 1 + j).toDouble();
      final ndsiRaw = (snowFit.intercept + snowFit.slope * x).clamp(0.0, 1.0);
      final efasRaw = efasFit.intercept + efasFit.slope * x;
      snowProjSpots.add(FlSpot(x, yMin + ndsiRaw * (yMax - yMin)));
      efasProjSpots.add(FlSpot(x, efasRaw));
    }

    final maxX = (points.length - 1 + _projectionMonths).toDouble();
    final lastObservedMonth = points.last.month;

    String? monthLabelAt(int i) {
      if (i < 0) return null;
      if (i < points.length) return points[i].month;
      return _addMonths(lastObservedMonth, i - (points.length - 1));
    }

    final ndsiSlopePerYear = snowFit.slope * 12.0;
    final efasSlopePerYear = efasFit.slope * 12.0;
    final ndsiTrendLabel = ndsiSlopePerYear >= 0
        ? '+${ndsiSlopePerYear.toStringAsFixed(2)}/yr'
        : '${ndsiSlopePerYear.toStringAsFixed(2)}/yr';
    final efasTrendLabel = efasSlopePerYear >= 0
        ? '+${efasSlopePerYear.toStringAsFixed(1)} pp/yr'
        : '${efasSlopePerYear.toStringAsFixed(1)} pp/yr';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: maxX,
              minY: yMin,
              maxY: yMax,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: (yMax - yMin) / 4,
                getDrawingHorizontalLine: (_) => const FlLine(
                  color: Colors.white12,
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              extraLinesData: ExtraLinesData(
                verticalLines: [
                  VerticalLine(
                    x: lastObservedX,
                    color: Colors.white24,
                    strokeWidth: 1,
                    dashArray: const [4, 3],
                    label: VerticalLineLabel(
                      show: true,
                      alignment: Alignment.topRight,
                      padding: const EdgeInsets.only(right: 4, top: 2),
                      style: GoogleFonts.inter(
                        color: Colors.white54,
                        fontSize: 9,
                      ),
                      labelResolver: (_) => 'now',
                    ),
                  ),
                ],
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  axisNameWidget: Text(
                    'EFAS %',
                    style: GoogleFonts.inter(color: _efasColor, fontSize: 9),
                  ),
                  axisNameSize: 14,
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: (yMax - yMin) / 4,
                    getTitlesWidget: (value, _) => Text(
                      value.toStringAsFixed(0),
                      style: GoogleFonts.inter(
                        color: _efasColor,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ),
                leftTitles: AxisTitles(
                  axisNameWidget: Text(
                    'NDSI',
                    style: GoogleFonts.inter(color: _snowColor, fontSize: 9),
                  ),
                  axisNameSize: 14,
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: (yMax - yMin) / 4,
                    getTitlesWidget: (value, _) {
                      final ndsi = (value - yMin) / (yMax - yMin);
                      if (ndsi < -0.05 || ndsi > 1.05) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        ndsi.clamp(0, 1).toStringAsFixed(1),
                        style: GoogleFonts.inter(
                          color: _snowColor,
                          fontSize: 9,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    interval:
                        ((points.length + _projectionMonths) / 6).ceilToDouble().clamp(1, 18),
                    getTitlesWidget: (value, _) {
                      final i = value.round();
                      final label = monthLabelAt(i);
                      if (label == null) return const SizedBox.shrink();
                      final mm = label.length >= 7 ? label.substring(5, 7) : label;
                      final yy = label.length >= 4 ? label.substring(2, 4) : '';
                      final isProjected = i >= points.length;
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '$mm/$yy',
                          style: GoogleFonts.inter(
                            color: isProjected
                                ? Colors.white24
                                : Colors.white38,
                            fontSize: 9,
                            fontStyle: isProjected
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => const Color(0xFF0D1B2A),
                  tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 6),
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final i = spot.x.round();
                      final isSnowSeries =
                          spot.barIndex == 0 || spot.barIndex == 2;
                      final isProjection = spot.barIndex >= 2;
                      final color = isSnowSeries ? _snowColor : _efasColor;

                      if (!isProjection) {
                        if (i < 0 || i >= points.length) return null;
                        final p = points[i];
                        return LineTooltipItem(
                          isSnowSeries
                              ? '${p.month}\nNDSI ${p.ndsiSnowFraction.toStringAsFixed(2)}'
                              : '${p.month}\nEFAS ${p.efasAnomalyPercent.toStringAsFixed(0)}%',
                          GoogleFonts.spaceGrotesk(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }

                      final label = monthLabelAt(i) ?? '';
                      if (isSnowSeries) {
                        final ndsi = (snowFit.intercept +
                                snowFit.slope * spot.x)
                            .clamp(0.0, 1.0);
                        return LineTooltipItem(
                          '$label  (proj.)\nNDSI ~${ndsi.toStringAsFixed(2)}',
                          GoogleFonts.spaceGrotesk(
                            color: color.withValues(alpha: 0.85),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.italic,
                          ),
                        );
                      }
                      final efas = efasFit.intercept + efasFit.slope * spot.x;
                      return LineTooltipItem(
                        '$label  (proj.)\nEFAS ~${efas.toStringAsFixed(0)}%',
                        GoogleFonts.spaceGrotesk(
                          color: color.withValues(alpha: 0.85),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.italic,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: snowSpots,
                  isCurved: true,
                  curveSmoothness: 0.18,
                  preventCurveOverShooting: true,
                  color: _snowColor,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: _snowColor.withValues(alpha: 0.08),
                  ),
                ),
                LineChartBarData(
                  spots: efasSpots,
                  isCurved: true,
                  curveSmoothness: 0.18,
                  preventCurveOverShooting: true,
                  color: _efasColor,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                ),
                LineChartBarData(
                  spots: snowProjSpots,
                  isCurved: false,
                  color: _snowColor.withValues(alpha: 0.85),
                  barWidth: 1.6,
                  dashArray: const [6, 4],
                  dotData: const FlDotData(show: false),
                ),
                LineChartBarData(
                  spots: efasProjSpots,
                  isCurved: false,
                  color: _efasColor.withValues(alpha: 0.85),
                  barWidth: 1.6,
                  dashArray: const [6, 4],
                  dotData: const FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Wrap(
          spacing: 14,
          runSpacing: 4,
          children: [
            _LegendDot(
              color: _snowColor,
              label: 'NDSI snow fraction',
            ),
            _LegendDot(
              color: _efasColor,
              label: 'EFAS anomaly (%)',
            ),
            _LegendDot(
              color: Colors.white60,
              label: 'Linear projection (24 mo)',
              dashed: true,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Trend: NDSI $ndsiTrendLabel  ·  EFAS $efasTrendLabel  '
          '(least-squares on observed series)',
          style: GoogleFonts.inter(
            color: Colors.white60,
            fontSize: 10,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          history.source,
          style: GoogleFonts.inter(
            color: Colors.white38,
            fontSize: 9,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

class _LinearFit {
  const _LinearFit({required this.slope, required this.intercept});

  final double slope;
  final double intercept;
}

_LinearFit _linearFit(List<double> xs, List<double> ys) {
  final n = xs.length;
  if (n < 2 || n != ys.length) {
    return const _LinearFit(slope: 0, intercept: 0);
  }
  double sumX = 0;
  double sumY = 0;
  double sumXY = 0;
  double sumXX = 0;
  for (var i = 0; i < n; i++) {
    final x = xs[i];
    final y = ys[i];
    sumX += x;
    sumY += y;
    sumXY += x * y;
    sumXX += x * x;
  }
  final denom = n * sumXX - sumX * sumX;
  final slope =
      denom.abs() < 1e-9 ? 0.0 : (n * sumXY - sumX * sumY) / denom;
  final intercept = (sumY - slope * sumX) / n;
  return _LinearFit(slope: slope, intercept: intercept);
}

String _addMonths(String yyyymm, int delta) {
  final parts = yyyymm.split('-');
  if (parts.length < 2) return yyyymm;
  final year = int.tryParse(parts[0]) ?? 0;
  final month = int.tryParse(parts[1]) ?? 1;
  final total = (year * 12 + (month - 1)) + delta;
  final newYear = total ~/ 12;
  final newMonth = total % 12 + 1;
  return '${newYear.toString().padLeft(4, '0')}-'
      '${newMonth.toString().padLeft(2, '0')}';
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
    this.dashed = false,
  });

  final Color color;
  final String label;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (dashed)
          CustomPaint(
            size: const Size(14, 2),
            painter: _DashedLinePainter(color: color),
          )
        else
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white60,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    const dashWidth = 3.0;
    const gapWidth = 2.0;
    var x = 0.0;
    final y = size.height / 2;
    while (x < size.width) {
      canvas.drawLine(Offset(x, y), Offset(x + dashWidth, y), paint);
      x += dashWidth + gapWidth;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _WeightsKnobsCard extends ConsumerStatefulWidget {
  const _WeightsKnobsCard();

  @override
  ConsumerState<_WeightsKnobsCard> createState() => _WeightsKnobsCardState();
}

class _WeightsKnobsCardState extends ConsumerState<_WeightsKnobsCard> {
  Timer? _debounce;
  late RiskWeights _draft;

  @override
  void initState() {
    super.initState();
    _draft = ref.read(riskWeightsProvider);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onWeightChanged(RiskWeights next) {
    setState(() => _draft = next);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      ref.read(riskWeightsProvider.notifier).state = next;
    });
  }

  void _reset() {
    _debounce?.cancel();
    setState(() => _draft = RiskWeights.defaults);
    ref.read(riskWeightsProvider.notifier).state = RiskWeights.defaults;
  }

  @override
  Widget build(BuildContext context) {
    final isDefault = _draft.isDefault;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF081525),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isDefault ? const Color(0xFF00D4FF) : Colors.amberAccent)
              .withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                PhosphorIconsRegular.slidersHorizontal,
                color: isDefault ? const Color(0xFF00D4FF) : Colors.amberAccent,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'DRIVER WEIGHTS',
                  style: GoogleFonts.spaceGrotesk(
                    color: isDefault
                        ? const Color(0xFF00D4FF)
                        : Colors.amberAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
              if (!isDefault)
                GestureDetector(
                  onTap: _reset,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.amberAccent.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      'RESET',
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.amberAccent,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isDefault
                ? 'Drag any slider to stress-test how a stronger or weaker channel changes the 10/20/50-year scenario.'
                : 'User-tuned scenario. Reset to compare against the canonical evidence-driven baseline.',
            style: GoogleFonts.inter(
              color: Colors.white60,
              fontSize: 10,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          _WeightSlider(
            label: 'Snow / NDSI',
            icon: PhosphorIconsRegular.snowflake,
            color: const Color(0xFF74B9FF),
            value: _draft.snow,
            onChanged: (v) => _onWeightChanged(_draft.copyWith(snow: v)),
          ),
          _WeightSlider(
            label: 'Surface water (SAR + NDWI)',
            icon: PhosphorIconsRegular.drop,
            color: const Color(0xFF00D4FF),
            value: _draft.surfaceWater,
            onChanged: (v) =>
                _onWeightChanged(_draft.copyWith(surfaceWater: v)),
          ),
          _WeightSlider(
            label: 'Vegetation buffering',
            icon: PhosphorIconsRegular.plant,
            color: Colors.greenAccent,
            value: _draft.vegetation,
            onChanged: (v) => _onWeightChanged(_draft.copyWith(vegetation: v)),
          ),
          _WeightSlider(
            label: 'EFAS / Lisflood discharge',
            icon: PhosphorIconsRegular.waves,
            color: Colors.tealAccent,
            value: _draft.hydrology,
            onChanged: (v) => _onWeightChanged(_draft.copyWith(hydrology: v)),
          ),
        ],
      ),
    );
  }
}

class _WeightSlider extends StatelessWidget {
  const _WeightSlider({
    required this.label,
    required this.icon,
    required this.color,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final Color color;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final emphasized = (value - 1.0).abs() >= 0.01;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 8),
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                activeTrackColor: color.withValues(alpha: 0.85),
                inactiveTrackColor: Colors.white12,
                thumbColor: color,
                overlayColor: color.withValues(alpha: 0.18),
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 7),
              ),
              child: Slider(
                value: value.clamp(0.0, 2.0),
                min: 0.0,
                max: 2.0,
                divisions: 20,
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 38,
            child: Text(
              '${value.toStringAsFixed(1)}x',
              textAlign: TextAlign.right,
              style: GoogleFonts.spaceGrotesk(
                color: emphasized ? color : Colors.white60,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HydrologyContextCard extends StatelessWidget {
  const _HydrologyContextCard({required this.evidence});

  final List<RiskEvidenceMetric> evidence;

  @override
  Widget build(BuildContext context) {
    final hydrologyEvidence = evidence.where((metric) {
      final text = '${metric.label} ${metric.source}'.toLowerCase();
      return text.contains('efas') || text.contains('lisflood');
    }).toList();

    if (hydrologyEvidence.isEmpty) {
      return const TabIntroCard(
        title: 'Hydrology forecast context',
        body:
            'EFAS/Lisflood is not connected for this AOI yet. Scenario pressure uses satellite evidence and stress assumptions.',
        color: Colors.orangeAccent,
      );
    }

    final metric = hydrologyEvidence.first;
    final valueText = metric.unit.isEmpty
        ? metric.value.toStringAsFixed(2)
        : '${metric.value.toStringAsFixed(1)}${metric.unit}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF081525),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'HYDROLOGY CONTEXT',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.greenAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Text(
                valueText,
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.greenAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Cached EFAS/Lisflood seasonal discharge anomaly. Used as context, not a live warning.',
            style: GoogleFonts.inter(
              color: Colors.white54,
              fontSize: 10,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScenarioTimelineCard extends StatelessWidget {
  const _ScenarioTimelineCard({required this.projections});

  final List<RiskProjection> projections;

  @override
  Widget build(BuildContext context) {
    final futureProjections = projections
        .where((projection) => projection.horizonYears > 0)
        .toList(growable: false);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF081525),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFF00D4FF).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SCENARIO TIMELINE',
            style: GoogleFonts.spaceGrotesk(
              color: const Color(0xFF00D4FF),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          const _ScenarioHeaderRow(),
          const SizedBox(height: 8),
          ...futureProjections.map((projection) {
            return _ScenarioTimelineRow(projection: projection);
          }),
        ],
      ),
    );
  }
}

class _ScenarioHeaderRow extends StatelessWidget {
  const _ScenarioHeaderRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _ScenarioHeaderCell(label: 'Year', flex: 2),
        _ScenarioHeaderCell(label: 'Flood'),
        _ScenarioHeaderCell(label: 'Slope'),
        _ScenarioHeaderCell(label: 'Runoff'),
        _ScenarioHeaderCell(label: 'Inund.'),
      ],
    );
  }
}

class _ScenarioHeaderCell extends StatelessWidget {
  const _ScenarioHeaderCell({required this.label, this.flex = 1});

  final String label;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: Colors.white38,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ScenarioTimelineRow extends StatelessWidget {
  const _ScenarioTimelineRow({required this.projection});

  final RiskProjection projection;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: severityColor(projection.floodRisk).withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              projection.label,
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _ScenarioValue(
            value: projection.floodRisk.displayName,
            color: severityColor(projection.floodRisk),
          ),
          _ScenarioValue(
            value: projection.landslideRisk.displayName,
            color: severityColor(projection.landslideRisk),
          ),
          _ScenarioValue(
            value: '+${projection.dischargeChangePercent.toStringAsFixed(0)}%',
            color: const Color(0xFF00D4FF),
          ),
          _ScenarioValue(
            value:
                '+${projection.floodProneAreaChangePercent.toStringAsFixed(0)}%',
            color: Colors.orangeAccent,
          ),
        ],
      ),
    );
  }
}

class _ScenarioValue extends StatelessWidget {
  const _ScenarioValue({required this.value, required this.color});

  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.spaceGrotesk(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ScenarioCaveatCard extends StatelessWidget {
  const _ScenarioCaveatCard();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Scenario pressure, not an official forecast. Uses Sentinel evidence plus cached EFAS context where available.',
      style: GoogleFonts.inter(
        color: Colors.white38,
        fontSize: 10,
        height: 1.35,
      ),
    );
  }
}
