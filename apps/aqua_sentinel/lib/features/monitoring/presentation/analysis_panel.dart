import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../models/environmental_analysis.dart';
import '../providers/monitoring_provider.dart';
import 'widgets/causes_tab.dart';
import 'widgets/impacts_tab.dart';
import 'widgets/prevention_tab.dart';
import 'widgets/problems_tab.dart';
import 'widgets/simulate_tab.dart';

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
      return _buildEmptyState();
    }

    return Container(
      color: const Color(0xFF060E1A),
      child: Column(
        children: [
          _buildHeader(selectedBody, selectedAoi),
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
        ProblemsTab(analysis: analysis, riskTimeline: riskTimeline),
        CausesTab(analysis: analysis, riskTimeline: riskTimeline),
        PreventionTab(analysis: analysis, riskTimeline: riskTimeline),
        ImpactsTab(analysis: analysis, riskTimeline: riskTimeline),
        SimulateTab(riskTimeline: riskTimeline),
      ],
    );
  }

  Widget _buildEmptyState() {
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

  Widget _buildHeader(WaterBodyInfo? body, AoiSelection? aoi) {
    final title = body?.name ?? aoi!.label;
    final latitude = body?.latitude ?? aoi!.latitude;
    final longitude = body?.longitude ?? aoi!.longitude;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF0D1B2A),
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
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
