import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Reusable glass circular icon button, used across all three onboarding
/// layouts' top chrome (menu / search / bell / back / heart icons).
class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const GlassIconButton({super.key, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.glassFill,
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Icon(icon, color: AppColors.textPrimary, size: 18),
    );
  }
}

/// Top chrome row shared by onboarding pages: brand wordmark + a skip
/// action, mirroring the logo/menu row in the reference screens.
class OnboardingTopBar extends StatelessWidget {
  final VoidCallback onSkip;

  const OnboardingTopBar({super.key, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('STYLOBUDDY', style: AppTextStyles.brandWordmark.copyWith(fontSize: 14)),
        GestureDetector(
          onTap: onSkip,
          child: Text('Skip', style: AppTextStyles.caption),
        ),
      ],
    );
  }
}
