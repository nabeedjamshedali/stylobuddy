import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../shopping_tokens.dart';

/// Prototype `.sh-empty`: discover (no icon/button) and wishlist (icon +
/// 'Explore suggestions' button) share this shape.
class ShEmptyCard extends StatelessWidget {
  const ShEmptyCard({
    super.key,
    this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  final String? icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 35),
      decoration: BoxDecoration(
        color: ShoppingTokens.emptyBg,
        border: Border.all(color: ShoppingTokens.emptyBorder),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        children: [
          if (icon != null)
            Text(
              icon!,
              style: AppTextStyles.dmSans(size: 27, color: ShoppingTokens.emptyInk),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.dmSans(
                size: 13,
                weight: FontWeight.w700,
                color: ShoppingTokens.emptyInk,
              ),
            ),
          ),
          Text(
            body,
            textAlign: TextAlign.center,
            style: AppTextStyles.dmSans(
              size: 11,
              color: ShoppingTokens.emptyBody,
              height: 1.6,
            ),
          ),
          if (actionLabel != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: PrimaryButton(
                label: actionLabel!,
                onPressed: onAction,
                fullWidth: false,
              ),
            ),
        ],
      ),
    );
  }
}
