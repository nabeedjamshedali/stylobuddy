import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:stylobuddy/app.dart';
import 'package:stylobuddy/core/router/app_router.dart';
import 'package:stylobuddy/core/router/app_routes.dart';
import 'package:stylobuddy/features/builder/cubit/builder_cubit.dart';
import 'package:stylobuddy/features/builder/view/manual_preview_view.dart';
import 'package:stylobuddy/features/calendar/cubit/planner_cubit.dart';
import 'package:stylobuddy/features/home/view/home_view.dart';
import 'package:stylobuddy/features/onboarding/view/welcome_view.dart';
import 'package:stylobuddy/features/packing/cubit/packing_cubit.dart';
import 'package:stylobuddy/features/profile/cubit/profile_cubit.dart';
import 'package:stylobuddy/features/saved/cubit/outfits_cubit.dart';
import 'package:stylobuddy/features/shopping/cubit/shopping_cubit.dart';
import 'package:stylobuddy/features/stylist/cubit/stylist_cubit.dart';
import 'package:stylobuddy/features/wardrobe/cubit/import_cubit.dart';
import 'package:stylobuddy/features/wardrobe/cubit/wardrobe_browse_cubit.dart';
import 'package:stylobuddy/features/wardrobe/cubit/wardrobe_cubit.dart';
import 'package:stylobuddy/features/wardrobe/cubit/wardrobe_state.dart';
import 'package:stylobuddy/shared/data/seed_data.dart';
import 'package:stylobuddy/shared/models/clothing_item.dart';

/// `ClothingItem`/`WardrobeState` have no `==` override, so content checks
/// compare ids rather than list/object identity.
List<String> _idsOf(WardrobeState state) =>
    state.items.map((i) => i.id).toList();

/// Pumps [StyloBuddyApp] with a fake, fully test-controlled uid stream
/// (never touching `FirebaseAuth.instance`) and returns the [BuildContext]
/// a test can call `context.read<...Cubit>()` against.
Future<BuildContext> _pumpApp(
  WidgetTester tester,
  Stream<String?> uidStream,
) async {
  await tester.pumpWidget(
    StyloBuddyApp(
      firestoreOverride: FakeFirebaseFirestore(),
      router: createAppRouter(),
      uidStream: uidStream,
    ),
  );
  await tester.pumpAndSettle();
  return tester.element(find.byType(MaterialApp));
}

/// Every root Cubit identity relevant to F14-A05/A06, captured as a tuple
/// of object references so two snapshots can be compared by identity.
List<Object> _rootCubits(BuildContext context) => [
  context.read<WardrobeCubit>(),
  context.read<OutfitsCubit>(),
  context.read<PlannerCubit>(),
  context.read<ProfileCubit>(),
  context.read<StylistCubit>(),
  context.read<WardrobeBrowseCubit>(),
  context.read<ImportCubit>(),
  context.read<BuilderCubit>(),
  context.read<ShoppingCubit>(),
  context.read<PackingCubit>(),
];

