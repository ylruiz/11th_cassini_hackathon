import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../data/alarms_provider.dart';
import '../models/alarm_model.dart';

@RoutePage()
class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alarmsAsync = ref.watch(alarmsProvider);
    final activeAlarms = ref.watch(activeAlarmsProvider);
    final soundEnabled = ref.watch(soundEnabledProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: const Color(0xFF060E1A),
        title: Text(
          'ALARMS',
          style: GoogleFonts.spaceGrotesk(
            color: const Color(0xFF00D4FF),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        leading: IconButton(
          icon: Icon(PhosphorIconsRegular.arrowLeft, color: Colors.white54),
          onPressed: () => context.router.maybePop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              soundEnabled
                  ? PhosphorIconsRegular.speakerHigh
                  : PhosphorIconsRegular.speakerSlash,
              color: soundEnabled ? const Color(0xFF00D4FF) : Colors.white38,
            ),
            onPressed: () =>
                ref.read(soundEnabledProvider.notifier).state = !soundEnabled,
          ),
        ],
      ),
      body: alarmsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF00D4FF)),
        ),
        error: (e, _) => Center(
          child: Text(
            'Failed to load alarms',
            style: GoogleFonts.inter(color: Colors.white54),
          ),
        ),
        data: (_) => activeAlarms.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: activeAlarms.length,
                itemBuilder: (context, index) {
                  final alarm = activeAlarms[index];
                  return _AlarmCard(
                    alarm: alarm,
                    onAcknowledge: () {
                      ref.read(alarmsProvider.notifier).acknowledge(alarm.id);
                    },
                    onResolve: () {
                      ref.read(alarmsProvider.notifier).resolve(alarm.id);
                    },
                  ).animate().fadeIn(delay: Duration(milliseconds: index * 80));
                },
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIconsRegular.checkCircle,
            size: 64,
            color: const Color(0xFF00D4FF).withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No active alarms',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All systems operating normally',
            style: GoogleFonts.inter(
              color: Colors.white38,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlarmCard extends StatelessWidget {
  const _AlarmCard({
    required this.alarm,
    required this.onAcknowledge,
    required this.onResolve,
  });

  final Alarm alarm;
  final VoidCallback onAcknowledge;
  final VoidCallback onResolve;

  Color get _severityColor {
    switch (alarm.severity) {
      case AlarmSeverity.critical:
        return const Color(0xFFFF4757);
      case AlarmSeverity.high:
        return const Color(0xFFFF9F43);
      case AlarmSeverity.medium:
        return const Color(0xFFFECA57);
      case AlarmSeverity.low:
        return const Color(0xFF54A0FF);
    }
  }

  IconData get _typeIcon {
    switch (alarm.type) {
      case AlarmType.waterQuality:
        return PhosphorIconsRegular.drop;
      case AlarmType.flood:
        return PhosphorIconsRegular.drop;
      case AlarmType.environmental:
        return PhosphorIconsRegular.leaf;
      case AlarmType.anomaly:
        return PhosphorIconsRegular.warningDiamond;
    }
  }

  String get _typeLabel {
    switch (alarm.type) {
      case AlarmType.waterQuality:
        return 'WATER QUALITY';
      case AlarmType.flood:
        return 'FLOOD';
      case AlarmType.environmental:
        return 'ENVIRONMENTAL';
      case AlarmType.anomaly:
        return 'ANOMALY';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2133),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _severityColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _severityColor.withValues(alpha: 0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _severityColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(_typeIcon, color: _severityColor, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _typeLabel,
                        style: GoogleFonts.spaceGrotesk(
                          color: _severityColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        alarm.triggeredBy,
                        style: GoogleFonts.inter(
                          color: Colors.white38,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _severityColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _severityColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    alarm.severity.name.toUpperCase(),
                    style: GoogleFonts.spaceGrotesk(
                      color: _severityColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alarm.message,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      PhosphorIconsRegular.mapPin,
                      color: Colors.white38,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${alarm.location.latitude.toStringAsFixed(2)}°, ${alarm.location.longitude.toStringAsFixed(2)}°',
                      style: GoogleFonts.inter(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      PhosphorIconsRegular.clock,
                      color: Colors.white38,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(alarm.createdAt),
                      style: GoogleFonts.inter(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (alarm.status == AlarmStatus.active) ...[
                      Expanded(
                        child: GestureDetector(
                          onTap: onAcknowledge,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00D4FF)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF00D4FF)
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'ACKNOWLEDGE',
                                style: GoogleFonts.spaceGrotesk(
                                  color: const Color(0xFF00D4FF),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: GestureDetector(
                        onTap: onResolve,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Center(
                            child: Text(
                              'RESOLVE',
                              style: GoogleFonts.spaceGrotesk(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} UTC';
    } catch (_) {
      return iso;
    }
  }
}

Future<void> showAlarmPanel(BuildContext context) async {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (_, scrollController) => _AlarmPanelSheet(
        scrollController: scrollController,
      ),
    ),
  );
}

class _AlarmPanelSheet extends ConsumerWidget {
  const _AlarmPanelSheet({required this.scrollController});
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAlarms = ref.watch(activeAlarmsProvider);
    final soundEnabled = ref.watch(soundEnabledProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D1B2A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: Color(0xFF00D4FF), width: 1),
          left: BorderSide(color: Color(0xFF00D4FF), width: 1),
          right: BorderSide(color: Color(0xFF00D4FF), width: 1),
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {},
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              children: [
                Text(
                  'ACTIVE ALARMS',
                  style: GoogleFonts.spaceGrotesk(
                    color: const Color(0xFF00D4FF),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
                const Spacer(),
                if (activeAlarms.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4757).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFFF4757).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      '${activeAlarms.length}',
                      style: GoogleFonts.spaceGrotesk(
                        color: const Color(0xFFFF4757),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    soundEnabled
                        ? PhosphorIconsRegular.speakerHigh
                        : PhosphorIconsRegular.speakerSlash,
                    color:
                        soundEnabled ? const Color(0xFF00D4FF) : Colors.white38,
                    size: 18,
                  ),
                  onPressed: () => ref
                      .read(soundEnabledProvider.notifier)
                      .state = !soundEnabled,
                ),
              ],
            ),
          ),
          Expanded(
            child: activeAlarms.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          PhosphorIconsRegular.checkCircle,
                          size: 48,
                          color: const Color(0xFF00D4FF).withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No active alarms',
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white54,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'All systems operating normally',
                          style: GoogleFonts.inter(
                            color: Colors.white30,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: activeAlarms.length,
                    itemBuilder: (context, index) {
                      final alarm = activeAlarms[index];
                      return _CompactAlarmCard(
                        alarm: alarm,
                        onAcknowledge: () {
                          ref
                              .read(alarmsProvider.notifier)
                              .acknowledge(alarm.id);
                        },
                        onResolve: () {
                          ref.read(alarmsProvider.notifier).resolve(alarm.id);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _CompactAlarmCard extends StatelessWidget {
  const _CompactAlarmCard({
    required this.alarm,
    required this.onAcknowledge,
    required this.onResolve,
  });

  final Alarm alarm;
  final VoidCallback onAcknowledge;
  final VoidCallback onResolve;

  Color get _severityColor {
    switch (alarm.severity) {
      case AlarmSeverity.critical:
        return const Color(0xFFFF4757);
      case AlarmSeverity.high:
        return const Color(0xFFFF9F43);
      case AlarmSeverity.medium:
        return const Color(0xFFFECA57);
      case AlarmSeverity.low:
        return const Color(0xFF54A0FF);
    }
  }

  IconData get _typeIcon {
    switch (alarm.type) {
      case AlarmType.waterQuality:
        return PhosphorIconsRegular.drop;
      case AlarmType.flood:
        return PhosphorIconsRegular.drop;
      case AlarmType.environmental:
        return PhosphorIconsRegular.leaf;
      case AlarmType.anomaly:
        return PhosphorIconsRegular.warningDiamond;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2133),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _severityColor.withValues(alpha: 0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onAcknowledge,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _severityColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(_typeIcon, color: _severityColor, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alarm.message,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(alarm.createdAt),
                        style: GoogleFonts.inter(
                          color: Colors.white38,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onResolve,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D4FF).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      PhosphorIconsRegular.check,
                      color: Color(0xFF00D4FF),
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} UTC';
    } catch (_) {
      return iso;
    }
  }
}
