import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../shared/widgets/generic_preview_view.dart';

/// Placeholder routes; replaced by the real onboarding screens.
final List<RouteBase> onboardingRoutes = [
  GoRoute(
    path: AppRoutes.welcome,
    builder: (context, state) => const GenericPreviewView(),
  ),
  GoRoute(
    path: AppRoutes.intro,
    builder: (context, state) => const GenericPreviewView(),
  ),
  GoRoute(
    path: AppRoutes.personalize,
    builder: (context, state) => const GenericPreviewView(),
  ),
];
