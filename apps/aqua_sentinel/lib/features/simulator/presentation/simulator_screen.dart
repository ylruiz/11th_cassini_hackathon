import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../data/simulator_provider.dart';
import '../models/water_issue_scenario.dart';

@RoutePage()
class SimulatorScreen extends ConsumerStatefulWidget {
  const SimulatorScreen({super.key});

  @override
  ConsumerState<SimulatorScreen> createState() => _SimulatorScreenState();
}

class _SimulatorScreenState extends ConsumerState<SimulatorScreen>
    with SingleTickerProviderStateMixin {
  WaterIssueType _issue = WaterIssueType.pollution;
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _selectIssue(WaterIssueType type) {
    setState(() => _issue = type);
    _tabs.animateTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final scenarios = ref.watch(waterScenariosProvider);
    final scenario = scenarios.firstWhere((s) => s.type == _issue);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.surface,
        title: Row(
          children: [
            PhosphorIcon(PhosphorIconsRegular.slidersHorizontal, color: cs.primary),
            const SizedBox(width: 8),
            const Text('Water Issue Simulator'),
          ],
        ),
      ),
      body: Column(
        children: [
          _IssueSelector(selected: _issue, onChanged: _selectIssue),
          _TimelineTabs(controller: _tabs),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _CausesTab(scenario: scenario),
                _NowTab(scenario: scenario),
                _WhatIfTab(scenario: scenario),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Issue selector ───────────────────────────────────────────────────────────

class _IssueSelector extends StatelessWidget {
  const _IssueSelector({required this.selected, required this.onChanged});

  final WaterIssueType selected;
  final ValueChanged<WaterIssueType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF060E1A),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PICK A WATER ISSUE',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white38,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _IssueChip(
                  label: 'Pollution',
                  icon: PhosphorIconsRegular.flask,
                  accentColor: Colors.orangeAccent,
                  selected: selected == WaterIssueType.pollution,
                  onTap: () => onChanged(WaterIssueType.pollution),
                ),
                const SizedBox(width: 8),
                _IssueChip(
                  label: 'Flooding',
                  icon: PhosphorIconsRegular.waves,
                  accentColor: const Color(0xFF00D4FF),
                  selected: selected == WaterIssueType.flooding,
                  onTap: () => onChanged(WaterIssueType.flooding),
                ),
                const SizedBox(width: 8),
                _IssueChip(
                  label: 'Drought',
                  icon: PhosphorIconsRegular.sun,
                  accentColor: const Color(0xFFFFB300),
                  selected: selected == WaterIssueType.drought,
                  onTap: () => onChanged(WaterIssueType.drought),
                ),
                const SizedBox(width: 8),
                _IssueChip(
                  label: 'Heat Stress',
                  icon: PhosphorIconsRegular.thermometer,
                  accentColor: Colors.deepOrangeAccent,
                  selected: selected == WaterIssueType.heatStress,
                  onTap: () => onChanged(WaterIssueType.heatStress),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IssueChip extends StatelessWidget {
  const _IssueChip({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color accentColor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 150.ms,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? accentColor.withValues(alpha: 0.15) : const Color(0xFF0D1B2A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? accentColor.withValues(alpha: 0.6) : Colors.white12,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? accentColor : Colors.white38),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                color: selected ? accentColor : Colors.white54,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Timeline tabs ────────────────────────────────────────────────────────────

class _TimelineTabs extends StatelessWidget {
  const _TimelineTabs({required this.controller});
  final TabController controller;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF00D4FF);
    return Container(
      color: const Color(0xFF060E1A),
      child: TabBar(
        controller: controller,
        indicatorColor: primary,
        labelColor: primary,
        unselectedLabelColor: Colors.white38,
        labelStyle: GoogleFonts.spaceGrotesk(
            fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w400),
        tabs: [
          Tab(
            icon: Icon(PhosphorIconsRegular.clockCounterClockwise, size: 15),
            text: 'Past',
          ),
          Tab(
            icon: Icon(PhosphorIconsRegular.pulse, size: 15),
            text: 'Now',
          ),
          Tab(
            icon: Icon(PhosphorIconsRegular.trendUp, size: 15),
            text: 'What If',
          ),
        ],
      ),
    );
  }
}

// ─── Past / Causes tab ────────────────────────────────────────────────────────

class _CausesTab extends StatelessWidget {
  const _CausesTab({required this.scenario});
  final WaterIssueScenario scenario;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _QuestionCard(
            question: scenario.causeTitle,
            timeLabel: 'HISTORICAL CONTEXT',
            timeColor: Colors.purpleAccent,
          ).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 12),
          _BodyCard(text: scenario.causeText)
              .animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 12),
          _FactChip(fact: scenario.causeFact)
              .animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 12),
          _SourceBadge(source: scenario.source)
              .animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }
}

