import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'ai_stylist_client.dart';

/// Calls the Supabase Edge Function over HTTP with the user's Firebase ID
/// token (F26). Every failure maps to `null`; this class never throws and
/// the app never shows an AI error. Its constructor touches neither
/// `FirebaseAuth.instance` nor the network.
class HttpAiStylistClient implements AiStylistClient {
  HttpAiStylistClient({
    this._client,
    Uri? functionUrl,
    Future<String?> Function()? getIdToken,
    Duration? timeout,
  }) : _functionUrl = functionUrl ?? defaultUrl,
       _getIdToken = getIdToken ?? _defaultGetIdToken,
       _timeout = timeout ?? defaultTimeout;

  static const defaultTimeout = Duration(seconds: 15);

  static final defaultUrl = Uri.parse(
    'https://dbaeaqyoyilxcuwplvuw.supabase.co/functions/v1/ai-stylist',
  );

  final http.Client? _client;
  final Uri _functionUrl;
  final Future<String?> Function() _getIdToken;
  final Duration _timeout;

  static Future<String?> _defaultGetIdToken() async {
    try {
      return await FirebaseAuth.instance.currentUser?.getIdToken();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<AiOutfit>?> suggest(AiStylistRequest request) async {
    final client = _client ?? http.Client();
    try {
      return await _call(client, request).timeout(_timeout);
    } catch (_) {
      return null;
    } finally {
      if (_client == null) client.close();
    }
  }

  Future<List<AiOutfit>?> _call(
    http.Client client,
    AiStylistRequest request,
  ) async {
    final token = await _getIdToken();
    if (token == null || token.isEmpty) return null;
    final response = await client.post(
      _functionUrl,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(request.toJson()),
    );
    if (response.statusCode != 200) return null;
    return _parse(response.bodyBytes);
  }

  static List<AiOutfit>? _parse(List<int> bytes) {
    final Object? json = jsonDecode(utf8.decode(bytes));
    if (json is! Map<String, dynamic>) return null;
    final outfits = json['outfits'];
    if (outfits is! List || outfits.isEmpty) return null;
    final parsed = <AiOutfit>[];
    for (final o in outfits) {
      if (o is! Map<String, dynamic>) return null;
      final name = o['name'];
      final why = o['why'];
      final ids = o['itemIds'];
      if (name is! String || why is! String || ids is! List) return null;
      if (ids.any((id) => id is! String)) return null;
      parsed.add(
        AiOutfit(name: name, why: why, itemIds: List<String>.from(ids)),
      );
    }
    return parsed;
  }
}
