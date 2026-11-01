import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:stylobuddy/shared/backend/storage_repository.dart';

class _FakeClient extends http.BaseClient {
  _FakeClient(this.handler);

  final Future<http.Response> Function(http.BaseRequest request) handler;
  final List<http.BaseRequest> requests = [];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add(request);
    final response = await handler(request);
    return http.StreamedResponse(
      Stream.value(utf8.encode(response.body)),
      response.statusCode,
      headers: response.headers,
    );
  }
}

XFile _file() => XFile.fromData(
  Uint8List.fromList([1, 2, 3]),
  name: 'photo.jpg',
  mimeType: 'image/jpeg',
);

void main() {
  test(
    'F15_regression uploadWardrobePhoto never makes a network call when no Firebase ID token is available',
    () async {
      var called = false;
      final client = _FakeClient((request) async {
        called = true;
        return http.Response('{}', 200);
      });
      final repo = StorageRepository(
        client: client,
        getIdToken: () async => null,
      );

      await expectLater(
        repo.uploadWardrobePhoto(itemId: 'item-1', file: _file()),
        throwsA(anything),
      );

      expect(called, isFalse);
    },
  );

  test(
    'F15_happy uploadWardrobePhoto signs then PUTs then returns a public URL containing uid/itemId.jpg',
    () async {
      final client = _FakeClient((request) async {
        if (request.method == 'POST') {
          return http.Response(
            jsonEncode({
              'uploadUrl': 'https://signed.example/uid-1/item-1.jpg?token=x',
              'path': 'uid-1/item-1.jpg',
            }),
            200,
          );
        }
        return http.Response('', 200);
      });
      final repo = StorageRepository(
        client: client,
        getIdToken: () async => 'fake-id-token',
      );

      final url = await repo.uploadWardrobePhoto(
        itemId: 'item-1',
        file: _file(),
      );

      expect(url, contains('uid-1/item-1.jpg'));
      expect(client.requests.length, 2);
      expect(client.requests[0].method, 'POST');
      expect(client.requests[1].method, 'PUT');
      expect(
        client.requests[0].headers['Authorization'],
        'Bearer fake-id-token',
      );
    },
  );

  test(
    'F15_edge uploadWardrobePhoto throws when the sign step returns a non-200',
    () async {
      final client = _FakeClient(
        (request) async => http.Response('nope', 401),
      );
      final repo = StorageRepository(
        client: client,
        getIdToken: () async => 'fake-id-token',
      );

      await expectLater(
        repo.uploadWardrobePhoto(itemId: 'item-1', file: _file()),
        throwsA(anything),
      );
    },
  );

  test(
    'F15_important3 uploadWardrobePhoto fails gracefully within a bounded time instead of hanging when the sign request never completes',
    () async {
      final neverCompletes = Completer<http.Response>();
      final client = _FakeClient((request) => neverCompletes.future);
      final repo = StorageRepository(
        client: client,
        getIdToken: () async => 'fake-id-token',
        // A short override so this test proves "bounded, not hanging"
        // without waiting out the real 30-second production timeout.
        networkTimeout: const Duration(milliseconds: 200),
      );

      await expectLater(
        repo.uploadWardrobePhoto(itemId: 'item-1', file: _file()),
        throwsA(anything),
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () => fail(
          'uploadWardrobePhoto hung instead of resolving (failing) within '
          'a bounded time',
        ),
      );
    },
  );

  test(
    'F15_edge uploadWardrobePhoto throws when the PUT step fails',
    () async {
      final client = _FakeClient((request) async {
        if (request.method == 'POST') {
          return http.Response(
            jsonEncode({
              'uploadUrl': 'https://signed.example/uid-1/item-1.jpg?token=x',
              'path': 'uid-1/item-1.jpg',
            }),
            200,
          );
        }
        return http.Response('expired', 403);
      });
      final repo = StorageRepository(
        client: client,
        getIdToken: () async => 'fake-id-token',
      );

      await expectLater(
        repo.uploadWardrobePhoto(itemId: 'item-1', file: _file()),
        throwsA(anything),
      );
    },
  );
}
