import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../shopping_tokens.dart';

/// Prototype `.sh-section-head`.
class ShSectionHead extends StatelessWidget {
  const ShSectionHead({super.key, required this.title, required this.count});

  final String title;
  final String count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.dmSans(
                size: 14,
                weight: FontWeight.w700,
                letterSpacing: -.25,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Text(
            count,
            style: AppTextStyles.dmSans(
              size: 10,
              color: ShoppingTokens.sectionCount,
            ),
          ),
        ],
      ),
    );
  }
}
