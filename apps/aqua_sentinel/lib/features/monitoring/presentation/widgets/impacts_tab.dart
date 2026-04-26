import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../models/environmental_analysis.dart';
import 'analysis_shared.dart';

class ImpactsTab extends StatelessWidget {
  const ImpactsTab({
    super.key,
    required this.analysis,
    this.riskTimeline,
  });

  final AreaAnalysis analysis;
  final RiskTimeline? riskTimeline;

  @override
  Widget build(BuildContext context) {
    if (riskTimeline != null) {
      return _RiskImpactsList(impacts: riskTimeline!.impacts);
    }

    if (analysis.ecosystemImpacts.isEmpty) {
      return Center(
        child: Text(
          'No ecosystem impact data available',
          style: GoogleFonts.inter(color: Colors.white38),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: analysis.ecosystemImpacts.length,
      itemBuilder: (context, index) {
        return _ImpactCard(impact: analysis.ecosystemImpacts[index]);
      },
    );
  }
}

class _ImpactCard extends StatelessWidget {
  const _ImpactCard({required this.impact});

  final EcosystemImpact impact;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const PhosphorIcon(PhosphorIconsRegular.plant,
                  color: Colors.orangeAccent, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ecosystem Impact',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.orangeAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Affected Species',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: impact.affectedSpecies
                .map((species) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1F2E),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        species,
                        style: GoogleFonts.inter(
                            color: Colors.white70, fontSize: 11),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          Text(
            'Habitat Impact',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            impact.habitatImpact,
            style: GoogleFonts.inter(
                color: Colors.white70, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ImpactMetric(
                    label: 'Duration', value: impact.duration),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ImpactMetric(
                    label: 'Recovery', value: impact.recoveryPotential),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RiskImpactsList extends StatelessWidget {
  const _RiskImpactsList({required this.impacts});

  final List<RiskImpact> impacts;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const TabIntroCard(
          title: 'Impact layer status',
          body:
              'This tab shows which datasets are still needed to translate hazard screening into impacts. It avoids pretending to know losses without exposure layers.',
          color: Colors.orangeAccent,
        ),
        const SizedBox(height: 12),
        ...impacts.map((impact) => _RiskImpactCard(impact: impact)),
      ],
    );
  }
}

class _RiskImpactCard extends StatelessWidget {
  const _RiskImpactCard({required this.impact});

  final RiskImpact impact;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const PhosphorIcon(
                PhosphorIconsRegular.warning,
                color: Colors.orangeAccent,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  impact.category.toUpperCase(),
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.orangeAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            impact.metric,
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            impact.value,
            style: GoogleFonts.spaceGrotesk(
              color: Colors.orangeAccent,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            impact.detail,
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
