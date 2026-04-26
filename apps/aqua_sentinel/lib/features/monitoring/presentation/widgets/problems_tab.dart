import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../models/environmental_analysis.dart';
import 'analysis_shared.dart';

class ProblemsTab extends StatelessWidget {
  const ProblemsTab({
    super.key,
    required this.analysis,
    this.riskTimeline,
  });

  final AreaAnalysis analysis;
  final RiskTimeline? riskTimeline;

  @override
  Widget build(BuildContext context) {
    if (riskTimeline != null) {
      return ListView(
        padding: const EdgeInsets.all(12),
        children: [
          CurrentSignalCard(timeline: riskTimeline!),
        ],
      );
    }

    if (analysis.problems.isEmpty) {
      return Center(
        child: Text(
          'No problems detected',
          style: GoogleFonts.inter(color: Colors.white38),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: analysis.problems.length,
      itemBuilder: (context, index) {
        return _ProblemCard(problem: analysis.problems[index]);
      },
    );
  }
}

class _ProblemCard extends StatelessWidget {
  const _ProblemCard({required this.problem});

  final EnvironmentalProblem problem;

  @override
  Widget build(BuildContext context) {
    final color = severityColor(problem.severity);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  problem.severity.displayName.toUpperCase(),
                  style: GoogleFonts.spaceGrotesk(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  problem.type.displayName,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            problem.description,
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const PhosphorIcon(PhosphorIconsRegular.broadcast,
                  color: Colors.white24, size: 12),
              const SizedBox(width: 4),
              Text(
                problem.source,
                style: GoogleFonts.inter(color: Colors.white24, fontSize: 10),
              ),
              const Spacer(),
              const PhosphorIcon(PhosphorIconsRegular.clock,
                  color: Colors.white24, size: 12),
              const SizedBox(width: 4),
              Text(
                _formatDate(problem.detectedAt),
                style: GoogleFonts.inter(color: Colors.white24, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }
}

class CurrentSignalCard extends StatelessWidget {
  const CurrentSignalCard({super.key, required this.timeline});

  final RiskTimeline timeline;

  @override
  Widget build(BuildContext context) {
    final signal = timeline.currentSignal;
    final color = severityColor(signal.severity);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF081525),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PhosphorIcon(PhosphorIconsRegular.broadcast,
                  color: color, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  signal.label.toUpperCase(),
                  style: GoogleFonts.spaceGrotesk(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Text(
                signal.value,
                style: GoogleFonts.spaceGrotesk(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          MethodNote(
            text:
                'Screening result, not a certified emergency alert. Values combine live Copernicus evidence with transparent thresholds.',
            color: color,
          ),
          const SizedBox(height: 10),
          Text(
            signal.summary,
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          if (timeline.evidence.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Evidence metrics',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white54,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            ...timeline.evidence
                .map((metric) => EvidenceMetricBar(metric: metric)),
          ],
          const SizedBox(height: 10),
          Text(
            signal.source,
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class RiskDriversList extends StatelessWidget {
  const RiskDriversList({
    super.key,
    required this.drivers,
    this.evidence = const [],
  });

  final List<RiskDriver> drivers;
  final List<RiskEvidenceMetric> evidence;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (evidence.isNotEmpty) ...[
          EvidenceSummaryCard(evidence: evidence),
          const SizedBox(height: 12),
        ],
        ...drivers.map((driver) => _RiskDriverCard(driver: driver)),
      ],
    );
  }
}

class _RiskDriverCard extends StatelessWidget {
  const _RiskDriverCard({required this.driver});

  final RiskDriver driver;

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
              const PhosphorIcon(
                PhosphorIconsRegular.lightbulb,
                color: Colors.purpleAccent,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  driver.label,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              SmallPill(label: driver.status, color: Colors.purpleAccent),
              const SizedBox(width: 8),
              SmallPill(
                  label: driver.trend, color: const Color(0xFF00D4FF)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            driver.detail,
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            driver.source,
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
