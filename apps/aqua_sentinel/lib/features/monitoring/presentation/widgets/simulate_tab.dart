import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/environmental_analysis.dart';
import 'analysis_shared.dart';

class SimulateTab extends StatelessWidget {
  const SimulateTab({super.key, this.riskTimeline});

  final RiskTimeline? riskTimeline;

  @override
  Widget build(BuildContext context) {
    final timeline = riskTimeline;
    if (timeline == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Future risk timeline is available for Inn River in this MVP.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _HydrologyContextCard(evidence: timeline.evidence),
        const SizedBox(height: 12),
        _ScenarioTimelineCard(projections: timeline.projections),
        const SizedBox(height: 12),
        const _ScenarioCaveatCard(),
      ],
    );
  }
}

class _HydrologyContextCard extends StatelessWidget {
  const _HydrologyContextCard({required this.evidence});

  final List<RiskEvidenceMetric> evidence;

  @override
  Widget build(BuildContext context) {
    final hydrologyEvidence = evidence.where((metric) {
      final text = '${metric.label} ${metric.source}'.toLowerCase();
      return text.contains('efas') || text.contains('lisflood');
    }).toList();

    if (hydrologyEvidence.isEmpty) {
      return const TabIntroCard(
        title: 'Hydrology forecast context',
        body:
            'EFAS/Lisflood is not connected for this AOI yet. Scenario pressure uses satellite evidence and stress assumptions.',
        color: Colors.orangeAccent,
      );
    }

    final metric = hydrologyEvidence.first;
    final valueText = metric.unit.isEmpty
        ? metric.value.toStringAsFixed(2)
        : '${metric.value.toStringAsFixed(1)}${metric.unit}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF081525),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'HYDROLOGY CONTEXT',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.greenAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Text(
                valueText,
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.greenAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Cached EFAS/Lisflood seasonal discharge anomaly. Used as context, not a live warning.',
            style: GoogleFonts.inter(
              color: Colors.white54,
              fontSize: 10,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScenarioTimelineCard extends StatelessWidget {
  const _ScenarioTimelineCard({required this.projections});

  final List<RiskProjection> projections;

  @override
  Widget build(BuildContext context) {
    final futureProjections = projections
        .where((projection) => projection.horizonYears > 0)
        .toList(growable: false);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF081525),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFF00D4FF).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SCENARIO TIMELINE',
            style: GoogleFonts.spaceGrotesk(
              color: const Color(0xFF00D4FF),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          const _ScenarioHeaderRow(),
          const SizedBox(height: 8),
          ...futureProjections.map((projection) {
            return _ScenarioTimelineRow(projection: projection);
          }),
        ],
      ),
    );
  }
}

class _ScenarioHeaderRow extends StatelessWidget {
  const _ScenarioHeaderRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _ScenarioHeaderCell(label: 'Year', flex: 2),
        _ScenarioHeaderCell(label: 'Flood'),
        _ScenarioHeaderCell(label: 'Slope'),
        _ScenarioHeaderCell(label: 'Runoff'),
        _ScenarioHeaderCell(label: 'Inund.'),
      ],
    );
  }
}

class _ScenarioHeaderCell extends StatelessWidget {
  const _ScenarioHeaderCell({required this.label, this.flex = 1});

  final String label;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: Colors.white38,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ScenarioTimelineRow extends StatelessWidget {
  const _ScenarioTimelineRow({required this.projection});

  final RiskProjection projection;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: severityColor(projection.floodRisk).withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              projection.label,
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _ScenarioValue(
            value: projection.floodRisk.displayName,
            color: severityColor(projection.floodRisk),
          ),
          _ScenarioValue(
            value: projection.landslideRisk.displayName,
            color: severityColor(projection.landslideRisk),
          ),
          _ScenarioValue(
            value: '+${projection.dischargeChangePercent.toStringAsFixed(0)}%',
            color: const Color(0xFF00D4FF),
          ),
          _ScenarioValue(
            value:
                '+${projection.floodProneAreaChangePercent.toStringAsFixed(0)}%',
            color: Colors.orangeAccent,
          ),
        ],
      ),
    );
  }
}

class _ScenarioValue extends StatelessWidget {
  const _ScenarioValue({required this.value, required this.color});

  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.spaceGrotesk(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ScenarioCaveatCard extends StatelessWidget {
  const _ScenarioCaveatCard();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Scenario pressure, not an official forecast. Uses Sentinel evidence plus cached EFAS context where available.',
      style: GoogleFonts.inter(
        color: Colors.white38,
        fontSize: 10,
        height: 1.35,
      ),
    );
  }
}
