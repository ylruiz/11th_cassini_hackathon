import 'package:auto_route/auto_route.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_globe_3d/flutter_globe_3d.dart';
import 'package:latlong2/latlong.dart';

import '../../alerts/providers/alarms_provider.dart';
import '../../alerts/models/alarm_model.dart';
import '../../impact/providers/impact_provider.dart';
import '../../impact/models/impact_data.dart';
import '../../map/presentation/map_screen.dart';
import '../providers/dashboard_globe_focus_provider.dart';
import '../providers/dashboard_tab_provider.dart';
import '../../monitoring/data/monitoring_provider.dart';
import '../../monitoring/models/environmental_analysis.dart';
import '../../simulator/models/water_issue_scenario.dart';
import '../../water_quality/data/water_quality_provider.dart';
import '../../water_quality/presentation/water_quality_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

@RoutePage()
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  late final EarthController _earthController;
  int _selectedNav = 0;
  bool _sidebarExpanded = true;
  bool _alarmsPanelOpen = false;

  @override
  void initState() {
    super.initState();
    _earthController = EarthController();
    _earthController.enableAutoRotate = true;
    _earthController.rotateSpeed = 0.15;
    _earthController.setLightMode(EarthLightMode.realTime);
  }

  @override
  void dispose() {
    _earthController.dispose();
    super.dispose();
  }

  void _onNavSelect(int i) {
    setState(() => _selectedNav = i);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width > 800;
    final activeAlarms = ref.watch(activeAlarmsProvider);

    ref.listen<int?>(dashboardTabProvider, (_, tab) {
      if (tab != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() => _selectedNav = tab);
            ref.read(dashboardTabProvider.notifier).state = null;
          }
        });
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      drawer: isWide ? null : _buildDrawer(context),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: isWide
                    ? Row(children: [
                        _Sidebar(
                          selected: _selectedNav,
                          expanded: _sidebarExpanded,
                          onSelect: _onNavSelect,
                          onToggle: () => setState(
                              () => _sidebarExpanded = !_sidebarExpanded),
                        ),
                        Expanded(
                            child: _buildMain(context, isWide, activeAlarms)),
                      ])
                    : _buildMain(context, isWide, activeAlarms),
              ),
            ],
          ),
          if (_alarmsPanelOpen)
            _AlarmsPanel(
              onClose: () => setState(() => _alarmsPanelOpen = false),
              onSelectAlarm: (alarm) {
                ref.read(mapNavigationProvider.notifier).state = LatLng(
                  alarm.location.latitude,
                  alarm.location.longitude,
                );
                setState(() {
                  _alarmsPanelOpen = false;
                  _selectedNav = 1;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMain(
      BuildContext context, bool isWide, List<Alarm> activeAlarms) {
    return IndexedStack(
      index: _selectedNav,
      children: [
        Column(
          children: [
            _TopBar(
              isWide: isWide,
              alarmCount: activeAlarms.length,
              onBellPressed: () =>
                  setState(() => _alarmsPanelOpen = !_alarmsPanelOpen),
            ),
            const _StatsBar(),
            Expanded(
              child: isWide
                  ? Row(
                      children: [
                        Expanded(
                          child: _GlobeHero(
                            controller: _earthController,
                            onNavigateToMap: () =>
                                setState(() => _selectedNav = 1),
                          ),
                        ),
                        _DashboardLeftPanel(
                          onNavigateToMonitoring: (LatLng? coord) {
                            if (coord != null) {
                              ref.read(mapNavigationProvider.notifier).state =
                                  coord;
                            }
                            setState(() => _selectedNav = 1);
                          },
                          onNavigateToQuality: (String? bodyId) {
                            if (bodyId != null) {
                              ref
                                  .read(selectedQualityBodyProvider.notifier)
                                  .state = bodyId;
                            }
                            setState(() => _selectedNav = 2);
                          },
                        ),
                      ],
                    )
                  : _GlobeHero(
                      controller: _earthController,
                      onNavigateToMap: () => setState(() => _selectedNav = 1),
                    ),
            ),
          ],
        ),
        Column(
          children: [
            _TopBar(
              isWide: isWide,
              alarmCount: activeAlarms.length,
              onBellPressed: () =>
                  setState(() => _alarmsPanelOpen = !_alarmsPanelOpen),
            ),
            const Expanded(child: MapView()),
          ],
        ),
        Column(
          children: [
            _TopBar(
              isWide: isWide,
              alarmCount: activeAlarms.length,
              onBellPressed: () =>
                  setState(() => _alarmsPanelOpen = !_alarmsPanelOpen),
            ),
            const Expanded(child: WaterQualityView()),
          ],
        ),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF0D1B2A),
      child: _Sidebar(
        selected: _selectedNav,
        expanded: true,
        onSelect: (i) {
          Navigator.of(context).pop();
          _onNavSelect(i);
        },
        onToggle: () {},
      ),
    );
  }
}

// ─── Sidebar ─────────────────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.selected,
    required this.expanded,
    required this.onSelect,
    required this.onToggle,
  });

  final int selected;
  final bool expanded;
  final ValueChanged<int> onSelect;
  final VoidCallback onToggle;

  static const _items = [
    (PhosphorIconsRegular.squaresFour, 'Dashboard'),
    (PhosphorIconsRegular.mapTrifold, 'Monitoring'),
    (PhosphorIconsRegular.drop, 'Water Quality'),
  ];

  static const _bottom = [
    (PhosphorIconsRegular.gauge, 'System Status'),
    (PhosphorIconsRegular.lifebuoy, 'Support'),
  ];

  @override
  Widget build(BuildContext context) {
    final w = expanded ? 220.0 : 64.0;
    return AnimatedContainer(
      duration: 200.ms,
      width: w,
      color: const Color(0xFF060E1A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLogo(),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 8),
          ..._items.asMap().entries.map(
                (e) => _NavItem(
                  icon: e.value.$1,
                  label: e.value.$2,
                  selected: selected == e.key,
                  expanded: expanded,
                  onTap: () => onSelect(e.key),
                ),
              ),
          const Spacer(),
          const Divider(color: Colors.white10, height: 1),
          ..._bottom.map(
            (e) => _NavItem(
              icon: e.$1,
              label: e.$2,
              selected: false,
              expanded: expanded,
              onTap: () {},
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF00D4FF).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: const Color(0xFF00D4FF).withValues(alpha: 0.4),
                  width: 1),
            ),
            child: const Icon(PhosphorIconsRegular.drop,
                color: Color(0xFF00D4FF), size: 18),
          ),
          if (expanded) ...[
            const SizedBox(width: 10),
            Text(
              'AquaSentinel',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.expanded,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF00D4FF);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 150.ms,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color:
              selected ? primary.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                selected ? primary.withValues(alpha: 0.3) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? primary : Colors.white38, size: 18),
            if (expanded) ...[
              const SizedBox(width: 10),
              Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  color: selected ? primary : Colors.white54,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Top bar ─────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.isWide,
    required this.alarmCount,
    required this.onBellPressed,
  });
  final bool isWide;
  final int alarmCount;
  final VoidCallback onBellPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 73,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF060E1A),
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          if (!isWide)
            IconButton(
              icon: const Icon(PhosphorIconsRegular.list,
                  color: Colors.white54, size: 20),
              onPressed: () => Scaffold.of(context).openDrawer(),
              padding: EdgeInsets.zero,
            ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MAIN CONTROLS',
                style: GoogleFonts.spaceGrotesk(
                  color: const Color(0xFF00D4FF),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
              ),
              Text(
                'European Water Risk Command Center',
                style: GoogleFonts.spaceGrotesk(
                    color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          Container(
            height: 32,
            width: isWide ? 200 : 140,
            decoration: BoxDecoration(
              color: const Color(0xFF0D1B2A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                const SizedBox(width: 10),
                const Icon(PhosphorIconsRegular.magnifyingGlass,
                    color: Colors.white38, size: 14),
                const SizedBox(width: 6),
                Text('Search...',
                    style:
                        GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _IconBadge(
            icon: PhosphorIconsRegular.bell,
            badge: alarmCount > 0 ? '$alarmCount' : null,
            onPressed: onBellPressed,
          ),
          const SizedBox(width: 8),
          _IconBadge(icon: PhosphorIconsRegular.userCircle, badge: null),
        ],
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.icon,
    required this.badge,
    this.onPressed,
  });
  final IconData icon;
  final String? badge;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: Icon(icon, color: Colors.white54, size: 20),
          onPressed: onPressed ?? () {},
          padding: const EdgeInsets.all(6),
          constraints: const BoxConstraints(),
        ),
        if (badge != null)
          Positioned(
            top: 2,
            right: 2,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Color(0xFFFF4757),
                shape: BoxShape.circle,
              ),
              child: Text(badge!,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }
}

// ─── Globe hero ──────────────────────────────────────────────────────────────

class _GlobeHero extends ConsumerStatefulWidget {
  const _GlobeHero({
    required this.controller,
    required this.onNavigateToMap,
  });
  final EarthController controller;
  final VoidCallback onNavigateToMap;

  @override
  ConsumerState<_GlobeHero> createState() => _GlobeHeroState();
}

class _GlobeHeroState extends ConsumerState<_GlobeHero> {
  double _baseZoom = 1.0;

  @override
  void initState() {
    super.initState();
    widget.controller.setCameraFocus(45.0, 15.0);
    widget.controller.setZoom(1.8);
    _addWaterBodyNodes();
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

// ─── Dashboard Left Panel ────────────────────────────────────────────────────

class _DashboardLeftPanel extends ConsumerWidget {
  const _DashboardLeftPanel({
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
                  const _RiskTimelineMini(),
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

// ─── Mini Risk Timeline ──────────────────────────────────────────────────────

class _RiskTimelineMini extends StatelessWidget {
  const _RiskTimelineMini();

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

// ─── Alarms Panel ───────────────────────────────────────────────────────────

class _AlarmsPanel extends ConsumerWidget {
  const _AlarmsPanel({
    required this.onClose,
    required this.onSelectAlarm,
  });
  final VoidCallback onClose;
  final void Function(Alarm) onSelectAlarm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAlarms = ref.watch(activeAlarmsProvider);

    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black54,
        child: Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: 320,
              color: const Color(0xFF0D1B2A),
              child: Column(
                children: [
                  Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: const BoxDecoration(
                      color: Color(0xFF060E1A),
                      border: Border(bottom: BorderSide(color: Colors.white10)),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'ACTIVE ALARMS',
                          style: GoogleFonts.spaceGrotesk(
                            color: const Color(0xFF00D4FF),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                          ),
                        ),
                        const Spacer(),
                        if (activeAlarms.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF4757)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: const Color(0xFFFF4757)
                                      .withValues(alpha: 0.3)),
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
                          icon: const Icon(PhosphorIconsRegular.x,
                              color: Colors.white54, size: 18),
                          onPressed: onClose,
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
                                  color: const Color(0xFF00D4FF)
                                      .withValues(alpha: 0.3),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No active alarms',
                                  style: GoogleFonts.spaceGrotesk(
                                    color: Colors.white54,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: activeAlarms.length,
                            itemBuilder: (context, index) {
                              final alarm = activeAlarms[index];
                              return _AlarmPanelItem(
                                alarm: alarm,
                                onTap: () => onSelectAlarm(alarm),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AlarmPanelItem extends StatelessWidget {
  const _AlarmPanelItem({required this.alarm, required this.onTap});
  final Alarm alarm;
  final VoidCallback onTap;

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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F2133),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _severityColor.withValues(alpha: 0.2)),
        ),
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        alarm.municipality ??
                            '${alarm.location.latitude.toStringAsFixed(2)}°, ${alarm.location.longitude.toStringAsFixed(2)}°',
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _severityColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          alarm.severity.name.toUpperCase(),
                          style: GoogleFonts.spaceGrotesk(
                            color: _severityColor,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alarm.message,
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stats Bar ────────────────────────────────────────────────────────────────

class _StatsBar extends ConsumerWidget {
  const _StatsBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(impactSummaryProvider);
    final alarms = ref.watch(activeAlarmsProvider);
    final criticalCount =
        alarms.where((a) => a.severity == AlarmSeverity.critical).length;

    // Pitch-derived framing: Tyrol invests ~€60M/yr to prevent ~€1.5B damage.
    // Prevention ROI roughly 25:1 for the portfolio.
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
          _StatCard(
            icon: PhosphorIconsRegular.currencyEur,
            label: 'Total Economic Exposure',
            value: '€${summary.totalEconomicImpactEurM.toStringAsFixed(1)}M',
            color: const Color(0xFFFF4757),
            iconColor: const Color(0xFFFF4757),
          ),
          const SizedBox(width: 24),
          _StatCard(
            icon: PhosphorIconsRegular.users,
            label: 'Population at Risk',
            value: _formatPopulation(summary.totalPopulationAtRisk),
            color: const Color(0xFF00D4FF),
            iconColor: const Color(0xFF00D4FF),
          ),
          const SizedBox(width: 24),
          _StatCard(
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
          const _StatCard(
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

class _StatCard extends StatelessWidget {
  const _StatCard({
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
