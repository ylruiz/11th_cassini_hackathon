import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../models/environmental_analysis.dart';
import 'analysis_shared.dart';

class PreventionTab extends StatelessWidget {
  const PreventionTab({
    super.key,
    required this.analysis,
    this.riskTimeline,
  });

  final AreaAnalysis analysis;
  final RiskTimeline? riskTimeline;

  @override
  Widget build(BuildContext context) {
    if (riskTimeline != null) {
      return _RiskActionsList(actions: riskTimeline!.actions);
    }

    if (analysis.preventionMeasures.isEmpty) {
      return Center(
        child: Text(
          'No prevention measures available',
          style: GoogleFonts.inter(color: Colors.white38),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: analysis.preventionMeasures.length,
      itemBuilder: (context, index) {
        return _PreventionCard(measure: analysis.preventionMeasures[index]);
      },
    );
  }
}

class _PreventionCard extends StatelessWidget {
  const _PreventionCard({required this.measure});

  final PreventionMeasure measure;

  @override
  Widget build(BuildContext context) {
    final feasibilityColor = _getFeasibilityColor(measure.feasibility);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const PhosphorIcon(PhosphorIconsRegular.shieldCheck,
                  color: Colors.greenAccent, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Prevention Measure',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.greenAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            measure.action,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InfoChip(
                  label: 'Feasibility',
                  value: measure.feasibility.toUpperCase(),
                  color: feasibilityColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: InfoChip(
                  label: 'Timeline',
                  value: measure.timeline,
                  color: const Color(0xFF00D4FF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const PhosphorIcon(PhosphorIconsRegular.currencyEur,
                          color: Colors.white38, size: 13),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          measure.estimatedCost,
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.greenAccent,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border:
                        Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const PhosphorIcon(PhosphorIconsRegular.warning,
                          color: Colors.orange, size: 13),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          measure.costIfNothingDone,
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.orange,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getFeasibilityColor(String feasibility) {
    switch (feasibility.toLowerCase()) {
      case 'high':
        return Colors.greenAccent;
      case 'medium':
        return Colors.orangeAccent;
      case 'low':
        return const Color(0xFFFF4757);
      default:
        return Colors.white38;
    }
  }
}

class _RiskActionsList extends StatelessWidget {
  const _RiskActionsList({required this.actions});

  final List<RiskAction> actions;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const TabIntroCard(
          title: 'Recommended next actions',
          body:
              'Actions separate observed evidence, calibration, and missing layers. The first step is ground-truthing; the model-improvement step is EFAS/Lisflood and exposure integration.',
          color: Colors.greenAccent,
        ),
        const SizedBox(height: 12),
        ...actions.map((action) => _RiskActionCard(action: action)),
      ],
    );
  }
}

class _RiskActionCard extends StatelessWidget {
  const _RiskActionCard({required this.action});

  final RiskAction action;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SmallPill(label: action.priority, color: Colors.greenAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  action.timeline,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.inter(color: Colors.white38, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            action.title,
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            action.expectedEffect,
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          SmallPill(
              label: action.estimatedCost, color: const Color(0xFF00D4FF)),
        ],
      ),
    );
  }
}
