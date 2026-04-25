import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../monitoring/data/monitoring_provider.dart';
import '../../monitoring/models/environmental_analysis.dart';
import '../../monitoring/presentation/analysis_panel.dart';

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

  @override
  Widget build(BuildContext context) {
    final selectedBody = ref.watch(selectedWaterBodyProvider);

    return Row(
      children: [
        Expanded(
          flex: 6,
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(46.0, 15.0),
              initialZoom: 4.5,
              onTap: (_, point) => _handleMapTap(point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'eu.cassini.aqua_sentinel',
              ),
              MarkerLayer(
                markers: waterBodies.map(_buildMarker).toList(),
              ),
            ],
          ),
        ),
        if (selectedBody != null)
          const SizedBox(
            width: 400,
            child: AnalysisPanel(),
          ),
      ],
    );
  }

  Marker _buildMarker(WaterBodyInfo body) {
    final isSelected = ref.read(selectedWaterBodyProvider)?.id == body.id;

    return Marker(
      point: LatLng(body.latitude, body.longitude),
      width: isSelected ? 50 : 40,
      height: isSelected ? 50 : 40,
      child: GestureDetector(
        onTap: () {
          ref.read(selectedWaterBodyProvider.notifier).state = body;
          _mapController.move(LatLng(body.latitude, body.longitude), 6);
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF00D4FF) : const Color(0xFF0D1B2A),
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
    for (final body in waterBodies) {
      if (_calculateDistance(point.latitude, point.longitude, body.latitude, body.longitude) < 100) {
        ref.read(selectedWaterBodyProvider.notifier).state = body;
        return;
      }
    }
    ref.read(selectedWaterBodyProvider.notifier).state = null;
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
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
    for (int i = 0; i < 10; i++) g = (g + x / g) / 2;
    return g;
  }
}
