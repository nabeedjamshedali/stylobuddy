import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

/// Upper bound for each network call this repository makes — A12 requires
/// an upload failure to never delay the batch save indefinitely; without
/// this, a hung signed-URL request or a hung PUT (e.g. a dead connection
/// that never errors and never completes) would block `ImportCubit.
/// confirmCurrent`'s `await` forever instead of landing in the existing
/// `catch` path with `imageUrl: null`.
const _defaultNetworkTimeout = Duration(seconds: 30);

/// This project's Supabase base URL, used both for the default Edge
/// Function endpoint and (previously) for constructing a public-object
/// URL — de-duplicated to one constant rather than two separate literals
/// drifting apart if the project ref ever changes.
const _supabaseBaseUrl = 'https://dbaeaqyoyilxcuwplvuw.supabase.co';

/// Calls the `storage-upload-url` Edge Function for a signed Supabase
/// Storage URL, then `PUT`s the file bytes to it directly (storage doc §1,
/// §2). Not wardrobe-specific logic even though wardrobe is its only
/// caller today — lives under `shared/backend` per the storage spec.
class StorageRepository {
  StorageRepository({
    http.Client? client,
    Uri? functionUrl,
    Future<String?> Function()? getIdToken,
    Duration? networkTimeout,
  }) : _client = client ?? http.Client(),
       _functionUrl =
           functionUrl ??
           Uri.parse('$_supabaseBaseUrl/functions/v1/storage-upload-url'),
       _getIdToken = getIdToken ?? _defaultGetIdToken,
       _networkTimeout = networkTimeout ?? _defaultNetworkTimeout;

  final http.Client _client;
  final Uri _functionUrl;
  final Future<String?> Function() _getIdToken;

  /// Test-only override seam; production always uses
  /// [_defaultNetworkTimeout]. A test that needs to prove "hangs are
  /// bounded" without actually waiting 30 real seconds injects a much
  /// shorter value here.
  final Duration _networkTimeout;

  static Future<String?> _defaultGetIdToken() async {
    try {
      return await FirebaseAuth.instance.currentUser?.getIdToken();
    } catch (_) {
      // Mirrors shared/backend/auth_session.dart's guard: no signed-in
      // Firebase user (or Firebase not initialized) means no token, never
      // a thrown exception out of this helper.
      return null;
    }
  }

  /// Uploads [file] for wardrobe item [itemId] and returns the resulting
  /// URL. Throws on any failure (missing token, non-200 from the Edge
  /// Function, a failed `PUT`) — callers (ImportCubit) treat that as an
  /// upload failure and save with `imageUrl: null` rather than letting it
  /// propagate (F15 §10). Never makes a network call at all when no
  /// Firebase ID token is available (guest/signed-out), matching the
  /// "guest mode makes zero network calls" guarantee structurally rather
  /// than via a caught failure.
  Future<String> uploadWardrobePhoto({
    required String itemId,
    required XFile file,
  }) async {
    final token = await _getIdToken();
    if (token == null || token.isEmpty) {
      throw StateError('No Firebase ID token available for upload');
    }

    final signResponse = await _client
        .post(
          _functionUrl,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'itemId': itemId}),
        )
        .timeout(_networkTimeout);
    if (signResponse.statusCode != 200) {
      throw Exception(
        'storage-upload-url returned ${signResponse.statusCode}',
      );
    }
    final body = jsonDecode(signResponse.body) as Map<String, dynamic>;
    final uploadUrl = body['uploadUrl'] as String?;
    if (uploadUrl == null || uploadUrl.isEmpty) {
      throw Exception('storage-upload-url response missing uploadUrl');
    }

    final bytes = await file.readAsBytes();
    final putResponse = await _client
        .put(
          Uri.parse(uploadUrl),
          headers: const {'Content-Type': 'image/jpeg'},
          body: bytes,
        )
        .timeout(_networkTimeout);
    if (putResponse.statusCode != 200 && putResponse.statusCode != 201) {
      throw Exception('upload PUT failed with ${putResponse.statusCode}');
    }

    return _resolveImageUrl(body: body);
  }

  // KNOWN GAP, revised after the review round: a constructed
  // `.../object/public/...` URL is a dead link for this task's `user-photos`
  // bucket (storage doc §1: it's private), so persisting that broken shape
  // would need a data backfill the moment a future task wires `GarmentImage`
  // up to read `imageUrl` back. Persisting the raw storage `path` instead
  // (e.g. `uid-1/item-1.jpg`) avoids that: it is not itself a fetchable URL
  // either, but it is the exact input a future signed-*read*-URL call needs,
  // so that future task can turn it into a real URL in place rather than
  // re-deriving it from a stored dead link or re-running a backfill over
  // every existing document.
  String _resolveImageUrl({required Map<String, dynamic> body}) {
    final path = body['path'] as String?;
    if (path == null || path.isEmpty) {
      throw Exception('storage-upload-url response missing path');
    }
    return path;
  }
}
