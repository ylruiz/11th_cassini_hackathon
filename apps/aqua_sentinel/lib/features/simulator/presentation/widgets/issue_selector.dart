import 'package:aqua_sentinel/features/simulator/models/water_issue_scenario.dart';
import 'package:aqua_sentinel/features/simulator/presentation/widgets/issue_chip.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class IssueSelector extends StatelessWidget {
  const IssueSelector(
      {super.key, required this.selected, required this.onChanged});

  final WaterIssueType selected;
  final ValueChanged<WaterIssueType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF060E1A),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PICK A WATER ISSUE',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white38,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                IssueChip(
                  label: 'Pollution',
                  icon: PhosphorIconsRegular.flask,
                  accentColor: Colors.orangeAccent,
                  selected: selected == WaterIssueType.pollution,
                  onTap: () => onChanged(WaterIssueType.pollution),
                ),
                const SizedBox(width: 8),
                IssueChip(
                  label: 'Flooding',
                  icon: PhosphorIconsRegular.waves,
                  accentColor: const Color(0xFF00D4FF),
                  selected: selected == WaterIssueType.flooding,
                  onTap: () => onChanged(WaterIssueType.flooding),
                ),
                const SizedBox(width: 8),
                IssueChip(
                  label: 'Drought',
                  icon: PhosphorIconsRegular.sun,
                  accentColor: const Color(0xFFFFB300),
                  selected: selected == WaterIssueType.drought,
                  onTap: () => onChanged(WaterIssueType.drought),
                ),
                const SizedBox(width: 8),
                IssueChip(
                  label: 'Heat Stress',
                  icon: PhosphorIconsRegular.thermometer,
                  accentColor: Colors.deepOrangeAccent,
                  selected: selected == WaterIssueType.heatStress,
                  onTap: () => onChanged(WaterIssueType.heatStress),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
