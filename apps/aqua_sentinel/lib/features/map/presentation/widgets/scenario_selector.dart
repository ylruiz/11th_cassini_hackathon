import 'package:aqua_sentinel/features/monitoring/models/environmental_analysis.dart';
import 'package:aqua_sentinel/features/monitoring/providers/monitoring_provider.dart';
import 'package:aqua_sentinel/features/simulator/models/water_issue_scenario.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ScenarioSelector extends StatelessWidget {
  const ScenarioSelector({
    super.key,
    required this.ref,
    required List<(WaterIssueType, String, Color)> scenarios,
    required this.body,
    required this.context,
  }) : _scenarios = scenarios;

  final WidgetRef ref;
  final List<(WaterIssueType, String, Color)> _scenarios;
  final WaterBodyInfo body;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    final selectedIssue = ref.watch(selectedIssueTypeProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF00D4FF).withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(PhosphorIconsRegular.drop,
              color: Color(0xFF00D4FF), size: 14),
          const SizedBox(width: 6),
          Text(
            body.name,
            style: GoogleFonts.spaceGrotesk(
              color: const Color(0xFF00D4FF),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          Container(width: 1, height: 16, color: Colors.white12),
          const SizedBox(width: 12),
          Text(
            'SCENARIO:',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _scenarios.map((s) {
                  final (type, label, color) = s;
                  final isSelected = type == selectedIssue;
                  return GestureDetector(
                    onTap: () {
                      ref.read(selectedIssueTypeProvider.notifier).state = type;
                      ref.read(viewModeProvider.notifier).state =
                          ViewMode.simulate;
                    },
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withValues(alpha: 0.15)
                              : const Color(0xFF1A2A3A),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? color
                                : color.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          label,
                          style: GoogleFonts.spaceGrotesk(
                            color: isSelected
                                ? color
                                : color.withValues(alpha: 0.55),
                            fontSize: 11,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Simulation running for ${selectedIssue.name}...',
                    style: GoogleFonts.inter(color: Colors.white),
                  ),
                  backgroundColor: const Color(0xFF0D1B2A),
                ),
              );
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: Colors.greenAccent.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(PhosphorIconsRegular.play,
                        color: Colors.greenAccent, size: 13),
                    const SizedBox(width: 6),
                    Text(
                      'RUN SIMULATION',
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.greenAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
