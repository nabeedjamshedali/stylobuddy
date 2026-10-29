import 'package:flutter_test/flutter_test.dart';
import 'package:stylobuddy/features/app_config/models/app_version.dart';

AppVersion _v(String raw) {
  final parsed = AppVersion.tryParse(raw);
  expect(parsed, isNotNull, reason: raw);
  return parsed!;
}

void main() {
  test('F25_A18 numeric, padded comparison; suffixes ignored; malformed strings are null', () {
    expect(_v('1.2.10') > _v('1.2.9'), isTrue);
    expect(_v('1.2.9') < _v('1.2.10'), isTrue);
    expect(_v('1.10.0') > _v('1.9.9'), isTrue);
    expect(_v('2.0') > _v('1.99.99'), isTrue);
    expect(_v('1.2'), _v('1.2.0'));
    expect(_v('1.2.0'), _v('1.2.0.0'));
    expect(_v('1.2').hashCode, _v('1.2.0.0').hashCode);
    expect(_v('01.2.3'), _v('1.2.3'));
    expect(_v('1.2.3+45'), _v('1.2.3'));
    expect(_v('1.2.3-beta.1'), _v('1.2.3'));
    expect(_v(' 1.0.0 '), _v('1.0.0'));
    expect(_v('1.2.3').compareTo(_v('1.2.3')), 0);

    for (final bad in [
      '',
      '  ',
      'abc',
      'v1.2',
      '1..2',
      '1.2.',
      '1.x',
      '1.2.3.4.5',
      '-1.0',
      // digits-only but beyond int range: must fail open, never throw
      '1.99999999999999999999',
      '99999999999999999999',
    ]) {
      expect(AppVersion.tryParse(bad), isNull, reason: "'$bad'");
    }
  });
}
