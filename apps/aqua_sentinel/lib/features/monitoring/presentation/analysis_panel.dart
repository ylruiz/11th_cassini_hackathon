import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../models/environmental_analysis.dart';
import '../data/monitoring_provider.dart';

class AnalysisPanel extends ConsumerStatefulWidget {
  const AnalysisPanel({super.key});

  @override
  ConsumerState<AnalysisPanel> createState() => _AnalysisPanelState();
}

class _AnalysisPanelState extends ConsumerState<AnalysisPanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedBody = ref.watch(selectedWaterBodyProvider);
    final selectedAoi = ref.watch(selectedAoiProvider);
    final cs = Theme.of(context).colorScheme;

    if (selectedBody == null && selectedAoi == null) {
      return _buildEmptyState(cs);
    }

    return Container(
      color: const Color(0xFF060E1A),
      child: Column(
        children: [
          _buildHeader(selectedBody, selectedAoi, cs),
          _buildTabBar(cs),
          Expanded(
            child: selectedBody != null
                ? _buildWaterBodyContent(selectedBody)
                : _buildAoiContent(selectedAoi!),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterBodyContent(WaterBodyInfo selectedBody) {
    final analysisAsync =
        ref.watch(environmentalAnalysisProvider(selectedBody.id));
    final riskTimelineAsync = ref.watch(riskTimelineProvider(selectedBody.id));

    return analysisAsync.when(
      data: (analysis) => riskTimelineAsync.when(
        data: (riskTimeline) => _buildTabView(analysis, riskTimeline),
        loading: () => _buildTabView(analysis, null),
        error: (_, __) => _buildTabView(analysis, null),
      ),
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF00D4FF)),
      ),
      error: (e, _) => Center(
        child: Text(
          'Error loading data',
          style: GoogleFonts.inter(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildAoiContent(AoiSelection selectedAoi) {
    final riskTimelineAsync = ref.watch(aoiRiskTimelineProvider(selectedAoi));

    return riskTimelineAsync.when(
      data: (riskTimeline) => _buildTabView(AreaAnalysis.empty(), riskTimeline),
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF00D4FF)),
      ),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Error loading AOI risk data',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.red),
          ),
        ),
      ),
    );
  }

  Widget _buildTabView(AreaAnalysis analysis, RiskTimeline? riskTimeline) {
    return TabBarView(
      controller: _tabController,
      children: [
        _ProblemsTab(analysis: analysis, riskTimeline: riskTimeline),
        _CausesTab(analysis: analysis, riskTimeline: riskTimeline),
        _PreventionTab(analysis: analysis, riskTimeline: riskTimeline),
        _ImpactsTab(analysis: analysis, riskTimeline: riskTimeline),
        _SimulateTab(riskTimeline: riskTimeline),
      ],
    );
  }

  Widget _buildEmptyState(ColorScheme cs) {
    return Container(
      color: const Color(0xFF060E1A),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const PhosphorIcon(
            PhosphorIconsRegular.mapPin,
            color: Colors.white24,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Select a water body',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white54,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap a marker on the map to view\nenvironmental analysis data',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: Colors.white38,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(WaterBodyInfo? body, AoiSelection? aoi, ColorScheme cs) {
    final title = body?.name ?? aoi!.label;
    final latitude = body?.latitude ?? aoi!.latitude;
    final longitude = body?.longitude ?? aoi!.longitude;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF0D1B2A),
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D4FF).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const PhosphorIcon(
                  PhosphorIconsRegular.drop,
                  color: Color(0xFF00D4FF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${latitude.toStringAsFixed(2)}°, ${longitude.toStringAsFixed(2)}°',
                      style: GoogleFonts.inter(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(PhosphorIconsRegular.x,
                    color: Colors.white38, size: 18),
                onPressed: () {
                  ref.read(selectedWaterBodyProvider.notifier).state = null;
                  ref.read(selectedAoiProvider.notifier).state = null;
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(ColorScheme cs) {
    const primary = Color(0xFF00D4FF);
    return Container(
      color: const Color(0xFF060E1A),
      child: TabBar(
        controller: _tabController,
        indicatorColor: primary,
        labelColor: primary,
        unselectedLabelColor: Colors.white38,
        labelStyle: GoogleFonts.spaceGrotesk(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.spaceGrotesk(
          fontSize: 11,
          fontWeight: FontWeight.w400,
        ),
        tabs: const [
          Tab(text: 'PROBLEMS'),
          Tab(text: 'CAUSES'),
          Tab(text: 'PREVENTION'),
          Tab(text: 'IMPACT'),
          Tab(text: 'SIMULATE'),
        ],
      ),
    );
  }
}

class _ProblemsTab extends StatelessWidget {
  final AreaAnalysis analysis;
  final RiskTimeline? riskTimeline;

  const _ProblemsTab({required this.analysis, this.riskTimeline});

  @override
  Widget build(BuildContext context) {
    if (riskTimeline != null) {
      return ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _CurrentSignalCard(timeline: riskTimeline!),
        ],
      );
    }

    if (analysis.problems.isEmpty && riskTimeline == null) {
      return _buildEmpty('No problems detected');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: analysis.problems.length,
      itemBuilder: (context, index) {
        final problem = analysis.problems[index];
        return _ProblemCard(problem: problem);
      },
    );
  }

  Widget _buildEmpty(String message) {
    return Center(
      child: Text(
        message,
        style: GoogleFonts.inter(color: Colors.white38),
      ),
    );
  }
}

class _ProblemCard extends StatelessWidget {
  final EnvironmentalProblem problem;

  const _ProblemCard({required this.problem});

  @override
  Widget build(BuildContext context) {
    final severityColor = _getSeverityColor(problem.severity);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: severityColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  problem.severity.displayName.toUpperCase(),
                  style: GoogleFonts.spaceGrotesk(
                    color: severityColor,
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

  Color _getSeverityColor(Severity severity) {
    switch (severity) {
      case Severity.low:
        return Colors.greenAccent;
      case Severity.medium:
        return Colors.orangeAccent;
      case Severity.high:
        return Colors.deepOrange;
      case Severity.critical:
        return const Color(0xFFFF4757);
    }
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

class _CausesTab extends StatelessWidget {
  final AreaAnalysis analysis;
  final RiskTimeline? riskTimeline;

  const _CausesTab({required this.analysis, this.riskTimeline});

  @override
  Widget build(BuildContext context) {
    if (riskTimeline != null) {
      return _RiskDriversList(
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
        final cause = analysis.causes[index];
        return _CauseCard(cause: cause);
      },
    );
  }
}

class _CauseCard extends StatelessWidget {
  final ProblemCause cause;

  const _CauseCard({required this.cause});

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

class _PreventionTab extends StatelessWidget {
  final AreaAnalysis analysis;
  final RiskTimeline? riskTimeline;

  const _PreventionTab({required this.analysis, this.riskTimeline});

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
        final measure = analysis.preventionMeasures[index];
        return _PreventionCard(measure: measure);
      },
    );
  }
}

class _PreventionCard extends StatelessWidget {
  final PreventionMeasure measure;

  const _PreventionCard({required this.measure});

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
                child: _InfoChip(
                  label: 'Feasibility',
                  value: measure.feasibility.toUpperCase(),
                  color: feasibilityColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _InfoChip(
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

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 9),
          ),
          Text(
            value,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.spaceGrotesk(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImpactsTab extends StatelessWidget {
  final AreaAnalysis analysis;
  final RiskTimeline? riskTimeline;

  const _ImpactsTab({required this.analysis, this.riskTimeline});

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
        final impact = analysis.ecosystemImpacts[index];
        return _ImpactCard(impact: impact);
      },
    );
  }
}

class _ImpactCard extends StatelessWidget {
  final EcosystemImpact impact;

  const _ImpactCard({required this.impact});

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
                child: _ImpactMetric(label: 'Duration', value: impact.duration),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ImpactMetric(
                    label: 'Recovery', value: impact.recoveryPotential),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ImpactMetric extends StatelessWidget {
  final String label;
  final String value;

  const _ImpactMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.orangeAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 9),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.spaceGrotesk(
              color: Colors.orangeAccent,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentSignalCard extends StatelessWidget {
  final RiskTimeline timeline;

  const _CurrentSignalCard({required this.timeline});

  @override
  Widget build(BuildContext context) {
    final signal = timeline.currentSignal;
    final color = _severityColor(signal.severity);

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
              PhosphorIcon(PhosphorIconsRegular.broadcast, color: color, size: 16),
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
          _MethodNote(
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
            ...timeline.evidence.map((metric) {
              return _EvidenceMetricBar(metric: metric);
            }),
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

class _RiskDriversList extends StatelessWidget {
  final List<RiskDriver> drivers;
  final List<RiskEvidenceMetric> evidence;

  const _RiskDriversList({required this.drivers, this.evidence = const []});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (evidence.isNotEmpty) ...[
          _EvidenceSummaryCard(evidence: evidence),
          const SizedBox(height: 12),
        ],
        ...drivers.map((driver) => _RiskDriverCard(driver: driver)),
      ],
    );
  }
}

class _RiskDriverCard extends StatelessWidget {
  final RiskDriver driver;

  const _RiskDriverCard({required this.driver});

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
              _SmallPill(label: driver.status, color: Colors.purpleAccent),
              const SizedBox(width: 8),
              _SmallPill(label: driver.trend, color: const Color(0xFF00D4FF)),
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

class _RiskActionsList extends StatelessWidget {
  final List<RiskAction> actions;

  const _RiskActionsList({required this.actions});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const _TabIntroCard(
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
  final RiskAction action;

  const _RiskActionCard({required this.action});

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
              _SmallPill(label: action.priority, color: Colors.greenAccent),
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
          _SmallPill(label: action.estimatedCost, color: const Color(0xFF00D4FF)),
        ],
      ),
    );
  }
}

class _MethodNote extends StatelessWidget {
  final String text;
  final Color color;

  const _MethodNote({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: Colors.white60,
          fontSize: 11,
          height: 1.4,
        ),
      ),
    );
  }
}

class _EvidenceSummaryCard extends StatelessWidget {
  final List<RiskEvidenceMetric> evidence;

  const _EvidenceSummaryCard({required this.evidence});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF081525),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00D4FF).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DATA USED IN THIS ASSESSMENT',
            style: GoogleFonts.spaceGrotesk(
              color: const Color(0xFF00D4FF),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          ...evidence.map((metric) => _EvidenceMetricBar(metric: metric)),
        ],
      ),
    );
  }
}

