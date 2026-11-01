import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import 'view/delete_account_view.dart';
import 'view/edit_profile_view.dart';
import 'view/edit_style_view.dart';
import 'view/notifications_view.dart';
import 'view/plan_view.dart';
import 'view/premium_view.dart';
import 'view/profile_view.dart';
import 'view/purchase_view.dart';
import 'view/settings_view.dart';
import 'view/signout_view.dart';
import 'view/subscription_view.dart';
import 'view/support_detail_view.dart';
import 'view/support_view.dart';
import 'view/weather_settings_view.dart';

/// Profile, settings and premium preview (F13): 14 routes under
/// `/profile`. Consumes the root `ProfileCubit` provided in `app.dart`.
final List<RouteBase> profileRoutes = [
  GoRoute(
    path: AppRoutes.profile,
    builder: (context, state) => const ProfileView(),
  ),
  GoRoute(
    path: AppRoutes.editProfile,
    builder: (context, state) => const EditProfileView(),
  ),
  GoRoute(
    path: AppRoutes.editStyle,
    builder: (context, state) => const EditStyleView(),
  ),
  GoRoute(
    path: AppRoutes.settings,
    builder: (context, state) => const SettingsView(),
  ),
  GoRoute(
    path: AppRoutes.notifications,
    builder: (context, state) => const NotificationsView(),
  ),
  GoRoute(
    path: AppRoutes.weatherSettings,
    builder: (context, state) => const WeatherSettingsView(),
  ),
  GoRoute(
    path: AppRoutes.support,
    builder: (context, state) => const SupportView(),
  ),
  GoRoute(
    path: AppRoutes.supportDetail,
    builder: (context, state) => const SupportDetailView(),
  ),
  GoRoute(
    path: AppRoutes.deleteAccount,
    builder: (context, state) => const DeleteAccountView(),
  ),
  GoRoute(
    path: AppRoutes.signout,
    builder: (context, state) => const SignoutView(),
  ),
  GoRoute(
    path: AppRoutes.premium,
    builder: (context, state) => const PremiumView(),
  ),
  GoRoute(
    path: AppRoutes.plan,
    builder: (context, state) => const PlanView(),
  ),
  GoRoute(
    path: AppRoutes.purchase,
    builder: (context, state) => const PurchaseView(),
  ),
  GoRoute(
    path: AppRoutes.subscription,
    builder: (context, state) => const SubscriptionView(),
  ),
];
