import 'dart:math' as math;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/backend/ai_stylist_client.dart';
import '../../../shared/backend/analytics_service.dart';
import '../../../shared/models/clothing_item.dart';
import '../../wardrobe/cubit/wardrobe_cubit.dart';
import '../models/style_result.dart';
import 'stylist_state.dart';

/// Shared results engine (F03, reused by F04 Match My Clothes).
class StylistCubit extends Cubit<StylistState> {
  StylistCubit(
    this._wardrobe, {
    int Function()? clock,
    AnalyticsService? analytics,
    this._aiClient,
    this._aiAvailable,
  }) : _clock = clock ?? (() => DateTime.now().millisecondsSinceEpoch),
       _analytics = analytics ?? const AnalyticsService.noop(),
       super(const StylistState());

  final WardrobeCubit _wardrobe;
  final int Function() _clock;
  final AnalyticsService _analytics;
  final AiStylistClient? _aiClient;
  final bool Function()? _aiAvailable;

  static const generationDelay = Duration(milliseconds: 1150);

  /// Ceiling for the AI call (F26); the HTTP client's own 15 s timeout
  /// normally fires first.
  static const aiTimeout = Duration(seconds: 16);

  /// Most wardrobe items sent to the AI (F26 section 6.4).
  static const _maxAiItems = 120;
  static const swappedMessage = 'Garment replaced';
  static const lockedSwapMessage = 'Mandatory items cannot be swapped';

  static const _templates = [
    ['white-shirt', 'navy-chinos', 'white-sneakers', 'black-watch'],
    ['black-shirt', 'beige-chinos', 'brown-loafers', 'tan-belt'],
    ['blue-shirt', 'black-jeans', 'black-boots', 'sunglasses'],
  ];
  static const _why = [
    'Considered proportions and a cohesive level of formality make these pieces feel intentional.',
    'The contrast and garment textures work together for a balanced, refined look.',
    'A relaxed combination with complementary shapes, tones and accessories.',
  ];
  static const _automaticNames = [
    'Refined Everyday',
    'Modern Classic',
    'Effortless Edge',
  ];
  static const _matchNames = [
    'Best Match',
    'Polished Alternative',
    'Fresh Combination',
  ];

  void setOccasion(String occasion) => emit(state.copyWith(occasion: occasion));
  void setStyleDirection(String v) => emit(state.copyWith(styleDirection: v));
  void setWeather(String v) => emit(state.copyWith(weather: v));
  void setCategory(String category) => emit(state.copyWith(category: category));
  void setAccessories(bool on) => emit(state.copyWith(accessories: on));
  void setActiveIndex(int index) => emit(state.copyWith(activeIndex: index));

  void toggleSelect(String id) {
    if (state.selected.contains(id)) {
      emit(
        state.copyWith(
          selected: state.selected.where((x) => x != id).toList(),
          locked: state.locked.where((x) => x != id).toList(),
        ),
      );
    } else {
      emit(state.copyWith(selected: [...state.selected, id]));
    }
  }

  void toggleLock(String id) {
    if (state.locked.contains(id)) {
      emit(state.copyWith(locked: state.locked.where((x) => x != id).toList()));
    } else {
      emit(state.copyWith(locked: [...state.locked, id]));
    }
  }

  void startMatching() =>
      emit(state.copyWith(selected: [], locked: [], category: 'All'));

  void selectAndLock(String id) =>
      emit(state.copyWith(selected: [id], locked: [id]));

  Future<void> generateAutomatic() {
    final owned = _wardrobe.state.items.map((i) => i.id).toSet();
    final combos = [
      for (final t in _templates) t.where(owned.contains).toList(),
    ];
    return _generate(
      combos,
      _automaticNames,
      match: false,
      aiRequest: _buildAiRequest(match: false),
    );
  }

  Future<void> generateMatches() => _generate(
    createMatches(),
    _matchNames,
    match: true,
    aiRequest: _buildAiRequest(match: true),
  );

  /// Whether the AI path is switched on for this user right now (flag on and
  /// signed in, decided by the app). Evaluated on every read; the views read
  /// this one getter for the honest labels (F26).
  bool get aiAvailable => _aiClient != null && (_aiAvailable?.call() ?? false);

