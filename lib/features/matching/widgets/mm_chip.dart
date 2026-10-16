import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../matching_tokens.dart';

/// Prototype `.mm-chips button`: pill category chip (99px radius).
class MmChip extends StatelessWidget {
  const MmChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.green : AppColors.white,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: selected ? AppColors.green : MatchingTokens.chipBorder,
          ),
        ),
        child: Text(
          label,
          softWrap: false,
          style: AppTextStyles.dmSans(
            size: 10,
            color: selected ? AppColors.white : MatchingTokens.chipInk,
          ),
        ),
      ),
    );
  }
}
