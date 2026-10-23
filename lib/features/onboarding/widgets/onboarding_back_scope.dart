import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../cubit/onboarding_cubit.dart';

/// Android system back for the onboarding flow (ADR-001). It must wrap the
/// shell's inner Navigator: go_router asks the root navigator first, so a
/// PopScope inside a single-page route is never consulted.
class OnboardingBackScope extends StatelessWidget {
  const OnboardingBackScope({
    super.key,
    required this.location,
    required this.child,
  });

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: location == AppRoutes.welcome,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (location == AppRoutes.gender) {
          context.go(AppRoutes.welcome);
        } else if (location == AppRoutes.intro) {
          context.read<OnboardingCubit>().back();
        } else if (location == AppRoutes.personalize) {
          context.go(AppRoutes.intro);
        }
      },
      child: child,
    );
  }
}
