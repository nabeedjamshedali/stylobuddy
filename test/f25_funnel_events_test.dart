import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylobuddy/features/auth/cubit/auth_cubit.dart';
import 'package:stylobuddy/features/auth/cubit/auth_state.dart';
import 'package:stylobuddy/features/auth/repository/auth_repository.dart';
import 'package:stylobuddy/features/onboarding/cubit/onboarding_cubit.dart';
import 'package:stylobuddy/features/saved/cubit/outfits_cubit.dart';
import 'package:stylobuddy/features/stylist/cubit/stylist_cubit.dart';
import 'package:stylobuddy/features/wardrobe/cubit/import_cubit.dart';
import 'package:stylobuddy/features/wardrobe/cubit/wardrobe_cubit.dart';
import 'package:stylobuddy/features/wardrobe/repository/in_memory_wardrobe_repository.dart';
import 'package:stylobuddy/shared/backend/pending_onboarding_selections.dart';
import 'package:stylobuddy/shared/backend/storage_repository.dart';
import 'package:stylobuddy/shared/models/genders.dart';
import 'package:stylobuddy/shared/models/outfit.dart';

import 'support/recording_analytics_sink.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockUser extends Mock implements User {}

class _MockImagePicker extends Mock implements ImagePicker {}

class _MockStorageRepository extends Mock implements StorageRepository {}

class _FakeXFile extends Fake implements XFile {}

Future<String?> _confirm(ImportCubit cubit) => cubit.confirmCurrent(
  name: 'Item',
  category: 'Shirts',
  color: 'White',
  occasion: 'Everyday',
  season: 'All season',
);

