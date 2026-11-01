import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:stylobuddy/app.dart';
import 'package:stylobuddy/core/router/app_router.dart';
import 'package:stylobuddy/features/profile/cubit/profile_cubit.dart';
import 'package:stylobuddy/shared/backend/pending_onboarding_selections.dart';

/// F24 integration: the real StyloBuddyApp with the F14 uidStream /
/// firestoreOverride harness (same pattern as app_backend_wiring_test.dart).
/// Firestore effects are checked with bounded polling, never a bare
/// pumpAndSettle wait.
class _Harness {
  _Harness(this.tester, this.firestore, this.router, this.uid);

  final WidgetTester tester;
  final FakeFirebaseFirestore firestore;
  final GoRouter router;
  final StreamController<String?> uid;

  static Future<_Harness> pump(
    WidgetTester tester, {
    FakeFirebaseFirestore? firestore,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final fs = firestore ?? FakeFirebaseFirestore();
    final controller = StreamController<String?>();
    addTearDown(controller.close);
    final router = createAppRouter();
    await tester.pumpWidget(
      StyloBuddyApp(
        firestoreOverride: fs,
        router: router,
        uidStream: controller.stream,
        initialUid: null,
      ),
    );
    await tester.pumpAndSettle();
    return _Harness(tester, fs, router, controller);
  }

  String get path => router.routerDelegate.currentConfiguration.last.matchedLocation;

  ProfileCubit get profileCubit =>
      tester.element(find.byType(MaterialApp)).read<ProfileCubit>();

  Future<void> tapText(String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  Future<void> chooseGender(String gender) async {
    await tapText('Get Started');
    expect(path, '/gender');
    await tester.tap(find.byKey(Key('gender-card-$gender')));
    await tester.pumpAndSettle();
  }

  /// /gender -> Continue -> all five slides -> /personalize, via the UI.
  Future<void> walkToPersonalize() async {
    await tapText('Continue');
    expect(path, '/intro');
    await tapText('Get Started');
    for (var i = 0; i < 3; i++) {
      await tapText('Continue');
    }
    await tapText('Create My Wardrobe');
    expect(path, '/personalize');
  }

  /// Emits [value] on the uid stream. ProfileCubit's BlocProvider is lazy,
  /// so (like app_backend_wiring_test's fix_round_Important3 tests) the
  /// signed-in ProfileCubit is read once to construct it, which runs
  /// lib/app.dart's real consume()/consumeGender()/bootstrapIfNeeded path.
  Future<void> signIn(String? value) async {
    uid.add(value);
    await tester.pumpAndSettle();
    profileCubit;
  }

  Future<Map<String, dynamic>?> doc(String id) async =>
      (await firestore.collection('users').doc(id).get()).data();

  /// Polls until [condition] holds or 5 s elapse; returns the last doc.
  Future<Map<String, dynamic>?> pollDoc(
    String id,
    bool Function(Map<String, dynamic>? data) condition,
  ) async {
    Map<String, dynamic>? data;
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (DateTime.now().isBefore(deadline)) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
      data = await doc(id);
      if (condition(data)) break;
    }
    return data;
  }

  /// Gives the unawaited bootstrap a bounded chance to run (and no-op).
  Future<void> settleBootstrap() async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump();
  }
}

void main() {
  setUp(PendingOnboardingSelections.clear);
  tearDown(PendingOnboardingSelections.clear);

  testWidgets(
    'F24_A32 a guest who chose Female through the UI is seeded with gender female on first sign-in',
    (tester) async {
      final h = await _Harness.pump(tester);
      await h.chooseGender('female');
      await h.walkToPersonalize();
      expect(PendingOnboardingSelections.genderForTest, 'female');

      await h.signIn('uid-new');
      final data = await h.pollDoc(
        'uid-new',
        (d) => d?['seeded'] == true,
      );
      expect(data?['seeded'], isTrue);
      expect(data?['gender'], 'female');

      String? cubitGender;
      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (DateTime.now().isBefore(deadline)) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
        cubitGender = h.profileCubit.state.gender;
        if (cubitGender != null) break;
      }
      expect(cubitGender, 'female');
      expect(PendingOnboardingSelections.genderForTest, isNull);
    },
  );

  testWidgets(
    'F24_A33 Skip introduction then sign-in seeds no gender key',
    (tester) async {
      final h = await _Harness.pump(tester);
      await h.tapText('Skip introduction');
      expect(h.path, '/auth');

      await h.signIn('uid-skip');
      final data = await h.pollDoc('uid-skip', (d) => d?['seeded'] == true);
      expect(data?['seeded'], isTrue);
      expect(data!.containsKey('gender'), isFalse);
      await h.settleBootstrap();
      expect(h.profileCubit.state.gender, isNull);
    },
  );

  testWidgets(
    'F24_A34 a returning uid consumes the choice without writing it; a later sign-up does not inherit it',
    (tester) async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('users').doc('uid-ret').set({'seeded': true});
      final h = await _Harness.pump(tester, firestore: firestore);
      await h.chooseGender('male');
      expect(PendingOnboardingSelections.genderForTest, 'male');

      await h.signIn('uid-ret');
      await h.settleBootstrap();
      final returning = await h.doc('uid-ret');
      expect(returning, {'seeded': true});
      expect(returning!.containsKey('gender'), isFalse);
      expect(PendingOnboardingSelections.genderForTest, isNull);

      await h.signIn(null);
      await h.signIn('uid-2');
      final data = await h.pollDoc('uid-2', (d) => d?['seeded'] == true);
      expect(data?['seeded'], isTrue);
      expect(data!.containsKey('gender'), isFalse);
    },
  );

  testWidgets(
    'F24_A35 a guest who skips sign-in keeps gender null in ProfileCubit and the holder unconsumed',
    (tester) async {
      final h = await _Harness.pump(tester);
      await h.chooseGender('female');
      await h.walkToPersonalize();
      await h.tapText('Continue →');
      expect(h.path, '/auth');
      await h.tapText('Skip for now');
      expect(h.path, '/home');

      expect(h.profileCubit.state.gender, isNull);
      expect(PendingOnboardingSelections.genderForTest, 'female');
    },
  );
}
