import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

/// Calls the `storage-upload-url` Edge Function for a signed Supabase
/// Storage URL, then `PUT`s the file bytes to it directly (storage doc §1,
/// §2). Not wardrobe-specific logic even though wardrobe is its only
/// caller today — lives under `shared/backend` per the storage spec.
class StorageRepository {
  StorageRepository({
    http.Client? client,
    Uri? functionUrl,
    Future<String?> Function()? getIdToken,
  }) : _client = client ?? http.Client(),
       _functionUrl =
           functionUrl ??
           Uri.parse(
             'https://dbaeaqyoyilxcuwplvuw.supabase.co/functions/v1/storage-upload-url',
           ),
       _getIdToken = getIdToken ?? _defaultGetIdToken;

  final http.Client _client;
  final Uri _functionUrl;
  final Future<String?> Function() _getIdToken;

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

    final signResponse = await _client.post(
      _functionUrl,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'itemId': itemId}),
    );
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
    final putResponse = await _client.put(
      Uri.parse(uploadUrl),
      headers: const {'Content-Type': 'image/jpeg'},
      body: bytes,
    );
    if (putResponse.statusCode != 200 && putResponse.statusCode != 201) {
      throw Exception('upload PUT failed with ${putResponse.statusCode}');
    }

    return _publicUrlFor(itemId: itemId, body: body);
  }

  // KNOWN GAP (discovered during this task's live verification, flagged
  // rather than silently worked around — see F15 §13's existing "not
  // displayed this task" note, now with a concrete reason): `user-photos`
  // is a *private* bucket (storage doc §1), so this constructed
  // `.../object/public/...` URL 404s/400s if actually fetched today.
  // Persisting it is harmless for this task (nothing reads `imageUrl` back
  // into a widget yet — GarmentImage doesn't render it, F15 §13), but
  // whichever future task wires `GarmentImage` to `imageUrl` must replace
  // this with a real signed *read* URL (or make the bucket public) before
  // that value is ever handed to an `Image.network`-style widget.
  String _publicUrlFor({
    required String itemId,
    required Map<String, dynamic> body,
  }) {
    final path = body['path'] as String?;
    if (path == null || path.isEmpty) {
      throw Exception('storage-upload-url response missing path');
    }
    return 'https://dbaeaqyoyilxcuwplvuw.supabase.co/storage/v1/object/public/user-photos/$path';
  }
}
