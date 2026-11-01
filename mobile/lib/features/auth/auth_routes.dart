import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../shared/backend/analytics_service.dart';
import 'cubit/auth_cubit.dart';
import 'view/auth_view.dart';
import 'view/forgot_view.dart';
import 'view/login_view.dart';
import 'view/reset_sent_view.dart';
import 'view/signup_view.dart';
import 'view/verify_email_view.dart';

/// All auth screens share one [AuthCubit] (the remembered email) through a
/// state-only shell route; none shows the bottom navigation.
final List<RouteBase> authRoutes = [
  ShellRoute(
    builder: (context, state, child) =>
        BlocProvider(
          create: (_) => AuthCubit(analytics: analyticsOf(context)),
          child: child,
        ),
    routes: [
      GoRoute(
        path: AppRoutes.auth,
        builder: (context, state) => const AuthView(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginView(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) => const SignupView(),
      ),
      GoRoute(
        path: AppRoutes.forgot,
        builder: (context, state) => const ForgotView(),
      ),
      GoRoute(
        path: AppRoutes.resetSent,
        builder: (context, state) => const ResetSentView(),
      ),
      GoRoute(
        path: AppRoutes.verifyEmail,
        builder: (context, state) => const VerifyEmailView(),
      ),
    ],
  ),
];
