import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stylobuddy/core/assets/app_assets.dart';

void main() {
  const seedIds = [
    'white-shirt',
    'black-shirt',
    'blue-shirt',
    'cream-blouse',
    'navy-chinos',
    'beige-chinos',
    'black-jeans',
    'blue-jeans',
    'white-sneakers',
    'brown-loafers',
    'black-boots',
    'black-watch',
    'black-bag',
    'floral-dress',
    'sage-dress',
    'black-skirt',
    'tan-belt',
    'gold-jewelry',
    'sunglasses',
    'cream-cardigan',
    'black-heels',
    'denim-jacket',
    'white-tee',
  ];

  test('garmentPath maps local fashion ids to webp', () {
    expect(
      AppAssets.garmentPath('white-shirt'),
      'assets/fashion/white-shirt.webp',
    );
  });

  test('garmentPath falls back to svg for non-local ids', () {
    expect(
      AppAssets.garmentPath('cream-blouse'),
      'assets/garments/cream-blouse.svg',
    );
    expect(AppAssets.garmentPath('gold-jewelry'), endsWith('.svg'));
    expect(AppAssets.isSvg(AppAssets.garmentPath('gold-jewelry')), isTrue);
    expect(AppAssets.isSvg(AppAssets.garmentPath('white-shirt')), isFalse);
  });

  test('there are exactly 17 local fashion ids', () {
    expect(AppAssets.localFashionIds.length, 17);
  });

  test(
    'every seed id and every bundled svg id resolves to an existing file',
    () {
      final svgIds = Directory('assets/garments')
          .listSync()
          .whereType<File>()
          .map((f) => f.uri.pathSegments.last.replaceAll('.svg', ''))
          .toList();
      expect(svgIds.length, 24);
      for (final id in {...seedIds, ...svgIds}) {
        expect(
          File(AppAssets.garmentPath(id)).existsSync(),
          isTrue,
          reason: id,
        );
      }
    },
  );

  test('onboarding and icon paths', () {
    expect(
      AppAssets.onboarding('onboard-00-rack.png'),
      'assets/onboarding/onboard-00-rack.png',
    );
    expect(File(AppAssets.appIcon).existsSync(), isTrue);
  });
}
