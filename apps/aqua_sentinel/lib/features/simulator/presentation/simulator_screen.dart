import 'package:aqua_sentinel/features/simulator/presentation/widgets/causes_tab.dart';
import 'package:aqua_sentinel/features/simulator/presentation/widgets/issue_selector.dart';
import 'package:aqua_sentinel/features/simulator/presentation/widgets/now_tab.dart';
import 'package:aqua_sentinel/features/simulator/presentation/widgets/simulation_viewport.dart';
import 'package:aqua_sentinel/features/simulator/presentation/widgets/timeline_tabs.dart';
import 'package:aqua_sentinel/features/simulator/presentation/widgets/what_if_tab.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../data/simulator_provider.dart';
import '../models/water_issue_scenario.dart';

@RoutePage()
class SimulatorScreen extends StatelessWidget {
  const SimulatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF060E1A),
      body: SimulatorView(),
    );
  }
}

class SimulatorView extends ConsumerStatefulWidget {
  const SimulatorView({super.key});

  @override
  ConsumerState<SimulatorView> createState() => _SimulatorViewState();
}

class _SimulatorViewState extends ConsumerState<SimulatorView>
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

  Color get _accentColor => switch (_issue) {
        WaterIssueType.pollution => Colors.orangeAccent,
        WaterIssueType.flooding => const Color(0xFF00D4FF),
        WaterIssueType.drought => const Color(0xFFFFB300),
        WaterIssueType.heatStress => Colors.deepOrangeAccent,
      };

  @override
  Widget build(BuildContext context) {
    final scenarios = ref.watch(waterScenariosProvider);
    final scenario = scenarios.firstWhere((s) => s.type == _issue);

    return Column(
      children: [
        IssueSelector(selected: _issue, onChanged: _selectIssue),
        SimulationViewport(issue: _issue, accentColor: _accentColor),
        TimelineTabs(controller: _tabs),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              CausesTab(scenario: scenario),
              NowTab(scenario: scenario),
              WhatIfTab(
                scenario: scenario,
                issue: _issue,
                accentColor: _accentColor,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