class _EvidenceMetricBar extends StatelessWidget {
  final RiskEvidenceMetric metric;

  const _EvidenceMetricBar({required this.metric});

  @override
  Widget build(BuildContext context) {
    final color = _metricColor(metric);
    final fraction = metric.fraction.clamp(0.0, 1.0);
    final valueText = metric.unit.isEmpty
        ? metric.value.toStringAsFixed(2)
        : '${metric.value.toStringAsFixed(1)}${metric.unit}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  metric.label,
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                valueText,
                style: GoogleFonts.spaceGrotesk(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            metric.interpretation,
            style: GoogleFonts.inter(
              color: Colors.white38,
              fontSize: 9,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Color _metricColor(RiskEvidenceMetric metric) {
    final label = metric.label.toLowerCase();
    if (label.contains('coverage') || label.contains('ndvi')) {
      return Colors.greenAccent;
    }
    if (label.contains('snow')) {
      return const Color(0xFF74B9FF);
    }
    if (label.contains('vegetation')) {
      return Colors.orangeAccent;
    }
    return const Color(0xFF00D4FF);
  }
}

class _RiskImpactsList extends StatelessWidget {
  final List<RiskImpact> impacts;

  const _RiskImpactsList({required this.impacts});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const _TabIntroCard(
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
  final RiskImpact impact;

  const _RiskImpactCard({required this.impact});

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

class _SimulateTab extends StatelessWidget {
  final RiskTimeline? riskTimeline;

  const _SimulateTab({this.riskTimeline});

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
  final String confidence;

  const _TimelineConfidenceCard({required this.confidence});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF081525),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00D4FF).withValues(alpha: 0.3)),
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

class _TabIntroCard extends StatelessWidget {
  final String title;
  final String body;
  final Color color;

  const _TabIntroCard({
    required this.title,
    required this.body,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF081525),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.spaceGrotesk(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: GoogleFonts.inter(
              color: Colors.white60,
              fontSize: 11,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectionOverviewCard extends StatelessWidget {
  final List<RiskProjection> projections;

  const _ProjectionOverviewCard({required this.projections});

  @override
  Widget build(BuildContext context) {
    final maxDischarge = projections
        .map((projection) => projection.dischargeChangePercent)
        .fold<double>(1, (max, value) => value > max ? value : max);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF081525),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00D4FF).withValues(alpha: 0.3)),
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
            final color = _severityColor(projection.floodRisk);
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
  final RiskProjection projection;

  const _RiskProjectionCard({required this.projection});

  @override
  Widget build(BuildContext context) {
    final floodColor = _severityColor(projection.floodRisk);
    final landslideColor = _severityColor(projection.landslideRisk);

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
                child: _ProjectionMetric(
                  label: 'Flood risk',
                  value: projection.floodRisk.displayName,
                  color: floodColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ProjectionMetric(
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
                child: _ProjectionMetric(
                  label: 'Runoff pressure',
                  value: '+${projection.dischargeChangePercent.toStringAsFixed(0)}%',
                  color: const Color(0xFF00D4FF),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ProjectionMetric(
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

class _ProjectionMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ProjectionMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 9),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallPill extends StatelessWidget {
  final String label;
  final Color color;

  const _SmallPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: GoogleFonts.spaceGrotesk(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

Color _severityColor(Severity severity) {
  switch (severity) {
    case Severity.low:
      return Colors.greenAccent;
    case Severity.medium:
      return Colors.orangeAccent;
    case Severity.high:
      return Colors.deepOrange;
    case Severity.critical:
      return const Color(0xFFFF4757);
  }
}

