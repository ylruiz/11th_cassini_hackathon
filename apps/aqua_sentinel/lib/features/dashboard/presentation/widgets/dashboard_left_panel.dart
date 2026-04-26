import 'package:aqua_sentinel/features/alerts/providers/alarms_provider.dart';
import 'package:aqua_sentinel/features/alerts/models/alarm_model.dart';
import 'package:aqua_sentinel/features/water_quality/data/water_quality_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class DashboardLeftPanel extends ConsumerWidget {
  const DashboardLeftPanel({
    super.key,
    required this.onNavigateToMonitoring,
    required this.onNavigateToQuality,
  });

  final void Function(LatLng? coord) onNavigateToMonitoring;
  final void Function(String? bodyId) onNavigateToQuality;

  static const _featuredRivers = [
    ('danube-delta', 'Danube Delta'),
    ('guadalquivir-river', 'Guadalquivir R.'),
    ('maas-river', 'Maas River'),
    ('maritsa-river', 'Maritsa River'),
    ('inn-river', 'Inn River'),
    ('po-river', 'Po River'),
    ('tisza-river', 'Tisza River'),
    ('vistula-river', 'Vistula River'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAlarms = ref.watch(activeAlarmsProvider);

    return Container(
      width: 256,
      decoration: BoxDecoration(
        color: const Color(0xFF060E1A).withValues(alpha: 0.92),
        border: const Border(left: BorderSide(color: Colors.white10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(-4, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PanelHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SuctionHeader(
                      title: 'ACTIVE ALARMS', count: activeAlarms.length),
                  const SizedBox(height: 8),
                  if (activeAlarms.isEmpty)
                    const EmptyState(message: 'No active alarms')
                  else
                    ...activeAlarms.map((a) => AlarmCard(
                          alarm: a,
                          onNavigateToMonitoring: (LatLng? coord) {},
                        )),
                  const SizedBox(height: 4),
                  ActionButton(
                    label: 'View all on monitoring map',
                    icon: PhosphorIconsRegular.mapTrifold,
                    onTap: () => onNavigateToMonitoring(null),
                  ),
                  const SizedBox(height: 16),
                  const SuctionHeader(title: 'RIVER HEALTH', count: null),
                  const SizedBox(height: 8),
                  ..._featuredRivers.map(
                    (r) => RiverRow(
                        id: r.$1,
                        name: r.$2,
                        onNavigateToQuality: onNavigateToQuality),
                  ),
                  const SizedBox(height: 4),
                  ActionButton(
                    label: 'Open water quality report',
                    icon: PhosphorIconsRegular.drop,
                    onTap: () => onNavigateToQuality(null),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SuctionHeader extends StatelessWidget {
  const SuctionHeader({
    super.key,
    required this.title,
    required this.count,
  });

  final String title;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white38,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: count! > 0
                  ? const Color(0xFFFF4757).withValues(alpha: 0.15)
                  : Colors.white10,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.spaceGrotesk(
                color: count! > 0 ? const Color(0xFFFF4757) : Colors.white38,
                fontSize: 8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class PanelHeader extends StatelessWidget {
  const PanelHeader({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF00D4FF);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
                color: Color(0xFF26de81), shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            'MISSION INTEL',
            style: GoogleFonts.spaceGrotesk(
              color: primaryColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
            ),
            child: Text(
              'LIVE',
              style: GoogleFonts.spaceGrotesk(
                color: primaryColor,
                fontSize: 8,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  static const _primaryColor = Color(0xFF00D4FF);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
                color: Color(0xFF26de81), shape: BoxShape.circle),
          )
              .animate(onPlay: (c) => c.repeat())
              .fadeIn()
              .then()
              .fadeOut(duration: 1000.ms),
          const SizedBox(width: 8),
          Text(
            'MISSION INTEL',
            style: GoogleFonts.spaceGrotesk(
              color: _primaryColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: _primaryColor.withValues(alpha: 0.2)),
            ),
            child: Text(
              'LIVE',
              style: GoogleFonts.spaceGrotesk(
                color: _primaryColor,
                fontSize: 8,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text(
          message,
          style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
        ),
      ),
    );
  }
}

class RiverRow extends ConsumerWidget {
  const RiverRow({
    super.key,
    required this.id,
    required this.name,
    required this.onNavigateToQuality,
  });

  final String id;
  final String name;
  final void Function(String? bodyId) onNavigateToQuality;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(waterQualityProvider(id));
    final (color, label) = _qualityStatus(data.overallStatusLabel);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => onNavigateToQuality(id),
        child: Container(
          margin: const EdgeInsets.only(bottom: 5),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1B2A),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  label,
                  style: GoogleFonts.spaceGrotesk(
                    color: color,
                    fontSize: 7,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(PhosphorIconsRegular.arrowRight,
                  color: Colors.white24, size: 10),
            ],
          ),
        ),
      ),
    );
  }

  (Color, String) _qualityStatus(String label) {
    if (label.contains('SAFE —') || label.contains('is SAFE')) {
      return (const Color(0xFF26de81), 'SAFE');
    }
    if (label.contains('CAUTION')) return (const Color(0xFFFECA57), 'CAUTION');
    if (label.contains('UNSAFE')) return (const Color(0xFFFF9F43), 'UNSAFE');
    return (const Color(0xFFFF4757), 'CRITICAL');
  }
}

class AlarmCard extends StatelessWidget {
  const AlarmCard(
      {super.key, required this.alarm, required this.onNavigateToMonitoring});

  final Alarm alarm;
  final void Function(LatLng? coord) onNavigateToMonitoring;

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(alarm.severity);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => onNavigateToMonitoring(
          LatLng(alarm.location.latitude, alarm.location.longitude),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(_alarmIcon(alarm.type),
                            color: Colors.white38, size: 11),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            alarm.municipality ??
                                '${alarm.location.latitude.toStringAsFixed(1)}°N',
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _timeAgo(alarm.createdAt),
                          style: GoogleFonts.spaceGrotesk(
                              color: color, fontSize: 9),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      alarm.message,
                      style:
                          GoogleFonts.inter(color: Colors.white38, fontSize: 9),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  alarm.severity.name.toUpperCase().substring(0, 3),
                  style: GoogleFonts.spaceGrotesk(
                    color: color,
                    fontSize: 7,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _severityColor(AlarmSeverity s) {
    switch (s) {
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

  IconData _alarmIcon(AlarmType t) {
    switch (t) {
      case AlarmType.flood:
        return PhosphorIconsRegular.waves;
      case AlarmType.waterQuality:
        return PhosphorIconsRegular.drop;
      case AlarmType.anomaly:
        return PhosphorIconsRegular.chartLineUp;
      case AlarmType.environmental:
        return PhosphorIconsRegular.leaf;
    }
  }

  String _timeAgo(String createdAt) {
    try {
      final diff = DateTime.now().difference(DateTime.parse(createdAt));
      if (diff.inHours > 24) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      return '${diff.inMinutes}m ago';
    } catch (_) {
      return '';
    }
  }
}
