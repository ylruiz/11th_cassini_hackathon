import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/environmental_analysis.dart';
import '../../../simulator/presentation/widgets/simulator_view.dart';
import 'analysis_shared.dart';

class SimulateTab extends StatelessWidget {
  const SimulateTab({super.key, this.riskTimeline});

  final RiskTimeline? riskTimeline;

  @override
  Widget build(BuildContext context) {
    final timeline = riskTimeline;
    if (timeline == null) {
      return const SimulatorView();
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _TimelineConfidenceCard(confidence: timeline.confidence),
        const SizedBox(height: 12),
        _ProjectionOverviewCard(projections: timeline.projections),
        const SizedBox(height: 12),
        ...timeline.projections.map((projection) {
          return _RiskProjectionCard(projection: projection);
        }),
      ],
    );
  }
}

class _TimelineConfidenceCard extends StatelessWidget {
  const _TimelineConfidenceCard({required this.confidence});

  final String confidence;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF081525),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFF00D4FF).withValues(alpha: 0.3)),
      ),
      child: Text(
        confidence,
        style: GoogleFonts.inter(
          color: Colors.white70,
          fontSize: 12,
          height: 1.5,
        ),
      ),
    );
  }
}

class _ProjectionOverviewCard extends StatelessWidget {
  const _ProjectionOverviewCard({required this.projections});

  final List<RiskProjection> projections;

  @override
  Widget build(BuildContext context) {
    final maxDischarge = projections
        .map((p) => p.dischargeChangePercent)
        .fold<double>(1, (max, value) => value > max ? value : max);

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
            'SCENARIO CURVE',
            style: GoogleFonts.spaceGrotesk(
              color: const Color(0xFF00D4FF),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ...projections.map((projection) {
            final value = projection.dischargeChangePercent / maxDischarge;
            final color = severityColor(projection.floodRisk);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 58,
                    child: Text(
                      projection.label,
                      style: GoogleFonts.inter(
                        color: Colors.white54,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: value.clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 44,
                    child: Text(
                      '+${projection.dischargeChangePercent.toStringAsFixed(0)}%',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.spaceGrotesk(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          Text(
            'Bars show a scenario pressure index scaled from current multi-sensor evidence; they are not calibrated discharge forecasts yet.',
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _RiskProjectionCard extends StatelessWidget {
  const _RiskProjectionCard({required this.projection});

  final RiskProjection projection;

  @override
  Widget build(BuildContext context) {
    final floodColor = severityColor(projection.floodRisk);
    final landslideColor = severityColor(projection.landslideRisk);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: floodColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            projection.label,
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ProjectionMetric(
                  label: 'Flood risk',
                  value: projection.floodRisk.displayName,
                  color: floodColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ProjectionMetric(
                  label: 'Landslide risk',
                  value: projection.landslideRisk.displayName,
                  color: landslideColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ProjectionMetric(
                  label: 'Runoff pressure',
                  value:
                      '+${projection.dischargeChangePercent.toStringAsFixed(0)}%',
                  color: const Color(0xFF00D4FF),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ProjectionMetric(
                  label: 'Inundation pressure',
                  value:
                      '+${projection.floodProneAreaChangePercent.toStringAsFixed(0)}%',
                  color: Colors.orangeAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            projection.summary,
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
