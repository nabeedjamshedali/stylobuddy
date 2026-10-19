import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/backend/firestore_service.dart';
import '../cubit/profile_state.dart';
import 'profile_repository.dart';

/// Signed-in repository (architecture D2, D4, D6): real reads/writes of
/// `users/{uid}` (schema doc §1). Every `set*`/`updateDetails` method is a
/// plain `set(doc, {field: value}, SetOptions(merge: true))` call, **not**
/// `runTransaction` — `ProfileCubit` always hands this repository the
/// final value to write (F18 doc §6/A04), so there is nothing left here to
/// read-then-modify, unlike F16's `logWear`/`removeWear`.
///
/// [watchProfile] excludes the infra-only `seeded` field and the
/// `wishlist` field (belongs to `ShoppingState`/Task 6, not `ProfileState`
/// — F18 doc §13) from the emitted [ProfileState] (F18-A02), mirroring
/// F14's own `seeded`-exclusion precedent.
class FirestoreProfileRepository implements ProfileRepository {
  FirestoreProfileRepository(this._service, this._uid)
    : _doc = _service.userDoc(_uid);

  final FirestoreService _service;
  final String _uid;
  final DocumentReference<Map<String, dynamic>> _doc;

  static const _defaults = ProfileState();

  static List<String> _listField(
    Map<String, dynamic> data,
    String key,
    List<String> fallback,
  ) {
    // Missing key -> fallback (F18-A18); explicitly-present (even if
    // empty) -> read back verbatim, never coerced back to the default.
    if (!data.containsKey(key) || data[key] == null) return fallback;
    return List<String>.from(data[key] as List);
  }

  static String _stringField(
    Map<String, dynamic> data,
    String key,
    String fallback,
  ) {
    // Missing key -> fallback (F18-A19); explicitly-present empty string
    // -> read back verbatim as '', never coerced to the default.
    if (!data.containsKey(key) || data[key] == null) return fallback;
    return data[key] as String;
  }

  static bool _boolField(
    Map<String, dynamic> data,
    String key,
    bool fallback,
  ) {
    if (!data.containsKey(key) || data[key] == null) return fallback;
    return data[key] as bool;
  }

  static ProfileState _fromFirestore(Map<String, dynamic> data) =>
      ProfileState(
        name: _stringField(data, 'name', _defaults.name),
        email: _stringField(data, 'email', _defaults.email),
        styles: _listField(data, 'styles', _defaults.styles),
        occasions: _listField(data, 'occasions', _defaults.occasions),
        dailyNotifications: _boolField(
          data,
          'dailyNotifications',
          _defaults.dailyNotifications,
        ),
        plannedNotifications: _boolField(
          data,
          'plannedNotifications',
          _defaults.plannedNotifications,
        ),
        productNotifications: _boolField(
          data,
          'productNotifications',
          _defaults.productNotifications,
        ),
        weatherConsent: _boolField(
          data,
          'weatherConsent',
          _defaults.weatherConsent,
        ),
        climate: _stringField(data, 'climate', _defaults.climate),
        plan: _stringField(data, 'plan', _defaults.plan),
        billingCycle: _stringField(
          data,
          'billingCycle',
          _defaults.billingCycle,
        ),
      );

  /// The full 11-field write payload for [state] — used both by individual
  /// setters (merged with just the changed field(s) at the call site) and
  /// by [bootstrapIfNeeded]'s seed write, so a freshly-seeded document
  /// always carries exactly these keys (plus `wishlist`/`seeded`, F18-A02),
  /// never a stray extra field.
  static Map<String, dynamic> _toFirestore(ProfileState state) => {
    'name': state.name,
    'email': state.email,
    'styles': state.styles,
    'occasions': state.occasions,
    'dailyNotifications': state.dailyNotifications,
    'plannedNotifications': state.plannedNotifications,
    'productNotifications': state.productNotifications,
    'weatherConsent': state.weatherConsent,
    'climate': state.climate,
    'plan': state.plan,
    'billingCycle': state.billingCycle,
  };

  @override
  Stream<ProfileState> watchProfile() => _doc.snapshots().map(
    (snapshot) => _fromFirestore(snapshot.data() ?? const <String, dynamic>{}),
  );

  Future<void> _merge(Map<String, dynamic> fields) =>
      _doc.set(fields, SetOptions(merge: true));

  @override
  Future<void> updateDetails(String name, String email) =>
      _merge({'name': name, 'email': email});

  @override
  Future<void> setStyles(List<String> styles) =>
      _merge({'styles': styles});

  @override
  Future<void> setOccasions(List<String> occasions) =>
      _merge({'occasions': occasions});

  @override
  Future<void> setDailyNotifications(bool v) =>
      _merge({'dailyNotifications': v});

  @override
  Future<void> setPlannedNotifications(bool v) =>
      _merge({'plannedNotifications': v});

  @override
  Future<void> setProductNotifications(bool v) =>
      _merge({'productNotifications': v});

  @override
  Future<void> setWeatherConsent(bool v) => _merge({'weatherConsent': v});

  @override
  Future<void> setClimate(String v) => _merge({'climate': v});

  @override
  Future<void> setPlan(String v) => _merge({'plan': v});

  @override
  Future<void> setBillingCycle(String v) => _merge({'billingCycle': v});

  /// D5 bootstrap seed (F18-A03/A06/A07): uses
  /// [FirestoreService.runBootstrapIfNeeded] (Task 1's unchanged
  /// transaction mechanism/guard/lock-keying) inside its `seeded`-guarded
  /// transaction. Profile has no subcollection to seed, so [seedWriter]
  /// itself is a no-op — the full default [ProfileState] payload (with
  /// `occasions` overridden by [pendingOccasions], the onboarding
  /// handoff's union, already consumed-and-cleared by the caller, when
  /// non-empty) plus `wishlist: []` are instead supplied via
  /// `extraFields`, merged directly into `runBootstrapIfNeeded`'s own
  /// existing `seeded: true` commit (see that method's doc comment for
  /// why: writing these as a *second*, separate `tx.set` against the same
  /// `userDoc` document — the natural-looking approach — silently loses
  /// data against `fake_cloud_firestore`, confirmed empirically while
  /// building this task). An empty [pendingOccasions] (nothing toggled)
  /// falls back to `ProfileState()`'s hardcoded default occasions, never
  /// an empty list (F18-A07: "didn't choose" != "chose to clear
  /// everything"). A second call for an already-seeded uid performs no
  /// further seed write at all (F14's guard, reaffirmed not
  /// reimplemented).
  Future<void> bootstrapIfNeeded({Set<String> pendingOccasions = const {}}) {
    final occasions = pendingOccasions.isEmpty
        ? _defaults.occasions
        : pendingOccasions.toList();
    return _service.runBootstrapIfNeeded(
      _uid,
      (tx, userDoc) async {},
      extraFields: () => {
        ..._toFirestore(ProfileState(occasions: occasions)),
        'wishlist': <String>[],
      },
    );
  }
}
