import 'package:aqua_sentinel/features/alerts/providers/alarms_provider.dart';
import 'package:aqua_sentinel/features/alerts/models/alarm_model.dart';
import 'package:aqua_sentinel/features/dashboard/presentation/widgets/stat_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class StatsBar extends ConsumerWidget {
  const StatsBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alarms = ref.watch(activeAlarmsProvider);

    final criticalCount =
        alarms.where((a) => a.severity == AlarmSeverity.critical).length;
    final highCount =
        alarms.where((a) => a.severity == AlarmSeverity.high).length;
    final mediumCount =
        alarms.where((a) => a.severity == AlarmSeverity.medium).length;
    final lowCount =
        alarms.where((a) => a.severity == AlarmSeverity.low).length;

    final now = DateTime.now();
    final lastScanTime = DateTime.now().subtract(const Duration(minutes: 2));
    final diffMinutes = now.difference(lastScanTime).inMinutes;
    final lastScanLabel = diffMinutes < 5 ? 'Just now' : '${diffMinutes}m ago';

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF060E1A),
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          StatCard(
            icon: PhosphorIconsRegular.warning,
            label: 'Active Alerts',
            value: alarms.isEmpty
                ? 'None'
                : '${criticalCount > 0 ? '$criticalCount Critical' : ''}${criticalCount > 0 && (highCount > 0 || mediumCount > 0 || lowCount > 0) ? ' · ' : ''}${highCount > 0 ? '$highCount Warnings' : ''}${highCount > 0 && (mediumCount > 0 || lowCount > 0) ? ' · ' : ''}${mediumCount > 0 ? '$mediumCount Moderate' : ''}${mediumCount > 0 && lowCount > 0 ? ' · ' : ''}${lowCount > 0 ? '$lowCount Low' : ''}',
            color: criticalCount > 0
                ? const Color(0xFFFF4757)
                : highCount > 0
                    ? const Color(0xFFFF9F43)
                    : const Color(0xFF00D4FF),
            iconColor: criticalCount > 0
                ? const Color(0xFFFF4757)
                : highCount > 0
                    ? const Color(0xFFFF9F43)
                    : const Color(0xFF00D4FF),
          ),
          const SizedBox(width: 24),
          const StatCard(
            icon: PhosphorIconsRegular.mapPin,
            label: 'Monitored Regions',
            value: '5',
            color: Color(0xFF00D4FF),
            iconColor: Color(0xFF00D4FF),
          ),
          const SizedBox(width: 24),
          StatCard(
            icon: PhosphorIconsRegular.airplaneTilt,
            label: 'Last Copernicus Scan',
            value: lastScanLabel,
            color: const Color(0xFF00D4FF),
            iconColor: const Color(0xFF00D4FF),
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
                const Icon(PhosphorIconsRegular.gitBranch,
                    color: Color(0xFF00D4FF), size: 12),
                const SizedBox(width: 6),
                Text(
                  'SENTINEL-2 L2A',
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
}
