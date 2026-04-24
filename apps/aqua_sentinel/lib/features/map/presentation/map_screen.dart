import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

@RoutePage()
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  _LayerMode _activeLayer = _LayerMode.base;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.surface,
        title: Row(
          children: [
            PhosphorIcon(PhosphorIcons.mapTrifold(), color: cs.primary),
            const SizedBox(width: 8),
            const Text('Water Map'),
          ],
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(48.8, 10.0),
              initialZoom: 4.5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'eu.cassini.aqua_sentinel',
              ),
              if (_activeLayer == _LayerMode.copernicus)
                TileLayer(
                  urlTemplate:
                      'https://maps.googleapis.com/maps/vt?pb=!1m5!1m4!1i{z}!2i{x}!3i{y}!4i256',
                  tileDisplay: const TileDisplay.instantaneous(opacity: 0.5),
                ),
            ],
          ),
          Positioned(
            top: 12,
            right: 12,
            child: _LayerSelector(
              active: _activeLayer,
              onChanged: (mode) => setState(() => _activeLayer = mode),
            ),
          ),
        ],
      ),
    );
  }
}

enum _LayerMode { base, copernicus, flood }

class _LayerSelector extends StatelessWidget {
  const _LayerSelector({required this.active, required this.onChanged});
  final _LayerMode active;
  final ValueChanged<_LayerMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            _LayerButton(
              label: 'Base',
              icon: PhosphorIconsRegular.mapTrifold,
              active: active == _LayerMode.base,
              onTap: () => onChanged(_LayerMode.base),
            ),
            const SizedBox(height: 4),
            _LayerButton(
              label: 'Copernicus',
              icon: PhosphorIconsRegular.broadcast,
              active: active == _LayerMode.copernicus,
              onTap: () => onChanged(_LayerMode.copernicus),
            ),
            const SizedBox(height: 4),
            _LayerButton(
              label: 'Flood Risk',
              icon: PhosphorIcons.warning(),
              active: active == _LayerMode.flood,
              onTap: () => onChanged(_LayerMode.flood),
            ),
          ],
        ),
      ),
    );
  }
}

class _LayerButton extends StatelessWidget {
  const _LayerButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? cs.primary.withOpacity(0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: active ? cs.primary : Colors.transparent, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(icon,
                color: active ? cs.primary : cs.tertiary, size: 16),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: active ? cs.primary : cs.tertiary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
