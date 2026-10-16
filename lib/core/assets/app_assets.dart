/// Asset path helpers. Garments with a real product photo use the bundled
/// webp; the rest fall back to the prototype's SVG illustrations
/// (see docs/image-prompts.md).
abstract final class AppAssets {
  static const localFashionIds = <String>{
    'white-shirt',
    'black-shirt',
    'blue-shirt',
    'navy-chinos',
    'beige-chinos',
    'black-jeans',
    'white-sneakers',
    'brown-loafers',
    'black-boots',
    'black-watch',
    'black-bag',
    'floral-dress',
    'tan-belt',
    'cream-cardigan',
    'black-heels',
    'denim-jacket',
    'white-tee',
  };

  static const appIcon = 'assets/branding/stylobuddy-icon-512.png';

  static String garmentPath(String id) => localFashionIds.contains(id)
      ? 'assets/fashion/$id.webp'
      : 'assets/garments/$id.svg';

  static bool isSvg(String path) => path.endsWith('.svg');

  static String onboarding(String file) => 'assets/onboarding/$file';
}
