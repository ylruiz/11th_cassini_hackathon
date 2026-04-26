import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class DashboardTopBar extends StatelessWidget {
  const DashboardTopBar({
    super.key,
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
          DashboardIconBadge(
            icon: PhosphorIconsRegular.bell,
            badge: alarmCount > 0 ? '$alarmCount' : null,
            onPressed: onBellPressed,
          ),
          const SizedBox(width: 8),
          const DashboardIconBadge(
              icon: PhosphorIconsRegular.userCircle, badge: null),
        ],
      ),
    );
  }
}

class DashboardIconBadge extends StatelessWidget {
  const DashboardIconBadge({
    super.key,
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
