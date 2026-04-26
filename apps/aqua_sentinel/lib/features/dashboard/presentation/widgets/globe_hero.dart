import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_globe_3d/flutter_globe_3d.dart';
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

class GlobeHero extends ConsumerStatefulWidget {
  const GlobeHero({
    super.key,
    required this.controller,
    required this.onNavigateToMap,
  });

  final EarthController controller;
  final VoidCallback onNavigateToMap;

  @override
  ConsumerState<GlobeHero> createState() => _GlobeHeroState();
}

class _GlobeHeroState extends ConsumerState<GlobeHero> {
  double _baseZoom = 1.0;

  @override
  void initState() {
    super.initState();
    widget.controller.setCameraFocus(45.0, 15.0);
    widget.controller.setZoom(1.8);
    _addWaterBodyNodes();
    _addMountainNodes();
  }

  void _addWaterBodyNodes() {
    for (final body in waterBodies) {
      widget.controller.addNode(EarthNode(
        id: 'wb-${body.id}',
        latitude: body.latitude,
        longitude: body.longitude,
        child: GestureDetector(
          onTap: () => _goToMonitoring(body.id),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Tooltip(
              message: body.name,
              textStyle:
                  GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 11),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1B2A),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: const Color(0xFF00D4FF).withValues(alpha: 0.4)),
              ),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1B2A),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF00D4FF), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00D4FF).withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  PhosphorIconsRegular.drop,
                  color: Color(0xFF00D4FF),
                  size: 16,
                ),
              ),
            ),
          ),
        ),
      ));
    }
  }

  void _addMountainNodes() {
    for (final mountain in mountainRanges) {
      widget.controller.addNode(EarthNode(
        id: 'mt-${mountain.id}',
        latitude: mountain.latitude,
        longitude: mountain.longitude,
        child: GestureDetector(
          onTap: () {
            ref.read(mapNavigationProvider.notifier).state = LatLng(
              mountain.latitude,
              mountain.longitude,
            );
            widget.onNavigateToMap();
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Tooltip(
              message: mountain.name,
              textStyle:
                  GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 11),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1B2A),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: const Color(0xFFFF9F43).withValues(alpha: 0.4)),
              ),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1B2A),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFF9F43), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF9F43).withValues(alpha: 0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  PhosphorIconsRegular.mountains,
                  color: Color(0xFFFF9F43),
                  size: 18,
                ),
              ),
            ),
          ),
        ),
      ));
    }
  }

  void _syncAlarmNodes(List<Alarm> alarms) {
    widget.controller.nodes.removeWhere((n) => n.id.startsWith('alarm-'));
    for (final alarm in alarms) {
      final color = _severityColor(alarm.severity);
      widget.controller.nodes.add(EarthNode(
        id: 'alarm-${alarm.id}',
        latitude: alarm.location.latitude,
        longitude: alarm.location.longitude,
        child: GestureDetector(
          onTap: () {
            ref.read(mapNavigationProvider.notifier).state = LatLng(
              alarm.location.latitude,
              alarm.location.longitude,
            );
            widget.onNavigateToMap();
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Tooltip(
              message: alarm.municipality ??
                  '${alarm.location.latitude.toStringAsFixed(1)}°, ${alarm.location.longitude.toStringAsFixed(1)}°',
              textStyle:
                  GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 11),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1B2A),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color.withValues(alpha: 0.4)),
              ),
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.6),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ));
    }
    widget.controller.setZoom(widget.controller.zoom);
  }

  void _goToMonitoring(String bodyId) {
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
    ref.read(viewModeProvider.notifier).state = ViewMode.simulate;
    ref.read(selectedIssueTypeProvider.notifier).state =
        _mapThreatToScenario(risk.primaryThreat);
    widget.onNavigateToMap();
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

  void _zoomIn() => widget.controller.setZoom(widget.controller.zoom + 0.25);
  void _zoomOut() => widget.controller.setZoom(widget.controller.zoom - 0.25);

  @override
  Widget build(BuildContext context) {
    final activeAlarms = ref.watch(activeAlarmsProvider);

    ref.listen<LatLng?>(dashboardGlobeFocusProvider, (_, focus) {
      if (focus != null) {
        widget.controller.setCameraFocus(focus.latitude, focus.longitude);
        widget.controller.setZoom(2.2);
        ref.read(dashboardGlobeFocusProvider.notifier).state = null;
      }
    });

    _syncAlarmNodes(activeAlarms);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF060E1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: const Color(0xFF00D4FF).withValues(alpha: 0.15)),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _GridBackground(),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _SpectralFeedHeader(),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Listener(
                    onPointerSignal: (event) {
                      if (event is PointerScrollEvent) {
                        GestureBinding.instance.pointerSignalResolver.register(
                          event,
                          (event) {
                            if (event is PointerScrollEvent) {
                              widget.controller.setZoom(
                                widget.controller.zoom -
                                    event.scrollDelta.dy * 0.003,
                              );
                            }
                          },
                        );
                      }
                    },
                    child: GestureDetector(
                      onTap: widget.onNavigateToMap,
                      onScaleStart: (_) => _baseZoom = widget.controller.zoom,
                      onScaleUpdate: (details) =>
                          widget.controller.setZoom(_baseZoom * details.scale),
                      child: SizedBox.expand(
                        child: Earth3D(
                          controller: widget.controller,
                          texture: const AssetImage('assets/earth_texture.png'),
                          initialScale: 1,
                        ).animate().fadeIn(duration: 900.ms).scale(
                            begin: const Offset(0.8, 0.8),
                            duration: 900.ms,
                            curve: Curves.easeOutBack),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: _GlobeFooter(),
                ),
              ],
            ),
            Positioned(
              right: 28,
              bottom: 52,
              child: Column(
                children: [
                  _ZoomButton(icon: PhosphorIconsRegular.plus, onTap: _zoomIn),
                  const SizedBox(height: 4),
                  _ZoomButton(
                      icon: PhosphorIconsRegular.minus, onTap: _zoomOut),
                ],
              ),
            ),
            _RecentAlertsPanel(onNavigateToMap: widget.onNavigateToMap),
          ],
        ),
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  const _ZoomButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFF0D1B2A),
          borderRadius: BorderRadius.circular(8),
          border:
              Border.all(color: const Color(0xFF00D4FF).withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: const Color(0xFF00D4FF), size: 16),
      ),
    );
  }
}

