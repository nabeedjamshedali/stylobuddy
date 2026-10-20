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
import 'package:stylobuddy/shared/backend/pending_onboarding_selections.dart';
import 'package:stylobuddy/shared/data/seed_data.dart';
import 'package:stylobuddy/shared/models/clothing_item.dart';
import 'package:stylobuddy/shared/models/planned_entry.dart';

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
    'F16_A17_app_wiring lib/app.dart constructs OutfitsCubit with FirestoreOutfitsRepository (not InMemoryOutfitsRepository/SeedData) once a uid is emitted, reflecting Firestore-seeded data rather than guest seed data — exercised through StyloBuddyApp itself, not a hand-built Cubit',
    (tester) async {
      // Builds both Cubits by hand (as outfits_cubit_dual_mode_test.dart's
      // F16_A17 already does) cannot catch app.dart's own uid-based
      // ternary being inverted or hard-coded — this test drives the real
      // StyloBuddyApp widget tree instead (same harness shape as
      // F15_A09 above).
      final firestore = FakeFirebaseFirestore();
      await firestore
          .collection('users/uid-1/outfits')
          .doc('firestore-only-outfit')
          .set({
            'id': 777,
            'name': 'Firestore Only Outfit',
            'occasion': 'Gala',
            'why': 'Seeded directly in Firestore for this test.',
            'items': ['black-shirt'],
            'worn': 0,
          });

      final controller = StreamController<String?>();
      addTearDown(controller.close);
      await tester.pumpWidget(
        StyloBuddyApp(
          firestoreOverride: firestore,
          router: createAppRouter(),
          uidStream: controller.stream,
          initialUid: null,
        ),
      );
      await tester.pumpAndSettle();

      // Guest-mode first frame: the uid-keyed subtree must show the
      // signed-out seed outfits, never the Firestore-seeded one.
      var context = tester.element(find.byType(MaterialApp));
      expect(
        context.read<OutfitsCubit>().state.outfits.any(
          (o) => o.id == 777,
        ),
        isFalse,
        reason: 'a guest OutfitsCubit must never see signed-in Firestore data',
      );

      controller.add('uid-1');
      // Per the implementer contract's "Known gotcha": a bare
      // pumpAndSettle()/microtask flush is not reliable here because
      // nothing is actively listening to OutfitsCubit via a BlocBuilder in
      // this test — poll with a bounded timeout instead.
      bool sawFirestoreOutfit = false;
      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (DateTime.now().isBefore(deadline)) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
        context = tester.element(find.byType(MaterialApp));
        sawFirestoreOutfit = context.read<OutfitsCubit>().state.outfits.any(
          (o) => o.id == 777,
        );
        if (sawFirestoreOutfit) break;
      }

      expect(
        sawFirestoreOutfit,
        isTrue,
        reason:
            'a signed-in uid must read from FirestoreOutfitsRepository, '
            'not from SeedData — app.dart\'s dual-mode ternary must have '
            'actually swapped the repository implementation',
      );
      final seedOutfitIds = SeedData.outfits.map((o) => o.id).toList();
      expect(
        context.read<OutfitsCubit>().state.outfits.any(
          (o) => seedOutfitIds.contains(o.id),
        ),
        isFalse,
        reason:
            'a signed-in OutfitsCubit must never fall back to guest-mode '
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

  testWidgets(
    'F17_A11 lib/app.dart constructs PlannerCubit with InMemoryPlannerRepository when uid == null and with FirestorePlannerRepository when uid == uid-1 — object type differs across the sign-in/out transition, driven through the real StyloBuddyApp',
    (tester) async {
      // Seed the fake Firestore directly (as a real signed-in user's
      // pre-existing document would be) before StyloBuddyApp is ever
      // pumped, so this exercises app.dart's own dual-mode construction
      // (not a hand-built PlannerCubit) actually reading from Firestore.
      final firestore = FakeFirebaseFirestore();
      await firestore
          .collection('users/uid-1/plannedEntries')
          .doc('2026-12-25')
          .set({'outfitId': 777, 'occasion': 'Holiday'});

      final controller = StreamController<String?>();
      addTearDown(controller.close);
      await tester.pumpWidget(
        StyloBuddyApp(
          firestoreOverride: firestore,
          router: createAppRouter(),
          uidStream: controller.stream,
          initialUid: null,
        ),
      );
      await tester.pumpAndSettle();

      // Guest-mode first frame: the uid-keyed subtree must show the seed
      // plan map, never the Firestore-seeded signed-in entry.
      var context = tester.element(find.byType(MaterialApp));
      expect(
        context.read<PlannerCubit>().state.planned.containsKey(
          '2026-12-25',
        ),
        isFalse,
        reason: 'a guest PlannerCubit must never see signed-in Firestore '
            'data',
      );
      expect(context.read<PlannerCubit>().state.planned, isNotEmpty);

      controller.add('uid-1');
      // Per the implementer contract's "Known gotcha": a bare
      // pumpAndSettle()/microtask flush is not reliable here because
      // nothing is actively listening to PlannerCubit via a BlocBuilder in
      // this test — poll with a bounded timeout instead.
      bool sawFirestoreEntry = false;
      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (DateTime.now().isBefore(deadline)) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
        context = tester.element(find.byType(MaterialApp));
        sawFirestoreEntry = context.read<PlannerCubit>().state.planned
            .containsKey('2026-12-25');
        if (sawFirestoreEntry) break;
      }

      expect(
        sawFirestoreEntry,
        isTrue,
        reason:
            'a signed-in uid must read from FirestorePlannerRepository, '
            'not from SeedData — app.dart\'s dual-mode ternary must have '
            'actually swapped the repository implementation',
      );
      final seedKeys = SeedData.planned.keys.toSet();
      expect(
        context.read<PlannerCubit>().state.planned.keys.any(
          seedKeys.contains,
        ),
        isFalse,
        reason:
            'a signed-in PlannerCubit must never fall back to guest-mode '
            'SeedData — only what Firestore actually has',
      );
    },
  );

  testWidgets(
    'F17_A12 a full sign-in -> plan an entry -> sign-out -> sign-in-again cycle leaves the newly-constructed PlannerCubit showing only that uid\'s own Firestore plannedEntries on re-sign-in, and the in-memory seed data (not the signed-in user\'s plans, and not an empty map) on sign-out',
    (tester) async {
      final firestore = FakeFirebaseFirestore();
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

      var context = tester.element(find.byType(MaterialApp));
      context.read<PlannerCubit>().plan(
        '2026-12-25',
        const PlannedEntry(outfitId: 5, occasion: 'Holiday'),
      );

      bool planned = false;
      var deadline = DateTime.now().add(const Duration(seconds: 5));
      while (DateTime.now().isBefore(deadline)) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
        context = tester.element(find.byType(MaterialApp));
        planned = context.read<PlannerCubit>().state.planned.containsKey(
          '2026-12-25',
        );
        if (planned) break;
      }
      expect(planned, isTrue);

      // Sign-out: the newly-constructed PlannerCubit must show the
      // in-memory seed data — neither the signed-in user's plans nor an
      // empty map.
      controller.add(null);
      await tester.pumpAndSettle();
      context = tester.element(find.byType(MaterialApp));
      final guestPlanned = context.read<PlannerCubit>().state.planned;
      expect(guestPlanned.containsKey('2026-12-25'), isFalse);
      expect(guestPlanned, isNotEmpty);
      expect(guestPlanned, SeedData.planned);

      // Sign-in-again as the same uid: must see that uid's own Firestore
      // plannedEntries, re-subscribed from scratch, no bleed-through.
      controller.add('uid-1');
      bool sawReSignedInEntry = false;
      deadline = DateTime.now().add(const Duration(seconds: 5));
      while (DateTime.now().isBefore(deadline)) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
        context = tester.element(find.byType(MaterialApp));
        sawReSignedInEntry = context.read<PlannerCubit>().state.planned
            .containsKey('2026-12-25');
        if (sawReSignedInEntry) break;
      }
      expect(sawReSignedInEntry, isTrue);
    },
  );

  testWidgets(
    'F18_A11 lib/app.dart constructs ProfileCubit with InMemoryProfileRepository when uid == null and with FirestoreProfileRepository when uid == uid-1 — object type differs across the sign-in/out transition, driven through the real StyloBuddyApp',
    (tester) async {
      // Seed the fake Firestore directly (as a real signed-in user's
      // pre-existing document would be) before StyloBuddyApp is ever
      // pumped, so this exercises app.dart's own dual-mode construction
      // (not a hand-built ProfileCubit) actually reading from Firestore.
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('users').doc('uid-1').set({
        'name': 'Firestore Only Name',
        'seeded': true,
      });

      final controller = StreamController<String?>();
      addTearDown(controller.close);
      await tester.pumpWidget(
        StyloBuddyApp(
          firestoreOverride: firestore,
          router: createAppRouter(),
          uidStream: controller.stream,
          initialUid: null,
        ),
      );
      await tester.pumpAndSettle();

      // Guest-mode first frame: the uid-keyed subtree must show the
      // hardcoded default profile, never the Firestore-seeded signed-in
      // one.
      var context = tester.element(find.byType(MaterialApp));
      expect(context.read<ProfileCubit>().state.name, 'Alex Morgan');

      controller.add('uid-1');
      // Per the implementer contract's "Known gotcha": a bare
      // pumpAndSettle()/microtask flush is not reliable here because
      // nothing is actively listening to ProfileCubit via a BlocBuilder in
      // this test — poll with a bounded timeout instead.
      bool sawFirestoreName = false;
      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (DateTime.now().isBefore(deadline)) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
        context = tester.element(find.byType(MaterialApp));
        sawFirestoreName =
            context.read<ProfileCubit>().state.name == 'Firestore Only Name';
        if (sawFirestoreName) break;
      }

      expect(
        sawFirestoreName,
        isTrue,
        reason:
            'a signed-in uid must read from FirestoreProfileRepository, '
            'not from the hardcoded InMemoryProfileRepository default — '
            "app.dart's dual-mode ternary must have actually swapped the "
            'repository implementation',
      );
    },
  );

  testWidgets(
    'F18_A16_app a sign-in -> edit -> sign-out -> sign-in-as-different-uid cycle through the real StyloBuddyApp never bleeds a prior uid\'s profile data into the next one, and a profile edit landed before the bootstrap seed commits survives it',
    (tester) async {
      final firestore = FakeFirebaseFirestore();
      // Fix-round Important #5, proven deterministically (not "waited
      // out"): pre-seed 'uid-a's document with a 'name' field and
      // deliberately NO 'seeded' flag, simulating an edit that landed on
      // the document (e.g. a queued offline write that just synced)
      // before this sign-in's D5 bootstrap has ever run. The bootstrap
      // below must leave this field alone, never revert it to the
      // hardcoded default.
      await firestore.collection('users').doc('uid-a').set({'name': 'User A'});

      final controller = StreamController<String?>();
      addTearDown(controller.close);
      await tester.pumpWidget(
        StyloBuddyApp(
          firestoreOverride: firestore,
          router: createAppRouter(),
          uidStream: controller.stream,
          initialUid: 'uid-a',
        ),
      );
      await tester.pumpAndSettle();
      // BlocProvider's `create` is lazy by default — it only runs on the
      // Cubit's first access, which is what actually kicks off the
      // bootstrap below. Force that access now (mirrors what a real
      // screen's `context.read<ProfileCubit>()` would do on navigation).
      tester.element(find.byType(MaterialApp)).read<ProfileCubit>();

      // Wait for the bootstrap to actually commit.
      var seeded = false;
      var deadline = DateTime.now().add(const Duration(seconds: 5));
      while (DateTime.now().isBefore(deadline)) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        final doc = await firestore.collection('users').doc('uid-a').get();
        seeded = doc.data()?['seeded'] == true;
        if (seeded) break;
      }
      expect(seeded, isTrue);

      var context = tester.element(find.byType(MaterialApp));
      expect(
        context.read<ProfileCubit>().state.name,
        'User A',
        reason:
            'a profile field already present before the seeded flag '
            'committed must survive the bootstrap seed, never revert to '
            "the hardcoded default ('Alex Morgan')",
      );

      context.read<ProfileCubit>().updateDetails('User A Edited', 'a@x.com');

      bool sawUserAEdited = false;
      var userADeadline = DateTime.now().add(const Duration(seconds: 5));
      while (DateTime.now().isBefore(userADeadline)) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
        context = tester.element(find.byType(MaterialApp));
        sawUserAEdited =
            context.read<ProfileCubit>().state.name == 'User A Edited';
        if (sawUserAEdited) break;
      }
      expect(sawUserAEdited, isTrue);

      // Sign-out: must show the guest default, never 'User A Edited'.
      controller.add(null);
      await tester.pumpAndSettle();
      context = tester.element(find.byType(MaterialApp));
      expect(context.read<ProfileCubit>().state.name, 'Alex Morgan');

      // Sign-in as a different uid: must never see uid-a's 'User A Edited'.
      controller.add('uid-b');
      final bleedDeadline = DateTime.now().add(const Duration(seconds: 5));
      bool bled = false;
      while (DateTime.now().isBefore(bleedDeadline)) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
        context = tester.element(find.byType(MaterialApp));
        if (context.read<ProfileCubit>().state.name == 'User A Edited') {
          bled = true;
          break;
        }
      }
      expect(bled, isFalse);
    },
  );

  testWidgets(
    'fix_round_Important1_combined_bootstrap a brand-new signed-in user\'s single bootstrap through the real StyloBuddyApp seeds Firestore with SeedData\'s wardrobe items, outfits, and planned entries — not just profile fields',
    (tester) async {
      final firestore = FakeFirebaseFirestore();
      final controller = StreamController<String?>();
      addTearDown(controller.close);
      await tester.pumpWidget(
        StyloBuddyApp(
          firestoreOverride: firestore,
          router: createAppRouter(),
          uidStream: controller.stream,
          initialUid: 'uid-new',
        ),
      );
      await tester.pumpAndSettle();
      // Force every root Cubit's lazy `create` to run, mirroring what
      // real navigation to each tab would do — the bootstrap itself is
      // only kicked off from ProfileCubit's `create`, but reading the
      // others here documents that all four Cubits end up backed by the
      // same seeded uid, not just Profile's.
      final context = tester.element(find.byType(MaterialApp));
      context.read<ProfileCubit>();
      context.read<WardrobeCubit>();
      context.read<OutfitsCubit>();
      context.read<PlannerCubit>();

      var seeded = false;
      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (DateTime.now().isBefore(deadline)) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        final doc = await firestore.collection('users').doc('uid-new').get();
        seeded = doc.data()?['seeded'] == true;
        if (seeded) break;
      }
      expect(seeded, isTrue);

      final usersDoc = firestore.collection('users').doc('uid-new');
      final wardrobeDocs = await usersDoc.collection('wardrobeItems').get();
      expect(
        wardrobeDocs.docs.map((d) => d.id).toSet(),
        SeedData.items.map((i) => i.id).toSet(),
        reason:
            'before this fix round, runBootstrapIfNeeded had zero '
            'production call sites for wardrobe seed data at all',
      );

      final outfitsDocs = await usersDoc.collection('outfits').get();
      expect(
        outfitsDocs.docs.map((d) => d.id).toSet(),
        SeedData.outfits.map((o) => o.id.toString()).toSet(),
      );

      final plannedDocs = await usersDoc.collection('plannedEntries').get();
      expect(
        plannedDocs.docs.map((d) => d.id).toSet(),
        SeedData.planned.keys.toSet(),
      );
    },
  );

  testWidgets(
    'fix_round_Important3_new_uid a non-empty PendingOnboardingSelections holder, consumed through the real lib/app.dart wiring (not a hand-reimplementation) on a brand-new uid\'s sign-in, reaches the bootstrap-seeded Firestore document, and is cleared afterward',
    (tester) async {
      PendingOnboardingSelections.setChosenOccasions({'Wedding'});
      PendingOnboardingSelections.setChosenChips({'Travel'});
      addTearDown(PendingOnboardingSelections.clear);

      final firestore = FakeFirebaseFirestore();
      final controller = StreamController<String?>();
      addTearDown(controller.close);
      await tester.pumpWidget(
        StyloBuddyApp(
          firestoreOverride: firestore,
          router: createAppRouter(),
          uidStream: controller.stream,
          initialUid: null,
        ),
      );
      await tester.pumpAndSettle();

      // Sign in as a brand-new uid: lib/app.dart's own uid-keyed
      // MultiBlocProvider construction (not a test-reimplemented copy of
      // its logic) must consume-and-clear the holder and fold it into the
      // bootstrap seed.
      controller.add('uid-new-signup');
      await tester.pumpAndSettle();
      tester.element(find.byType(MaterialApp)).read<ProfileCubit>();

      List<Object?>? seededOccasions;
      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (DateTime.now().isBefore(deadline)) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        final doc = await firestore
            .collection('users')
            .doc('uid-new-signup')
            .get();
        seededOccasions = doc.data()?['occasions'] as List<Object?>?;
        if (seededOccasions != null) break;
      }

      expect(
        seededOccasions,
        isNotNull,
        reason: 'the real lib/app.dart wiring must have actually run the '
            'bootstrap and written occasions',
      );
      expect(seededOccasions, containsAll(['Wedding', 'Travel']));

      // The holder must have been cleared by app.dart's own consume()
      // call, not leaking into a later, unrelated sign-up.
      expect(PendingOnboardingSelections.consume(), isEmpty);
    },
  );

  testWidgets(
    'fix_round_Important3_returning_uid a RETURNING (already-seeded) uid\'s sign-in must NOT apply stale pending selections — the seeded guard blocks the write, but the holder is still cleared',
    (tester) async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('users').doc('uid-returning').set({
        'occasions': ['Office'],
        'seeded': true,
      });

      PendingOnboardingSelections.setChosenOccasions({'Wedding'});
      addTearDown(PendingOnboardingSelections.clear);

      final controller = StreamController<String?>();
      addTearDown(controller.close);
      await tester.pumpWidget(
        StyloBuddyApp(
          firestoreOverride: firestore,
          router: createAppRouter(),
          uidStream: controller.stream,
          initialUid: null,
        ),
      );
      await tester.pumpAndSettle();

      controller.add('uid-returning');
      await tester.pumpAndSettle();
      tester.element(find.byType(MaterialApp)).read<ProfileCubit>();

      // Give the unawaited bootstrap call a chance to run (it will no-op
      // per the seeded guard) before asserting.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pump();

      final doc = await firestore.collection('users').doc('uid-returning').get();
      expect(
        doc.data()!['occasions'],
        ['Office'],
        reason: "a returning uid's bootstrap must be a no-op (F14's "
            'existing seeded guard) — the stale pending selection must '
            'never overwrite it',
      );

      // The holder is still consumed-and-cleared by app.dart even though
      // the bootstrap itself ended up doing nothing.
      expect(PendingOnboardingSelections.consume(), isEmpty);
    },
  );

  testWidgets(
    'F19_A11 lib/app.dart constructs ShoppingCubit with InMemoryShoppingRepository when uid == null and with FirestoreShoppingRepository when uid == uid-1 — object type differs across the sign-in/out transition, driven through the real StyloBuddyApp',
    (tester) async {
      // Seed the fake Firestore directly (as a real signed-in user's
      // pre-existing document would be) before StyloBuddyApp is ever
      // pumped, so this exercises app.dart's own dual-mode construction
      // (not a hand-built ShoppingCubit) actually reading from Firestore.
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('users').doc('uid-1').set({
        'wishlist': ['firestore-only-item'],
        'seeded': true,
      });

      final controller = StreamController<String?>();
      addTearDown(controller.close);
      await tester.pumpWidget(
        StyloBuddyApp(
          firestoreOverride: firestore,
          router: createAppRouter(),
          uidStream: controller.stream,
          initialUid: null,
        ),
      );
      await tester.pumpAndSettle();

      // Guest-mode first frame: the uid-keyed subtree must show the
      // default empty wishlist, never the Firestore-seeded signed-in one.
      var context = tester.element(find.byType(MaterialApp));
      expect(context.read<ShoppingCubit>().state.wishlist, isEmpty);

      controller.add('uid-1');
      // Per the implementer contract's "Known gotcha": a bare
      // pumpAndSettle()/microtask flush is not reliable here because
      // nothing is actively listening to ShoppingCubit via a BlocBuilder
      // in this test — poll with a bounded timeout instead.
      bool sawFirestoreWishlist = false;
      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (DateTime.now().isBefore(deadline)) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
        context = tester.element(find.byType(MaterialApp));
        sawFirestoreWishlist = context
            .read<ShoppingCubit>()
            .state
            .wishlist
            .contains('firestore-only-item');
        if (sawFirestoreWishlist) break;
      }

      expect(
        sawFirestoreWishlist,
        isTrue,
        reason:
            'a signed-in uid must read from FirestoreShoppingRepository, '
            'not from the hardcoded InMemoryShoppingRepository default — '
            "app.dart's dual-mode ternary must have actually swapped the "
            'repository implementation',
      );
    },
  );
}