void main() {
  setUpAll(() {
    registerFallbackValue(ImageSource.camera);
    registerFallbackValue(_FakeXFile());
  });

  setUp(PendingOnboardingSelections.clear);

  test('F25_A34 onboarding start/complete/skip events, and the gender choice is never logged', () async {
    final r = recordingAnalytics();
    final cubit = OnboardingCubit(analytics: r.service);
    addTearDown(cubit.close);

    cubit.setGender(Genders.female);
    cubit.start();
    expect(r.sink.eventNames, ['onboarding_start']);

    cubit.toggleOccasion('Office');
    cubit.toggleOccasion('Travel');
    for (var i = 0; i < 4; i++) {
      cubit.next();
    }
    expect(r.sink.eventNames, ['onboarding_start']);
    cubit.next();
    expect(r.sink.eventNames, ['onboarding_start', 'onboarding_complete']);
    expect(cubit.state.chosenOccasions.length, 2);
    expect(r.sink.named('onboarding_complete').single.parameters, {
      'occasion_count': 2,
    });

    final skips = recordingAnalytics();
    final skipCubit = OnboardingCubit(analytics: skips.service);
    addTearDown(skipCubit.close);
    skipCubit.setGender(Genders.male);
    skipCubit.skipFromWelcome();
    skipCubit.next();
    skipCubit.next();
    await Future<void>.delayed(Duration.zero);
    final emitted = [];
    final sub = skipCubit.stream.listen(emitted.add);
    skipCubit.skipFromWelcome();
    skipCubit.skipFromIntro();
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();
    expect(emitted, isEmpty, reason: 'skip methods emit no state');
    expect(skips.sink.events.map((c) => c.parameters).toList(), [
      {'skip_from': 'welcome'},
      {'skip_from': 'welcome'},
      {'skip_from': 'intro', 'slide': 3},
    ]);

    for (final call in [...r.sink.calls, ...skips.sink.calls]) {
      for (final entry in call.parameters.entries) {
        expect(entry.key.contains('gender'), isFalse, reason: '$call');
        expect(entry.value, isNot(anyOf('male', 'female')), reason: '$call');
      }
    }
  });

  group('F25_A35 AuthCubit', () {
    late _MockAuthRepository repository;

    setUp(() => repository = _MockAuthRepository());

    test('F25_A35 Google success logs login{method: google} once; failures and cancels log nothing', () async {
      final r = recordingAnalytics();
      final user = _MockUser();
      when(() => user.email).thenReturn('a@b.c');
      final cubit = AuthCubit(repository: repository, analytics: r.service);
      addTearDown(cubit.close);

      when(() => repository.signInWithGoogle()).thenAnswer((_) async => user);
      expect(await cubit.signInWithGoogle(), AuthResult.success);
      expect(r.sink.events, hasLength(1));
      expect(r.sink.events.single.name, 'login');
      expect(r.sink.events.single.parameters, {'method': 'google'});

      r.sink.clear();
      for (final Object failure in [
        StateError('cancelled'),
        FirebaseAuthException(code: 'network-request-failed', message: 'x'),
        Exception('plugin'),
      ]) {
        when(() => repository.signInWithGoogle()).thenThrow(failure);
        expect(await cubit.signInWithGoogle(), AuthResult.failure);
      }
      expect(r.sink.calls, isEmpty);
    });

    test('F25_A35 continueAsGuest logs guest_start and emits no state', () async {
      final r = recordingAnalytics();
      final cubit = AuthCubit(repository: repository, analytics: r.service);
      addTearDown(cubit.close);
      final emitted = [];
      final sub = cubit.stream.listen(emitted.add);
      cubit.continueAsGuest();
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      expect(r.sink.eventNames, ['guest_start']);
      expect(r.sink.events.single.parameters, isEmpty);
      expect(emitted, isEmpty);
    });
  });

  group('F25_A36 StylistCubit', () {
    late WardrobeCubit wardrobe;

    setUp(() => wardrobe = WardrobeCubit(InMemoryWardrobeRepository()));
    tearDown(() => wardrobe.close());

    test('F25_A36 automatic and match generations each log once with their result count', () async {
      final r = recordingAnalytics();
      final cubit = StylistCubit(wardrobe, analytics: r.service);
      addTearDown(cubit.close);

      final first = cubit.generateAutomatic();
      await cubit.generateAutomatic(); // already generating: ignored
      expect(r.sink.calls, isEmpty, reason: 'nothing before the wait ends');
      await first;
      expect(r.sink.events, hasLength(1));
      expect(r.sink.events.single.name, 'outfit_generated');
      expect(r.sink.events.single.parameters, {
        'mode': 'automatic',
        'result_count': 3,
      });

      r.sink.clear();
      cubit.selectAndLock('white-shirt');
      await cubit.generateMatches();
      expect(r.sink.events.single.parameters, {
        'mode': 'match',
        'result_count': cubit.state.results.length,
      });
    });

    test('F25_A36 closing the cubit during the wait logs nothing', () async {
      final r = recordingAnalytics();
      final cubit = StylistCubit(wardrobe, analytics: r.service);
      final pending = cubit.generateAutomatic();
      await cubit.close();
      await pending;
      expect(r.sink.calls, isEmpty);
    });
  });

  group('F25_A37 ImportCubit', () {
    late WardrobeCubit wardrobe;
    late _MockImagePicker picker;
    late _MockStorageRepository storage;
    late RecordingAnalyticsSink sink;
    late ImportCubit cubit;
    var clock = 1000;

    setUp(() {
      wardrobe = WardrobeCubit(InMemoryWardrobeRepository());
      picker = _MockImagePicker();
      storage = _MockStorageRepository();
      final r = recordingAnalytics();
      sink = r.sink;
      clock = 1000;
      cubit = ImportCubit(
        wardrobe,
        clock: () => clock++,
        imagePicker: picker,
        storageRepository: storage,
        analytics: r.service,
      );
    });

    tearDown(() {
      cubit.close();
      wardrobe.close();
    });

    test('F25_A37 a finished 3-draft batch with no photos logs once with photo_count 0', () async {
      cubit.setCount(3);
      cubit.makeDrafts();
      await _confirm(cubit);
      await _confirm(cubit);
      expect(sink.calls, isEmpty, reason: 'intermediate drafts log nothing');
      await _confirm(cubit);
      expect(sink.events, hasLength(1));
      expect(sink.events.single.name, 'wardrobe_items_added');
      expect(sink.events.single.parameters, {
        'source': 'camera',
        'item_count': 3,
        'photo_count': 0,
      });
    });

    test('F25_A37 gallery batch counts only successfully uploaded photos', () async {
      cubit.setSource('gallery');
      cubit.setCount(3);
      cubit.makeDrafts();
      final ids = cubit.state.drafts.map((d) => d.id).toList();
      final ok = _FakeXFile();
      final bad = _FakeXFile();
      when(() => storage.uploadWardrobePhoto(itemId: ids[0], file: ok))
          .thenAnswer((_) async => 'https://example.com/a.jpg');
      when(() => storage.uploadWardrobePhoto(itemId: ids[1], file: bad))
          .thenThrow(Exception('upload failed'));

      when(() => picker.pickImage(source: any(named: 'source')))
          .thenAnswer((_) async => ok);
      await cubit.pickPhoto();
      await _confirm(cubit);
      when(() => picker.pickImage(source: any(named: 'source')))
          .thenAnswer((_) async => bad);
      await cubit.pickPhoto();
      await _confirm(cubit);
      await _confirm(cubit);

      expect(sink.events.single.parameters, {
        'source': 'gallery',
        'item_count': 3,
        'photo_count': 1,
      });
    });
  });

  group('F25_A38 OutfitsCubit', () {
    late WardrobeCubit wardrobe;

    setUp(() => wardrobe = WardrobeCubit(InMemoryWardrobeRepository()));
    tearDown(() => wardrobe.close());

    test('F25_A38 only newly created outfits log outfit_saved, with their source', () async {
      final r = recordingAnalytics();
      var clock = 5000;
      final cubit = OutfitsCubit(
        wardrobe,
        clock: () => clock++,
        analytics: r.service,
      );
      addTearDown(cubit.close);

      const draft = Outfit(
        id: 0,
        name: 'Look',
        occasion: 'Everyday',
        items: ['white-shirt', 'navy-chinos', 'white-sneakers'],
        why: 'why',
      );
      cubit.saveOrFind(draft);
      expect(r.sink.events.single.parameters, {
        'source': 'generated',
        'item_count': 3,
      });
      expect(r.sink.events.single.name, 'outfit_saved');

      r.sink.clear();
      cubit.saveOrFind(draft); // identical items: existing outfit returned
      expect(r.sink.calls, isEmpty);

      final created = cubit.upsertManual(
        name: 'Mine',
        items: ['black-shirt', 'beige-chinos'],
        occasion: 'Office',
      );
      expect(r.sink.events.single.parameters, {
        'source': 'builder',
        'item_count': 2,
      });

      r.sink.clear();
      cubit.upsertManual(
        editingId: created.id,
        name: 'Mine edited',
        items: ['black-shirt'],
        occasion: 'Office',
      );
      expect(r.sink.calls, isEmpty, reason: 'edits are not new saves');

      cubit.upsertManual(
        editingId: 999999,
        name: 'Stale',
        items: ['black-shirt', 'tan-belt', 'black-watch', 'brown-loafers'],
        occasion: 'Office',
      );
      expect(r.sink.events.single.parameters, {
        'source': 'builder',
        'item_count': 4,
      });
    });
  });

  test('F25_A39 every logging cubit defaults to the no-op service and still works without one', () async {
    const files = {
      'lib/features/onboarding/cubit/onboarding_cubit.dart',
      'lib/features/auth/cubit/auth_cubit.dart',
      'lib/features/stylist/cubit/stylist_cubit.dart',
      'lib/features/wardrobe/cubit/import_cubit.dart',
      'lib/features/saved/cubit/outfits_cubit.dart',
    };
    for (final path in files) {
      expect(
        File(path).readAsStringSync(),
        contains('analytics ?? const AnalyticsService.noop()'),
        reason: path,
      );
    }

    final onboarding = OnboardingCubit()
      ..start()
      ..skipFromWelcome();
    final auth = AuthCubit(repository: _MockAuthRepository())..continueAsGuest();
    final wardrobe = WardrobeCubit(InMemoryWardrobeRepository());
    final outfits = OutfitsCubit(wardrobe)
      ..upsertManual(name: 'n', items: ['black-shirt'], occasion: 'Office');
    final stylist = StylistCubit(wardrobe);
    await stylist.generateAutomatic();
    final import = ImportCubit(
      wardrobe,
      imagePicker: _MockImagePicker(),
      storageRepository: _MockStorageRepository(),
    )..setCount(1)..makeDrafts();
    expect(await _confirm(import), isNull);
    expect(stylist.state.results, isNotEmpty);
    for (final c in [onboarding, auth, outfits, stylist, import, wardrobe]) {
      await c.close();
    }
  });
}
