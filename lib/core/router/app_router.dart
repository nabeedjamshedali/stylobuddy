import 'package:go_router/go_router.dart';

import '../../features/auth/auth_routes.dart';
import '../../features/builder/builder_routes.dart';
import '../../features/calendar/calendar_routes.dart';
import '../../features/home/home_routes.dart';
import '../../features/insights/insights_routes.dart';
import '../../features/matching/matching_routes.dart';
import '../../features/onboarding/onboarding_routes.dart';
import '../../features/packing/packing_routes.dart';
import '../../features/profile/profile_routes.dart';
import '../../features/saved/saved_routes.dart';
import '../../features/shopping/shopping_routes.dart';
import '../../features/stylist/stylist_routes.dart';
import '../../features/wardrobe/wardrobe_routes.dart';
import '../../shared/widgets/generic_preview_view.dart';
import 'app_routes.dart';
import 'app_shell.dart';

/// Builds the app router. Onboarding/auth routes sit outside the shell (no
/// bottom nav); everything else renders inside [AppShell].
GoRouter createAppRouter({String initialLocation = AppRoutes.welcome}) {
  return GoRouter(
    initialLocation: initialLocation,
    errorBuilder: (context, state) => const GenericPreviewView(),
    routes: [
      ...onboardingRoutes,
      ...authRoutes,
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          ...homeRoutes,
          ...wardrobeRoutes,
          ...stylistRoutes,
          ...matchingRoutes,
          ...builderRoutes,
          ...savedRoutes,
          ...calendarRoutes,
          ...packingRoutes,
          ...shoppingRoutes,
          ...insightsRoutes,
          ...profileRoutes,
        ],
      ),
    ],
  );
}

final GoRouter appRouter = createAppRouter();
