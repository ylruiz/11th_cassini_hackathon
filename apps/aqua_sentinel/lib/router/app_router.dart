import 'package:auto_route/auto_route.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/map/presentation/map_screen.dart';
import '../features/alerts/presentation/alarm_screen.dart';
import '../features/water_quality/presentation/water_quality_screen.dart';

part 'app_router.g.dart';
part 'app_router.gr.dart';

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(page: DashboardRoute.page, initial: true),
        AutoRoute(page: MapRoute.page),
        AutoRoute(page: WaterQualityRoute.page),
      ];
}

@riverpod
AppRouter appRouter(AppRouterRef ref) => AppRouter();
