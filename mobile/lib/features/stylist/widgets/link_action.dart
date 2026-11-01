import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../stylist_tokens.dart';

/// Prototype `.ai-link-btn`: full-width green text button.
class LinkAction extends StatelessWidget {
  const LinkAction({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.dmSans(
              size: 11,
              weight: FontWeight.w700,
              color: StylistTokens.lookExplore,
            ),
          ),
        ),
      ),
    );
  }
}
