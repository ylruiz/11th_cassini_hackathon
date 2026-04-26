import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class EmptyStateContainer extends StatelessWidget {
  const EmptyStateContainer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
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
