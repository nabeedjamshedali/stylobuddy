import 'package:flutter_test/flutter_test.dart';
import 'package:stylobuddy/features/builder/cubit/builder_cubit.dart';
import 'package:stylobuddy/features/builder/models/builder_save_result.dart';
import 'package:stylobuddy/features/saved/cubit/outfits_cubit.dart';
import 'package:stylobuddy/features/wardrobe/cubit/wardrobe_cubit.dart';
import 'package:stylobuddy/features/wardrobe/repository/wardrobe_repository.dart';

void main() {
  late WardrobeCubit wardrobe;
  late OutfitsCubit outfits;
  late BuilderCubit cubit;
  var clockValue = 5000;

  setUp(() {
    clockValue = 5000;
    wardrobe = WardrobeCubit(WardrobeRepository());
    outfits = OutfitsCubit(wardrobe, clock: () => clockValue++);
    cubit = BuilderCubit(outfits);
  });

  tearDown(() {
    cubit.close();
    outfits.close();
    wardrobe.close();
  });

  test('test_F07_A01_empty_name_toasts_and_creates_no_outfit', () {
    cubit.toggle('white-shirt');
    final before = outfits.state.outfits.length;
    final result = cubit.save();
    expect(result.message, 'Give your outfit a name');
    expect(result.outfitId, isNull);
    expect(outfits.state.outfits.length, before);
  });

  test('test_F07_A02_whitespace_name_toasts_trimmed', () {
    cubit.setName('   ');
    cubit.toggle('white-shirt');
    final result = cubit.save();
    expect(result.message, 'Give your outfit a name');
    expect(result.outfitId, isNull);
  });

  test('test_F07_A03_valid_name_no_items_toasts', () {
    cubit.setName('Friday look');
    final before = outfits.state.outfits.length;
    final result = cubit.save();
    expect(result.message, 'Choose at least one item');
    expect(result.outfitId, isNull);
    expect(outfits.state.outfits.length, before);
  });

  test('test_F07_A04_blank_name_and_no_items_name_message_wins', () {
    final result = cubit.save();
    expect(result.message, 'Give your outfit a name');
  });

  test('test_F07_A05_valid_save_inserts_outfit_and_resets_draft', () {
    cubit.setName('Friday look');
    cubit.setOccasion('Office');
    cubit.toggle('white-shirt');
    cubit.toggle('navy-chinos');
    final before = outfits.state.outfits.length;

    final result = cubit.save();

    expect(result.message, 'Outfit saved');
    expect(result.outfitId, isNotNull);
    expect(outfits.state.outfits.length, before + 1);
    final created = outfits.state.outfits[0];
    expect(created.id, result.outfitId);
    expect(created.name, 'Friday look');
    expect(created.items, ['white-shirt', 'navy-chinos']);
    expect(created.occasion, 'Office');
    expect(
      created.why,
      'A look you put together from your own wardrobe.',
    );
    expect(cubit.state.picked, isEmpty);
    expect(cubit.state.editingId, isNull);
    expect(cubit.state.name, '');
  });

  test(
    'test_F07_A06_start_edit_loads_outfit_and_keeps_id_on_save',
    () {
      cubit.start(editId: 2);
      expect(cubit.state.editingId, 2);
      expect(cubit.state.category, 'All');
      expect(cubit.state.name, 'Modern Weekend');
      expect(cubit.state.occasion, 'Casual');
      expect(
        cubit.state.picked,
        ['black-shirt', 'beige-chinos', 'brown-loafers', 'black-watch'],
      );

      cubit.setName('Updated Weekend');
      cubit.setOccasion('Party');
      cubit.remove('black-watch');
      final before = outfits.state.outfits.length;

      final result = cubit.save();

      expect(result.outfitId, 2);
      expect(outfits.state.outfits.length, before);
      final updated = outfits.byId(2)!;
      expect(updated.name, 'Updated Weekend');
      expect(updated.occasion, 'Party');
      expect(updated.items, ['black-shirt', 'beige-chinos', 'brown-loafers']);
    },
  );

  test('test_F07_A07_start_with_no_editId_clears_draft', () {
    cubit.start(editId: 2);
    cubit.setCategory('Shoes');

    cubit.start();

    expect(cubit.state.picked, isEmpty);
    expect(cubit.state.name, '');
    expect(cubit.state.occasion, 'Everyday');
    expect(cubit.state.editingId, isNull);
    expect(cubit.state.category, 'All');
  });

  test(
    'test_F07_A08_start_nonexistent_editId_then_save_creates_new_outfit',
    () {
      cubit.start(editId: 999);
      expect(cubit.state.picked, isEmpty);
      expect(cubit.state.name, '');

      cubit.setName('Fresh look');
      cubit.toggle('white-shirt');
      final before = outfits.state.outfits.length;

      BuilderSaveResult? result;
      expect(() => result = cubit.save(), returnsNormally);

      expect(outfits.state.outfits.length, before + 1);
      expect(result!.outfitId, isNotNull);
      expect(outfits.byId(result!.outfitId!)!.name, 'Fresh look');
    },
  );

  test('toggle adds then removes an id', () {
    cubit.toggle('white-shirt');
    expect(cubit.state.picked, ['white-shirt']);
    cubit.toggle('white-shirt');
    expect(cubit.state.picked, isEmpty);
  });

  test('setCategory updates the active category', () {
    cubit.setCategory('Shoes');
    expect(cubit.state.category, 'Shoes');
  });
}
