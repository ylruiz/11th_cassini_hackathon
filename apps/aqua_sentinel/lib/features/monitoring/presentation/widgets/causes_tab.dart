import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../models/environmental_analysis.dart';
import 'problems_tab.dart' show RiskDriversList;

class CausesTab extends StatelessWidget {
  const CausesTab({
    super.key,
    required this.analysis,
    this.riskTimeline,
  });

  final AreaAnalysis analysis;
  final RiskTimeline? riskTimeline;

  @override
  Widget build(BuildContext context) {
    if (riskTimeline != null) {
      return RiskDriversList(
        drivers: riskTimeline!.drivers,
        evidence: riskTimeline!.evidence,
      );
    }

    if (analysis.causes.isEmpty) {
      return Center(
        child: Text(
          'No cause data available',
          style: GoogleFonts.inter(color: Colors.white38),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: analysis.causes.length,
      itemBuilder: (context, index) {
        return _CauseCard(cause: analysis.causes[index]);
      },
    );
  }
}

class _CauseCard extends StatelessWidget {
  const _CauseCard({required this.cause});

  final ProblemCause cause;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const PhosphorIcon(PhosphorIconsRegular.lightbulb,
                  color: Colors.purpleAccent, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Primary Cause',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.purpleAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            cause.primaryCause,
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Contributing Factors',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          ...cause.contributingFactors.map((factor) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: Colors.white54)),
                    Expanded(
                      child: Text(
                        factor,
                        style: GoogleFonts.inter(
                            color: Colors.white54, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.purpleAccent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PhosphorIcon(PhosphorIconsRegular.broadcast,
                    color: Colors.white24, size: 12),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    cause.sourceDetails,
                    style: GoogleFonts.inter(
                        color: Colors.white38, fontSize: 10, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
