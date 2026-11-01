import 'dart:async';

import 'package:stylobuddy/shared/backend/ai_stylist_client.dart';

/// Scripted [AiStylistClient] for tests. Records every request.
class FakeAiStylistClient implements AiStylistClient {
  FakeAiStylistClient({
    this.outfits,
    this.error,
    this.delay = Duration.zero,
    this.neverCompletes = false,
    this.respond,
  });

  /// Returned on success; null means "unavailable".
  List<AiOutfit>? outfits;

  /// Thrown instead of answering (a misbehaving client).
  Object? error;

  /// Time before answering.
  Duration delay;

  /// The call never completes.
  bool neverCompletes;

  /// Builds the answer from the request (overrides [outfits]).
  List<AiOutfit>? Function(AiStylistRequest request)? respond;

  final requests = <AiStylistRequest>[];

  @override
  Future<List<AiOutfit>?> suggest(AiStylistRequest request) async {
    requests.add(request);
    if (neverCompletes) return Completer<List<AiOutfit>?>().future;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    final e = error;
    if (e != null) throw e;
    return respond != null ? respond!(request) : outfits;
  }
}
