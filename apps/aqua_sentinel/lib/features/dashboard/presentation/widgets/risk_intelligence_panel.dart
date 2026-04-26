import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../alerts/models/alarm_model.dart';
import '../../../alerts/providers/alarms_provider.dart';
import '../../../impact/models/impact_data.dart';
import '../../../impact/providers/impact_provider.dart';
import '../../../map/presentation/map_screen.dart';
import '../../../monitoring/models/environmental_analysis.dart';
import '../../../monitoring/providers/monitoring_provider.dart';
import '../../../simulator/models/water_issue_scenario.dart';
import '../../providers/dashboard_globe_focus_provider.dart';

class RiskIntelligencePanel extends ConsumerWidget {
  const RiskIntelligencePanel({
    super.key,
    required this.onNavigateToMonitoring,
    required this.onNavigateToQuality,
  });

  final void Function(LatLng? coord) onNavigateToMonitoring;
  final void Function(String? bodyId) onNavigateToQuality;

  static const _primaryColor = Color(0xFF00D4FF);

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

  Color _tierColor(RiskTier t) {
    switch (t) {
      case RiskTier.low:
        return const Color(0xFF26de81);
      case RiskTier.moderate:
        return const Color(0xFFFECA57);
      case RiskTier.high:
        return const Color(0xFFFF9F43);
      case RiskTier.critical:
        return const Color(0xFFFF4757);
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

  WaterIssueType _mapThreatToScenario(String threat) {
    final lower = threat.toLowerCase();
    if (lower.contains('flood') || lower.contains('inundat')) {
      return WaterIssueType.flooding;
    }
    if (lower.contains('drought') || lower.contains('dry')) {
      return WaterIssueType.drought;
    }
    if (lower.contains('temperature') ||
        lower.contains('heat') ||
        lower.contains('warm')) {
      return WaterIssueType.heatStress;
    }
    if (lower.contains('snow') ||
        lower.contains('melt') ||
        lower.contains('glacier')) {
      return WaterIssueType.snowMelt;
    }
    return WaterIssueType.pollution;
  }

  void _goToMonitoring(WidgetRef ref, String bodyId) {
    final body = waterBodies.firstWhere(
      (b) => b.id == bodyId,
      orElse: () => waterBodies.first,
    );
    final risks = ref.read(waterBodyRiskProvider);
    final risk = risks.firstWhere(
      (r) => r.waterBodyId == bodyId,
      orElse: () => risks.isNotEmpty
          ? risks.first
          : const WaterBodyRiskScore(
              waterBodyId: '',
              waterBodyName: '',
              country: '',
              riskScore: 0,
              tier: RiskTier.low,
              populationAtRisk: 0,
              economicImpactEurM: 0,
              primaryThreat: '',
              dataSource: '',
              lastUpdated: '',
              sectorImpacts: [],
            ),
    );
    ref.read(mapNavigationProvider.notifier).state =
        LatLng(body.latitude, body.longitude);
    ref.read(selectedWaterBodyProvider.notifier).state = body;
    ref.read(selectedIssueTypeProvider.notifier).state =
        _mapThreatToScenario(risk.primaryThreat);
    ref.read(viewModeProvider.notifier).state = ViewMode.simulate;
    onNavigateToMonitoring(null);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAlarms = ref.watch(activeAlarmsProvider);
    final riskScores = ref.watch(waterBodyRiskProvider);
    final hotspots = riskScores.where((r) => r.riskScore > 55).toList()
      ..sort((a, b) => b.riskScore.compareTo(a.riskScore));

    return Container(
      width: 300,
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
          _buildPanelHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                      'PRIORITY RISK HOTSPOTS', hotspots.length),
                  const SizedBox(height: 10),
                  if (hotspots.isEmpty)
                    _buildEmptyState('No priority hotspots')
                  else
                    ...hotspots.map((h) => _buildHotspotCard(h, ref)),
                  const SizedBox(height: 6),
                  _buildActionButton(
                    'Open long-term simulator',
                    PhosphorIconsRegular.globe,
                    () => onNavigateToMonitoring(null),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionHeader('ACTIVE ALERTS', activeAlarms.length),
                  const SizedBox(height: 10),
                  if (activeAlarms.isEmpty)
                    _buildEmptyState('No active alarms')
                  else
                    ...activeAlarms.take(3).map((a) => _buildAlarmCard(a)),
                  if (activeAlarms.length > 3) ...[
                    const SizedBox(height: 4),
                    _buildActionButton(
                      'View all ${activeAlarms.length} alerts',
                      PhosphorIconsRegular.mapTrifold,
                      () => onNavigateToMonitoring(null),
                    ),
                  ],
                  const SizedBox(height: 20),
                  const RiskTimelineMini(),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanelHeader() {
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
            'RISK INTELLIGENCE',
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

  Widget _buildSectionHeader(String title, int? count) {
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
              color: count > 0
                  ? const Color(0xFFFF4757).withValues(alpha: 0.15)
                  : Colors.white10,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.spaceGrotesk(
                color: count > 0 ? const Color(0xFFFF4757) : Colors.white38,
                fontSize: 8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHotspotCard(WaterBodyRiskScore risk, WidgetRef ref) {
    final color = _tierColor(risk.tier);
    final body = waterBodies.firstWhere(
      (b) => b.id == risk.waterBodyId,
      orElse: () => waterBodies.first,
    );
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        ref.read(dashboardGlobeFocusProvider.notifier).state =
            LatLng(body.latitude, body.longitude);
      },
      child: GestureDetector(
        onTap: () => _goToMonitoring(ref, risk.waterBodyId),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1B2A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      risk.waterBodyName,
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      risk.tier.displayName,
                      style: GoogleFonts.spaceGrotesk(
                        color: color,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                risk.primaryThreat,
                style: GoogleFonts.inter(
                  color: Colors.white54,
                  fontSize: 10,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _HotspotMetric(
                    icon: PhosphorIconsRegular.currencyEur,
                    label: 'Exposure',
                    value: '€${risk.economicImpactEurM.toStringAsFixed(1)}M',
                    color: const Color(0xFFFF4757),
                  ),
                  const SizedBox(width: 8),
                  _HotspotMetric(
                    icon: PhosphorIconsRegular.users,
                    label: 'At Risk',
                    value:
                        '${(risk.populationAtRisk / 1000).toStringAsFixed(0)}k',
                    color: const Color(0xFF00D4FF),
                  ),
                  const SizedBox(width: 8),
                  _HotspotMetric(
                    icon: PhosphorIconsRegular.chartBar,
                    label: 'Score',
                    value: '${risk.riskScore}',
                    color: color,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: risk.riskScore / 100,
                  backgroundColor: Colors.white10,
                  color: color,
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlarmCard(Alarm alarm) {
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

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: _primaryColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _primaryColor.withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: _primaryColor, size: 11),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  color: _primaryColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(PhosphorIconsRegular.arrowRight,
                  color: Color(0xFF00D4FF), size: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
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

class _HotspotMetric extends StatelessWidget {
  const _HotspotMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 9),
                const SizedBox(width: 3),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: Colors.white38,
                    fontSize: 8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: GoogleFonts.spaceGrotesk(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RiskTimelineMini extends StatelessWidget {
  const RiskTimelineMini({super.key});

  static const _milestones = [
    ('Today', 'Current baseline', Color(0xFF00D4FF)),
    ('+10 yr', 'Moderate increase', Color(0xFFFECA57)),
    ('+20 yr', 'High risk zones expand', Color(0xFFFF9F43)),
    ('+30 yr', 'Critical thresholds', Color(0xFFFF4757)),
    ('+40 yr', 'Severe exposure', Color(0xFFFF4757)),
    ('+50 yr', 'Catastrophic potential', Color(0xFFFF4757)),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LONG-TERM PROJECTION',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white38,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          ..._milestones.asMap().entries.map((e) {
            final (label, desc, color) = e.value;
            final isLast = e.key == _milestones.length - 1;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 1,
                        height: 18,
                        color: Colors.white24,
                      ),
                  ],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.spaceGrotesk(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        desc,
                        style: GoogleFonts.inter(
                          color: Colors.white38,
                          fontSize: 9,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 4),
          Text(
            'Based on Copernicus satellite trend analysis + climate models',
            style: GoogleFonts.inter(
              color: Colors.white24,
              fontSize: 8,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
