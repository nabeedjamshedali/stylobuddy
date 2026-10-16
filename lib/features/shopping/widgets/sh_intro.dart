import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../shopping_tokens.dart';

/// Prototype `.sh-intro`.
class ShIntro extends StatelessWidget {
  const ShIntro({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(17, 21, 17, 20),
      decoration: BoxDecoration(
        color: ShoppingTokens.introBg,
        border: Border.all(color: ShoppingTokens.introBorder),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SMARTER SHOPPING',
            style: AppTextStyles.dmSans(
              size: 9,
              weight: FontWeight.w800,
              color: ShoppingTokens.eyebrow,
              letterSpacing: 1.8,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 13, bottom: 11),
            child: Text(
              'Wear more.\nBuy intentionally.',
              style: AppTextStyles.manrope(
                size: 27,
                weight: FontWeight.w700,
                color: ShoppingTokens.introHeading,
                height: 1.13,
                letterSpacing: -1.1,
              ),
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 285),
            child: Text(
              'Discover useful wardrobe additions based on what you already '
              'own—not random trends.',
              style: AppTextStyles.dmSans(
                size: 11,
                color: ShoppingTokens.introBody,
                height: 1.65,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
