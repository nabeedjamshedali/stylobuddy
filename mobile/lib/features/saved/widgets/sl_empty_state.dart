import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../saved_tokens.dart';

/// Prototype `.sl-empty`: dashed-border placeholder, shared by the Saved
/// Looks and Wear History tabs (with and without an active search).
class SlEmptyState extends StatelessWidget {
  const SlEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.action,
  });

  final String icon;
  final String title;
  final String? body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 26),
      decoration: BoxDecoration(
        color: SavedTokens.emptyBg,
        border: Border.all(color: SavedTokens.emptyBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            icon,
            style: AppTextStyles.dmSans(size: 27, color: SavedTokens.emptyIcon),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.dmSans(size: 15, weight: FontWeight.w700),
          ),
          if (body != null) ...[
            const SizedBox(height: 6),
            Text(
              body!,
              textAlign: TextAlign.center,
              style: AppTextStyles.dmSans(
                size: 11,
                color: SavedTokens.emptyBody,
                height: 1.6,
              ),
            ),
          ],
          if (action != null) ...[const SizedBox(height: 15), action!],
        ],
      ),
    );
  }
}
