import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stylobuddy/shared/backend/ai_stylist_client.dart';
import 'package:stylobuddy/shared/backend/http_ai_stylist_client.dart';
import 'package:stylobuddy/shared/models/clothing_item.dart';

AiStylistRequest _request({List<ClothingItem>? items}) => AiStylistRequest(
  mode: AiStylistMode.match,
  occasion: 'Office',
  styleDirection: 'Smart casual',
  weather: 'Mild / all season',
  includeAccessories: true,
  lockedIds: const ['a'],
  selectedIds: const ['a', 'b'],
  items:
      items ??
      const [
        ClothingItem(
          id: 'a',
          name: 'A',
          category: 'Shirts',
          color: 'White',
          occasion: 'Office',
        ),
        ClothingItem(
          id: 'b',
          name: 'B',
          category: 'Pants',
          color: 'Navy',
          occasion: 'Office',
        ),
      ],
);

const _okBody =
    '{"outfits":[{"name":"A","why":"B","itemIds":["x","y"]}]}';

MockClient _responding(String body, {int status = 200}) => MockClient(
  (_) async => http.Response(body, status),
);

void main() {
  test('F26_A51 toJson has exactly the contract keys and truncates', () {
    final json = _request(
      items: [
        ClothingItem(
          id: 'a',
          name: 'n' * 80,
          category: 'Shirts',
          color: 'White',
          occasion: 'Office',
          wears: 4,
          sourceId: 'src-marker',
          imageUrl: 'url-marker',
        ),
        ClothingItem(
          id: 'b',
          name: '\u{1F457}' * 31,
          category: 'Shirts',
          color: 'White',
          occasion: 'Office',
        ),
      ],
    ).toJson();
    expect(json.keys.toSet(), {
      'occasion',
      'styleDirection',
      'weather',
      'includeAccessories',
      'mode',
      'lockedIds',
      'selectedIds',
      'items',
    });
    expect(json['mode'], 'match');
    final items = json['items']! as List;
    for (final i in items) {
      expect((i as Map).keys.toSet(), {
        'id',
        'name',
        'category',
        'color',
        'occasion',
        'season',
      });
    }
    final text = jsonEncode(json);
    expect(text, isNot(contains('src-marker')));
    expect(text, isNot(contains('url-marker')));
    expect(text, isNot(contains('wears')));
    expect((items[0] as Map)['name'], 'n' * 60);
    expect((items[1] as Map)['name'], '\u{1F457}' * 30);
    expect(truncateUtf16('abc', 60), 'abc');
    expect(
      _request().copyAuto().toJson()['mode'],
      'auto',
    );
  });

  testWidgets('F26_A52 posts the contract and parses outfits', (tester) async {
    late http.Request seen;
    var calls = 0;
    final client = HttpAiStylistClient(
      client: MockClient((request) async {
        calls++;
        seen = request;
        return http.Response(_okBody, 200);
      }),
      getIdToken: () async => 'tok',
    );
    final req = _request();
    final result = await client.suggest(req);
    expect(calls, 1);
    expect(seen.method, 'POST');
    expect(
      seen.url.toString(),
      'https://dbaeaqyoyilxcuwplvuw.supabase.co/functions/v1/ai-stylist',
    );
    expect(seen.headers['Authorization'], 'Bearer tok');
    expect(seen.headers['Content-Type'], startsWith('application/json'));
    expect(seen.body, jsonEncode(req.toJson()));
    expect(result, [
      const AiOutfit(name: 'A', why: 'B', itemIds: ['x', 'y']),
    ]);
  });

  group('F26_A53 every failure is null', () {
    Future<void> expectNull(
      WidgetTester tester,
      HttpAiStylistClient client,
    ) async {
      expect(await client.suggest(_request()), isNull);
    }

    testWidgets('F26_A53 no token sends nothing', (tester) async {
      for (final token in <String?>[null, '']) {
        var calls = 0;
        final client = HttpAiStylistClient(
          client: MockClient((_) async {
            calls++;
            return http.Response(_okBody, 200);
          }),
          getIdToken: () async => token,
        );
        await expectNull(tester, client);
        expect(calls, 0);
      }
    });

    testWidgets('F26_A53 token throws', (tester) async {
      await expectNull(
        tester,
        HttpAiStylistClient(
          client: _responding(_okBody),
          getIdToken: () async => throw StateError('no user'),
        ),
      );
    });

    testWidgets('F26_A53 token never completes', (tester) async {
      final client = HttpAiStylistClient(
        client: _responding(_okBody),
        getIdToken: () => Completer<String?>().future,
        timeout: const Duration(milliseconds: 50),
      );
      final future = client.suggest(_request());
      await tester.pump(const Duration(milliseconds: 60));
      expect(await future, isNull);
    });

    testWidgets('F26_A53 bad statuses', (tester) async {
      for (final status in [400, 401, 429, 500, 501, 502]) {
        await expectNull(
          tester,
          HttpAiStylistClient(
            client: _responding(_okBody, status: status),
            getIdToken: () async => 'tok',
          ),
        );
      }
    });

    testWidgets('F26_A53 malformed 200 bodies', (tester) async {
      for (final body in [
        'not json',
        '{}',
        '{"outfits":[]}',
        '{"outfits":"x"}',
        '{"outfits":[{"why":"B","itemIds":["x","y"]}]}',
        '{"outfits":[{"name":"A","why":"B","itemIds":["x",1]}]}',
        '[]',
        // one bad entry spoils the whole response
        '{"outfits":[{"name":"A","why":"B","itemIds":["x","y"]},{"name":"C"}]}',
      ]) {
        await expectNull(
          tester,
          HttpAiStylistClient(
            client: _responding(body),
            getIdToken: () async => 'tok',
          ),
        );
      }
    });

    testWidgets('F26_A53 transport failures', (tester) async {
      await expectNull(
        tester,
        HttpAiStylistClient(
          client: MockClient((_) async => throw const SocketException('down')),
          getIdToken: () async => 'tok',
        ),
      );
      final hanging = HttpAiStylistClient(
        client: MockClient((_) => Completer<http.Response>().future),
        getIdToken: () async => 'tok',
        timeout: const Duration(milliseconds: 50),
      );
      final future = hanging.suggest(_request());
      await tester.pump(const Duration(milliseconds: 60));
      expect(await future, isNull);
    });
  });

  test('F26_A54 default timeout and a bare constructor', () {
    expect(HttpAiStylistClient.defaultTimeout, const Duration(seconds: 15));
    expect(HttpAiStylistClient.new, returnsNormally);
    expect(HttpAiStylistClient.defaultUrl.path, '/functions/v1/ai-stylist');
  });
}

extension on AiStylistRequest {
  AiStylistRequest copyAuto() => AiStylistRequest(
    mode: AiStylistMode.auto,
    occasion: occasion,
    styleDirection: styleDirection,
    weather: weather,
    includeAccessories: includeAccessories,
    lockedIds: const [],
    selectedIds: const [],
    items: items,
  );
}
