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
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedBody = ref.watch(selectedWaterBodyProvider);
    final cs = Theme.of(context).colorScheme;

    if (selectedBody == null) {
      return _buildEmptyState(cs);
    }

    final analysisAsync =
        ref.watch(environmentalAnalysisProvider(selectedBody.id));

    return Container(
      color: const Color(0xFF060E1A),
      child: Column(
        children: [
          _buildHeader(selectedBody, cs),
          _buildTabBar(cs),
          Expanded(
            child: analysisAsync.when(
              data: (analysis) => TabBarView(
                controller: _tabController,
                children: [
                  _ProblemsTab(analysis: analysis),
                  _CausesTab(analysis: analysis),
                  _PreventionTab(analysis: analysis),
                  _ImpactsTab(analysis: analysis),
                ],
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme cs) {
    return Container(
      color: const Color(0xFF060E1A),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PhosphorIcon(
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

  Widget _buildHeader(WaterBodyInfo body, ColorScheme cs) {
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
                child: PhosphorIcon(
                  PhosphorIconsRegular.drop,
                  color: const Color(0xFF00D4FF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      body.name,
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${body.latitude.toStringAsFixed(2)}°, ${body.longitude.toStringAsFixed(2)}°',
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
        ],
      ),
    );
  }
}

class _ProblemsTab extends StatelessWidget {
  final AreaAnalysis analysis;

  const _ProblemsTab({required this.analysis});

  @override
  Widget build(BuildContext context) {
    if (analysis.problems.isEmpty) {
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
              PhosphorIcon(PhosphorIconsRegular.broadcast,
                  color: Colors.white24, size: 12),
              const SizedBox(width: 4),
              Text(
                problem.source,
                style: GoogleFonts.inter(color: Colors.white24, fontSize: 10),
              ),
              const Spacer(),
              PhosphorIcon(PhosphorIconsRegular.clock,
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

  const _CausesTab({required this.analysis});

  @override
  Widget build(BuildContext context) {
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
              PhosphorIcon(PhosphorIconsRegular.lightbulb,
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
                PhosphorIcon(PhosphorIconsRegular.broadcast,
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

  const _PreventionTab({required this.analysis});

  @override
  Widget build(BuildContext context) {
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
              PhosphorIcon(PhosphorIconsRegular.shieldCheck,
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
                      PhosphorIcon(PhosphorIconsRegular.currencyEur,
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
                      PhosphorIcon(PhosphorIconsRegular.warning,
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

  const _ImpactsTab({required this.analysis});

  @override
  Widget build(BuildContext context) {
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
              PhosphorIcon(PhosphorIconsRegular.plant,
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

