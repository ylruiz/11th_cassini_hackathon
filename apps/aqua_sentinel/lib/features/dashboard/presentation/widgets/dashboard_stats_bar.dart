import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../alerts/models/alarm_model.dart';
import '../../../alerts/providers/alarms_provider.dart';
import '../../../impact/providers/impact_provider.dart';

class DashboardStatsBar extends ConsumerWidget {
  const DashboardStatsBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(impactSummaryProvider);
    final alarms = ref.watch(activeAlarmsProvider);
    final criticalCount =
        alarms.where((a) => a.severity == AlarmSeverity.critical).length;

    const preventionRoi = '25:1';

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF060E1A),
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          _DashboardStatCard(
            icon: PhosphorIconsRegular.currencyEur,
            label: 'Total Economic Exposure',
            value: '€${summary.totalEconomicImpactEurM.toStringAsFixed(1)}M',
            color: const Color(0xFFFF4757),
            iconColor: const Color(0xFFFF4757),
          ),
          const SizedBox(width: 24),
          _DashboardStatCard(
            icon: PhosphorIconsRegular.users,
            label: 'Population at Risk',
            value: _formatPopulation(summary.totalPopulationAtRisk),
            color: const Color(0xFF00D4FF),
            iconColor: const Color(0xFF00D4FF),
          ),
          const SizedBox(width: 24),
          _DashboardStatCard(
            icon: PhosphorIconsRegular.warningOctagon,
            label: 'Critical Hotspots',
            value:
                '${summary.criticalCount} critical · ${summary.highCount} high',
            color: criticalCount > 0
                ? const Color(0xFFFF4757)
                : const Color(0xFFFF9F43),
            iconColor: criticalCount > 0
                ? const Color(0xFFFF4757)
                : const Color(0xFFFF9F43),
          ),
          const SizedBox(width: 24),
          const _DashboardStatCard(
            icon: PhosphorIconsRegular.trendUp,
            label: 'Prevention ROI',
            value: preventionRoi,
            color: Color(0xFF26de81),
            iconColor: Color(0xFF26de81),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF00D4FF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: const Color(0xFF00D4FF).withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(PhosphorIconsRegular.broadcast,
                    color: Color(0xFF00D4FF), size: 12),
                const SizedBox(width: 6),
                Text(
                  'COPERNICUS SENTINEL-2 / SENTINEL-1',
                  style: GoogleFonts.spaceGrotesk(
                    color: const Color(0xFF00D4FF),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatPopulation(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}k';
    return '$n';
  }
}

class _DashboardStatCard extends StatelessWidget {
  const _DashboardStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.iconColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 10),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white38,
                fontSize: 10,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.spaceGrotesk(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
