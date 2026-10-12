import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Wordmark lockup, matching the reference's top-left "VYRO" brand mark
/// (glyph + letter-spaced wordmark), centered for the splash moment.
class SplashLogo extends StatelessWidget {
  const SplashLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.glassBorder, width: 1.5),
            color: AppColors.glassFill,
          ),
          child: const Icon(
            Icons.auto_awesome,
            color: AppColors.accent,
            size: 28,
          ),
        ),
        const SizedBox(height: 18),
        Text('STYLOBUDDY', style: AppTextStyles.brandWordmark),
      ],
    );
  }
}
