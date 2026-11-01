import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylobuddy/features/wardrobe/cubit/import_cubit.dart';
import 'package:stylobuddy/features/wardrobe/cubit/wardrobe_cubit.dart';
import 'package:stylobuddy/features/wardrobe/repository/in_memory_wardrobe_repository.dart';
import 'package:stylobuddy/shared/backend/storage_repository.dart';

class _MockImagePicker extends Mock implements ImagePicker {}

class _MockStorageRepository extends Mock implements StorageRepository {}

class _FakeXFile extends Fake implements XFile {}

void main() {
  setUpAll(() {
    registerFallbackValue(ImageSource.camera);
    registerFallbackValue(_FakeXFile());
  });

  late WardrobeCubit wardrobe;
  late _MockImagePicker picker;
  late _MockStorageRepository storage;
  late ImportCubit cubit;
  var clockValue = 1000;

  setUp(() {
    wardrobe = WardrobeCubit(InMemoryWardrobeRepository());
    picker = _MockImagePicker();
    storage = _MockStorageRepository();
    clockValue = 1000;
    cubit = ImportCubit(
      wardrobe,
      clock: () => clockValue++,
      imagePicker: picker,
      storageRepository: storage,
    );
  });

  tearDown(() {
    cubit.close();
    wardrobe.close();
  });

  test(
    'F15_A10 confirming the last draft with a picked file calls uploadWardrobePhoto(itemId: draft.id, file: that file) before the save, and the saved item.imageUrl equals the resolved URL',
    () async {
      cubit.setCount(1);
      cubit.makeDrafts();
      final draftId = cubit.state.current!.id;
      final file = _FakeXFile();
      when(() => picker.pickImage(source: any(named: 'source'))).thenAnswer(
        (_) async => file,
      );
      await cubit.pickPhoto();
      when(
        () => storage.uploadWardrobePhoto(itemId: draftId, file: file),
      ).thenAnswer((_) async => 'https://example.com/$draftId.jpg');

      final error = await cubit.confirmCurrent(
        name: 'My Item',
        category: 'Shirts',
        color: 'White',
        occasion: 'Everyday',
        season: 'All season',
      );

      expect(error, isNull);
      verify(
        () => storage.uploadWardrobePhoto(itemId: draftId, file: file),
      ).called(1);
      final saved = wardrobe.state.items.firstWhere((i) => i.id == draftId);
      expect(saved.imageUrl, 'https://example.com/$draftId.jpg');
    },
  );

  test(
    'F15_A11 confirming a batch where no draft carries a picked file never calls uploadWardrobePhoto; every saved item imageUrl is null and sourceId-based art resolution is unaffected',
    () async {
      cubit.setCount(3);
      cubit.makeDrafts();
      final draftIds = cubit.state.drafts.map((d) => d.id).toList();
      final sourceIds = cubit.state.drafts.map((d) => d.sourceId).toList();

      for (var i = 0; i < 3; i++) {
        await cubit.confirmCurrent(
          name: 'Item $i',
          category: 'Shirts',
          color: 'White',
          occasion: 'Everyday',
          season: 'All season',
        );
      }

      verifyNever(
        () => storage.uploadWardrobePhoto(
          itemId: any(named: 'itemId'),
          file: any(named: 'file'),
        ),
      );
      for (var i = 0; i < draftIds.length; i++) {
        final saved = wardrobe.state.items.firstWhere(
          (item) => item.id == draftIds[i],
        );
        expect(saved.imageUrl, isNull);
        expect(saved.sourceId, sourceIds[i]);
      }
      expect(cubit.state.lastImportHadUploadFailure, isFalse);
    },
  );

  test(
    'F15_A12 a picked file whose upload throws still results in the item being saved, with imageUrl null, never skipped or thrown past the caller',
    () async {
      cubit.setCount(1);
      cubit.makeDrafts();
      final draftId = cubit.state.current!.id;
      final file = _FakeXFile();
      when(() => picker.pickImage(source: any(named: 'source'))).thenAnswer(
        (_) async => file,
      );
      await cubit.pickPhoto();
      when(
        () => storage.uploadWardrobePhoto(itemId: draftId, file: file),
      ).thenThrow(Exception('network down'));

      final error = await cubit.confirmCurrent(
        name: 'My Item',
        category: 'Shirts',
        color: 'White',
        occasion: 'Everyday',
        season: 'All season',
      );

      expect(error, isNull);
      final saved = wardrobe.state.items.firstWhere((i) => i.id == draftId);
      expect(saved.imageUrl, isNull);
    },
  );

  test(
    'F15_A13 a failed upload surfaces a distinguishable signal (lastImportHadUploadFailure) distinct from the no-picked-file path',
    () async {
      cubit.setCount(1);
      cubit.makeDrafts();
      final draftId = cubit.state.current!.id;
      final file = _FakeXFile();
      when(() => picker.pickImage(source: any(named: 'source'))).thenAnswer(
        (_) async => file,
      );
      await cubit.pickPhoto();
      when(
        () => storage.uploadWardrobePhoto(itemId: draftId, file: file),
      ).thenThrow(Exception('network down'));

      await cubit.confirmCurrent(
        name: 'My Item',
        category: 'Shirts',
        color: 'White',
        occasion: 'Everyday',
        season: 'All season',
      );

      expect(cubit.state.lastImportHadUploadFailure, isTrue);
    },
  );

  test(
    'F15_A13_contrast the no-picked-file path leaves lastImportHadUploadFailure false',
    () async {
      cubit.setCount(1);
      cubit.makeDrafts();

      await cubit.confirmCurrent(
        name: 'My Item',
        category: 'Shirts',
        color: 'White',
        occasion: 'Everyday',
        season: 'All season',
      );

      expect(cubit.state.lastImportHadUploadFailure, isFalse);
    },
  );

  test(
    'F15_A14 two consecutive imports, one with a picked-file upload and one without, produce distinct ids with imageUrl set/null exactly per draft',
    () async {
      // First import: no picked file.
      cubit.setCount(1);
      cubit.makeDrafts();
      final firstId = cubit.state.current!.id;
      await cubit.confirmCurrent(
        name: 'First',
        category: 'Shirts',
        color: 'White',
        occasion: 'Everyday',
        season: 'All season',
      );

      // Second import: a picked-file upload.
      cubit.setCount(1);
      cubit.makeDrafts();
      final secondId = cubit.state.current!.id;
      expect(secondId, isNot(firstId));
      final file = _FakeXFile();
      when(() => picker.pickImage(source: any(named: 'source'))).thenAnswer(
        (_) async => file,
      );
      await cubit.pickPhoto();
      when(
        () => storage.uploadWardrobePhoto(itemId: secondId, file: file),
      ).thenAnswer((_) async => 'https://example.com/$secondId.jpg');
      await cubit.confirmCurrent(
        name: 'Second',
        category: 'Shirts',
        color: 'White',
        occasion: 'Everyday',
        season: 'All season',
      );

      final first = wardrobe.state.items.firstWhere((i) => i.id == firstId);
      final second = wardrobe.state.items.firstWhere((i) => i.id == secondId);
      expect(first.imageUrl, isNull);
      expect(second.imageUrl, 'https://example.com/$secondId.jpg');
    },
  );

  test(
    'F15_edge backing out of the picker (no file ever picked) is a no-op, identical to the no-photo path',
    () async {
      cubit.setCount(1);
      cubit.makeDrafts();
      when(() => picker.pickImage(source: any(named: 'source'))).thenAnswer(
        (_) async => null,
      );

      await cubit.pickPhoto();

      expect(cubit.state.pickedFiles, isEmpty);
    },
  );

  test(
    'F15_regression makeDrafts resets pickedFiles and lastImportHadUploadFailure for a fresh batch',
    () async {
      cubit.setCount(1);
      cubit.makeDrafts();
      final file = _FakeXFile();
      when(() => picker.pickImage(source: any(named: 'source'))).thenAnswer(
        (_) async => file,
      );
      await cubit.pickPhoto();
      expect(cubit.state.pickedFiles, isNotEmpty);

      cubit.setCount(1);
      cubit.makeDrafts();

      expect(cubit.state.pickedFiles, isEmpty);
      expect(cubit.state.lastImportHadUploadFailure, isFalse);
    },
  );

  test(
    'F06_A28_regression importing 3 items without any picker interaction still keeps edits, adds 3 items (no behavior change to the existing simulated path)',
    () async {
      cubit.setCount(3);
      cubit.makeDrafts();
      final before = wardrobe.state.items.length;

      for (var i = 0; i < 3; i++) {
        final error = await cubit.confirmCurrent(
          name: 'Edited $i',
          category: 'Jackets',
          color: 'Blue',
          occasion: 'Casual',
          season: 'Fall',
        );
        expect(error, isNull);
      }

      expect(wardrobe.state.items.length, before + 3);
      expect(cubit.state.drafts, isEmpty);
      expect(cubit.state.lastImportCount, 3);
    },
  );

  test(
    'F15_important4 calling confirmCurrent twice in quick succession (before the first await resolves) results in only one save',
    () async {
      cubit.setCount(1);
      cubit.makeDrafts();
      final draftId = cubit.state.current!.id;
      final file = _FakeXFile();
      when(() => picker.pickImage(source: any(named: 'source'))).thenAnswer(
        (_) async => file,
      );
      await cubit.pickPhoto();
      final uploadGate = Completer<String>();
      when(
        () => storage.uploadWardrobePhoto(itemId: draftId, file: file),
      ).thenAnswer((_) => uploadGate.future);

      // The first call is not awaited yet, so it is suspended mid-upload
      // (inside the `await _storage.uploadWardrobePhoto(...)` call) when
      // the second call starts — a real double-tap before the first save
      // has landed.
      final firstCall = cubit.confirmCurrent(
        name: 'My Item',
        category: 'Shirts',
        color: 'White',
        occasion: 'Everyday',
        season: 'All season',
      );
      final secondCall = cubit.confirmCurrent(
        name: 'My Item Again',
        category: 'Shirts',
        color: 'White',
        occasion: 'Everyday',
        season: 'All season',
      );

      uploadGate.complete('https://example.com/$draftId.jpg');
      await Future.wait([firstCall, secondCall]);

      verify(
        () => storage.uploadWardrobePhoto(itemId: draftId, file: file),
      ).called(1);
      expect(
        wardrobe.state.items.where((i) => i.id == draftId).length,
        1,
        reason: 'the second, re-entrant call must not duplicate the save',
      );
      expect(cubit.state.saving, isFalse);
    },
  );

  test(
    'F06_A27_regression a blank name still returns the validation error and does not save',
    () async {
      cubit.setCount(1);
      cubit.makeDrafts();

      final error = await cubit.confirmCurrent(
        name: '   ',
        category: 'Shirts',
        color: 'White',
        occasion: 'Everyday',
        season: 'All season',
      );

      expect(error, 'Name is required');
      expect(cubit.state.drafts, isNotEmpty);
    },
  );
}
