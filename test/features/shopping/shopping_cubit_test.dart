import 'package:flutter_test/flutter_test.dart';
import 'package:stylobuddy/features/shopping/cubit/shopping_cubit.dart';

void main() {
  late ShoppingCubit cubit;

  setUp(() => cubit = ShoppingCubit());
  tearDown(() => cubit.close());

  test('F11_A06 initial state opens on the discover tab with an empty wishlist', () {
    expect(cubit.state.tab, 'discover');
    expect(cubit.state.wishlist, isEmpty);
    expect(cubit.state.selectedId, isNull);
  });

  test('F11_A06 select stores the chosen id', () {
    cubit.select('neutral-blazer');
    expect(cubit.state.selectedId, 'neutral-blazer');
  });

  test('F11_A08 toggling wishlist on an unsaved id adds it and reports added', () {
    final added = cubit.toggleWishlist('neutral-blazer');
    expect(added, isTrue);
    expect(cubit.state.wishlist, ['neutral-blazer']);
  });

  test('F11_A08 toggling again removes it and reports not added', () {
    cubit.toggleWishlist('neutral-blazer');
    final added = cubit.toggleWishlist('neutral-blazer');
    expect(added, isFalse);
    expect(cubit.state.wishlist, isEmpty);
  });

  test('F11_A09 wishlist entries keep insertion order', () {
    cubit.toggleWishlist('formal-shoes');
    cubit.toggleWishlist('neutral-blazer');
    cubit.toggleWishlist('everyday-bag');
    expect(cubit.state.wishlist, ['formal-shoes', 'neutral-blazer', 'everyday-bag']);
  });

  test('F11_A10 wishlist keeps an entry independent of discover contents', () {
    cubit.toggleWishlist('neutral-bottom');
    cubit.setTab('wishlist');
    expect(cubit.state.wishlist, contains('neutral-bottom'));
    expect(cubit.state.tab, 'wishlist');
  });
}
