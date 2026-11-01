import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../shared/backend/analytics_service.dart';
import 'cubit/onboarding_cubit.dart';
import 'view/gender_choice_view.dart';
import 'view/intro_view.dart';
import 'widgets/onboarding_back_scope.dart';
import 'view/personalize_view.dart';
import 'view/welcome_view.dart';

/// Welcome, gender (F24), intro and personalize share one [OnboardingCubit] through a
/// shell route (no bottom nav; the shell only provides state).
final List<RouteBase> onboardingRoutes = [
  ShellRoute(
    builder: (context, state, child) => BlocProvider(
      create: (_) => OnboardingCubit(analytics: analyticsOf(context)),
      child: OnboardingBackScope(location: state.uri.path, child: child),
    ),
    routes: [
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomeView(),
      ),
      GoRoute(
        path: AppRoutes.gender,
        builder: (context, state) => const GenderChoiceView(),
      ),
      GoRoute(
        path: AppRoutes.intro,
        builder: (context, state) => const IntroView(),
      ),
      GoRoute(
        path: AppRoutes.personalize,
        builder: (context, state) => const PersonalizeView(),
      ),
    ],
  ),
];
