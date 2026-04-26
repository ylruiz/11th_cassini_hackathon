import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latlong2/latlong.dart';

/// Set this to make the dashboard 3D globe rotate to a specific lat/lon.
/// The globe listens and clears it after moving.
final dashboardGlobeFocusProvider = StateProvider<LatLng?>((ref) => null);
