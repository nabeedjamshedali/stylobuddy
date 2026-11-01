/// Thin wrapper around the Firestore emulator's REST API (F22 doc §5 "Test
/// harness", §13 Q5 ruling: Dart + `package:http`, no Node/JS toolchain).
///
/// Every test in `test/firestore_rules_test/` goes through [RulesTestClient]
/// rather than `package:cloud_firestore`, because the emulator's security
/// rules evaluation is only reachable over its own REST/gRPC surface with an
/// identity header the production SDK has no supported way to fabricate
/// (F22_A02's "owner"/other-uid/signed-out identities).
library;

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'firestore_values.dart';

/// `demo-` prefix is load-bearing (F22_A01): the emulator refuses to talk to
/// any real Firebase backend for a project id with that prefix, so this
/// suite cannot reach the production project even by accident (its id is
/// deliberately not spelled out anywhere under test/firestore_rules_test/,
/// per F22_A01's own self-check).
const String kProjectId = 'demo-stylobuddy';

/// Resolves `FIRESTORE_EMULATOR_HOST`, throwing synchronously (never
/// returning a sentinel/skip) when it is unset, so a suite run without the
/// emulator fails loudly and names the problem (F22_A01).
String emulatorHostOrThrow([Map<String, String>? env]) {
  final host = (env ?? Platform.environment)['FIRESTORE_EMULATOR_HOST'];
  if (host == null || host.isEmpty) {
    throw StateError(
      'Firestore emulator not reachable: FIRESTORE_EMULATOR_HOST is unset. '
      'Run via `./scripts/run_firestore_rules_suite.sh` (project '
      '$kProjectId, JAVA_HOME/PATH scoped to the JDK 21 install — see '
      'task-9-brief.md).',
    );
  }
  return host;
}

/// Builds an unsigned mock Firebase ID token the Firestore emulator accepts
/// for `request.auth` (F22 doc §5: "unsigned mock ID token (emulator-
/// accepted) with sub=user_id=`<uid>`"). The emulator does not verify the
/// signature, so the trailing signature segment is intentionally empty.
String mockIdToken(String uid) {
  final header = _b64url(utf8.encode(jsonEncode({'alg': 'none', 'typ': 'JWT'})));
  final payload = _b64url(
    utf8.encode(
      jsonEncode({
        'sub': uid,
        'user_id': uid,
        'iss': 'https://securetoken.google.com/$kProjectId',
        'aud': kProjectId,
        'auth_time': 0,
        'iat': 0,
        'exp': 9999999999,
        'firebase': {'identities': <String, dynamic>{}, 'sign_in_provider': 'custom'},
      }),
    ),
  );
  return '$header.$payload.';
}

String _b64url(List<int> bytes) =>
    base64Url.encode(bytes).replaceAll('=', '');

/// Bypasses every rule (Admin SDK equivalent, F22 doc §4) — used only to
/// seed/verify fixtures, never to exercise the rule under test itself.
const String ownerToken = 'owner';

/// Result of one REST call, carrying just enough to assert allow/deny
/// (F22_A02: a denial must be specifically PERMISSION_DENIED, never "any
/// error").
class RulesResult {
  RulesResult(this.statusCode, this.body);

  final int statusCode;
  final Map<String, dynamic> body;

  bool get ok => statusCode >= 200 && statusCode < 300;

  /// The gRPC status string (`PERMISSION_DENIED`, `NOT_FOUND`,
  /// `FAILED_PRECONDITION`, `INVALID_ARGUMENT`, ...), or `null` on success.
  String? get errorStatus => (body['error'] as Map?)?['status'] as String?;

  bool get isPermissionDenied => statusCode == 403 && errorStatus == 'PERMISSION_DENIED';
  bool get isNotFound => statusCode == 404 && errorStatus == 'NOT_FOUND';

  /// Decoded field map of a single-document response (get, or one entry of
  /// a commit's... not applicable to list responses).
  Map<String, Object?> get fields => decodeFields(body);

  /// Decoded documents of a list response.
  List<Map<String, Object?>> get documents => ((body['documents'] as List?) ?? const [])
      .map((d) => decodeFields(d as Map<String, dynamic>))
      .toList();
}

class RulesTestClient {
  RulesTestClient() : host = emulatorHostOrThrow();

  final String host;
  final http.Client _http = http.Client();

  String get _docsRoot => 'http://$host/v1/projects/$kProjectId/databases/(default)/documents';

  String _fullName(String path) =>
      'projects/$kProjectId/databases/(default)/documents/$path';

  Map<String, String> _headers(String? token) => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  Future<RulesResult> get(String path, {String? token}) async {
    final response = await _http.get(
      Uri.parse('$_docsRoot/$path'),
      headers: _headers(token),
    );
    return _result(response);
  }

  Future<RulesResult> list(String collectionPath, {String? token}) async {
    final response = await _http.get(
      Uri.parse('$_docsRoot/$collectionPath'),
      headers: _headers(token),
    );
    return _result(response);
  }

