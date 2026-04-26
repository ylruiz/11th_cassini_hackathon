import 'package:aqua_sentinel/features/map/presentation/widgets/footer.dart';
import 'package:aqua_sentinel/features/map/presentation/widgets/scenario_selector.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../alerts/providers/alarms_provider.dart';
import '../../monitoring/providers/monitoring_provider.dart';
import '../../monitoring/models/environmental_analysis.dart';
import '../../monitoring/presentation/analysis_panel.dart';
import '../../simulator/models/water_issue_scenario.dart';


/// Set this to a lat/lon to make the map fly to that location.
/// MapView listens to it and clears it after moving.
final mapNavigationProvider = StateProvider<LatLng?>((ref) => null);

@RoutePage()
class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF060E1A),
      body: MapView(),
    );
  }
}

class MapView extends ConsumerStatefulWidget {
  const MapView({super.key});

  @override
  ConsumerState<MapView> createState() => _MapViewState();
}

class _MapViewState extends ConsumerState<MapView> {
  final MapController _mapController = MapController();
  bool _isAoiMode = false;
  LatLng? _aoiStart;

  @override
  Widget build(BuildContext context) {
    final selectedBody = ref.watch(selectedWaterBodyProvider);
    final selectedAoi = ref.watch(selectedAoiProvider);

    ref.listen<LatLng?>(mapNavigationProvider, (_, target) {
      if (target != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _mapController.move(target, 8);
            ref.read(mapNavigationProvider.notifier).state = null;
          }
        });
      }
    });

    ref.listen<String?>(selectedAlarmIdProvider, (_, alarmId) {
      if (alarmId != null) {
        ref.read(selectedAlarmIdProvider.notifier).state = null;
      }
    });

    return Row(
      children: [
        Expanded(
          flex: 6,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF060E1A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF00D4FF).withValues(alpha: 0.15),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  children: [
                    if (selectedBody != null)
                      ScenarioSelector(
                          ref: ref,
                          body: selectedBody,
                          context: context,
                          scenarios: _scenarios),
                    _buildAoiToolbar(context),
                    Expanded(
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: const LatLng(46.0, 15.0),
                          initialZoom: 4.5,
                          onTap: (_, point) => _handleMapTap(point),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'eu.cassini.aqua_sentinel',
                          ),
                          MarkerLayer(
                            markers:
                                waterBodies.map(_buildWaterBodyMarker).toList(),
                          ),
                          MarkerLayer(
                            markers: mountainRanges
                                .map(_buildMountainMarker)
                                .toList(),
                          ),
                          if (selectedAoi != null)
                            PolygonLayer(
                              polygons: [_buildAoiPolygon(selectedAoi)],
                            ),
                          if (_aoiStart != null)
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: _aoiStart!,
                                  width: 34,
                                  height: 34,
                                  child: const Icon(
                                    PhosphorIconsRegular.crosshair,
                                    color: Color(0xFF00D4FF),
                                    size: 28,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const Footer(),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (selectedBody != null || selectedAoi != null)
          const SizedBox(
            width: 460,
            child: AnalysisPanel(),
          ),
      ],
    );
  }

  static const _scenarios = [
    (WaterIssueType.pollution, 'Pollution', Color(0xFFFF9F43)),
    (WaterIssueType.flooding, 'Flooding', Color(0xFF00D4FF)),
    (WaterIssueType.drought, 'Drought', Color(0xFFFFC048)),
    (WaterIssueType.heatStress, 'Heat Stress', Color(0xFFFF6B35)),
    (WaterIssueType.snowMelt, 'Snow Melt', Color(0xFF74B9FF)),
  ];

  Widget _buildAoiToolbar(BuildContext context) {
    final selectedAoi = ref.watch(selectedAoiProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF081525),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF00D4FF).withValues(alpha: 0.12),
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            PhosphorIconsRegular.selection,
            color: Color(0xFF00D4FF),
            size: 14,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              selectedAoi == null
                  ? (_isAoiMode
                      ? 'Click two map corners to screen an Alpine AOI'
                      : 'Screen a custom Alpine region with Copernicus')
                  : 'AOI selected: ${selectedAoi.label}',
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 11),
            ),
          ),
          const SizedBox(width: 8),
          ToolbarButton(
            label: 'OETZTAL PRESET',
            icon: PhosphorIconsRegular.mountains,
            isActive: selectedAoi?.label == 'Oetztal Alps AOI',
            onTap: _selectOetztalPreset,
          ),
          const SizedBox(width: 8),
          ToolbarButton(
            label: 'INN VALLEY',
            icon: PhosphorIconsRegular.mapPin,
            isActive: selectedAoi?.label == 'Inn Valley AOI',
            onTap: _selectInnValleyPreset,
          ),
          const SizedBox(width: 8),
          ToolbarButton(
            label: _isAoiMode ? 'CANCEL DRAW' : 'DRAW AOI',
            icon: _isAoiMode
                ? PhosphorIconsRegular.x
                : PhosphorIconsRegular.rectangle,
            isActive: _isAoiMode,
            onTap: () {
              setState(() {
                _isAoiMode = !_isAoiMode;
                _aoiStart = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Marker _buildWaterBodyMarker(WaterBodyInfo body) {
    final isSelected = ref.read(selectedWaterBodyProvider)?.id == body.id;

    return Marker(
      point: LatLng(body.latitude, body.longitude),
      width: isSelected ? 50 : 40,
      height: isSelected ? 50 : 40,
      child: GestureDetector(
        onTap: () {
          ref.read(selectedWaterBodyProvider.notifier).state = body;
          ref.read(selectedAoiProvider.notifier).state = null;
          setState(() {
            _isAoiMode = false;
            _aoiStart = null;
          });
          _mapController.move(LatLng(body.latitude, body.longitude), 6);
        },
        child: Container(
          decoration: BoxDecoration(
            color:
                isSelected ? const Color(0xFF00D4FF) : const Color(0xFF0D1B2A),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF00D4FF), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00D4FF).withValues(alpha: 0.4),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            PhosphorIconsRegular.drop,
            color: isSelected ? Colors.white : const Color(0xFF00D4FF),
            size: isSelected ? 24 : 18,
          ),
        ),
      ),
    );
  }

  Marker _buildMountainMarker(MountainRangeInfo mountain) {
    return Marker(
      point: LatLng(mountain.latitude, mountain.longitude),
      width: 44,
      height: 44,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isAoiMode = false;
            _aoiStart = null;
          });
          ref.read(selectedWaterBodyProvider.notifier).state = null;
          ref.read(selectedAoiProvider.notifier).state = AoiSelection(
            label: mountain.name,
            bbox: AoiBounds(
              west: mountain.longitude - 0.5,
              south: mountain.latitude - 0.5,
              east: mountain.longitude + 0.5,
              north: mountain.latitude + 0.5,
            ),
          );
          _mapController.move(
              LatLng(mountain.latitude, mountain.longitude), 6);
        },
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0D1B2A),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFFF9F43), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF9F43).withValues(alpha: 0.5),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            PhosphorIconsRegular.mountains,
            color: Color(0xFFFF9F43),
            size: 20,
          ),
        ),
      ),
    );
  }

  void _handleMapTap(LatLng point) {
    if (_isAoiMode) {
      _handleAoiTap(point);
      return;
    }

    for (final body in waterBodies) {
      if (_calculateDistance(
              point.latitude, point.longitude, body.latitude, body.longitude) <
          100) {
        ref.read(selectedWaterBodyProvider.notifier).state = body;
        ref.read(selectedAoiProvider.notifier).state = null;
        return;
      }
    }
    for (final mountain in mountainRanges) {
      if (_calculateDistance(point.latitude, point.longitude,
              mountain.latitude, mountain.longitude) <
          150) {
        ref.read(selectedWaterBodyProvider.notifier).state = null;
        ref.read(selectedAoiProvider.notifier).state = AoiSelection(
          label: mountain.name,
          bbox: AoiBounds(
            west: mountain.longitude - 2.0,
            south: mountain.latitude - 2.0,
            east: mountain.longitude + 2.0,
            north: mountain.latitude + 2.0,
          ),
        );
        _mapController.move(
            LatLng(mountain.latitude, mountain.longitude), 6);
        return;
      }
    }
    ref.read(selectedWaterBodyProvider.notifier).state = null;
    ref.read(selectedAoiProvider.notifier).state = null;
  }

  void _handleAoiTap(LatLng point) {
    if (_aoiStart == null) {
      setState(() {
        _aoiStart = point;
      });
      return;
    }

    final west = _min(_aoiStart!.longitude, point.longitude);
    final east = _max(_aoiStart!.longitude, point.longitude);
    final south = _min(_aoiStart!.latitude, point.latitude);
    final north = _max(_aoiStart!.latitude, point.latitude);

    if ((east - west) < 0.02 || (north - south) < 0.02) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Draw a larger region for AOI screening.',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF0D1B2A),
        ),
      );
      return;
    }

    ref.read(selectedWaterBodyProvider.notifier).state = null;
    ref.read(selectedAoiProvider.notifier).state = AoiSelection(
      label: 'Custom Alpine AOI',
      bbox: AoiBounds(west: west, south: south, east: east, north: north),
    );
    setState(() {
      _isAoiMode = false;
      _aoiStart = null;
    });
  }

  void _selectOetztalPreset() {
    ref.read(selectedWaterBodyProvider.notifier).state = null;
    ref.read(selectedAoiProvider.notifier).state = const AoiSelection(
      label: 'Oetztal Alps AOI',
      bbox: AoiBounds(
        west: 10.75,
        south: 46.75,
        east: 11.35,
        north: 47.35,
      ),
    );
    setState(() {
      _isAoiMode = false;
      _aoiStart = null;
    });
    _mapController.move(const LatLng(47.05, 11.05), 8);
  }

  void _selectInnValleyPreset() {
    ref.read(selectedWaterBodyProvider.notifier).state = null;
    ref.read(selectedAoiProvider.notifier).state = const AoiSelection(
      label: 'Inn Valley AOI',
      bbox: AoiBounds(
        west: 11.15,
        south: 47.15,
        east: 11.75,
        north: 47.55,
      ),
    );
    setState(() {
      _isAoiMode = false;
      _aoiStart = null;
    });
    _mapController.move(const LatLng(47.35, 11.45), 8);
  }

  Polygon _buildAoiPolygon(AoiSelection selection) {
    final bbox = selection.bbox;
    return Polygon(
      points: [
        LatLng(bbox.south, bbox.west),
        LatLng(bbox.south, bbox.east),
        LatLng(bbox.north, bbox.east),
        LatLng(bbox.north, bbox.west),
      ],
      color: const Color(0xFF00D4FF).withValues(alpha: 0.12),
      borderColor: const Color(0xFF00D4FF),
      borderStrokeWidth: 2,
    );
  }

  double _min(double a, double b) => a < b ? a : b;

  double _max(double a, double b) => a > b ? a : b;

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 -
        _cos((lat2 - lat1) * p) / 2 +
        _cos(lat1 * p) * _cos(lat2 * p) * (1 - _cos((lon2 - lon1) * p)) / 2;
    return 12742 * _asin(_sqrt(a));
  }

  double _cos(double x) {
    x = x % (2 * 3.14159);
    double result = 1.0, term = 1.0;
    for (int i = 1; i <= 10; i++) {
      term *= -x * x / ((2 * i - 1) * (2 * i));
      result += term;
    }
    return result;
  }

  double _asin(double x) {
    if (x >= 1) return 1.570796;
    if (x <= -1) return -1.570796;
    return x + (x * x * x) / 6 + (3 * x * x * x * x * x) / 40;
  }

  double _sqrt(double x) {
    if (x <= 0) return 0;
    double g = x / 2;
    for (int i = 0; i < 10; i++) {
      g = (g + x / g) / 2;
    }
    return g;
  }
}

class ToolbarButton extends StatelessWidget {
  const ToolbarButton({
    super.key,
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final PhosphorIconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? const Color(0xFF00D4FF) : Colors.white38;

    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isActive ? 0.16 : 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 13),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
