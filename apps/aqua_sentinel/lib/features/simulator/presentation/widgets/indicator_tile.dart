import 'package:aqua_sentinel/features/simulator/models/water_issue_scenario.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IndicatorTile extends StatelessWidget {
  const IndicatorTile({super.key, required this.indicator});
  final ScenarioIndicator indicator;

  @override
  Widget build(BuildContext context) {
    final color =
        indicator.isPositive ? Colors.greenAccent : const Color(0xFFFF6B6B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              indicator.label,
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
            ),
          ),
          Text(
            indicator.value,
            style: GoogleFonts.spaceGrotesk(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
