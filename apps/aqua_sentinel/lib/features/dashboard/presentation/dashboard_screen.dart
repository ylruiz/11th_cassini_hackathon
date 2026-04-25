import 'package:auto_route/auto_route.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../alerts/data/alarms_provider.dart';
import '../../alerts/models/alarm_model.dart';
import '../../map/presentation/map_screen.dart';
import '../../water_quality/presentation/water_quality_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_globe_3d/flutter_globe_3d.dart';
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
              child: _GlobeHero(
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
                'Cosmic Dashboard Refined',
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
    widget.controller.setZoom(1.0);
  }

  void _zoomIn() => widget.controller.setZoom(widget.controller.zoom + 0.25);
  void _zoomOut() => widget.controller.setZoom(widget.controller.zoom - 0.25);

  @override
  Widget build(BuildContext context) {
    final activeAlarms = ref.watch(activeAlarmsProvider);

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
                      onScaleStart: (_) => _baseZoom = widget.controller.zoom,
                      onScaleUpdate: (details) =>
                          widget.controller.setZoom(_baseZoom * details.scale),
                      child: Center(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: Earth3D(
                              controller: widget.controller,
                              texture:
                                  const AssetImage('assets/earth_texture.png'),
                              initialScale: 1,
                            ).animate().fadeIn(duration: 900.ms).scale(
                                begin: const Offset(0.8, 0.8),
                                duration: 900.ms,
                                curve: Curves.easeOutBack),
                          ),
                        ),
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
            if (activeAlarms.isNotEmpty)
              Positioned.fill(
                child: _AlarmMarkersOverlay(
                  alarms: activeAlarms,
                  onNavigateToMap: widget.onNavigateToMap,
                ),
              ),
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
                'REAL-TIME SPECTRAL FEED',
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
        _CoordChip(label: 'LAT', value: '48.2° N'),
        const SizedBox(width: 12),
        _CoordChip(label: 'LON', value: '10.0° E'),
        const SizedBox(width: 12),
        _CoordChip(label: 'ALT', value: '821 km'),
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
                'ACTIVE SCAN REGION',
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

class _AlarmMarkersOverlay extends ConsumerWidget {
  const _AlarmMarkersOverlay({
    required this.alarms,
    required this.onNavigateToMap,
  });
  final List<Alarm> alarms;
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(60),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: alarms.map((alarm) {
              final lat = alarm.location.latitude;
              final lon = alarm.location.longitude;

              final x = ((lon + 180) / 360) * constraints.maxWidth;
              final y = ((90 - lat) / 180) * constraints.maxHeight;

              final color = _severityColor(alarm.severity);
              final isCritical = alarm.severity == AlarmSeverity.critical;
              final isHigh = alarm.severity == AlarmSeverity.high;
              final pulseMs = isCritical ? 800 : 1200;

              final label =
                  '${alarm.severity.name.toUpperCase()} — ${alarm.municipality ?? 'Lat ${lat.toStringAsFixed(1)}, Lon ${lon.toStringAsFixed(1)}'}';

              return Positioned(
                left: x - 14,
                top: y - 14,
                child: Tooltip(
                  message: label,
                  textStyle: GoogleFonts.spaceGrotesk(
                      color: Colors.white, fontSize: 11),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1B2A),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: color.withValues(alpha: 0.4)),
                  ),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {
                        ref.read(mapNavigationProvider.notifier).state =
                            LatLng(lat, lon);
                        onNavigateToMap();
                      },
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (isCritical || isHigh)
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: color.withValues(alpha: 0.7),
                                    width: 2,
                                  ),
                                ),
                              )
                                  .animate(onPlay: (c) => c.repeat())
                                  .scale(
                                    begin: const Offset(0.4, 0.4),
                                    end: const Offset(1.3, 1.3),
                                    duration: pulseMs.ms,
                                    curve: Curves.easeOut,
                                  )
                                  .fadeOut(duration: pulseMs.ms),
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.6),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
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
          _StatCard(
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
          const _StatCard(
            icon: PhosphorIconsRegular.mapPin,
            label: 'Monitored Regions',
            value: '5',
            color: Color(0xFF00D4FF),
            iconColor: Color(0xFF00D4FF),
          ),
          const SizedBox(width: 24),
          _StatCard(
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
