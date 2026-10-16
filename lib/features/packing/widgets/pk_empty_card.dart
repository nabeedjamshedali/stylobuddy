import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../packing_tokens.dart';

/// Prototype `.pk-empty`: dashed card used for 'No trips planned yet' (with
/// an icon) and 'Your list is empty' (without one).
class PkEmptyCard extends StatelessWidget {
  const PkEmptyCard({
    super.key,
    required this.title,
    required this.body,
    this.icon,
  });

  final String title;
  final String body;
  final String? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 29),
      decoration: BoxDecoration(
        color: PackingTokens.emptyBg,
        border: Border.all(color: PackingTokens.emptyBorder),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        children: [
          if (icon != null) ...[
            Text(
              icon!,
              style: AppTextStyles.dmSans(size: 29, color: PackingTokens.emptyIcon),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            title,
            style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              body,
              textAlign: TextAlign.center,
              style: AppTextStyles.dmSans(
                size: 11,
                color: PackingTokens.emptyBody,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
