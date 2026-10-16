import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../shopping_catalog.dart';
import '../shopping_tokens.dart';

/// Prototype `shopArt`: a gradient tile built from the catalog symbol glyph
/// and a 'WARDROBE EDIT' caption, not an image.
class ShArt extends StatelessWidget {
  const ShArt({super.key, required this.id, this.symbolSize = 51});

  final String id;
  final double symbolSize;

  @override
  Widget build(BuildContext context) {
    final colors = ShoppingTokens.artBg[id] ?? const [Colors.white, Colors.white];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            ShoppingCatalog.byId(id).symbol,
            style: AppTextStyles.dmSans(
              size: symbolSize,
              weight: FontWeight.w300,
              color: ShoppingTokens.artSymbol.withValues(alpha: .86),
            ),
          ),
          Positioned(
            bottom: 10,
            child: Text(
              'WARDROBE EDIT',
              style: AppTextStyles.dmSans(
                size: 7,
                weight: FontWeight.w800,
                color: ShoppingTokens.artCaption,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
