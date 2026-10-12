import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/gradient_backdrop.dart';

/// Stand-in destination after onboarding completes. The real app flow
/// (home/shop/etc.) is being redesigned and intentionally not built yet
/// per the current scope — this just proves the onboarding handoff works.
class HomePlaceholderView extends StatelessWidget {
  const HomePlaceholderView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackdrop(
        glowAlignment: Alignment.center,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: AppColors.accent, size: 48),
              const SizedBox(height: 16),
              Text('Onboarding complete', style: AppTextStyles.headline.copyWith(fontSize: 22)),
              const SizedBox(height: 8),
              Text('Main app UI coming next.', style: AppTextStyles.body),
            ],
          ),
        ),
      ),
    );
  }
}
