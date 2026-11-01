import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../packing_tokens.dart';

/// Prototype `.pk-feature`: 'Your wardrobe goes with you.' card on
/// `/packing`.
class PkFeatureCard extends StatelessWidget {
  const PkFeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });

  final String icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 18),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 17),
      decoration: BoxDecoration(
        color: PackingTokens.featureBg,
        border: Border.all(color: PackingTokens.featureBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 35,
            height: 35,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: PackingTokens.featureIconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              icon,
              style: AppTextStyles.dmSans(
                size: 19,
                color: PackingTokens.featureIconInk,
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w700),
                ),
                const SizedBox(height: 5),
                Text(
                  body,
                  style: AppTextStyles.dmSans(
                    size: 10,
                    color: PackingTokens.featureBody,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
