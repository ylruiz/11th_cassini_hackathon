import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../monitoring/data/monitoring_provider.dart';
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
                      _buildScenarioSelector(selectedBody, context),
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
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (selectedBody != null || selectedAoi != null)
          const SizedBox(
            width: 400,
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
          _ToolbarButton(
            label: 'OETZTAL PRESET',
            icon: PhosphorIconsRegular.mountains,
            isActive: selectedAoi?.label == 'Oetztal Alps AOI',
            onTap: _selectOetztalPreset,
          ),
          const SizedBox(width: 8),
          _ToolbarButton(
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

  Widget _buildScenarioSelector(WaterBodyInfo body, BuildContext context) {
    final selectedIssue = ref.watch(selectedIssueTypeProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF00D4FF).withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(PhosphorIconsRegular.drop,
              color: Color(0xFF00D4FF), size: 14),
          const SizedBox(width: 6),
          Text(
            body.name,
            style: GoogleFonts.spaceGrotesk(
              color: const Color(0xFF00D4FF),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          Container(width: 1, height: 16, color: Colors.white12),
          const SizedBox(width: 12),
          Text(
            'SCENARIO:',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _scenarios.map((s) {
                  final (type, label, color) = s;
                  final isSelected = type == selectedIssue;
                  return GestureDetector(
                    onTap: () {
                      ref.read(selectedIssueTypeProvider.notifier).state = type;
                      ref.read(viewModeProvider.notifier).state =
                          ViewMode.simulate;
                    },
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withValues(alpha: 0.15)
                              : const Color(0xFF1A2A3A),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? color
                                : color.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          label,
                          style: GoogleFonts.spaceGrotesk(
                            color: isSelected
                                ? color
                                : color.withValues(alpha: 0.55),
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Simulation running for ${selectedIssue.name}...',
                    style: GoogleFonts.inter(color: Colors.white),
                  ),
                  backgroundColor: const Color(0xFF0D1B2A),
                ),
              );
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: Colors.greenAccent.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(PhosphorIconsRegular.play,
                        color: Colors.greenAccent, size: 13),
                    const SizedBox(width: 6),
                    Text(
                      'RUN SIMULATION',
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.greenAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        border: Border(
          top: BorderSide(
            color: const Color(0xFF00D4FF).withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIconsRegular.mapTrifold,
            color: const Color(0xFF00D4FF).withValues(alpha: 0.5),
            size: 13,
          ),
          const SizedBox(width: 6),
          Text(
            'OpenStreetMap',
            style: TextStyle(
              color: const Color(0xFF00D4FF).withValues(alpha: 0.5),
              fontSize: 10,
            ),
          ),
          const SizedBox(width: 16),
          Icon(
            PhosphorIconsRegular.mapPin,
            color: const Color(0xFF00D4FF).withValues(alpha: 0.7),
            size: 13,
          ),
          const SizedBox(width: 4),
          Text(
            'Galileo / EGNOS',
            style: TextStyle(
              color: const Color(0xFF00D4FF).withValues(alpha: 0.7),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),
          Icon(
            PhosphorIconsRegular.broadcast,
            color: const Color(0xFF00D4FF).withValues(alpha: 0.7),
            size: 13,
          ),
          const SizedBox(width: 4),
          Text(
            'Copernicus Sentinel-2',
            style: TextStyle(
              color: const Color(0xFF00D4FF).withValues(alpha: 0.7),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
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

class _ToolbarButton extends StatelessWidget {
  final String label;
  final PhosphorIconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _ToolbarButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

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
