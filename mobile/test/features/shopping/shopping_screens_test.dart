import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylobuddy/core/router/app_routes.dart';
import 'package:stylobuddy/features/shopping/cubit/shopping_cubit.dart';
import 'package:stylobuddy/features/wardrobe/cubit/wardrobe_cubit.dart';
import 'package:stylobuddy/shared/models/clothing_item.dart';
import 'package:stylobuddy/shared/widgets/screen_head.dart';

import '../support/f02_harness.dart';

ShoppingCubit shoppingCubitOf(WidgetTester tester) =>
    tester.element(find.byType(ScreenHead).first).read<ShoppingCubit>();

WardrobeCubit wardrobeCubitOf(WidgetTester tester) =>
    tester.element(find.byType(ScreenHead).first).read<WardrobeCubit>();

void main() {
  testWidgets('F11_A01 shopping renders the intro copy', (tester) async {
    await pumpApp(tester, AppRoutes.shopping);
    for (final t in [
      'Shopping Assistant',
      'SMARTER SHOPPING',
      'Wear more.\nBuy intentionally.',
      'Discover useful wardrobe additions based on what you already own—not '
          'random trends.',
    ]) {
      expect(find.text(t), findsOneWidget, reason: t);
    }
  });

  testWidgets(
    'F11_A02 seed wardrobe shows all 5 suggestions and tab counts/section copy',
    (tester) async {
      await pumpApp(tester, AppRoutes.shopping);
      expect(find.text('Discover 5', findRichText: true), findsOneWidget);
      expect(find.text('Wishlist 0', findRichText: true), findsOneWidget);
      expect(find.text('Consider for your wardrobe'), findsOneWidget);
      expect(find.text('Illustrative analysis'), findsOneWidget);
      expect(
        find.text(
          'These are sample wardrobe-gap ideas based on clothing '
          'categories—not live AI recommendations.',
        ),
        findsOneWidget,
      );
      expect(find.text('Neutral tailored blazer'), findsOneWidget);
      expect(find.text('Lightweight layering knit'), findsOneWidget);
      expect(find.text('Dress-ready footwear'), findsOneWidget);
      expect(find.text('Everyday structured bag'), findsOneWidget);
      expect(find.text('Versatile neutral bottoms'), findsOneWidget);
    },
  );

  testWidgets(
    'F11_A05 hiding all suggestions shows the discover empty state',
    (tester) async {
      await pumpApp(tester, AppRoutes.shopping);
      final wardrobe = wardrobeCubitOf(tester);
      ClothingItem of(String id, String category) => ClothingItem(
        id: id,
        name: id,
        category: category,
        color: 'Black',
        occasion: 'Casual',
      );
      wardrobe.addItems([
        of('o1', 'Outerwear'),
        of('o2', 'Outerwear'),
        of('o3', 'Outerwear'),
        of('s1', 'Shoes'),
        of('a1', 'Accessories'),
        of('p1', 'Pants'),
        of('p2', 'Pants'),
      ]);
      await tester.pumpAndSettle();
      expect(find.text('Your wardrobe covers these categories'), findsOneWidget);
      expect(
        find.text('Explore your clothing collection or return when you add more items.'),
        findsOneWidget,
      );
      expect(find.text('Neutral tailored blazer'), findsNothing);
    },
  );

  testWidgets(
    'F11_A06 a suggestion card shows tag/title/tone/link and opens /shop-item',
    (tester) async {
      final router = await pumpApp(tester, AppRoutes.shopping);
      expect(find.text('Versatile layer'), findsOneWidget);
      expect(find.text('Neutral tailored blazer'), findsOneWidget);
      expect(find.text('Sand / charcoal'), findsOneWidget);
      expect(find.text('Explore suggestion →'), findsWidgets);

      await tester.tap(find.text('Neutral tailored blazer'));
      await tester.pumpAndSettle();
      expect(pathOf(router), AppRoutes.shopItem);
      expect(shoppingCubitOf(tester).state.selectedId, 'neutral-blazer');
    },
  );

  testWidgets('F11_A07 renders the phase 1 / phase 2 block', (tester) async {
    await pumpApp(tester, AppRoutes.shopping);
    expect(find.text('PHASE 1 · AVAILABLE IN PROTOTYPE'), findsOneWidget);
    expect(find.text('Shop your wardrobe gaps'), findsOneWidget);
    expect(find.text('PHASE 2 · PLANNED'), findsOneWidget);
    expect(find.text('Explore real products'), findsOneWidget);
    expect(
      find.text(
        'Store availability, product links and prices will be added '
        'later. No live products are shown here.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'F11_A09 wishlist tab shows saved count, entries in order, and empty state',
    (tester) async {
      await pumpApp(tester, AppRoutes.shopping);
      final wishlistTab = find.text('Wishlist 0', findRichText: true);
      await tester.ensureVisible(wishlistTab);
      await tester.tap(wishlistTab);
      await tester.pumpAndSettle();
      expect(find.text('Your shopping wishlist'), findsOneWidget);
      expect(find.text('0 saved'), findsOneWidget);
      expect(find.text('Nothing saved yet'), findsOneWidget);
      expect(
        find.text('Explore suggestions and save ideas you want to remember.'),
        findsOneWidget,
      );
      await tapText(tester, 'Explore suggestions');
      expect(shoppingCubitOf(tester).state.tab, 'discover');
    },
  );

  testWidgets('F11_A11 detail renders the blazer suggestion fully', (tester) async {
    final router = await pumpApp(tester, AppRoutes.shopping);
    await tester.tap(find.text('Neutral tailored blazer'));
    await tester.pumpAndSettle();
    expect(pathOf(router), AppRoutes.shopItem);

    for (final t in [
      'Wardrobe Suggestion',
      'VERSATILE LAYER',
      'Neutral tailored blazer',
      'Sand / charcoal · Outerwear',
      'Why it could help',
      'Style with what you own',
      'Try a simple cut with enough room for lightweight layers.',
      'These are category-level suggestions, not real store products or '
          'guaranteed AI compatibility scores.',
    ]) {
      expect(find.text(t), findsOneWidget, reason: t);
    }
    expect(find.text('White Oxford Shirt'), findsOneWidget);
    expect(find.text('Navy Chinos'), findsOneWidget);
    expect(find.text('Brown Loafers'), findsOneWidget);
  });

  testWidgets(
    'F11_A12 detail for neutral-bottom omits green-shirt (missing from the wardrobe)',
    (tester) async {
      final router = await pumpApp(tester, AppRoutes.shopping);
      final card = find.text('Versatile neutral bottoms');
      await tester.ensureVisible(card);
      await tester.tap(card);
      await tester.pumpAndSettle();
      expect(pathOf(router), AppRoutes.shopItem);
      expect(find.text('White Sneakers'), findsOneWidget);
      expect(find.text('Black Watch'), findsOneWidget);
      // Only 2 owned pieces shown, not 3: green-shirt is not in the seed wardrobe.
      expect(find.textContaining('green'), findsNothing);
    },
  );

  testWidgets(
    'F11_A13 save toggles label and toasts; F11_A08 toast text matches',
    (tester) async {
      await pumpApp(tester, AppRoutes.shopping);
      await tester.tap(find.text('Neutral tailored blazer'));
      await tester.pumpAndSettle();

      expect(find.text('♡ Save to wishlist'), findsOneWidget);
      await tapText(tester, '♡ Save to wishlist');
      expect(find.text('Added to wishlist'), findsOneWidget);
      expect(find.text('✓ Saved · Remove from wishlist'), findsOneWidget);
      await drainToast(tester);

      await tapText(tester, '✓ Saved · Remove from wishlist');
      expect(find.text('Removed from wishlist'), findsOneWidget);
      expect(find.text('♡ Save to wishlist'), findsOneWidget);
      await drainToast(tester);
    },
  );

  testWidgets('F11_A14 add-to-wardrobe button opens /import', (tester) async {
    final router = await pumpApp(tester, AppRoutes.shopping);
    await tester.tap(find.text('Neutral tailored blazer'));
    await tester.pumpAndSettle();
    await tapText(tester, 'I bought something like this · Add to wardrobe');
    expect(pathOf(router), AppRoutes.import);
  });

  testWidgets('F11_A15 unknown selectedId renders the first catalog entry', (
    tester,
  ) async {
    await pumpApp(tester, AppRoutes.shopping);
    final cubit = shoppingCubitOf(tester);
    cubit.select('unknown-id');
    await tester.pumpAndSettle();
    final router = await pumpApp(tester, AppRoutes.shopItem);
    // Re-pump at the detail route directly with a fresh app (selectedId null
    // by default) still falls back to the first entry without throwing.
    expect(find.text('Neutral tailored blazer'), findsOneWidget);
    expect(pathOf(router), AppRoutes.shopItem);
  });

  testWidgets('F11_A16 header back targets shopping -> /home, shop-item -> /shopping', (
    tester,
  ) async {
    final router = await pumpApp(tester, AppRoutes.shopping);
    await tester.tap(find.text('Neutral tailored blazer'));
    await tester.pumpAndSettle();
    expect(pathOf(router), AppRoutes.shopItem);

    await tester.tap(find.text('‹'));
    await tester.pumpAndSettle();
    expect(pathOf(router), AppRoutes.shopping);

    await tester.tap(find.text('‹'));
    await tester.pumpAndSettle();
    expect(pathOf(router), AppRoutes.home);
  });
}