  /// The request for the AI path, or null when the algorithm must run (AI
  /// unavailable, empty wardrobe, or a match request that cannot be built).
  AiStylistRequest? _buildAiRequest({required bool match}) {
    if (!aiAvailable) return null;
    final wardrobe = _wardrobe.state.items;
    if (wardrobe.isEmpty) return null;
    bool sendable(String id) =>
        id.isNotEmpty && id.length <= AiStylistRequest.maxFieldLength;
    final owned = wardrobe.map((i) => i.id).toSet();
    final selectedOwned = match
        ? state.selected.where(owned.contains).toList()
        : <String>[];
    final lockedOwned = state.locked.where(selectedOwned.contains).toList();
    if (lockedOwned.any((id) => !sendable(id))) return null;
    // Bucket order: locked, other selected, same occasion, the rest. Each
    // bucket keeps wardrobe order and no item appears twice.
    final seen = <String>{};
    final ordered = <ClothingItem>[];
    void take(bool Function(ClothingItem) test) {
      for (final i in wardrobe) {
        if (sendable(i.id) && !seen.contains(i.id) && test(i)) {
          seen.add(i.id);
          ordered.add(i);
        }
      }
    }

    take((i) => lockedOwned.contains(i.id));
    take((i) => selectedOwned.contains(i.id));
    take((i) => i.occasion == state.occasion);
    take((_) => true);
    final items = ordered.take(_maxAiItems).toList();
    final sent = items.map((i) => i.id).toSet();
    final selectedIds = [
      for (final id in selectedOwned)
        if (sent.contains(id)) id,
    ];
    if (match && selectedIds.isEmpty) return null;
    return AiStylistRequest(
      mode: match ? AiStylistMode.match : AiStylistMode.auto,
      occasion: state.occasion,
      styleDirection: state.styleDirection,
      weather: state.weather,
      includeAccessories: state.accessories,
      lockedIds: state.locked.where(selectedIds.contains).toList(),
      selectedIds: selectedIds,
      items: items,
    );
  }

  Future<List<AiOutfit>?> _askAi(AiStylistRequest request) async {
    try {
      return await _aiClient!.suggest(request).timeout(aiTimeout);
    } catch (_) {
      return null;
    }
  }

  /// Client-side recheck of the AI answer (F26-A59): only sent ids, 2-6
  /// distinct per look, locked pieces kept, and with "Complete my outfits"
  /// off only selected pieces. At most three looks.
  List<AiOutfit> _validAiOutfits(
    List<AiOutfit>? outfits,
    AiStylistRequest request,
  ) {
    if (outfits == null) return const [];
    final sent = request.items.map((i) => i.id).toSet();
    final matchMode = request.mode == AiStylistMode.match;
    final kept = <AiOutfit>[];
    for (final o in outfits) {
      final ids = <String>[];
      for (final id in o.itemIds) {
        if (sent.contains(id) && !ids.contains(id)) ids.add(id);
      }
      if (ids.length < 2 || ids.length > 6) continue;
      if (matchMode) {
        if (request.lockedIds.any((id) => !ids.contains(id))) continue;
        if (!request.includeAccessories &&
            ids.any((id) => !request.selectedIds.contains(id))) {
          continue;
        }
      }
      kept.add(AiOutfit(name: o.name, why: o.why, itemIds: ids));
      if (kept.length == 3) break;
    }
    return kept;
  }

  Future<void> _generate(
    List<List<String>> combos,
    List<String> names, {
    required bool match,
    AiStylistRequest? aiRequest,
  }) async {
    if (state.isGenerating) return;
    final occasion = state.occasion;
    final base = _clock();
    var results = [
      for (var i = 0; i < combos.length; i++)
        StyleResult(
          id: base + i,
          name: i < names.length ? names[i] : 'Look ${i + 1}',
          items: combos[i],
          occasion: occasion,
          why: _why[i % 3],
        ),
    ];
    emit(state.copyWith(isGenerating: true));
    if (aiRequest == null) {
      await Future<void>.delayed(generationDelay);
    } else {
      // generationDelay is the minimum wait, so a fast answer does not flash.
      final answers = await Future.wait<Object?>([
        Future<void>.delayed(generationDelay),
        _askAi(aiRequest),
      ]);
      final outfits = _validAiOutfits(answers[1] as List<AiOutfit>?, aiRequest);
      if (outfits.isNotEmpty) {
        results = [
          for (var i = 0; i < outfits.length; i++)
            StyleResult(
              id: base + i,
              name: outfits[i].name,
              items: outfits[i].itemIds,
              occasion: occasion,
              why: outfits[i].why,
              source: StyleResultSource.ai,
            ),
        ];
      }
    }
    if (isClosed) return;
    emit(
      state.copyWith(results: results, isMatchMode: match, isGenerating: false),
    );
    _analytics.outfitGenerated(
      mode: match ? OutfitGenerationMode.match : OutfitGenerationMode.automatic,
      resultCount: results.length,
    );
  }

