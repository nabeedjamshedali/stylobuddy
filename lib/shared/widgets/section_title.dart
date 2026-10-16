import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Prototype `.section-title`: bold title with optional green "link →".
class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.title,
    this.linkLabel,
    this.onLink,
  });

  final String title;
  final String? linkLabel;
  final VoidCallback? onLink;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w700),
          ),
          if (linkLabel != null)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onLink,
              child: Text(
                '$linkLabel →',
                style: AppTextStyles.dmSans(
                  size: 10,
                  weight: FontWeight.w700,
                  color: AppColors.green,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
