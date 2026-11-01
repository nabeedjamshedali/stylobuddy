import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:stylobuddy/core/router/app_routes.dart';
import 'package:stylobuddy/features/profile/cubit/profile_cubit.dart';
import 'package:stylobuddy/features/profile/cubit/profile_state.dart';
import 'package:stylobuddy/features/profile/widgets/pf_identity_card.dart';
import 'package:stylobuddy/features/wardrobe/cubit/wardrobe_cubit.dart';
import 'package:stylobuddy/features/saved/cubit/outfits_cubit.dart';

import '../support/f02_harness.dart';

ProfileCubit profileCubitOf(WidgetTester tester) =>
    tester.element(find.byType(Scaffold).first).read<ProfileCubit>();

WardrobeCubit wardrobeCubitOf(WidgetTester tester) =>
    tester.element(find.byType(Scaffold).first).read<WardrobeCubit>();

OutfitsCubit outfitsCubitOf(WidgetTester tester) =>
    tester.element(find.byType(Scaffold).first).read<OutfitsCubit>();

/// Pushes [path] on the live router without re-pumping the whole app, so
/// the feature-local in-memory cubits survive the navigation.
Future<void> goTo(WidgetTester tester, GoRouter router, String path) async {
  router.push(path);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'F13_A01 profile renders defaults and the avatar initial rule',
    (tester) async {
      await pumpApp(tester, AppRoutes.profile);
      for (final t in [
        'YOUR SPACE',
        'My profile',
        'Alex Morgan',
        'alex@example.com',
        'Personal wardrobe profile',
      ]) {
        expect(find.text(t), findsOneWidget, reason: t);
      }
      expect(
        find.descendant(
          of: find.byType(PfIdentityCard),
          matching: find.text('A'),
        ),
        findsOneWidget,
      );

      final cubit = profileCubitOf(tester);
      cubit.updateDetails('sam', cubit.state.email);
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(PfIdentityCard),
          matching: find.text('S'),
        ),
        findsOneWidget,
      );

      cubit.updateDetails('', cubit.state.email);
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(PfIdentityCard),
          matching: find.text('A'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'F13_A02 the edit pencil opens edit-profile; the premium banner opens '
    'premium',
    (tester) async {
      var router = await pumpApp(tester, AppRoutes.profile);
      for (final t in [
        'STYLOBUDDY PLUS',
        'Make every outfit count.',
        'Explore premium styling tools →',
      ]) {
        expect(find.text(t), findsOneWidget, reason: t);
      }
      await tapText(tester, '✎');
      expect(pathOf(router), AppRoutes.editProfile);

      router = await pumpApp(tester, AppRoutes.profile);
      await tapText(tester, 'Explore premium styling tools →');
      expect(pathOf(router), AppRoutes.premium);
    },
  );

  testWidgets('F13_A03 style hub rows open their routes', (tester) async {
    final cases = {
      'Outfit planner': (AppRoutes.calendar, 'Plan looks ahead of time'),
      'Packing assistant': (AppRoutes.packing, 'Build travel wardrobes'),
      'Shopping assistant': (AppRoutes.shopping, 'Fill wardrobe gaps'),
      'Style insights': (AppRoutes.insights, 'Understand your wardrobe'),
    };
    for (final entry in cases.entries) {
      final router = await pumpApp(tester, AppRoutes.profile);
      expect(find.text(entry.value.$2), findsOneWidget, reason: entry.key);
      await tapText(tester, entry.key);
      expect(pathOf(router), entry.value.$1, reason: entry.key);
    }
  });

  testWidgets(
    'F13_A04 account rows open their routes and the style subtitle updates',
    (tester) async {
      var router = await pumpApp(tester, AppRoutes.profile);
      expect(find.text('Name and contact email'), findsOneWidget);
      expect(find.text('Minimal · Smart casual'), findsOneWidget);
      expect(find.text('Notifications, privacy, billing'), findsOneWidget);

      await tapText(tester, 'Personal details');
      expect(pathOf(router), AppRoutes.editProfile);

      router = await pumpApp(tester, AppRoutes.profile);
      await tapText(tester, 'Style preferences');
      expect(pathOf(router), AppRoutes.editStyle);

      router = await pumpApp(tester, AppRoutes.profile);
      await tapText(tester, 'Settings');
      expect(pathOf(router), AppRoutes.settings);

      router = await pumpApp(tester, AppRoutes.profile);
      profileCubitOf(tester).togglePreference(
        PreferenceField.styles,
        'Bold',
      );
      await tester.pumpAndSettle();
      expect(find.text('Minimal · Smart casual · Bold'), findsOneWidget);
    },
  );

  testWidgets(
    'F13_A05 edit-profile renders head, fields prefilled and the helper',
    (tester) async {
      await pumpApp(tester, AppRoutes.editProfile);
      for (final t in [
        'Personal Details',
        'A little about you.',
        'Keep your profile details up to date.',
        'Display name',
        'Email address',
        'Changes here are saved only in this demo session.',
        'Save changes',
      ]) {
        expect(find.text(t), findsOneWidget, reason: t);
      }
      expect(
        find.widgetWithText(TextField, 'Alex Morgan'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(TextField, 'alex@example.com'),
        findsOneWidget,
      );
      final nameField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Alex Morgan'),
      );
      expect(nameField.maxLength, 64);
    },
  );

  testWidgets(
    'F13_A06 saving a blank or whitespace-only name toasts and keeps the '
    'old name',
    (tester) async {
      final router = await pumpApp(tester, AppRoutes.editProfile);
      await tester.enterText(
        find.widgetWithText(TextField, 'Alex Morgan'),
        '   ',
      );
      await tapText(tester, 'Save changes');
      expect(find.text('Please enter a name and valid email'), findsOneWidget);
      expect(pathOf(router), AppRoutes.editProfile);
      expect(profileCubitOf(tester).state.name, 'Alex Morgan');
      await drainToast(tester);
    },
  );

  testWidgets(
    'F13_A07 invalid emails toast and change nothing; a valid email passes',
    (tester) async {
      for (final email in ['abc', 'a@b', 'a b@c.d', '']) {
        final router = await pumpApp(tester, AppRoutes.editProfile);
        await tester.enterText(
          find.widgetWithText(TextField, 'alex@example.com'),
          email,
        );
        await tapText(tester, 'Save changes');
        expect(
          find.text('Please enter a name and valid email'),
          findsOneWidget,
          reason: email,
        );
        expect(pathOf(router), AppRoutes.editProfile, reason: email);
        expect(
          profileCubitOf(tester).state.email,
          'alex@example.com',
          reason: email,
        );
        await drainToast(tester);
      }

      final router = await pumpApp(tester, AppRoutes.editProfile);
      await tester.enterText(
        find.widgetWithText(TextField, 'alex@example.com'),
        'sam@x.co',
      );
      await tapText(tester, 'Save changes');
      expect(pathOf(router), AppRoutes.profile);
      expect(profileCubitOf(tester).state.email, 'sam@x.co');
      await drainToast(tester);
    },
  );

  testWidgets(
    'F13_A08 a valid save stores trimmed values, opens profile and toasts',
    (tester) async {
      final router = await pumpApp(tester, AppRoutes.editProfile);
      await tester.enterText(
        find.widgetWithText(TextField, 'Alex Morgan'),
        '  Sam Lee  ',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'alex@example.com'),
        '  sam@x.co  ',
      );
      await tapText(tester, 'Save changes');
      expect(pathOf(router), AppRoutes.profile);
      expect(find.text('Profile updated in demo'), findsOneWidget);
      final state = profileCubitOf(tester).state;
      expect(state.name, 'Sam Lee');
      expect(state.email, 'sam@x.co');
      await drainToast(tester);
    },
  );

  testWidgets(
    'F13_A09 edit-style renders head, both chip groups and the selection '
    'markers',
    (tester) async {
      await pumpApp(tester, AppRoutes.editStyle);
      for (final t in [
        'Your Style',
        'What feels like you?',
        'PERSONAL STYLE',
        'Minimal',
        'Smart casual',
        'Classic',
        'Streetwear',
        'Elegant',
        'Bold',
        'YOUR OCCASIONS',
        'Everyday',
        'Office',
        'Wedding',
        'Date Night',
        'Party',
        'Travel',
      ]) {
        expect(find.text(t), findsOneWidget, reason: t);
      }
      expect(find.text('✓'), findsNWidgets(4)); // Minimal, Smart casual, Everyday, Office
      expect(find.text('＋'), findsNWidgets(8));
    },
  );

  testWidgets(
    'F13_A10 tapping a chip toggles it immediately in ProfileState',
    (tester) async {
      await pumpApp(tester, AppRoutes.editStyle);
      final cubit = profileCubitOf(tester);
      expect(cubit.state.styles, isNot(contains('Bold')));
      await tapText(tester, 'Bold');
      expect(cubit.state.styles, contains('Bold'));
      await tapText(tester, 'Bold');
      expect(cubit.state.styles, isNot(contains('Bold')));
    },
  );

  testWidgets(
    'F13_A11 Save preferences opens profile and toasts; styleSummary joins '
    "with ' • '",
    (tester) async {
      final router = await pumpApp(tester, AppRoutes.editStyle);
      await tapText(tester, 'Save preferences');
      expect(pathOf(router), AppRoutes.profile);
      expect(find.text('Preferences saved'), findsOneWidget);

      final cubit = ProfileCubit();
      cubit.togglePreference(PreferenceField.styles, 'Bold');
      expect(cubit.state.styleSummary, 'Minimal • Smart casual • Bold');
      cubit.close();
      await drainToast(tester);
    },
  );

  testWidgets(
    'F13_A12 settings renders every section, the version footer and routes',
    (tester) async {
      var router = await pumpApp(tester, AppRoutes.settings);
      for (final t in [
        'Settings',
        'PERSONALIZATION',
        'Daily looks and outfit reminders',
        'Optional context for recommendations',
        'SUBSCRIPTION',
        'Free plan · Plans not yet priced',
        'SUPPORT & ACCOUNT',
        'Policies and support',
        'Leave the current demo session',
        'StyloBuddy · Interface prototype V19',
      ]) {
        expect(find.text(t), findsOneWidget, reason: t);
      }

      final targets = {
        'Notifications': AppRoutes.notifications,
        'Weather preferences': AppRoutes.weatherSettings,
        'Subscription & billing': AppRoutes.subscription,
        'Help, privacy & legal': AppRoutes.support,
        'Sign out': AppRoutes.signout,
      };
      for (final entry in targets.entries) {
        router = await pumpApp(tester, AppRoutes.settings);
        await tapText(tester, entry.key);
        expect(pathOf(router), entry.value, reason: entry.key);
      }
    },
  );

  testWidgets(
    'F13_A13 notifications renders defaults and toggles update the matching '
    'flag',
    (tester) async {
      await pumpApp(tester, AppRoutes.notifications);
      for (final t in [
        'Notifications',
        'Stay in the know.',
        'Daily outfit ideas',
        'Planned outfit reminders',
        'Product updates',
        'System notification permissions will be requested in the real app.',
      ]) {
        expect(find.text(t), findsOneWidget, reason: t);
      }
      final checkboxes = tester.widgetList<Checkbox>(find.byType(Checkbox)).toList();
      expect(checkboxes[0].value, isTrue);
      expect(checkboxes[1].value, isTrue);
      expect(checkboxes[2].value, isFalse);

      final cubit = profileCubitOf(tester);
      await tester.tap(find.byType(Checkbox).at(2));
      await tester.pumpAndSettle();
      expect(cubit.state.productNotifications, isTrue);
    },
  );

  testWidgets(
    'F13_A14 Done opens settings, toasts, and toggles persist after leaving '
    'and returning',
    (tester) async {
      final router = await pumpApp(tester, AppRoutes.notifications);
      final cubit = profileCubitOf(tester);
      await tester.tap(find.byType(Checkbox).first); // daily -> off
      await tester.pumpAndSettle();
      expect(cubit.state.dailyNotifications, isFalse);

      await tapText(tester, 'Done');
      expect(pathOf(router), AppRoutes.settings);
      expect(find.text('Notification preferences saved'), findsOneWidget);

      await goTo(tester, router, AppRoutes.notifications);
      final checkboxes = tester.widgetList<Checkbox>(find.byType(Checkbox)).toList();
      expect(checkboxes[0].value, isFalse);
      await drainToast(tester);
    },
  );

  testWidgets(
    'F13_A15 weather settings renders defaults, choosing Cold sets climate, '
    'Save settings opens settings with toast',
    (tester) async {
      final router = await pumpApp(tester, AppRoutes.weatherSettings);
      for (final t in [
        'Weather & Location',
        'Dress for your day.',
        'Use local weather',
        'FALLBACK CLIMATE',
        'Warm',
        'Mild',
        'Cool',
        'Cold',
        'No location data is accessed by this offline prototype.',
      ]) {
        expect(find.text(t), findsOneWidget, reason: t);
      }
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);

      final cubit = profileCubitOf(tester);
      await tapText(tester, 'Cold');
      expect(cubit.state.climate, 'Cold');

      await tapText(tester, 'Save settings');
      expect(pathOf(router), AppRoutes.settings);
      expect(find.text('Weather settings saved'), findsOneWidget);
      await drainToast(tester);
    },
  );

  testWidgets('F13_A16 support renders every row and route', (tester) async {
    var router = await pumpApp(tester, AppRoutes.support);
    for (final t in [
      'Help center',
      'Contact support',
      'Privacy policy',
      'Terms of service',
      'Delete account',
    ]) {
      expect(find.text(t), findsOneWidget, reason: t);
    }

    for (final label in [
      'Help center',
      'Contact support',
      'Privacy policy',
      'Terms of service',
    ]) {
      router = await pumpApp(tester, AppRoutes.support);
      await tapText(tester, label);
      expect(pathOf(router), AppRoutes.supportDetail, reason: label);
    }

    router = await pumpApp(tester, AppRoutes.support);
    await tapText(tester, 'Delete account');
    expect(pathOf(router), AppRoutes.deleteAccount);
  });

  testWidgets(
    'F13_A17 support-detail renders copy and Back to help returns',
    (tester) async {
      final router = await pumpApp(tester, AppRoutes.supportDetail);
      for (final t in [
        'Help & Information',
        'Coming before launch',
        'Official support channels, policies and terms are not included in '
            'this design prototype.',
        'Back to help',
      ]) {
        expect(find.text(t), findsOneWidget, reason: t);
      }
      await tapText(tester, 'Back to help');
      expect(pathOf(router), AppRoutes.support);
    },
  );

  testWidgets(
    'F13_A18 delete-account renders the warning and opens the deletion '
    'preview modal',
    (tester) async {
      await pumpApp(tester, AppRoutes.deleteAccount);
      for (final t in [
        'Your account, your choice.',
        'This is a visual preview only. No real user account or cloud data '
            'will be deleted.',
        'Review deletion',
      ]) {
        expect(find.text(t), findsOneWidget, reason: t);
      }
      await tapText(tester, 'Review deletion');
      expect(find.text('Deletion preview'), findsOneWidget);
      expect(
        find.text(
          'This demo does not connect to a live user account. No data '
          'will be deleted.',
        ),
        findsOneWidget,
      );
      expect(find.text('Close'), findsOneWidget);
      await tapText(tester, 'Close');
      expect(find.text('Deletion preview'), findsNothing);
    },
  );

  testWidgets(
    'F13_A19 reviewing and closing the deletion modal changes no wardrobe, '
    'outfit or profile state',
    (tester) async {
      await pumpApp(tester, AppRoutes.deleteAccount);
      final wardrobe = wardrobeCubitOf(tester);
      final outfits = outfitsCubitOf(tester);
      final profile = profileCubitOf(tester);
      final wardrobeBefore = wardrobe.state.items.length;
      final outfitsBefore = outfits.state.wearLog.length;
      final nameBefore = profile.state.name;

      await tapText(tester, 'Review deletion');
      await tapText(tester, 'Close');

      expect(wardrobe.state.items.length, wardrobeBefore);
      expect(outfits.state.wearLog.length, outfitsBefore);
      expect(profile.state.name, nameBefore);
    },
  );

  testWidgets(
    'F13_A20 signout renders copy; Stay signed in returns; Sign out · Demo '
    'opens auth, toasts and hides the bottom nav; state is unchanged',
    (tester) async {
      var router = await pumpApp(tester, AppRoutes.signout);
      for (final t in [
        'Sign Out',
        'Sign out of StyloBuddy?',
        'Sign in again to access your synced wardrobe in the future app.',
        'Stay signed in',
        'Sign out · Demo',
      ]) {
        expect(find.text(t), findsOneWidget, reason: t);
      }
      await tapText(tester, 'Stay signed in');
      expect(pathOf(router), AppRoutes.settings);

      router = await pumpApp(tester, AppRoutes.signout);
      final wardrobeBefore = wardrobeCubitOf(tester).state.items.length;
      final nameBefore = profileCubitOf(tester).state.name;
      await tapText(tester, 'Sign out · Demo');
      expect(pathOf(router), AppRoutes.auth);
      expect(find.text('Signed out of demo preview'), findsOneWidget);
      for (final label in navLabels) {
        expect(find.text(label), findsNothing, reason: label);
      }
      expect(wardrobeCubitOf(tester).state.items.length, wardrobeBefore);
      expect(profileCubitOf(tester).state.name, nameBefore);
      await drainToast(tester);
    },
  );

  testWidgets(
    'F13_A21 premium renders the paywall, benefits, helper and CTA',
    (tester) async {
      final router = await pumpApp(tester, AppRoutes.premium);
      for (final t in [
        'StyloBuddy Plus',
        'More possibilities.\nMore personal style.',
        'PLANNED PREMIUM VALUE',
        'Additional AI outfit recommendations',
        'Advanced garment matching',
        'Expanded style insights',
        'Smarter trip and calendar planning',
        'These are proposed benefits. Entitlements and pricing require cost '
            'review.',
        'Preview plan options →',
      ]) {
        expect(find.text(t), findsOneWidget, reason: t);
      }
      await tapText(tester, 'Preview plan options →');
      expect(pathOf(router), AppRoutes.plan);
    },
  );

  testWidgets(
    'F13_A22 plan renders both cards (Yearly selected), choosing Monthly '
    'calls setBillingCycle, and Continue opens purchase',
    (tester) async {
      final router = await pumpApp(tester, AppRoutes.plan);
      for (final t in [
        'Choose a Plan',
        'Choose your rhythm.',
        'Monthly',
        'Pay month to month',
        'Yearly',
        'A longer-term option',
        'No purchase is available in this prototype. Final plans depend on '
            'AI operating costs.',
        'Continue · Preview only',
      ]) {
        expect(find.text(t), findsOneWidget, reason: t);
      }
      expect(find.text('Price TBD'), findsNWidgets(2));
      final cubit = profileCubitOf(tester);
      expect(cubit.state.billingCycle, 'yearly');

      await tapText(tester, 'Monthly');
      expect(cubit.state.billingCycle, 'monthly');

      await tapText(tester, 'Continue · Preview only');
      expect(pathOf(router), AppRoutes.purchase);
    },
  );

  testWidgets(
    'F13_A23 purchase renders the checkout-pending copy and links to '
    'subscription',
    (tester) async {
      final router = await pumpApp(tester, AppRoutes.purchase);
      for (final t in [
        'Checkout Preview',
        'Checkout integration pending',
        'StoreKit, Google Play Billing, purchase verification and '
            'entitlement syncing will be implemented later. No payment '
            'will be initiated.',
        'View subscription settings',
      ]) {
        expect(find.text(t), findsOneWidget, reason: t);
      }
      await tapText(tester, 'View subscription settings');
      expect(pathOf(router), AppRoutes.subscription);
    },
  );

  testWidgets(
    'F13_A24 subscription renders the current plan, manage row and restore '
    'toast',
    (tester) async {
      final router = await pumpApp(tester, AppRoutes.subscription);
      for (final t in [
        'Subscription',
        'CURRENT PLAN',
        'Free',
        'Subscription pricing and included AI usage are still under '
            'review.',
        'Explore StyloBuddy Plus →',
        'MANAGE',
        'Plan options',
        'Restore purchases · Demo',
        "The prototype doesn't communicate with app stores or process "
            'real purchases.',
      ]) {
        expect(find.text(t), findsOneWidget, reason: t);
      }
      await tapText(tester, 'Restore purchases · Demo');
      expect(find.text('No purchases to restore in this demo'), findsOneWidget);
      await drainToast(tester);

      await tapText(tester, 'Plan options');
      expect(pathOf(router), AppRoutes.plan);
    },
  );

  testWidgets(
    'F13_A25 premium -> plan -> purchase -> subscription leaves plan Free',
    (tester) async {
      final router = await pumpApp(tester, AppRoutes.premium);
      await goTo(tester, router, AppRoutes.plan);
      await goTo(tester, router, AppRoutes.purchase);
      await goTo(tester, router, AppRoutes.subscription);
      expect(profileCubitOf(tester).state.plan, 'Free');
      expect(find.text('Free'), findsOneWidget);
    },
  );

  testWidgets('F13_A26 header back targets', (tester) async {
    final targets = {
      AppRoutes.editProfile: AppRoutes.profile,
      AppRoutes.editStyle: AppRoutes.profile,
      AppRoutes.settings: AppRoutes.profile,
      AppRoutes.notifications: AppRoutes.settings,
      AppRoutes.weatherSettings: AppRoutes.settings,
      AppRoutes.support: AppRoutes.settings,
      AppRoutes.signout: AppRoutes.settings,
      AppRoutes.subscription: AppRoutes.settings,
      AppRoutes.supportDetail: AppRoutes.support,
      AppRoutes.deleteAccount: AppRoutes.support,
      AppRoutes.premium: AppRoutes.profile,
      AppRoutes.plan: AppRoutes.premium,
      AppRoutes.purchase: AppRoutes.plan,
    };
    for (final entry in targets.entries) {
      final router = await pumpApp(tester, entry.key);
      await tester.tap(find.text('‹').first);
      await tester.pumpAndSettle();
      expect(pathOf(router), entry.value, reason: entry.key);
    }
  });

  testWidgets(
    'F13_A27 all 14 routes render inside the shell and highlight the right '
    'tab',
    (tester) async {
      const profileTab = {
        AppRoutes.profile,
        AppRoutes.settings,
        AppRoutes.editProfile,
        AppRoutes.editStyle,
        AppRoutes.notifications,
        AppRoutes.support,
        AppRoutes.premium,
        AppRoutes.plan,
        AppRoutes.purchase,
        AppRoutes.subscription,
      };
      const homeTab = {
        AppRoutes.weatherSettings,
        AppRoutes.supportDetail,
        AppRoutes.deleteAccount,
        AppRoutes.signout,
      };
      for (final route in profileTab) {
        expect(AppRoutes.tabFor(route), AppRoutes.profile, reason: route);
      }
      for (final route in homeTab) {
        expect(AppRoutes.tabFor(route), AppRoutes.home, reason: route);
      }

      for (final route in [...profileTab, ...homeTab]) {
        await pumpApp(tester, route);
        for (final label in navLabels) {
          expect(find.text(label), findsOneWidget, reason: '$route/$label');
        }
      }
    },
  );
}
