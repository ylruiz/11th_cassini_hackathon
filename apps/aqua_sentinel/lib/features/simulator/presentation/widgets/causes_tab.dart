import 'package:aqua_sentinel/features/simulator/presentation/widgets/body_card.dart';
import 'package:aqua_sentinel/features/simulator/presentation/widgets/fact_chip.dart';
import 'package:aqua_sentinel/features/simulator/presentation/widgets/question_card.dart';
import 'package:aqua_sentinel/features/simulator/presentation/widgets/source_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/water_issue_scenario.dart';

class CausesTab extends StatelessWidget {
  const CausesTab({super.key, required this.scenario});
  final WaterIssueScenario scenario;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          QuestionCard(
            question: scenario.causeTitle,
            timeLabel: 'HISTORICAL CONTEXT',
            timeColor: Colors.purpleAccent,
          ).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 12),
          BodyCard(text: scenario.causeText).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 12),
          FactChip(fact: scenario.causeFact).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 12),
          SourceBadge(source: scenario.source).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }
}
