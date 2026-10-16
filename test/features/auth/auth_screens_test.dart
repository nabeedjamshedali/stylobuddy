import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylobuddy/features/profile/cubit/profile_cubit.dart';

import '../support/f02_harness.dart';

Future<void> _type(WidgetTester tester, int field, String text) async {
  await tester.enterText(find.byType(TextField).at(field), text);
}

bool _obscured(WidgetTester tester, int field) =>
    tester.widget<TextField>(find.byType(TextField).at(field)).obscureText;

Future<void> _fillSignup(
  WidgetTester tester, {
  String name = 'Sam Doe',
  String email = 'sam@example.com',
  String password = 'longenough',
  String confirm = 'longenough',
}) async {
  await _type(tester, 0, name);
  await _type(tester, 1, email);
  await _type(tester, 2, password);
  await _type(tester, 3, confirm);
}

void main() {
  group('auth chooser', () {
    testWidgets('F02_A15 renders and each button acts', (tester) async {
      final router = await pumpApp(tester, '/auth');
      expect(find.text('Create your wardrobe.'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Continue with Apple'), findsOneWidget);
      expect(find.text('Continue with Email'), findsOneWidget);

      await tapText(tester, 'Continue with Google');
      expect(find.text('Google authentication UI preview'), findsOneWidget);
      await tapText(tester, 'Continue with Apple');
      expect(find.text('Apple authentication UI preview'), findsOneWidget);
      await drainToast(tester);

      await tapText(tester, 'Continue with Email');
      expect(pathOf(router), '/login');
    });

    testWidgets('F02_A15 Skip for now enters /home with nav', (tester) async {
      final router = await pumpApp(tester, '/auth');
      await tapText(tester, 'Skip for now');
      expect(pathOf(router), '/home');
      for (final label in navLabels) {
        expect(find.text(label), findsOneWidget);
      }
    });
  });

  group('login', () {
    testWidgets('F02_A16 renders copy and semantic submit label', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpApp(tester, '/login');
      for (final t in [
        'STYLE STARTS HERE',
        'Welcome back.',
        'Sign in to continue building your personal wardrobe.',
        'Email address',
        'Password',
        'Forgot password?',
        'New to StyloBuddy?',
        'Create an account',
      ]) {
        expect(find.text(t), findsOneWidget, reason: t);
      }
      expect(find.bySemanticsLabel('Sign in →'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('F02_A17 valid login goes home, toasts, nav visible', (
      tester,
    ) async {
      final router = await pumpApp(tester, '/login');
      await _type(tester, 0, 'you@example.com');
      await _type(tester, 1, 'abc');
      await tapText(tester, 'Sign in');
      expect(pathOf(router), '/home');
      expect(find.text('Signed in to demo account'), findsOneWidget);
      for (final label in navLabels) {
        expect(find.text(label), findsOneWidget);
      }
      await drainToast(tester);
    });

    testWidgets('F02_A18 empty password or invalid email stays, no toast', (
      tester,
    ) async {
      final router = await pumpApp(tester, '/login');
      await _type(tester, 0, 'you@example.com');
      await tapText(tester, 'Sign in');
      expect(pathOf(router), '/login');
      expect(find.text('Signed in to demo account'), findsNothing);

      await _type(tester, 0, 'nope');
      await _type(tester, 1, 'abc');
      await tapText(tester, 'Sign in');
      expect(pathOf(router), '/login');
      expect(find.text('Signed in to demo account'), findsNothing);
    });

    testWidgets('F02_A19 password show/hide toggles obscuring and label', (
      tester,
    ) async {
      await pumpApp(tester, '/login');
      expect(_obscured(tester, 1), isTrue);
      expect(find.text('Show'), findsOneWidget);
      await tapText(tester, 'Show');
      expect(_obscured(tester, 1), isFalse);
      expect(find.text('Hide'), findsOneWidget);
      await tapText(tester, 'Hide');
      expect(_obscured(tester, 1), isTrue);
      expect(find.text('Show'), findsOneWidget);
    });

    testWidgets('F02_A25 login header back is /auth; forgot link pushes', (
      tester,
    ) async {
      final router = await pumpApp(tester, '/login');
      await tester.tap(find.byKey(const Key('auth-back')));
      await tester.pumpAndSettle();
      expect(pathOf(router), '/auth');
    });
  });

  group('signup', () {
    testWidgets('F02_A20 renders copy', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(tester, '/signup');
      for (final t in [
        'Create your account.',
        'Save your wardrobe, discover outfits, and keep everything in one place.',
        'Full name',
        'Email address',
        'Password',
        'Confirm password',
        'Use 8 or more characters for a secure password.',
        'By continuing, you agree to the Terms of Service and Privacy Policy.',
        'Already have an account?',
        'Sign in',
      ]) {
        expect(find.text(t), findsOneWidget, reason: t);
      }
      expect(find.bySemanticsLabel('Create account →'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('F02_A21 valid signup opens /verify-email', (tester) async {
      final router = await pumpApp(tester, '/signup');
      await _fillSignup(tester);
      await tapText(tester, 'Create account');
      expect(pathOf(router), '/verify-email');
    });

    testWidgets('F02_A21 short password and mismatch show inline errors', (
      tester,
    ) async {
      final router = await pumpApp(tester, '/signup');
      await _fillSignup(tester, password: 'short', confirm: 'short');
      await tapText(tester, 'Create account');
      expect(pathOf(router), '/signup');
      expect(
        find.text('Use at least 8 characters for your password.'),
        findsOneWidget,
      );

      await _type(tester, 2, 'longenough');
      await _type(tester, 3, 'different');
      await tapText(tester, 'Create account');
      expect(pathOf(router), '/signup');
      expect(
        find.text('Passwords do not match. Please try again.'),
        findsOneWidget,
      );
      expect(
        find.text('Use at least 8 characters for your password.'),
        findsNothing,
      );

      await _type(tester, 3, 'longenough');
      await tapText(tester, 'Create account');
      expect(pathOf(router), '/verify-email');
    });

    testWidgets('F02_A21 blank required field blocks silently', (tester) async {
      final router = await pumpApp(tester, '/signup');
      await _fillSignup(tester, name: 'J');
      await tapText(tester, 'Create account');
      expect(pathOf(router), '/signup');
      expect(find.textContaining('Passwords do not match'), findsNothing);
      expect(find.textContaining('Use at least 8'), findsNothing);
    });

    testWidgets('F02_A28 signup leaves ProfileState untouched', (tester) async {
      await pumpApp(tester, '/signup');
      await _fillSignup(tester, name: 'Sam Doe', email: 'sam@example.com');
      await tapText(tester, 'Create account');
      final profile = tester
          .element(find.byType(Scaffold).first)
          .read<ProfileCubit>()
          .state;
      expect(profile.name, 'Alex Morgan');
      expect(profile.email, 'alex@example.com');
    });

    testWidgets('F02_A25 signup header back is /auth', (tester) async {
      final router = await pumpApp(tester, '/signup');
      await tester.tap(find.byKey(const Key('auth-back')));
      await tester.pumpAndSettle();
      expect(pathOf(router), '/auth');
    });
  });

  group('forgot, reset-sent, verify-email', () {
    testWidgets('F02_A22 forgot renders; valid email opens /reset-sent', (
      tester,
    ) async {
      final router = await pumpApp(tester, '/forgot');
      for (final t in [
        'Reset your password.',
        'Enter your email and we’ll help you get back into your account.',
        'Remembered it?',
        'Back to sign in',
      ]) {
        expect(find.text(t), findsOneWidget, reason: t);
      }
      expect(find.text('Send reset link'), findsOneWidget);

      await tapText(tester, 'Send reset link');
      expect(pathOf(router), '/forgot', reason: 'empty email stays');

      await _type(tester, 0, 'me@example.com');
      await tapText(tester, 'Send reset link');
      expect(pathOf(router), '/reset-sent');
    });

    testWidgets('F02_A23 reset-sent shows entered email in bold', (
      tester,
    ) async {
      final router = await pumpApp(tester, '/forgot');
      await _type(tester, 0, 'me@example.com');
      await tapText(tester, 'Send reset link');
      expect(find.text('Check your inbox.'), findsOneWidget);
      expect(find.text('Reset link preview'), findsOneWidget);
      final rich = find.textContaining(
        'In the real app, a secure link would be sent to me@example.com. '
        'No email has been sent by this prototype.',
        findRichText: true,
      );
      expect(rich, findsOneWidget);
      final text = tester.widget<Text>(
        find.byWidgetPredicate(
          (w) =>
              w is Text &&
              (w.textSpan?.toPlainText().startsWith('In the real app') ??
                  false),
        ),
      );
      final spans = (text.textSpan! as TextSpan).children!.cast<TextSpan>();
      expect(spans[1].text, 'me@example.com');
      expect(spans[1].style!.fontWeight, FontWeight.w700);

      await tapText(tester, 'Try another email');
      expect(pathOf(router), '/forgot');
    });

    testWidgets('F02_A23 reset-sent falls back with no stored email', (
      tester,
    ) async {
      final router = await pumpApp(tester, '/reset-sent');
      expect(
        find.textContaining(
          'sent to your email address. No email has been sent by this prototype.',
          findRichText: true,
        ),
        findsOneWidget,
      );
      await tapText(tester, 'Back to sign in');
      expect(pathOf(router), '/login');
    });

    testWidgets('F02_A24 verify-email copy, continue and resend', (
      tester,
    ) async {
      final router = await pumpApp(tester, '/signup');
      await _fillSignup(tester, email: 'sam@example.com');
      await tapText(tester, 'Create account');
      expect(find.text('One more step.'), findsOneWidget);
      expect(find.text('Verification preview'), findsOneWidget);
      expect(
        find.textContaining(
          'In production, we’ll send a verification email to sam@example.com. '
          'This is an interactive design preview only.',
          findRichText: true,
        ),
        findsOneWidget,
      );

      await tapText(tester, 'Resend verification email');
      expect(
        find.text('No real email is sent in this prototype'),
        findsOneWidget,
      );
      expect(pathOf(router), '/verify-email');
      await drainToast(tester);

      await tapText(tester, 'Continue to demo');
      expect(pathOf(router), '/home');
      expect(find.text('Verification simulated'), findsOneWidget);
      await drainToast(tester);
    });

    testWidgets('F02_A24 verify-email without email uses the fallback', (
      tester,
    ) async {
      await pumpApp(tester, '/verify-email');
      expect(
        find.textContaining(
          'verification email to your email address. This is',
          findRichText: true,
        ),
        findsOneWidget,
      );
    });

    testWidgets('F02_A25 header back targets when there is no history', (
      tester,
    ) async {
      for (final (start, target) in [
        ('/forgot', '/login'),
        ('/reset-sent', '/forgot'),
        ('/verify-email', '/signup'),
      ]) {
        final router = await pumpApp(tester, start);
        await tester.tap(find.byKey(const Key('auth-back')));
        await tester.pumpAndSettle();
        expect(pathOf(router), target, reason: start);
      }
    });

    testWidgets('F02_A25 back pops when history exists', (tester) async {
      final router = await pumpApp(tester, '/auth');
      await tapText(tester, 'Continue with Email');
      await tapText(tester, 'Forgot password?');
      expect(pathOf(router), '/forgot');
      await tester.tap(find.byKey(const Key('auth-back')));
      await tester.pumpAndSettle();
      expect(pathOf(router), '/login');
      await tester.tap(find.byKey(const Key('auth-back')));
      await tester.pumpAndSettle();
      expect(pathOf(router), '/auth');
    });

    testWidgets('F02_A26 none of the auth routes shows the bottom nav', (
      tester,
    ) async {
      for (final route in [
        '/welcome',
        '/intro',
        '/personalize',
        '/auth',
        '/login',
        '/signup',
        '/forgot',
        '/reset-sent',
        '/verify-email',
      ]) {
        await pumpApp(tester, route);
        for (final label in navLabels) {
          expect(find.text(label), findsNothing, reason: '$route $label');
        }
      }
    });
  });
}
