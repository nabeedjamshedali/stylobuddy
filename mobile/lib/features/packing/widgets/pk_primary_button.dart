import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../packing_tokens.dart';

/// Prototype `.pk-button`: full-width button, label left and arrow right.
class PkPrimaryButton extends StatelessWidget {
  const PkPrimaryButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PackingTokens.buttonBg,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTextStyles.dmSans(
                  size: 12,
                  weight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
              Text(
                '→',
                style: AppTextStyles.dmSans(size: 12, color: AppColors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
