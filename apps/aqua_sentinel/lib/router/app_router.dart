import 'package:auto_route/auto_route.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/map/presentation/map_screen.dart';
import '../features/simulator/presentation/simulator_screen.dart';

part 'app_router.g.dart';
part 'app_router.gr.dart';

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(page: DashboardRoute.page, initial: true),
        AutoRoute(page: MapRoute.page),
        AutoRoute(page: SimulatorRoute.page),
      ];
}

@riverpod
AppRouter appRouter(AppRouterRef ref) => AppRouter();