  /// Exact port of prototype `createMatches` (app.js:112-136).
  List<List<String>> createMatches() {
    final items = _wardrobe.state.items;
    final ownedIds = items.map((i) => i.id).toSet();
    final selected = state.selected.where(ownedIds.contains).toList();
    final locked = state.locked.where(selected.contains).toList();
    final others = selected.where((id) => !locked.contains(id)).toList();
    String group(String id) => _wardrobe.itemOrFallback(id).category;
    bool isMain(String id) =>
        const ['Shirts', 'Dresses', 'Outerwear'].contains(group(id));
    bool isBottom(String id) => const ['Pants', 'Skirts'].contains(group(id));
    final shoes = [
      for (final x in items)
        if (x.category == 'Shoes' && !selected.contains(x.id)) x.id,
    ];
    final accessories = [
      for (final x in items)
        if (x.category == 'Accessories' && !selected.contains(x.id)) x.id,
    ];
    final outfits = <List<String>>[];
    final seen = <String>{};
    for (var i = 0; i < math.max(others.length * 2, 3); i++) {
      var result = [...locked];
      final tops = others.where(isMain).toList();
      final bottoms = others.where(isBottom).toList();
      if (!result.any(isMain) && tops.isNotEmpty) {
        result.add(tops[i % tops.length]);
      }
      if (!result.any(isBottom) &&
          !result.any((id) => group(id) == 'Dresses') &&
          bottoms.isNotEmpty) {
        result.add(bottoms[(i ~/ math.max(tops.length, 1)) % bottoms.length]);
      }
      final remaining = others.where((id) => !result.contains(id)).toList();
      if (result.isEmpty && remaining.isNotEmpty) {
        result.add(remaining[i % remaining.length]);
      }
      if (state.accessories) {
        if (!result.any((id) => group(id) == 'Shoes') && shoes.isNotEmpty) {
          result.add(shoes[i % shoes.length]);
        }
        if (accessories.isNotEmpty) {
          result.add(accessories[i % accessories.length]);
        }
      }
      result = result.toSet().toList();
      final key = (result.toList()..sort()).join('|');
      if (result.isNotEmpty && seen.add(key)) outfits.add(result);
      if (outfits.length == 3) break;
    }
    if (outfits.isEmpty && locked.isNotEmpty) outfits.add(locked.toList());
    return outfits;
  }

  /// Replaces [oldId] by [newId] in the active result. Returns the toast
  /// message to surface, or null when there is no active result.
  String? swapItem(String oldId, String newId) {
    final active = state.activeResult;
    if (active == null) return null;
    if (state.isMatchMode && state.locked.contains(oldId)) {
      return lockedSwapMessage;
    }
    final newName = _wardrobe.itemOrFallback(newId).name;
    final updated = active.copyWith(
      items: [for (final id in active.items) id == oldId ? newId : id],
      source: StyleResultSource.algorithm,
      why:
          'This preview pairs $newName with the other selected wardrobe pieces. Review the complete styling before wearing.',
    );
    final index = state.results.indexOf(active);
    emit(
      state.copyWith(
        results: [
          for (var i = 0; i < state.results.length; i++)
            i == index ? updated : state.results[i],
        ],
      ),
    );
    return swappedMessage;
  }

  /// Share text for the active result (empty when there is none).
  String shareSummary() {
    final r = state.activeResult;
    if (r == null) return '';
    final lines = r.items.map((id) => '• ${_wardrobe.itemOrFallback(id).name}');
    return '${r.name} — StyloBuddy\n${lines.join('\n')}\n\n${r.why}';
  }
}