class _GridBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CustomPaint(painter: _GridPainter()),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00D4FF).withValues(alpha: 0.04)
      ..strokeWidth = 1;
    const step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SpectralFeedHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().toUtc();
    final formattedDate =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} UTC';

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF00D4FF).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
                color: const Color(0xFF00D4FF).withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF00D4FF),
                  shape: BoxShape.circle,
                ),
              )
                  .animate(onPlay: (c) => c.repeat())
                  .fadeIn()
                  .then()
                  .fadeOut(duration: 800.ms),
              const SizedBox(width: 6),
              Text(
                'EUROPEAN WATER RISK OVERVIEW',
                style: GoogleFonts.spaceGrotesk(
                  color: const Color(0xFF00D4FF),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Text(
          formattedDate,
          style: GoogleFonts.spaceGrotesk(
            color: const Color(0xFF00D4FF),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Sentinel-2 / Copernicus',
          style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
        ),
      ],
    );
  }
}

class _GlobeFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CoordChip(label: 'WATERSHEDS', value: '10 monitored'),
        const SizedBox(width: 12),
        _CoordChip(label: 'COVERAGE', value: 'EU + Balkans'),
        const SizedBox(width: 12),
        _CoordChip(label: 'UPDATE', value: 'Every 5 days'),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFFF4757).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
                color: const Color(0xFFFF4757).withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(PhosphorIconsRegular.warning,
                  color: Color(0xFFFF4757), size: 12),
              const SizedBox(width: 4),
              Text(
                'LONG-TERM RISK PREDICTION ACTIVE',
                style: GoogleFonts.spaceGrotesk(
                  color: const Color(0xFFFF4757),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CoordChip extends StatelessWidget {
  const _CoordChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label ',
            style:
                GoogleFonts.spaceGrotesk(color: Colors.white38, fontSize: 10)),
        Text(value,
            style: GoogleFonts.spaceGrotesk(
              color: const Color(0xFF00D4FF),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            )),
      ],
    );
  }
}

class _RecentAlertsPanel extends ConsumerWidget {
  const _RecentAlertsPanel({required this.onNavigateToMap});

  final VoidCallback onNavigateToMap;

  Color _severityColor(AlarmSeverity severity) {
    switch (severity) {
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

  IconData _alarmTypeIcon(AlarmType type) {
    switch (type) {
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

  String _formatTimeAgo(String createdAt) {
    try {
      final created = DateTime.parse(createdAt);
      final now = DateTime.now();
      final diff = now.difference(created);
      if (diff.inHours > 24) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      return '${diff.inMinutes}m ago';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alarms = ref.watch(activeAlarmsProvider);
    final recentAlarms = alarms.take(3).toList();

    if (recentAlarms.isEmpty) return const SizedBox.shrink();

    return Positioned(
      left: 20,
      bottom: 20,
      child: Container(
        width: 290,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1B2A).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4757).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(PhosphorIconsRegular.bell,
                          color: Color(0xFFFF4757), size: 10),
                      const SizedBox(width: 4),
                      Text(
                        'RECENT ALERTS',
                        style: GoogleFonts.spaceGrotesk(
                          color: const Color(0xFFFF4757),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${alarms.length}',
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white54,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...recentAlarms.map((alarm) {
              final color = _severityColor(alarm.severity);
              return MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    ref.read(mapNavigationProvider.notifier).state = LatLng(
                      alarm.location.latitude,
                      alarm.location.longitude,
                    );
                    onNavigateToMap();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(6),
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
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(_alarmTypeIcon(alarm.type),
                            color: Colors.white54, size: 13),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                alarm.municipality ??
                                    '${alarm.location.latitude.toStringAsFixed(1)}°, ${alarm.location.longitude.toStringAsFixed(1)}°',
                                style: GoogleFonts.spaceGrotesk(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                alarm.message,
                                style: GoogleFonts.inter(
                                    color: Colors.white38, fontSize: 9),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatTimeAgo(alarm.createdAt),
                          style: GoogleFonts.spaceGrotesk(
                            color: color,
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(PhosphorIconsRegular.arrowRight,
                            color: Colors.white24, size: 10),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