  /// Issues a Firestore `RunQuery` on [collectionPath] constrained to the
  /// single document at [docPath] via a `__name__` equality filter
  /// (F22_A05's get-vs-list distinguishing case): even though the query can
  /// only ever match one document the caller already owns, it is still
  /// evaluated by the rules engine as a `list`/`runQuery` operation, never
  /// as `get` — so it must be denied under `allow get` even when the
  /// unconstrained [list] case would be denied for an unrelated reason.
  Future<RulesResult> runQueryByName(
    String collectionPath,
    String docPath, {
    String? token,
  }) async {
    final lastSlash = collectionPath.lastIndexOf('/');
    final parent = lastSlash == -1 ? _docsRoot : '$_docsRoot/${collectionPath.substring(0, lastSlash)}';
    final collectionId = lastSlash == -1 ? collectionPath : collectionPath.substring(lastSlash + 1);
    final response = await _http.post(
      Uri.parse('$parent:runQuery'),
      headers: _headers(token),
      body: jsonEncode({
        'structuredQuery': {
          'from': [
            {'collectionId': collectionId},
          ],
          'where': {
            'fieldFilter': {
              'field': {'fieldPath': '__name__'},
              'op': 'EQUAL',
              'value': {'referenceValue': _fullName(docPath)},
            },
          },
        },
      }),
    );
    return _resultFromRunQuery(response);
  }

  RulesResult _resultFromRunQuery(http.Response response) {
    if (response.body.isEmpty) return RulesResult(response.statusCode, <String, dynamic>{});
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) return RulesResult(response.statusCode, decoded);
    // A successful runQuery response is a JSON array of
    // `{document, readTime}` entries (possibly empty), not an object.
    return RulesResult(response.statusCode, <String, dynamic>{'runQueryResults': decoded});
  }

  /// Issues one or more writes atomically (Firestore `Commit`), mirroring
  /// what `firebase emulators:exec`-backed assertions need for both single
  /// writes and multi-document "transactions" (F22_A31/A47): the Firestore
  /// REST `:commit` endpoint applies every listed write all-or-nothing and
  /// evaluates rules per write, which is exactly what A47's "0 of 27 docs on
  /// denial" assertion needs.
  Future<RulesResult> commit(List<Map<String, dynamic>> writes, {String? token}) async {
    final response = await _http.post(
      Uri.parse('$_docsRoot:commit'),
      headers: _headers(token),
      body: jsonEncode({'writes': writes}),
    );
    return _result(response);
  }

  Future<void> clearData() async {
    final response = await _http.delete(
      Uri.parse('http://$host/emulator/v1/projects/$kProjectId/databases/(default)/documents'),
    );
    if (response.statusCode != 200) {
      throw StateError('Failed to clear emulator data: ${response.statusCode} ${response.body}');
    }
  }

  RulesResult _result(http.Response response) {
    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;
    return RulesResult(response.statusCode, decoded);
  }

  // ---- write builders (Firestore REST `Write` message shapes) ----

  /// A full-document overwrite (`.set(value)`, no merge options) —
  /// `request.resource.data` is exactly [fields].
  Map<String, dynamic> fullSet(String path, Map<String, Object?> fields) => {
    'update': {'name': _fullName(path), 'fields': encodeFields(fields)},
  };

  /// A merge-set (`.set(value, SetOptions(merge: true))`) — only the listed
  /// keys are touched; `request.resource.data` in rules is the FULL
  /// resulting document (existing fields + these), per Firestore's own
  /// merge semantics (F22 doc §5 point 2/A48).
  Map<String, dynamic> mergeSet(String path, Map<String, Object?> fields) => {
    'update': {'name': _fullName(path), 'fields': encodeFields(fields)},
    'updateMask': {'fieldPaths': fields.keys.toList()},
  };

  /// `.update(fields)` — like [mergeSet], but requires the document to
  /// already exist (Firestore `not-found` otherwise), matching
  /// `OutfitsRepository.upsertManual`'s edit branch (F22_A24).
  Map<String, dynamic> updateExisting(String path, Map<String, Object?> fields) => {
    'update': {'name': _fullName(path), 'fields': encodeFields(fields)},
    'updateMask': {'fieldPaths': fields.keys.toList()},
    'currentDocument': {'exists': true},
  };

  Map<String, dynamic> deleteDoc(String path) => {
    'delete': _fullName(path),
  };

  /// `FieldValue.arrayUnion`/`arrayRemove` field transforms
  /// (`FirestoreShoppingRepository.setMembership`, F22_A11).
  Map<String, dynamic> arrayTransform(
    String path,
    String field, {
    List<Object?> union = const [],
    List<Object?> remove = const [],
  }) => {
    'transform': {
      'document': _fullName(path),
      'fieldTransforms': [
        if (union.isNotEmpty)
          {
            'fieldPath': field,
            'appendMissingElements': {'values': union.map(encodeValue).toList()},
          },
        if (remove.isNotEmpty)
          {
            'fieldPath': field,
            'removeAllFromArray': {'values': remove.map(encodeValue).toList()},
          },
      ],
    },
  };
}
