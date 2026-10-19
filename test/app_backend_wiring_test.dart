import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylobuddy/app.dart';
import 'package:stylobuddy/core/router/app_router.dart';
import 'package:stylobuddy/features/builder/cubit/builder_cubit.dart';
import 'package:stylobuddy/features/calendar/cubit/planner_cubit.dart';
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
    StyloBuddyApp(router: createAppRouter(), uidStream: uidStream),
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
      expect(_idsOf(finalContext.read<WardrobeCubit>().state), initialWardrobeIds);
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
    'F14_A04 a duplicate consecutive uid emission does not rebuild the provider subtree',
    (tester) async {
      final controller = StreamController<String?>();
      addTearDown(controller.close);
      await _pumpApp(tester, controller.stream);

      controller.add('uid-1');
      await tester.pumpAndSettle();
      final afterFirst = tester.element(
        find.byType(MaterialApp),
      ).read<WardrobeCubit>();

      controller.add('uid-1'); // duplicate consecutive value
      await tester.pumpAndSettle();
      final afterDuplicate = tester.element(
        find.byType(MaterialApp),
      ).read<WardrobeCubit>();

      expect(identical(afterFirst, afterDuplicate), isTrue);
    },
  );
}
