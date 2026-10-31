import 'package:flutter_test/flutter_test.dart';
import 'package:stylobuddy/features/stylist/cubit/stylist_cubit.dart';
import 'package:stylobuddy/features/stylist/models/style_result.dart';
import 'package:stylobuddy/features/wardrobe/cubit/wardrobe_cubit.dart';
import 'package:stylobuddy/features/wardrobe/repository/in_memory_wardrobe_repository.dart';
import 'package:stylobuddy/shared/backend/ai_stylist_client.dart';
import 'package:stylobuddy/shared/backend/analytics_service.dart';
import 'package:stylobuddy/shared/models/clothing_item.dart';

import '../../support/fake_ai_stylist_client.dart';
import '../../support/recording_analytics_sink.dart';

const _two = [
  AiOutfit(
    name: 'AI One',
    why: 'Why one.',
    itemIds: ['white-shirt', 'navy-chinos'],
  ),
  AiOutfit(
    name: 'AI Two',
    why: 'Why two.',
    itemIds: ['black-shirt', 'beige-chinos', 'brown-loafers'],
  ),
];

const _ms10 = Duration(milliseconds: 10);
const _s3 = Duration(milliseconds: 3000);

class _Harness {
  _Harness({
    FakeAiStylistClient? fake,
    bool withClient = true,
    bool Function()? available,
    int Function()? clock,
  }) : fake = fake ?? FakeAiStylistClient(outfits: _two),
       wardrobe = WardrobeCubit(InMemoryWardrobeRepository()),
       analytics = recordingAnalytics() {
    cubit = StylistCubit(
      wardrobe,
      clock: clock ?? () => 1000,
      analytics: analytics.service,
      aiClient: withClient ? this.fake : null,
      aiAvailable: available ?? () => true,
    );
  }

  final WardrobeCubit wardrobe;
  late final StylistCubit cubit;
  final FakeAiStylistClient fake;
  final ({RecordingAnalyticsSink sink, AnalyticsService service}) analytics;

  Future<void> close() async {
    await cubit.close();
    await wardrobe.close();
  }

  void replaceWardrobe(List<ClothingItem> items) {
    for (final i in List.of(wardrobe.state.items)) {
      wardrobe.removeItem(i.id);
    }
    wardrobe.addItems(items);
  }
}

List<List<String>> _items(StylistCubit c) =>
    c.state.results.map((r) => r.items).toList();

const _f03Names = ['Refined Everyday', 'Modern Classic', 'Effortless Edge'];
const _f03Items = [
  ['white-shirt', 'navy-chinos', 'white-sneakers', 'black-watch'],
  ['black-shirt', 'beige-chinos', 'brown-loafers', 'tan-belt'],
  ['blue-shirt', 'black-jeans', 'black-boots', 'sunglasses'],
];

void expectF03Looks(StylistCubit c) {
  expect(c.state.results.map((r) => r.name), _f03Names);
  expect(_items(c), _f03Items);
  expect(
    c.state.results.map((r) => r.source),
    everyElement(StyleResultSource.algorithm),
  );
}

ClothingItem _item(String id, {String occasion = 'Office'}) => ClothingItem(
  id: id,
  name: 'Item $id',
  category: 'Shirts',
  color: 'Red',
  occasion: occasion,
);

