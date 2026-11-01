/// A dotted numeric app version (`1.2.10`) for the forced-update gate (F25).
///
/// Comparison is numeric per segment (`1.2.10 > 1.2.9`), missing trailing
/// segments count as zero (`1.2 == 1.2.0`), and build metadata (`+7`) and
/// pre-release suffixes (`-beta.1`) are ignored.
class AppVersion implements Comparable<AppVersion> {
  const AppVersion._(this.segments);

  final List<int> segments;

  static final _digits = RegExp(r'^\d+$');
  static const _maxSegments = 4;

  /// `null` for anything that is not 1-4 dot-separated non-negative
  /// integers once trimmed and stripped of `+build` / `-prerelease`.
  static AppVersion? tryParse(String raw) {
    var text = raw.trim();
    final plus = text.indexOf('+');
    if (plus >= 0) text = text.substring(0, plus);
    final dash = text.indexOf('-');
    if (dash >= 0) text = text.substring(0, dash);
    if (text.isEmpty) return null;
    final parts = text.split('.');
    if (parts.length > _maxSegments) return null;
    final segments = <int>[];
    for (final part in parts) {
      if (!_digits.hasMatch(part)) return null;
      final value = int.tryParse(part);
      if (value == null) return null;
      segments.add(value);
    }
    return AppVersion._(List.unmodifiable(segments));
  }

  int _at(int index) => index < segments.length ? segments[index] : 0;

  @override
  int compareTo(AppVersion other) {
    for (var i = 0; i < _maxSegments; i++) {
      final diff = _at(i).compareTo(other._at(i));
      if (diff != 0) return diff;
    }
    return 0;
  }

  bool operator <(AppVersion other) => compareTo(other) < 0;

  bool operator >(AppVersion other) => compareTo(other) > 0;

  @override
  bool operator ==(Object other) => other is AppVersion && compareTo(other) == 0;

  @override
  int get hashCode => Object.hashAll([for (var i = 0; i < _maxSegments; i++) _at(i)]);

  @override
  String toString() => segments.join('.');
}