// ─── Now tab ─────────────────────────────────────────────────────────────────

class _NowTab extends StatelessWidget {
  const _NowTab({required this.scenario});
  final WaterIssueScenario scenario;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _QuestionCard(
            question: scenario.nowTitle,
            timeLabel: 'LIVE MONITORING',
            timeColor: const Color(0xFF00D4FF),
          ).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 12),
          _BodyCard(text: scenario.nowText)
              .animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 12),
          ...scenario.nowIndicators.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _IndicatorTile(indicator: e.value)
                      .animate()
                      .fadeIn(delay: (150 * (e.key + 1)).ms)
                      .slideX(begin: 0.05),
                ),
              ),
          const SizedBox(height: 4),
          _SourceBadge(source: scenario.source)
              .animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }
}

// ─── What If tab ─────────────────────────────────────────────────────────────

class _WhatIfTab extends StatelessWidget {
  const _WhatIfTab({required this.scenario});
  final WaterIssueScenario scenario;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _QuestionCard(
            question: scenario.whatIfTitle,
            timeLabel: 'SIMULATION',
            timeColor: Colors.greenAccent,
          ).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 12),
          _BodyCard(text: scenario.whatIfText)
              .animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 16),
          Text(
            'PROJECTED OUTCOMES',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white38,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 8),
          ...scenario.whatIfImpacts.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ImpactTile(text: e.value)
                      .animate()
                      .fadeIn(delay: (150 * (e.key + 1)).ms)
                      .slideX(begin: 0.05),
                ),
              ),
          const SizedBox(height: 12),
          _SourceBadge(source: scenario.source)
              .animate().fadeIn(delay: 500.ms),
        ],
      ),
    );
  }
}

// ─── Shared sub-widgets ───────────────────────────────────────────────────────

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.question,
    required this.timeLabel,
    required this.timeColor,
  });

  final String question;
  final String timeLabel;
  final Color timeColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: timeColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: timeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: timeColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              timeLabel,
              style: GoogleFonts.spaceGrotesk(
                color: timeColor,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            question,
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _BodyCard extends StatelessWidget {
  const _BodyCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: Colors.white70,
          fontSize: 14,
          height: 1.6,
        ),
      ),
    );
  }
}

class _FactChip extends StatelessWidget {
  const _FactChip({required this.fact});
  final String fact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.purpleAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(PhosphorIconsRegular.lightbulb,
              color: Colors.purpleAccent, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              fact,
              style: GoogleFonts.inter(
                color: Colors.purpleAccent,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IndicatorTile extends StatelessWidget {
  const _IndicatorTile({required this.indicator});
  final ScenarioIndicator indicator;

  @override
  Widget build(BuildContext context) {
    final color =
        indicator.isPositive ? Colors.greenAccent : const Color(0xFFFF6B6B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              indicator.label,
              style: GoogleFonts.inter(
                  color: Colors.white70, fontSize: 13),
            ),
          ),
          Text(
            indicator.value,
            style: GoogleFonts.spaceGrotesk(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImpactTile extends StatelessWidget {
  const _ImpactTile({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.greenAccent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(PhosphorIconsRegular.checkCircle,
              color: Colors.greenAccent, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.source});
  final String source;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(PhosphorIconsRegular.broadcast,
            color: Colors.white24, size: 13),
        const SizedBox(width: 6),
        Text(
          'Data source: $source',
          style: GoogleFonts.inter(
            color: Colors.white24,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
