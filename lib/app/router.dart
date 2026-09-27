import 'package:go_router/go_router.dart';
import '../features/conversation/presentation/screens/conversation_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';

class AppRoutes {
  static const String home = '/';
  static const String settings = '/settings';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const ConversationScreen(),
    ),
    GoRoute(
      path: AppRoutes.settings,
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
