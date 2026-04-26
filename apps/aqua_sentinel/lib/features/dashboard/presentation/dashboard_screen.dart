import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_globe_3d/flutter_globe_3d.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../alerts/models/alarm_model.dart';
import '../../alerts/providers/alarms_provider.dart';
import '../../map/presentation/map_screen.dart';
import '../../water_quality/data/water_quality_provider.dart';
import '../../water_quality/presentation/water_quality_screen.dart';
import '../providers/dashboard_tab_provider.dart';
import 'widgets/alarms_overlay.dart';
import 'widgets/dashboard_stats_bar.dart';
import 'widgets/globe_hero.dart';
import 'widgets/risk_intelligence_panel.dart';
import 'widgets/sidebar.dart';
import 'widgets/top_bar.dart';

@RoutePage()
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  late final EarthController _earthController;
  int _selectedNav = 0;
  bool _sidebarExpanded = true;
  bool _alarmsPanelOpen = false;

  @override
  void initState() {
    super.initState();
    _earthController = EarthController();
    _earthController.enableAutoRotate = true;
    _earthController.rotateSpeed = 0.15;
    _earthController.setLightMode(EarthLightMode.realTime);
  }

  @override
  void dispose() {
    _earthController.dispose();
    super.dispose();
  }

  void _onNavSelect(int i) {
    setState(() => _selectedNav = i);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width > 800;
    final activeAlarms = ref.watch(activeAlarmsProvider);

    ref.listen<int?>(dashboardTabProvider, (_, tab) {
      if (tab != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() => _selectedNav = tab);
            ref.read(dashboardTabProvider.notifier).state = null;
          }
        });
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      drawer: isWide ? null : _buildDrawer(context),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: isWide
                    ? Row(children: [
                        DashboardSidebar(
                          selected: _selectedNav,
                          expanded: _sidebarExpanded,
                          onSelect: _onNavSelect,
                          onToggle: () => setState(
                              () => _sidebarExpanded = !_sidebarExpanded),
                        ),
                        Expanded(
                            child: _buildMain(context, isWide, activeAlarms)),
                      ])
                    : _buildMain(context, isWide, activeAlarms),
              ),
            ],
          ),
          if (_alarmsPanelOpen)
            AlarmsOverlay(
              onClose: () => setState(() => _alarmsPanelOpen = false),
              onSelectAlarm: (alarm) {
                ref.read(mapNavigationProvider.notifier).state = LatLng(
                  alarm.location.latitude,
                  alarm.location.longitude,
                );
                setState(() {
                  _alarmsPanelOpen = false;
                  _selectedNav = 1;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMain(
      BuildContext context, bool isWide, List<Alarm> activeAlarms) {
    return IndexedStack(
      index: _selectedNav,
      children: [
        Column(
          children: [
            DashboardTopBar(
              isWide: isWide,
              alarmCount: activeAlarms.length,
              onBellPressed: () =>
                  setState(() => _alarmsPanelOpen = !_alarmsPanelOpen),
            ),
            const DashboardStatsBar(),
            Expanded(
              child: isWide
                  ? Row(
                      children: [
                        Expanded(
                          child: GlobeHero(
                            controller: _earthController,
                            onNavigateToMap: () =>
                                setState(() => _selectedNav = 1),
                          ),
                        ),
                        RiskIntelligencePanel(
                          onNavigateToMonitoring: (LatLng? coord) {
                            if (coord != null) {
                              ref.read(mapNavigationProvider.notifier).state =
                                  coord;
                            }
                            setState(() => _selectedNav = 1);
                          },
                          onNavigateToQuality: (String? bodyId) {
                            if (bodyId != null) {
                              ref
                                  .read(selectedQualityBodyProvider.notifier)
                                  .state = bodyId;
                            }
                            setState(() => _selectedNav = 2);
                          },
                        ),
                      ],
                    )
                  : GlobeHero(
                      controller: _earthController,
                      onNavigateToMap: () => setState(() => _selectedNav = 1),
                    ),
            ),
          ],
        ),
        Column(
          children: [
            DashboardTopBar(
              isWide: isWide,
              alarmCount: activeAlarms.length,
              onBellPressed: () =>
                  setState(() => _alarmsPanelOpen = !_alarmsPanelOpen),
            ),
            const Expanded(child: MapView()),
          ],
        ),
        Column(
          children: [
            DashboardTopBar(
              isWide: isWide,
              alarmCount: activeAlarms.length,
              onBellPressed: () =>
                  setState(() => _alarmsPanelOpen = !_alarmsPanelOpen),
            ),
            const Expanded(child: WaterQualityView()),
          ],
        ),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF0D1B2A),
      child: DashboardSidebar(
        selected: _selectedNav,
        expanded: true,
        onSelect: (i) {
          Navigator.of(context).pop();
          _onNavSelect(i);
        },
        onToggle: () {},
      ),
    );
  }
}
