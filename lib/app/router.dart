import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppRoutes {
  static const String home = '/';
  static const String settings = '/settings';
  static const String history = '/history';
}

/// AppRouter creates the GoRouter configuration.
/// Pass in builder functions for decoupling presentation modules.
GoRouter createRouter({
  required Widget Function(BuildContext) homeBuilder,
  required Widget Function(BuildContext) settingsBuilder,
  Widget Function(BuildContext)? historyBuilder,
}) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => homeBuilder(context),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => settingsBuilder(context),
      ),
      if (historyBuilder != null)
        GoRoute(
          path: AppRoutes.history,
          builder: (context, state) => historyBuilder(context),
        ),
    ],
  );
}
