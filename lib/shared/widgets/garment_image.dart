import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/assets/app_assets.dart';

/// Garment artwork by id: bundled webp photo or SVG illustration. Falls back
/// to the SVG illustration when the photo cannot be decoded.
class GarmentImage extends StatelessWidget {
  const GarmentImage({super.key, required this.id, this.fit = BoxFit.contain});

  final String id;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final path = AppAssets.garmentPath(id);
    if (AppAssets.isSvg(path)) return _svg(path);
    return Image.asset(
      path,
      fit: fit,
      errorBuilder: (_, _, _) => _svg('assets/garments/$id.svg'),
    );
  }

  Widget _svg(String path) => SvgPicture.asset(
        path,
        fit: fit,
        placeholderBuilder: (_) => const SizedBox.shrink(),
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      );
}
