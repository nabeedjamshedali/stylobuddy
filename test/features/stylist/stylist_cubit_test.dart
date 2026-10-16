import 'package:flutter_test/flutter_test.dart';
import 'package:stylobuddy/features/stylist/cubit/stylist_cubit.dart';
import 'package:stylobuddy/features/wardrobe/cubit/wardrobe_cubit.dart';
import 'package:stylobuddy/features/wardrobe/repository/wardrobe_repository.dart';

void main() {
  late WardrobeCubit wardrobe;
  late StylistCubit cubit;

  setUp(() {
    wardrobe = WardrobeCubit(WardrobeRepository());
    cubit = StylistCubit(wardrobe);
  });

  tearDown(() async {
    await cubit.close();
    await wardrobe.close();
  });

  Future<void> generate(Future<void> Function() run) async {
    final future = run();
    await Future<void>.delayed(StylistCubit.generationDelay);
    await future;
  }

  List<List<String>> lookItems() =>
      cubit.state.results.map((r) => r.items).toList();

  test('F03_A01 automatic yields three named seed looks', () async {
    await generate(cubit.generateAutomatic);
    expect(cubit.state.results.map((r) => r.name), [
      'Refined Everyday',
      'Modern Classic',
      'Effortless Edge',
    ]);
    expect(lookItems(), [
      ['white-shirt', 'navy-chinos', 'white-sneakers', 'black-watch'],
      ['black-shirt', 'beige-chinos', 'brown-loafers', 'tan-belt'],
      ['blue-shirt', 'black-jeans', 'black-boots', 'sunglasses'],
    ]);
  });

  test('F03_A02 ids missing from the wardrobe are filtered out', () async {
    wardrobe.removeItem('white-shirt');
    await generate(cubit.generateAutomatic);
    expect(lookItems().first, [
      'navy-chinos',
      'white-sneakers',
      'black-watch',
    ]);
  });

  test('F03_A03 empty wardrobe gives three empty looks, no crash', () async {
    for (final i in List.of(wardrobe.state.items)) {
      wardrobe.removeItem(i.id);
    }
    await generate(cubit.generateAutomatic);
    expect(cubit.state.results.length, 3);
    expect(lookItems(), [<String>[], <String>[], <String>[]]);
  });

  test('F03_A04 why copy by index and occasion from state', () async {
    cubit.setOccasion('Office');
    await generate(cubit.generateAutomatic);
    expect(cubit.state.results.map((r) => r.why), [
      'Considered proportions and a cohesive level of formality make these pieces feel intentional.',
      'The contrast and garment textures work together for a balanced, refined look.',
      'A relaxed combination with complementary shapes, tones and accessories.',
    ]);
    expect(cubit.state.results.map((r) => r.occasion), everyElement('Office'));
  });

  test('F03_A05 generation flag and 1150 ms delay', () async {
    final future = cubit.generateAutomatic();
    expect(cubit.state.isGenerating, isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    expect(cubit.state.results, isEmpty);
    expect(cubit.state.isGenerating, isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await future;
    expect(cubit.state.results.length, 3);
    expect(cubit.state.isGenerating, isFalse);
  });

  void pick(
    List<String> selected,
    List<String> locked, {
    bool accessories = true,
  }) {
    selected.forEach(cubit.toggleSelect);
    locked.forEach(cubit.toggleLock);
    cubit.setAccessories(accessories);
  }

  test('F03_A06 createMatches exact result with locked shirt', () {
    pick(['white-shirt', 'navy-chinos', 'blue-jeans'], ['white-shirt']);
    expect(cubit.createMatches(), [
      ['white-shirt', 'navy-chinos', 'white-sneakers', 'black-watch'],
      ['white-shirt', 'blue-jeans', 'brown-loafers', 'black-bag'],
      ['white-shirt', 'navy-chinos', 'black-boots', 'tan-belt'],
    ]);
  });

  test('F03_A07 locked in every look, one shoe, one accessory, unique', () {
    final selected = ['white-shirt', 'navy-chinos', 'blue-jeans'];
    pick(selected, ['white-shirt']);
    final looks = cubit.createMatches();
    expect(looks.length, lessThanOrEqualTo(3));
    final keys = <String>{};
    for (final look in looks) {
      expect(look, contains('white-shirt'));
      final cats = look.map((id) => wardrobe.itemOrFallback(id).category);
      expect(cats.where((c) => c == 'Shoes').length, 1);
      expect(cats.where((c) => c == 'Accessories').length, 1);
      final extra = look.where((id) => !selected.contains(id));
      expect(extra.length, 2);
      expect(keys.add((look.toList()..sort()).join('|')), isTrue);
    }
  });

  test('F03_A08 accessories off adds nothing and skips duplicates', () {
    pick(
      ['white-shirt', 'navy-chinos', 'blue-jeans'],
      ['white-shirt'],
      accessories: false,
    );
    expect(cubit.createMatches(), [
      ['white-shirt', 'navy-chinos'],
      ['white-shirt', 'blue-jeans'],
    ]);
  });

  test('F03_A09 locked-only with accessories off gives one look', () {
    pick(['black-skirt'], ['black-skirt'], accessories: false);
    expect(cubit.createMatches(), [
      ['black-skirt'],
    ]);
  });

  test('F03_A10 locked-only with accessories on gives three looks', () {
    pick(['black-skirt'], ['black-skirt']);
    expect(cubit.createMatches(), [
      ['black-skirt', 'white-sneakers', 'black-watch'],
      ['black-skirt', 'brown-loafers', 'black-bag'],
      ['black-skirt', 'black-boots', 'tan-belt'],
    ]);
  });

  test('F03_A11 nothing selected returns no matches (exact port)', () {
    cubit.setAccessories(false);
    expect(cubit.createMatches(), isEmpty);
  });

  test('F03_A12 unowned selected ids and unselected locks are ignored', () {
    pick(['white-shirt', 'ghost-item'], ['ghost-item', 'black-skirt'],
        accessories: false);
    expect(cubit.createMatches(), [
      ['white-shirt'],
    ]);
  });

  test('F03_A13 match naming, 4th look name, and mode flag', () async {
    pick(['white-shirt'], ['white-shirt']);
    await generate(cubit.generateMatches);
    expect(cubit.state.results.map((r) => r.name), [
      'Best Match',
      'Polished Alternative',
      'Fresh Combination',
    ]);
    expect(cubit.state.isMatchMode, isTrue);
    await generate(cubit.generateAutomatic);
    expect(cubit.state.isMatchMode, isFalse);
  });

  test('F03_A14 select, lock, start matching and select-and-lock', () {
    cubit.toggleSelect('a');
    expect(cubit.state.selected, ['a']);
    cubit.toggleLock('a');
    expect(cubit.state.locked, ['a']);
    cubit.toggleSelect('a');
    expect(cubit.state.selected, isEmpty);
    expect(cubit.state.locked, isEmpty);
    cubit.toggleLock('b');
    cubit.toggleLock('b');
    expect(cubit.state.locked, isEmpty);
    cubit.setCategory('Shoes');
    cubit.toggleSelect('c');
    cubit.startMatching();
    expect(cubit.state.selected, isEmpty);
    expect(cubit.state.category, 'All');
    cubit.selectAndLock('x');
    expect(cubit.state.selected, ['x']);
    expect(cubit.state.locked, ['x']);
  });

  test('F03_A15 occasion and accessories setters feed generation', () {
    cubit.setOccasion('Party');
    expect(cubit.state.occasion, 'Party');
    pick(['black-skirt'], ['black-skirt'], accessories: false);
    expect(cubit.state.accessories, isFalse);
    expect(cubit.createMatches(), [
      ['black-skirt'],
    ]);
  });

  test('F03_A16 swapItem replaces in place and rewrites why', () async {
    await generate(cubit.generateAutomatic);
    final msg = cubit.swapItem('navy-chinos', 'beige-chinos');
    expect(msg, StylistCubit.swappedMessage);
    final look = cubit.state.results.first;
    expect(look.items, [
      'white-shirt',
      'beige-chinos',
      'white-sneakers',
      'black-watch',
    ]);
    expect(
      look.why,
      'This preview pairs ${wardrobe.itemOrFallback('beige-chinos').name} with the other selected wardrobe pieces. Review the complete styling before wearing.',
    );
    expect(look.name, 'Refined Everyday');
  });

  test('F03_A17 locked piece cannot be swapped in match mode', () async {
    pick(['white-shirt', 'navy-chinos'], ['white-shirt']);
    await generate(cubit.generateMatches);
    final before = cubit.state.results.first.items;
    final msg = cubit.swapItem('white-shirt', 'blue-shirt');
    expect(msg, 'Mandatory items cannot be swapped');
    expect(cubit.state.results.first.items, before);
  });

  test('F03_A18 shareSummary format', () async {
    await generate(cubit.generateAutomatic);
    final r = cubit.state.results.first;
    final names = r.items.map((id) => '• ${wardrobe.itemOrFallback(id).name}');
    expect(
      cubit.shareSummary(),
      'Refined Everyday — StyloBuddy\n${names.join('\n')}\n\n${r.why}',
    );
  });
}
