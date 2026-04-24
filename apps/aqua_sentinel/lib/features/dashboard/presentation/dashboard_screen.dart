import 'package:auto_route/auto_route.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      drawer: isWide ? null : _buildDrawer(context),
      body: isWide
          ? Row(children: [
              _Sidebar(
                selected: _selectedNav,
                expanded: _sidebarExpanded,
                onSelect: (i) => setState(() => _selectedNav = i),
                onToggle: () =>
                    setState(() => _sidebarExpanded = !_sidebarExpanded),
              ),
              Expanded(child: _buildMain(context, isWide)),
              _RightPanel(),
            ])
          : _buildMain(context, isWide),
    );
  }

  Widget _buildMain(BuildContext context, bool isWide) {
    return Column(
      children: [
        _TopBar(isWide: isWide),
        Expanded(
          child: _GlobeHero(controller: _earthController),
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
          setState(() => _selectedNav = i);
          Navigator.of(context).pop();
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
    (PhosphorIconsRegular.mapTrifold, 'Water Map'),
    (PhosphorIconsRegular.bellRinging, 'Alerts'),
    (PhosphorIconsRegular.slidersHorizontal, 'Simulator'),
    (PhosphorIconsRegular.testTube, 'Water Quality'),
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
  const _TopBar({required this.isWide});
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
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
          _IconBadge(icon: PhosphorIconsRegular.bell, badge: '2'),
          const SizedBox(width: 8),
          _IconBadge(icon: PhosphorIconsRegular.userCircle, badge: null),
        ],
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.badge});
  final IconData icon;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: Icon(icon, color: Colors.white54, size: 20),
          onPressed: () {},
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

class _GlobeHero extends StatefulWidget {
  const _GlobeHero({required this.controller});
  final EarthController controller;

  @override
  State<_GlobeHero> createState() => _GlobeHeroState();
}

class _GlobeHeroState extends State<_GlobeHero> {
  double _baseZoom = 1.0;

  void _zoomIn() => widget.controller.setZoom(widget.controller.zoom + 0.25);
  void _zoomOut() => widget.controller.setZoom(widget.controller.zoom - 0.25);

  @override
  Widget build(BuildContext context) {
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
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Earth3D(
                            controller: widget.controller,
                            texture:
                                const AssetImage('assets/earth_texture.png'),
                            initialScale: 1.0,
                          )
                              .animate()
                              .fadeIn(duration: 900.ms)
                              .scale(
                                  begin: const Offset(0.8, 0.8),
                                  duration: 900.ms,
                                  curve: Curves.easeOutBack),
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
              bottom: 28,
              child: Column(
                children: [
                  _ZoomButton(icon: PhosphorIconsRegular.plus, onTap: _zoomIn),
                  const SizedBox(height: 4),
                  _ZoomButton(icon: PhosphorIconsRegular.minus, onTap: _zoomOut),
                ],
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
          border: Border.all(
              color: const Color(0xFF00D4FF).withValues(alpha: 0.3)),
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
              ).animate(onPlay: (c) => c.repeat()).fadeIn().then().fadeOut(
                  duration: 800.ms),
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
            style: GoogleFonts.spaceGrotesk(color: Colors.white38, fontSize: 10)),
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

// ─── Right panel (stats) ─────────────────────────────────────────────────────

class _RightPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: const Color(0xFF060E1A),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 56),
            _StatCard(
              label: 'WATER QUALITY INDEX',
              value: '86.4k',
              delta: '+12% from prev cycle',
              deltaPositive: true,
              icon: PhosphorIconsRegular.drop,
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 12),
            _StatCard(
              label: 'ACTIVE ALERTS',
              value: '03',
              delta: 'Sub-surface anomaly',
              deltaPositive: false,
              icon: PhosphorIconsRegular.warning,
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 12),
            _StatCard(
              label: 'GLOBAL COVERAGE',
              value: '98',
              delta: 'Buffer/Night',
              deltaPositive: true,
              icon: PhosphorIconsRegular.globeHemisphereWest,
            ).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: 20),
            _ScanRegionCard().animate().fadeIn(delay: 500.ms),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.delta,
    required this.deltaPositive,
    required this.icon,
  });

  final String label;
  final String value;
  final String delta;
  final bool deltaPositive;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF00D4FF);
    final deltaColor =
        deltaPositive ? Colors.greenAccent : const Color(0xFFFF4757);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: primary, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white38,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            delta,
            style: GoogleFonts.inter(color: deltaColor, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _ScanRegionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: const Color(0xFF00D4FF).withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ACTIVE SCAN REGION',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white38,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          _RegionChip(label: 'Balkans', severity: 'HIGH'),
          const SizedBox(height: 6),
          _RegionChip(label: 'Iberian Peninsula', severity: 'MED'),
          const SizedBox(height: 6),
          _RegionChip(label: 'Northern Italy', severity: 'LOW'),
        ],
      ),
    );
  }
}

class _RegionChip extends StatelessWidget {
  const _RegionChip({required this.label, required this.severity});
  final String label;
  final String severity;

  @override
  Widget build(BuildContext context) {
    final color = switch (severity) {
      'HIGH' => const Color(0xFFFF4757),
      'MED' => Colors.orangeAccent,
      _ => Colors.greenAccent,
    };
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label,
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 11)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(severity,
              style: GoogleFonts.spaceGrotesk(
                  color: color, fontSize: 8, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

