import 'package:aqua_sentinel/features/simulator/presentation/widgets/body_card.dart';
import 'package:aqua_sentinel/features/simulator/presentation/widgets/impact_tile.dart';
import 'package:aqua_sentinel/features/simulator/presentation/widgets/projection_chart.dart';
import 'package:aqua_sentinel/features/simulator/presentation/widgets/question_card.dart';
import 'package:aqua_sentinel/features/simulator/presentation/widgets/source_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/water_issue_scenario.dart';

class WhatIfTab extends StatelessWidget {
  const WhatIfTab({
    super.key,
    required this.scenario,
    required this.issue,
    required this.accentColor,
  });

  final WaterIssueScenario scenario;
  final WaterIssueType issue;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          QuestionCard(
            question: scenario.whatIfTitle,
            timeLabel: 'SIMULATION',
            timeColor: Colors.greenAccent,
          ).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 12),
          BodyCard(text: scenario.whatIfText).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 16),
          ProjectionChart(issue: issue, accentColor: accentColor)
              .animate()
              .fadeIn(delay: 150.ms),
          const SizedBox(height: 16),
          Text(
            'PROJECTED OUTCOMES',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white38,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 8),
          ...scenario.whatIfImpacts.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ImpactTile(text: e.value)
                      .animate()
                      .fadeIn(delay: (150 * (e.key + 1)).ms)
                      .slideX(begin: 0.05),
                ),
              ),
          const SizedBox(height: 12),
          SourceBadge(source: scenario.source).animate().fadeIn(delay: 500.ms),
        ],
      ),
    );
  }
}
