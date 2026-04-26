import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class DashboardSidebar extends StatelessWidget {
  const DashboardSidebar({
    super.key,
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
                (e) => DashboardNavItem(
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
            (e) => DashboardNavItem(
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
          ClipOval(
            child: Image.asset(
              'assets/logo.png',
              width: 32,
              height: 32,
              fit: BoxFit.cover,
            ),
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

class DashboardNavItem extends StatelessWidget {
  const DashboardNavItem({
    super.key,
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
