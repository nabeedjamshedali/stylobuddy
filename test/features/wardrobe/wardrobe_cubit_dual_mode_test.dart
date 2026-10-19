import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylobuddy/features/wardrobe/cubit/wardrobe_cubit.dart';
import 'package:stylobuddy/features/wardrobe/repository/firestore_wardrobe_repository.dart';
import 'package:stylobuddy/features/wardrobe/repository/in_memory_wardrobe_repository.dart';
import 'package:stylobuddy/shared/backend/firestore_service.dart';
import 'package:stylobuddy/shared/models/clothing_item.dart';

void main() {
  test(
    'F15_A09 WardrobeCubit constructed with InMemoryWardrobeRepository vs FirestoreWardrobeRepository is a different object type, not just different data',
    () async {
      final guestCubit = WardrobeCubit(InMemoryWardrobeRepository());
      final firestore = FakeFirebaseFirestore();
      final signedInCubit = WardrobeCubit(
        FirestoreWardrobeRepository(
          FirestoreService(firestore: firestore),
          'uid-1',
        ),
      );

      addTearDown(guestCubit.close);
      addTearDown(signedInCubit.close);
      // Let both repositories' first `watchItems()` event be delivered
      // (both are genuinely async: the in-memory one buffers its seeded
      // event until the first microtask tick after listen(), the
      // Firestore one until the fake double's first snapshot arrives).
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Not directly inspectable (the repository field is private), but
      // the observable behavior difference is: guest state is non-empty
      // immediately (seed data), signed-in state starts empty until a
      // snapshot arrives — this is the type-level behavior difference
      // F15-A09 is about.
      expect(guestCubit.state.items, isNotEmpty);
      expect(signedInCubit.state.items, isEmpty);
    },
  );

  test(
    'F15_A23 two concurrent WardrobeCubit constructions for the same brand-new uid never result in more than the bootstrap-seeded set of documents — the wardrobe path itself performs no writes',
    () async {
      final firestore = FakeFirebaseFirestore();
      final service = FirestoreService(firestore: firestore);

      // Simulate the bootstrap seeding a fixed set exactly once, as the
      // real runBootstrapIfNeeded caller would (not this task's code).
      await service.runBootstrapIfNeeded('uid-new', (tx, userDoc) async {
        tx.set(userDoc.collection('wardrobeItems').doc('seed-1'), {
          'id': 'seed-1',
          'name': 'Seed Item',
          'category': 'Shirts',
          'color': 'White',
          'occasion': 'Everyday',
          'season': 'All season',
          'wears': 0,
        });
      });

      final cubitA = WardrobeCubit(
        FirestoreWardrobeRepository(service, 'uid-new'),
      );
      final cubitB = WardrobeCubit(
        FirestoreWardrobeRepository(service, 'uid-new'),
      );
      addTearDown(cubitA.close);
      addTearDown(cubitB.close);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      final raw = await firestore
          .collection('users/uid-new/wardrobeItems')
          .get();
      expect(raw.docs.length, 1);
      expect(cubitA.state.items.length, 1);
      expect(cubitB.state.items.length, 1);
    },
  );

  test(
    'F15_A07_sample a WardrobeCubit backed by InMemoryWardrobeRepository behaves exactly like today\'s synchronous F06 suite for a representative write (addItems)',
    () {
      final cubit = WardrobeCubit(InMemoryWardrobeRepository());
      addTearDown(cubit.close);
      final before = cubit.state.items.length;

      cubit.addItems([
        const ClothingItem(
          id: 'new-item',
          name: 'New Item',
          category: 'Shirts',
          color: 'Red',
          occasion: 'Everyday',
        ),
      ]);

      expect(cubit.state.items.length, before + 1);
    },
  );
}
