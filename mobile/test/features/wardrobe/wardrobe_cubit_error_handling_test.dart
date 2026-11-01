import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stylobuddy/features/wardrobe/cubit/wardrobe_cubit.dart';
import 'package:stylobuddy/features/wardrobe/repository/wardrobe_repository.dart';
import 'package:stylobuddy/shared/models/clothing_item.dart';

/// A [WardrobeRepository] double whose every write rejects, and whose
/// `watchItems()` stream can be made to emit an error on demand — used to
/// prove `WardrobeCubit` never lets either failure surface as an unhandled
/// async error (which `main.dart` routes to Crashlytics as `fatal: true`).
class _FlakyWardrobeRepository implements WardrobeRepository {
  final _controller = StreamController<List<ClothingItem>>.broadcast();

  void emitSnapshotError(Object error) => _controller.addError(error);

  void emitSnapshot(List<ClothingItem> items) => _controller.add(items);

  @override
  Stream<List<ClothingItem>> watchItems() => _controller.stream;

  @override
  Future<void> addItem(ClothingItem item) async =>
      throw Exception('addItem rejected');

  @override
  Future<void> addItems(List<ClothingItem> items) async =>
      throw Exception('addItems rejected');

  @override
  Future<void> updateItem(ClothingItem item) async =>
      throw Exception('updateItem rejected');

  @override
  Future<void> removeItem(String id) async =>
      throw Exception('removeItem rejected');

  @override
  Future<void> adjustWears(List<String> ids, int delta) async =>
      throw Exception('adjustWears rejected');
}

const _item = ClothingItem(
  id: 'item-1',
  name: 'Shirt',
  category: 'Shirts',
  color: 'White',
  occasion: 'Everyday',
);

void main() {
  Future<Object?> runGuarded(FutureOr<void> Function() body) {
    final completer = Completer<Object?>();
    runZonedGuarded(
      () async {
        await body();
        if (!completer.isCompleted) completer.complete(null);
      },
      (error, stack) {
        if (!completer.isCompleted) completer.complete(error);
      },
    );
    return completer.future;
  }

  test(
    'F15_important1 addItems against a rejecting repository write does not surface as an unhandled async error',
    () async {
      final repo = _FlakyWardrobeRepository();
      final cubit = WardrobeCubit(repo);
      addTearDown(cubit.close);

      final uncaught = await runGuarded(() async {
        cubit.addItems([_item]);
        await Future<void>.delayed(const Duration(milliseconds: 20));
      });

      expect(uncaught, isNull);
      // The optimistic local update still applied even though the
      // background persistence call failed.
      expect(cubit.state.items.any((i) => i.id == 'item-1'), isTrue);
    },
  );

  test(
    'F15_important1 updateItem/removeItem/adjustWears against a rejecting repository do not surface as unhandled async errors',
    () async {
      final repo = _FlakyWardrobeRepository();
      final cubit = WardrobeCubit(repo);
      addTearDown(cubit.close);
      cubit.addItems([_item]);

      final uncaught = await runGuarded(() async {
        cubit.updateItem(_item.copyWith(name: 'Renamed'));
        cubit.adjustWears(['item-1'], 1);
        cubit.removeItem('item-1');
        await Future<void>.delayed(const Duration(milliseconds: 20));
      });

      expect(uncaught, isNull);
    },
  );

  test(
    'F15_important1 a watchItems() stream error is caught by onError, logged, and does not kill the subscription or surface as an unhandled async error',
    () async {
      final repo = _FlakyWardrobeRepository();
      final cubit = WardrobeCubit(repo);
      addTearDown(cubit.close);

      final uncaught = await runGuarded(() async {
        repo.emitSnapshotError(Exception('permission-denied'));
        await Future<void>.delayed(const Duration(milliseconds: 20));

        // The subscription must still be alive after the error — a later,
        // successful snapshot still reaches this Cubit's state rather than
        // the stream having been silently abandoned.
        repo.emitSnapshot([_item]);
        await Future<void>.delayed(const Duration(milliseconds: 20));
      });

      expect(uncaught, isNull);
      expect(cubit.state.items.any((i) => i.id == 'item-1'), isTrue);
    },
  );
}
