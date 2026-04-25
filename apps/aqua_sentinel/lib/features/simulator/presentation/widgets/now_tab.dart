import 'package:aqua_sentinel/features/simulator/presentation/widgets/body_card.dart';
import 'package:aqua_sentinel/features/simulator/presentation/widgets/indicator_tile.dart';
import 'package:aqua_sentinel/features/simulator/presentation/widgets/question_card.dart';
import 'package:aqua_sentinel/features/simulator/presentation/widgets/source_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/water_issue_scenario.dart';

class NowTab extends StatelessWidget {
  const NowTab({super.key, required this.scenario});
  final WaterIssueScenario scenario;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          QuestionCard(
            question: scenario.nowTitle,
            timeLabel: 'LIVE MONITORING',
            timeColor: const Color(0xFF00D4FF),
          ).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 12),
          BodyCard(text: scenario.nowText).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 12),
          ...scenario.nowIndicators.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: IndicatorTile(indicator: e.value)
                      .animate()
                      .fadeIn(delay: (150 * (e.key + 1)).ms)
                      .slideX(begin: 0.05),
                ),
              ),
          const SizedBox(height: 4),
          SourceBadge(source: scenario.source).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }
}