void main() {
  test('F26_A50 StyleResult.source defaults to algorithm and copies', () {
    expect(StyleResultSource.values, [
      StyleResultSource.ai,
      StyleResultSource.algorithm,
    ]);
    const r = StyleResult(id: 1, name: 'n', items: [], occasion: 'o', why: 'w');
    expect(r.source, StyleResultSource.algorithm);
    expect(r.copyWith().source, StyleResultSource.algorithm);
    final ai = r.copyWith(source: StyleResultSource.ai);
    expect(ai.source, StyleResultSource.ai);
    expect(
      [ai.id, ai.name, ai.items, ai.occasion, ai.why],
      [1, 'n', <String>[], 'o', 'w'],
    );
    expect(ai.copyWith(name: 'x').source, StyleResultSource.ai);
  });

  test('F26_A54 cubit timing constants', () {
    expect(StylistCubit.aiTimeout, const Duration(seconds: 16));
    expect(StylistCubit.generationDelay, const Duration(milliseconds: 1150));
  });

  test(
    'F26_A55 aiAvailable follows client and predicate on every read',
    () async {
      final fake = FakeAiStylistClient();
      final wardrobe = WardrobeCubit(InMemoryWardrobeRepository());
      addTearDown(wardrobe.close);
      StylistCubit make({AiStylistClient? c, bool Function()? p}) {
        final cubit = StylistCubit(wardrobe, aiClient: c, aiAvailable: p);
        addTearDown(cubit.close);
        return cubit;
      }

      expect(make().aiAvailable, isFalse);
      expect(make(p: () => true).aiAvailable, isFalse);
      expect(make(c: fake).aiAvailable, isFalse);
      expect(make(c: fake, p: () => false).aiAvailable, isFalse);
      expect(make(c: fake, p: () => true).aiAvailable, isTrue);

      var on = false;
      final flipping = make(c: fake, p: () => on);
      var emissions = 0;
      final sub = flipping.stream.listen((_) => emissions++);
      addTearDown(sub.cancel);
      expect(flipping.aiAvailable, isFalse);
      on = true;
      expect(flipping.aiAvailable, isTrue);
      on = false;
      expect(flipping.aiAvailable, isFalse);
      await Future<void>.delayed(Duration.zero);
      expect(emissions, 0);
    },
  );

  testWidgets('F26_A56 AI success in auto mode', (tester) async {
    final h = _Harness(
      fake: FakeAiStylistClient(outfits: _two, delay: _ms10),
      clock: () => 5000,
    );
    addTearDown(h.close);
    h.cubit.setOccasion('Office');
    final run = h.cubit.generateAutomatic();
    expect(h.cubit.state.isGenerating, isTrue);
    await tester.pump(StylistCubit.generationDelay);
    await run;
    final s = h.cubit.state;
    expect(s.isGenerating, isFalse);
    expect(s.isMatchMode, isFalse);
    expect(s.results.map((r) => r.name), ['AI One', 'AI Two']);
    expect(s.results.map((r) => r.why), ['Why one.', 'Why two.']);
    expect(_items(h.cubit), [_two[0].itemIds, _two[1].itemIds]);
    expect(s.results.map((r) => r.source), everyElement(StyleResultSource.ai));
    expect(s.results.map((r) => r.occasion), everyElement('Office'));
    expect(s.results.map((r) => r.id), [5000, 5001]);
    expect(s.resultsByAi, isTrue);

    expect(h.fake.requests, hasLength(1));
    final req = h.fake.requests.single;
    expect(req.mode, AiStylistMode.auto);
    expect(req.lockedIds, isEmpty);
    expect(req.selectedIds, isEmpty);
    expect(req.occasion, 'Office');
    expect(req.styleDirection, 'Smart casual');
    expect(req.weather, 'Mild / all season');
    expect(req.includeAccessories, isTrue);
    expect(h.analytics.sink.named('outfit_generated'), hasLength(1));
    expect(h.analytics.sink.named('outfit_generated').single.parameters, {
      'mode': 'automatic',
      'result_count': 2,
    });
  });

  testWidgets('F26_A57 minimum wait and slow answer', (tester) async {
    final fast = _Harness(
      fake: FakeAiStylistClient(outfits: _two, delay: _ms10),
    );
    addTearDown(fast.close);
    final run = fast.cubit.generateAutomatic();
    await tester.pump(const Duration(milliseconds: 1100));
    expect(fast.cubit.state.isGenerating, isTrue);
    expect(fast.cubit.state.results, isEmpty);
    await tester.pump(const Duration(milliseconds: 50));
    await run;
    expect(fast.cubit.state.results.map((r) => r.name), ['AI One', 'AI Two']);

    final slow = _Harness(
      fake: FakeAiStylistClient(outfits: _two, delay: _s3),
    );
    addTearDown(slow.close);
    final run2 = slow.cubit.generateAutomatic();
    await tester.pump(const Duration(milliseconds: 2900));
    expect(slow.cubit.state.isGenerating, isTrue);
    await tester.pump(const Duration(milliseconds: 100));
    await run2;
    expect(slow.cubit.state.isGenerating, isFalse);
    expect(slow.cubit.state.results.map((r) => r.name), ['AI One', 'AI Two']);
  });

  group('F26_A58 fallback triggers', () {
    final cases = <String, FakeAiStylistClient Function()>{
      'null': () => FakeAiStylistClient(),
      'empty': () => FakeAiStylistClient(outfits: const []),
      'throws': () => FakeAiStylistClient(error: StateError('boom')),
      'foreign ids': () => FakeAiStylistClient(
        outfits: const [
          AiOutfit(name: 'X', why: 'y', itemIds: ['ghost-1', 'ghost-2']),
        ],
      ),
    };
    for (final entry in cases.entries) {
      testWidgets('F26_A58 ${entry.key}', (tester) async {
        final h = _Harness(fake: entry.value());
        addTearDown(h.close);
        final run = h.cubit.generateAutomatic();
        await tester.pump(StylistCubit.generationDelay);
        await run;
        expect(h.fake.requests, hasLength(1));
        expectF03Looks(h.cubit);
        expect(h.cubit.state.isGenerating, isFalse);
        expect(h.cubit.state.resultsByAi, isFalse);
        expect(h.analytics.sink.named('outfit_generated'), hasLength(1));
      });
    }

    testWidgets('F26_A58 never completing falls back at aiTimeout', (
      tester,
    ) async {
      final h = _Harness(fake: FakeAiStylistClient(neverCompletes: true));
      addTearDown(h.close);
      final run = h.cubit.generateAutomatic();
      await tester.pump(
        StylistCubit.aiTimeout - const Duration(milliseconds: 1),
      );
      expect(h.cubit.state.isGenerating, isTrue);
      expect(h.cubit.state.results, isEmpty);
      await tester.pump(const Duration(milliseconds: 1));
      await run;
      expectF03Looks(h.cubit);
      expect(h.analytics.sink.named('outfit_generated'), hasLength(1));
    });
  });

  testWidgets('F26_A59 client-side recheck', (tester) async {
    final h = _Harness(
      fake: FakeAiStylistClient(
        outfits: const [
          AiOutfit(
            name: 'Keep',
            why: 'w',
            itemIds: ['white-shirt', 'ghost', 'navy-chinos'],
          ),
          AiOutfit(name: 'Single', why: 'w', itemIds: ['white-shirt', 'ghost']),
        ],
      ),
    );
    addTearDown(h.close);
    var run = h.cubit.generateAutomatic();
    await tester.pump(StylistCubit.generationDelay);
    await run;
    expect(h.cubit.state.results.map((r) => r.name), ['Keep']);
    expect(_items(h.cubit), [
      ['white-shirt', 'navy-chinos'],
    ]);
    expect(h.cubit.state.results.single.source, StyleResultSource.ai);

    // Match mode: a look without the locked piece is dropped; with none
    // left, the algorithm results are used.
    final m = _Harness(
      fake: FakeAiStylistClient(
        outfits: const [
          AiOutfit(
            name: 'NoLock',
            why: 'w',
            itemIds: ['navy-chinos', 'blue-jeans'],
          ),
        ],
      ),
    );
    addTearDown(m.close);
    m.cubit
      ..toggleSelect('white-shirt')
      ..toggleSelect('navy-chinos')
      ..toggleSelect('blue-jeans')
      ..toggleLock('white-shirt');
    run = m.cubit.generateMatches();
    await tester.pump(StylistCubit.generationDelay);
    await run;
    expect(m.cubit.state.results.map((r) => r.name), isNot(contains('NoLock')));
    expect(m.cubit.state.results, isNotEmpty);
    expect(
      m.cubit.state.results.map((r) => r.source),
      everyElement(StyleResultSource.algorithm),
    );

    // Accessories off: an unselected owned id is dropped.
    final a = _Harness(
      fake: FakeAiStylistClient(
        outfits: const [
          AiOutfit(
            name: 'Extra',
            why: 'w',
            itemIds: ['white-shirt', 'navy-chinos', 'black-watch'],
          ),
          AiOutfit(
            name: 'Only selected',
            why: 'w',
            itemIds: ['white-shirt', 'navy-chinos'],
          ),
        ],
      ),
    );
    addTearDown(a.close);
    a.cubit
      ..setAccessories(false)
      ..toggleSelect('white-shirt')
      ..toggleSelect('navy-chinos')
      ..toggleLock('white-shirt');
    run = a.cubit.generateMatches();
    await tester.pump(StylistCubit.generationDelay);
    await run;
    expect(a.cubit.state.results.map((r) => r.name), ['Only selected']);
    expect(a.cubit.state.results.single.source, StyleResultSource.ai);

    // Accessories on: the extra owned id is an allowed completion.
    final c = _Harness(
      fake: FakeAiStylistClient(
        outfits: const [
          AiOutfit(
            name: 'Completed',
            why: 'w',
            itemIds: ['white-shirt', 'navy-chinos', 'black-watch'],
          ),
        ],
      ),
    );
    addTearDown(c.close);
    c.cubit
      ..toggleSelect('white-shirt')
      ..toggleSelect('navy-chinos')
      ..toggleLock('white-shirt');
    run = c.cubit.generateMatches();
    await tester.pump(StylistCubit.generationDelay);
    await run;
    expect(c.cubit.state.results.map((r) => r.name), ['Completed']);
  });

  group('F26_A60 no AI call', () {
    testWidgets('F26_A60 predicate false', (tester) async {
      final h = _Harness(available: () => false);
      addTearDown(h.close);
      final run = h.cubit.generateAutomatic();
      await tester.pump(StylistCubit.generationDelay);
      await run;
      expect(h.fake.requests, isEmpty);
      expectF03Looks(h.cubit);
    });

    testWidgets('F26_A60 guest (no client)', (tester) async {
      final h = _Harness(withClient: false);
      addTearDown(h.close);
      final run = h.cubit.generateAutomatic();
      await tester.pump(StylistCubit.generationDelay);
      await run;
      expect(h.fake.requests, isEmpty);
      expectF03Looks(h.cubit);
    });

    testWidgets('F26_A60 empty wardrobe', (tester) async {
      final h = _Harness();
      addTearDown(h.close);
      h.replaceWardrobe([]);
      final run = h.cubit.generateAutomatic();
      await tester.pump(StylistCubit.generationDelay);
      await run;
      expect(h.fake.requests, isEmpty);
      expect(h.cubit.state.results, hasLength(3));
      expect(_items(h.cubit), [<String>[], <String>[], <String>[]]);
    });

    testWidgets('F26_A60 match with no owned selected id', (tester) async {
      final h = _Harness();
      addTearDown(h.close);
      h.cubit.toggleSelect('ghost-item');
      final run = h.cubit.generateMatches();
      await tester.pump(StylistCubit.generationDelay);
      await run;
      expect(h.fake.requests, isEmpty);
      // createMatches' own output (shoes/accessories only, accessories on).
      expect(
        h.cubit.state.results.map((r) => r.source),
        everyElement(StyleResultSource.algorithm),
      );
    });

    testWidgets('F26_A60 match with a 61-character locked id', (tester) async {
      final h = _Harness();
      addTearDown(h.close);
      final longId = 'x' * 61;
      h.wardrobe.addItems([_item(longId)]);
      h.cubit
        ..toggleSelect(longId)
        ..toggleSelect('navy-chinos')
        ..toggleLock(longId);
      final run = h.cubit.generateMatches();
      await tester.pump(StylistCubit.generationDelay);
      await run;
      expect(h.fake.requests, isEmpty);
      expect(h.cubit.state.results, isNotEmpty);
      expect(
        h.cubit.state.results.map((r) => r.source),
        everyElement(StyleResultSource.algorithm),
      );
    });
  });

  testWidgets('F26_A61 match request and AI results keep the lock', (
    tester,
  ) async {
    final h = _Harness(
      fake: FakeAiStylistClient(
        outfits: const [
          AiOutfit(
            name: 'Locked Look',
            why: 'w',
            itemIds: ['white-shirt', 'navy-chinos'],
          ),
        ],
      ),
    );
    addTearDown(h.close);
    h.cubit
      ..setAccessories(false)
      ..toggleSelect('white-shirt')
      ..toggleSelect('navy-chinos')
      ..toggleSelect('ghost-item')
      ..toggleLock('white-shirt')
      ..toggleLock('black-skirt');
    final run = h.cubit.generateMatches();
    await tester.pump(StylistCubit.generationDelay);
    await run;
    final req = h.fake.requests.single;
    expect(req.mode, AiStylistMode.match);
    expect(req.selectedIds, ['white-shirt', 'navy-chinos']);
    expect(req.lockedIds, ['white-shirt']);
    expect(req.includeAccessories, isFalse);
    expect(h.cubit.state.isMatchMode, isTrue);
    expect(h.cubit.state.results.map((r) => r.name), ['Locked Look']);

    final before = h.cubit.state.results;
    // black-skirt is still in state.locked but was never selected.
    expect(
      h.cubit.swapItem('white-shirt', 'blue-shirt'),
      StylistCubit.lockedSwapMessage,
    );
    expect(h.cubit.state.results, before);
  });

  testWidgets('F26_A62 swap flips only the swapped result to algorithm', (
    tester,
  ) async {
    final h = _Harness(
      fake: FakeAiStylistClient(
        outfits: const [
          AiOutfit(
            name: 'One',
            why: 'w1',
            itemIds: ['white-shirt', 'navy-chinos'],
          ),
          AiOutfit(
            name: 'Two',
            why: 'w2',
            itemIds: ['black-shirt', 'navy-chinos'],
          ),
        ],
      ),
    );
    addTearDown(h.close);
    final run = h.cubit.generateAutomatic();
    await tester.pump(StylistCubit.generationDelay);
    await run;
    expect(h.cubit.state.resultsByAi, isTrue);
    h.cubit.setActiveIndex(0);
    expect(h.cubit.swapItem('navy-chinos', 'beige-chinos'), isNotNull);
    final r = h.cubit.state.results;
    expect(r[0].source, StyleResultSource.algorithm);
    expect(r[0].items, ['white-shirt', 'beige-chinos']);
    expect(r[0].name, 'One');
    expect(
      r[0].why,
      'This preview pairs Beige Chinos with the other selected wardrobe pieces. Review the complete styling before wearing.',
    );
    expect(r[1].source, StyleResultSource.ai);
    expect(h.cubit.state.resultsByAi, isFalse);
  });

  testWidgets('F26_A63 the 120-item cap order', (tester) async {
    final h = _Harness(fake: FakeAiStylistClient());
    addTearDown(h.close);
    String id(int n) => 'item-${n.toString().padLeft(3, '0')}';
    h.replaceWardrobe([
      for (var n = 0; n < 150; n++)
        _item(id(n), occasion: n.isEven ? 'Office' : 'Everyday'),
    ]);
    h.cubit
      ..setOccasion('Office')
      ..toggleSelect(id(149))
      ..toggleSelect(id(148))
      ..toggleSelect(id(1))
      ..toggleLock(id(149));
    final run = h.cubit.generateMatches();
    await tester.pump(StylistCubit.generationDelay);
    await run;
    final ids = h.fake.requests.single.items.map((i) => i.id).toList();
    final expected = [
      id(149),
      id(1),
      id(148),
      for (var n = 0; n < 148; n += 2) id(n),
      for (var n = 3; n < 150; n += 2) id(n),
    ].take(120).toList();
    expect(ids, hasLength(120));
    expect(ids, expected);
    expect(ids.sublist(0, 3), [id(149), id(1), id(148)]);
    expect(ids[3], id(0));
    expect(ids[76], id(146));
    expect(ids[77], id(3));
    expect(h.fake.requests.single.selectedIds, [id(149), id(148), id(1)]);

    // Auto: a 120-item wardrobe sends all 120; a 61-char id is never sent.
    final a = _Harness(fake: FakeAiStylistClient());
    addTearDown(a.close);
    a.replaceWardrobe([
      for (var n = 0; n < 120; n++) _item(id(n)),
      _item('y' * 61),
    ]);
    final run2 = a.cubit.generateAutomatic();
    await tester.pump(StylistCubit.generationDelay);
    await run2;
    final sent = a.fake.requests.single.items.map((i) => i.id).toList();
    expect(sent, [for (var n = 0; n < 120; n++) id(n)]);
  });

  testWidgets('F26_A64 in-flight and closed handling', (tester) async {
    final h = _Harness(
      fake: FakeAiStylistClient(outfits: _two, delay: _s3),
    );
    final first = h.cubit.generateAutomatic();
    final second = h.cubit.generateAutomatic();
    await tester.pump(const Duration(milliseconds: 1200));
    expect(h.fake.requests, hasLength(1));
    expect(h.cubit.state.isGenerating, isTrue);
    await tester.pump(const Duration(milliseconds: 1900));
    await first;
    await second;
    expect(h.cubit.state.results, hasLength(2));
    await h.close();

    final c = _Harness(
      fake: FakeAiStylistClient(outfits: _two, delay: _s3),
    );
    final run = c.cubit.generateAutomatic();
    await tester.pump(const Duration(milliseconds: 500));
    await c.close();
    await tester.pump(_s3);
    await run;
    expect(c.analytics.sink.named('outfit_generated'), isEmpty);
    expect(tester.takeException(), isNull);
  });
}
