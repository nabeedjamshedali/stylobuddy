import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../shopping_tokens.dart';

/// Prototype `.sh-tip`.
class ShTipCard extends StatelessWidget {
  const ShTipCard({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 18),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: ShoppingTokens.tipBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '✧',
            style: AppTextStyles.dmSans(size: 20, color: ShoppingTokens.tipIcon),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.dmSans(
                size: 11,
                color: ShoppingTokens.tipBody,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