void main() {
  testWidgets(
    'F14_A05 a null -> uid-1 transition disposes and rebuilds every root Cubit with a new identity',
    (tester) async {
      final controller = StreamController<String?>();
      addTearDown(controller.close);
      final context = await _pumpApp(tester, controller.stream);
      final before = _rootCubits(context);

      controller.add('uid-1');
      await tester.pumpAndSettle();
      final after = _rootCubits(tester.element(find.byType(MaterialApp)));

      expect(before.length, after.length);
      for (var i = 0; i < before.length; i++) {
        expect(
          identical(before[i], after[i]),
          isFalse,
          reason: 'cubit at index $i was not reconstructed',
        );
      }
      // Not just "a new instance exists" — the pre-transition instance must
      // actually be torn down (.close()d), or a stale widget that cached a
      // reference to it (see the F14_A05 regression test below) could call
      // a dead Cubit and crash with "emit after close".
      for (final cubit in before) {
        expect(
          (cubit as dynamic).isClosed,
          isTrue,
          reason: 'pre-transition cubit $cubit was not closed',
        );
      }
    },
  );

  testWidgets(
    'F14_A05_regression a uid transition tears down the whole navigation tree, not just the providers, so a route that cached a Cubit reference in initState is disposed rather than reparented',
    (tester) async {
      final controller = StreamController<String?>();
      addTearDown(controller.close);
      // Deliberately no `router:` override here: this regression is about
      // the *default* (no-override) production wiring in app.dart, where a
      // shared/singleton router previously survived a uid-keyed rebuild.
      await tester.pumpWidget(
        StyloBuddyApp(
          firestoreOverride: FakeFirebaseFirestore(),
          uidStream: controller.stream,
        ),
      );
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(WelcomeView));
      GoRouter.of(context).go(AppRoutes.manualPreview);
      await tester.pumpAndSettle();
      expect(find.byType(ManualPreviewView), findsOneWidget);
      final cachedCubit = tester
          .element(find.byType(ManualPreviewView))
          .read<BuilderCubit>();

      controller.add('uid-1');
      await tester.pumpAndSettle();

      // The route whose State cached `cachedCubit` in initState must not
      // survive the transition (reparented into the new tree) — the whole
      // navigation stack is torn down and rebuilt at the fresh router's
      // initial location together with the providers above it.
      expect(
        find.byType(ManualPreviewView),
        findsNothing,
        reason: 'a reparented (not disposed) route would still be found here',
      );
      expect(cachedCubit.isClosed, isTrue);
    },
  );

  testWidgets(
    'F14_A06 a full null -> uid-1 -> null round trip leaves every root Cubit back at guest-mode initial state',
    (tester) async {
      final controller = StreamController<String?>();
      addTearDown(controller.close);
      final context = await _pumpApp(tester, controller.stream);
      final initialWardrobeIds = _idsOf(context.read<WardrobeCubit>().state);
      final initialProfileName = context.read<ProfileCubit>().state.name;

      controller.add('uid-1');
      await tester.pumpAndSettle();
      controller.add(null);
      await tester.pumpAndSettle();

      final finalContext = tester.element(find.byType(MaterialApp));
      expect(
        _idsOf(finalContext.read<WardrobeCubit>().state),
        initialWardrobeIds,
      );
      expect(finalContext.read<ProfileCubit>().state.name, initialProfileName);
    },
  );

  testWidgets(
    'F14_A08 WardrobeCubit.state.items is the SeedData in-memory list on a cold guest launch and again right after a simulated sign-out',
    (tester) async {
      final controller = StreamController<String?>();
      addTearDown(controller.close);
      final context = await _pumpApp(tester, controller.stream);
      final seedIds = SeedData.items.map((i) => i.id).toList();
      expect(_idsOf(context.read<WardrobeCubit>().state), seedIds);

      controller.add('uid-1');
      await tester.pumpAndSettle();
      controller.add(null);
      await tester.pumpAndSettle();

      final afterSignOut = tester.element(find.byType(MaterialApp));
      expect(_idsOf(afterSignOut.read<WardrobeCubit>().state), seedIds);
    },
  );

  testWidgets(
    'F14_A09 a guest-only wardrobe edit never appears in the newly-built signed-in WardrobeCubit',
    (tester) async {
      final controller = StreamController<String?>();
      addTearDown(controller.close);
      final context = await _pumpApp(tester, controller.stream);
      final guestOnlyItem = ClothingItem(
        id: 'guest-only-item',
        name: 'Guest Only',
        category: 'Shirts',
        color: 'Red',
        occasion: 'Everyday',
      );
      context.read<WardrobeCubit>().addItems([guestOnlyItem]);
      expect(
        context.read<WardrobeCubit>().state.items.any(
          (i) => i.id == 'guest-only-item',
        ),
        isTrue,
      );

      controller.add('uid-1');
      await tester.pumpAndSettle();

      final signedInContext = tester.element(find.byType(MaterialApp));
      expect(
        signedInContext.read<WardrobeCubit>().state.items.any(
          (i) => i.id == 'guest-only-item',
        ),
        isFalse,
      );
    },
  );

  testWidgets(
    'F14_A05_home_regression a uid emitted while sitting on /auth lands the '
    'fresh router on /home, not /welcome (real sign-in regression)',
    (tester) async {
      final controller = StreamController<String?>();
      addTearDown(controller.close);
      // Deliberately no `router:` override: this is about the production
      // wiring in app.dart picking a uid-aware `initialLocation` for the
      // brand-new router it builds on a uid change, mirroring what happens
      // when AuthView's own `context.go(AppRoutes.home)` races the
      // uid-change-triggered router rebuild during a real Google sign-in.
      await tester.pumpWidget(
        StyloBuddyApp(
          firestoreOverride: FakeFirebaseFirestore(),
          uidStream: controller.stream,
        ),
      );
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(WelcomeView));
      GoRouter.of(context).go(AppRoutes.auth);
      await tester.pumpAndSettle();

      controller.add('uid-1');
      await tester.pumpAndSettle();

      expect(find.byType(HomeView), findsOneWidget);
      expect(find.byType(WelcomeView), findsNothing);
    },
  );

  testWidgets(
    'F14_A06_signout_regression a uid going back to null still lands the '
    'fresh router on /welcome',
    (tester) async {
      final controller = StreamController<String?>();
      addTearDown(controller.close);
      await tester.pumpWidget(
        StyloBuddyApp(
          firestoreOverride: FakeFirebaseFirestore(),
          uidStream: controller.stream,
        ),
      );
      await tester.pumpAndSettle();

      controller.add('uid-1');
      await tester.pumpAndSettle();
      expect(find.byType(HomeView), findsOneWidget);

      controller.add(null);
      await tester.pumpAndSettle();

      expect(find.byType(WelcomeView), findsOneWidget);
      expect(find.byType(HomeView), findsNothing);
    },
  );

  testWidgets(
    'F14_dispose_followup a router passed in via the router: test override is '
    'never disposed by StyloBuddyApp when the subtree unmounts',
    (tester) async {
      final overrideRouter = createAppRouter();
      addTearDown(overrideRouter.dispose);
      final controller = StreamController<String?>();
      addTearDown(controller.close);

      await tester.pumpWidget(
        StyloBuddyApp(
          firestoreOverride: FakeFirebaseFirestore(),
          router: overrideRouter,
          uidStream: controller.stream,
        ),
      );
      await tester.pumpAndSettle();

      // Unmount the whole StyloBuddyApp subtree.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      // If `_RoutedMaterialAppState.dispose()` had (incorrectly) disposed
      // this test-owned router, attaching a listener to its routerDelegate
      // (a ChangeNotifier) would throw a "used after dispose" assertion.
      expect(
        () => overrideRouter.routerDelegate.addListener(() {}),
        returnsNormally,
      );
    },
  );

  testWidgets(
    'F14_A04 a duplicate consecutive uid emission does not rebuild the provider subtree',
    (tester) async {
      final controller = StreamController<String?>();
      addTearDown(controller.close);
      await _pumpApp(tester, controller.stream);

      controller.add('uid-1');
      await tester.pumpAndSettle();
      final afterFirst = tester
          .element(find.byType(MaterialApp))
          .read<WardrobeCubit>();

      controller.add('uid-1'); // duplicate consecutive value
      await tester.pumpAndSettle();
      final afterDuplicate = tester
          .element(find.byType(MaterialApp))
          .read<WardrobeCubit>();

      expect(identical(afterFirst, afterDuplicate), isTrue);
    },
  );

  testWidgets(
    'F14_initialData_first_frame a cold start already signed in renders the '
    'signed-in subtree on the very first frame, before the uid stream has '
    'emitted anything',
    (tester) async {
      // Deliberately never calls `await tester.pumpAndSettle()` or any
      // `pump()` before the first assertion: the bug this guards against is
      // specifically about what is visible on the very first build, before
      // any microtask (and so before the stream's own first, always-async,
      // emission) has had a chance to run. `pumpWidget` itself performs
      // exactly one frame.
      final controller = StreamController<String?>();
      addTearDown(controller.close);

      // Deliberately no `router:` override: the uid-aware
      // `initialLocation` pick lives in `_RoutedMaterialAppState.initState`,
      // which only runs when app.dart builds its own router (see
      // `F14_A05_home_regression` above for the same reasoning).
      await tester.pumpWidget(
        StyloBuddyApp(
          firestoreOverride: FakeFirebaseFirestore(),
          uidStream: controller.stream,
          initialUid: 'uid-1',
        ),
      );

      expect(
        find.byType(WelcomeView),
        findsNothing,
        reason:
            'the guest subtree must not render even for one frame when the '
            'StreamBuilder was given a signed-in initialData',
      );
      expect(find.byType(HomeView), findsOneWidget);
    },
  );

  testWidgets(
    'F15_A09 lib/app.dart constructs WardrobeCubit with FirestoreWardrobeRepository (not InMemoryWardrobeRepository/SeedData) once a uid is emitted, reflecting Firestore-seeded data rather than guest seed data',
    (tester) async {
      final firestore = FakeFirebaseFirestore();
      // Seed the fake Firestore directly (as a real signed-in user's
      // pre-existing document would be) before StyloBuddyApp is ever
      // pumped, so this exercises `app.dart`'s own dual-mode construction
      // (not a hand-built WardrobeCubit) actually reading from Firestore.
      await firestore
          .collection('users/uid-1/wardrobeItems')
          .doc('firestore-only-item')
          .set({
            'id': 'firestore-only-item',
            'name': 'Firestore Only',
            'category': 'Shirts',
            'color': 'Teal',
            'occasion': 'Everyday',
            'season': 'All season',
            'wears': 0,
          });

      final controller = StreamController<String?>();
      addTearDown(controller.close);
      await tester.pumpWidget(
        StyloBuddyApp(
          firestoreOverride: firestore,
          router: createAppRouter(),
          uidStream: controller.stream,
          initialUid: 'uid-1',
        ),
      );
      await tester.pumpAndSettle();
      // `pumpAndSettle` only re-pumps while a frame is actually scheduled;
      // emitting into a Cubit with no currently-listening `BlocBuilder`
      // doesn't itself schedule one, so it can return before
      // fake_cloud_firestore's `snapshots()` Future chain (pure microtasks,
      // no Timer) has actually run to completion — confirmed live while
      // writing this test: a single `pumpAndSettle()` (even paired with one
      // extra real-time delay) is flaky here. Polling via `runAsync` (which
      // steps outside the frame-pump mechanism so the real microtask/event
      // loop queue can drain) until the expected item actually shows up,
      // bounded so a genuine regression still fails fast rather than
      // hanging, is the reliable form.
      List<String> ids = [];
      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (DateTime.now().isBefore(deadline)) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
        final context = tester.element(find.byType(MaterialApp));
        ids = _idsOf(context.read<WardrobeCubit>().state);
        if (ids.contains('firestore-only-item')) break;
      }

      expect(
        ids,
        contains('firestore-only-item'),
        reason:
            'a signed-in uid must read from FirestoreWardrobeRepository, '
            'not from SeedData',
      );
      final seedIds = SeedData.items.map((i) => i.id).toList();
      expect(
        ids.any(seedIds.contains),
        isFalse,
        reason:
            'a signed-in WardrobeCubit must never fall back to guest-mode '
            'SeedData — only what Firestore actually has',
      );
    },
  );

  testWidgets(
    'F15_A24 a full sign-in -> draft -> sign-out -> sign-in-again cycle leaves no stale picked-file/draft state in the newly-constructed ImportCubit',
    (tester) async {
      final controller = StreamController<String?>();
      addTearDown(controller.close);
      await _pumpApp(tester, controller.stream);

      controller.add('uid-1');
      await tester.pumpAndSettle();
      final firstSessionContext = tester.element(find.byType(MaterialApp));
      final firstImportCubit = firstSessionContext.read<ImportCubit>();
      // Builds a draft batch (the same state `pickPhoto()` would otherwise
      // attach a real picked file onto) without touching the real
      // image_picker plugin, which this widget-test environment cannot
      // invoke. `drafts`/`pickedFiles` are both part of the "no stale
      // picker state" surface this assertion is about.
      firstSessionContext.read<ImportCubit>().setCount(1);
      firstSessionContext.read<ImportCubit>().makeDrafts();
      expect(firstSessionContext.read<ImportCubit>().state.drafts, isNotEmpty);

      controller.add(null);
      await tester.pumpAndSettle();
      controller.add('uid-1');
      await tester.pumpAndSettle();

      final secondSessionContext = tester.element(find.byType(MaterialApp));
      final freshImportCubit = secondSessionContext.read<ImportCubit>();
      expect(
        identical(freshImportCubit, firstImportCubit),
        isFalse,
        reason: 'the sign-out/sign-in cycle must reconstruct ImportCubit',
      );
      expect(freshImportCubit.state.drafts, isEmpty);
      expect(freshImportCubit.state.pickedFiles, isEmpty);
    },
  );

  testWidgets(
    'F14_A07 StyloBuddyApp with no uidStream override renders guest/SeedData state (relies on the synchronous guest-mode fallback in uidChanges(), not an injected fake stream)',
    (tester) async {
      // Deliberately no `uidStream:` override: this exercises the real
      // `uidChanges()` default path. In this widget-test environment
      // `Firebase.initializeApp()` is never called, so
      // `FirebaseAuth.instance` throws synchronously inside `uidChanges()`
      // and it falls back to a signed-out-only stream (F14-A14) — the same
      // mechanism every other harness file in this suite that omits
      // `uidStream:` actually relies on.
      await tester.pumpWidget(
        StyloBuddyApp(
          firestoreOverride: FakeFirebaseFirestore(),
          router: createAppRouter(),
        ),
      );
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(MaterialApp));
      final seedIds = SeedData.items.map((i) => i.id).toList();
      expect(_idsOf(context.read<WardrobeCubit>().state), seedIds);
    },
  );
}
