import 'package:auto_route/auto_route.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../data/water_quality_provider.dart';
import '../models/water_quality_data.dart';

@RoutePage()
class WaterQualityScreen extends ConsumerWidget {
  const WaterQualityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(waterQualityProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.surface,
        title: Row(
          children: [
            PhosphorIcon(PhosphorIcons.testTube(), color: cs.primary),
            const SizedBox(width: 8),
            const Text('Water Quality'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _IndicatorRow(indicators: data.indicators)
              .animate()
              .fadeIn(duration: 400.ms),
          const SizedBox(height: 20),
          _TrendChart(
            label: data.trendLabel,
            spots: data.trendSpots,
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 20),
          _PollutionList(events: data.pollutionEvents)
              .animate()
              .fadeIn(delay: 400.ms),
        ],
      ),
    );
  }
}

// ─── Indicator row ────────────────────────────────────────────────────────────

class _IndicatorRow extends StatelessWidget {
  const _IndicatorRow({required this.indicators});
  final List<WaterIndicator> indicators;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: indicators
          .map((ind) => SizedBox(
                width: (MediaQuery.sizeOf(context).width - 52) / 3,
                child: _IndicatorCard(indicator: ind),
              ))
          .toList(),
    );
  }
}

class _IndicatorCard extends StatelessWidget {
  const _IndicatorCard({required this.indicator});
  final WaterIndicator indicator;

  Color _color(BuildContext context) => switch (indicator.status) {
        IndicatorStatus.good => Colors.greenAccent,
        IndicatorStatus.warning => Colors.orangeAccent,
        IndicatorStatus.danger => Theme.of(context).colorScheme.error,
      };

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              indicator.value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              indicator.label,
              style: const TextStyle(fontSize: 11),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              indicator.plainDescription,
              style: GoogleFonts.inter(
                  fontSize: 10,
                  color: Colors.white38,
                  height: 1.4),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Trend chart ──────────────────────────────────────────────────────────────

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.label, required this.spots});
  final String label;
  final List<(double, double)> spots;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final chartSpots =
        spots.map((p) => FlSpot(p.$1, p.$2)).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Higher is worse — safe limit is 50 mg/L',
              style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: chartSpots,
                      isCurved: true,
                      color: cs.primary,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: cs.primary.withValues(alpha: 0.15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Pollution events list ────────────────────────────────────────────────────

class _PollutionList extends StatelessWidget {
  const _PollutionList({required this.events});
  final List<WaterPollutionEvent> events;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Events',
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...events.map(
          (event) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(
                PhosphorIcons.mapPin(),
                color: _statusColor(context, event.status),
              ),
              title: Text(
                event.location,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14),
              ),
              subtitle: Text(
                event.description,
                style: GoogleFonts.inter(fontSize: 12, color: Colors.white54),
              ),
              trailing: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _statusColor(context, event.status),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _statusColor(BuildContext context, IndicatorStatus status) =>
      switch (status) {
        IndicatorStatus.good => Colors.greenAccent,
        IndicatorStatus.warning => Colors.orangeAccent,
        IndicatorStatus.danger => Theme.of(context).colorScheme.error,
      };
}
