import 'package:flutter_test/flutter_test.dart';
import 'package:stylobuddy/features/wardrobe/cubit/wardrobe_cubit.dart';
import 'package:stylobuddy/features/wardrobe/repository/wardrobe_repository.dart';

void main() {
  late WardrobeCubit cubit;
  setUp(() => cubit = WardrobeCubit(WardrobeRepository()));
  tearDown(() => cubit.close());

  test('seed has 23 items with wears i % 5', () {
    expect(cubit.state.items.length, 23);
    expect(cubit.state.items[0].id, 'white-shirt');
    expect(cubit.state.items[1].wears, 1);
    expect(cubit.state.items[22].wears, 2);
  });

  test('itemOrFallback builds placeholder for unknown id', () {
    final item = cubit.itemOrFallback('mystery-coat');
    expect(item.name, 'mystery coat');
    expect(item.category, 'Shirts');
    expect(item.color, 'Unknown');
    expect(item.occasion, 'Everyday');
    expect(cubit.itemOrFallback('white-shirt').name, 'White Oxford Shirt');
  });

  test('adjustWears clamps at zero and increments', () {
    cubit.adjustWears(['white-shirt'], -5);
    expect(cubit.itemOrFallback('white-shirt').wears, 0);
    cubit.adjustWears(['white-shirt'], 2);
    expect(cubit.itemOrFallback('white-shirt').wears, 2);
  });

  test('add, update and remove items', () {
    final base = cubit.itemOrFallback('white-shirt');
    cubit.addItems([base.copyWith(name: 'x')]);
    expect(cubit.state.items.length, 24);
    cubit.updateItem(base.copyWith(name: 'Renamed'));
    expect(cubit.state.items.first.name, 'Renamed');
    cubit.removeItem('white-shirt');
    expect(cubit.state.items.any((i) => i.id == 'white-shirt'), isFalse);
  });

  test('imageId falls back to id unless sourceId set', () {
    final base = cubit.itemOrFallback('white-shirt');
    expect(base.imageId, 'white-shirt');
    expect(base.copyWith(sourceId: 'black-shirt').imageId, 'black-shirt');
  });
}
