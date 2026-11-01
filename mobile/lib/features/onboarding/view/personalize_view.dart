import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/chip_button.dart';
import '../../../shared/widgets/option_tile.dart';
import '../../../shared/widgets/screen_head.dart';
import '../../../shared/widgets/section_title.dart';
import '../cubit/onboarding_cubit.dart';
import '../cubit/onboarding_state.dart';
import '../models/intro_slide.dart';

/// Prototype `pages.personalize`. "Smart casual" is the fixed preselected
/// option: in the prototype tapping an option only toasts.
class PersonalizeView extends StatelessWidget {
  const PersonalizeView({super.key});

  static const preselectedStyle = 'Smart casual';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ScreenHead(
                title: 'Your Style, Your Way',
                fallbackRoute: AppRoutes.intro,
              ),
              Text(
                'What feels most like you?',
                style: AppTextStyles.manrope(
                  size: 22,
                  height: 1.3,
                  letterSpacing: -.8,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose a few favorites. You can change them later.',
                style: AppTextStyles.dmSans(
                  size: 12,
                  color: AppColors.muted,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              for (final style in personalizeStyles)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: style == personalizeStyles.last ? 0 : 8,
                  ),
                  child: OptionTile(
                    label: style,
                    selected: style == preselectedStyle,
                    onTap: () => AppToast.show(context, '$style selected'),
                  ),
                ),
              const SizedBox(height: 20),
              const SectionTitle(title: 'Occasions you dress for'),
              const _ChipRow(),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Continue →',
                onPressed: () => context.push(AppRoutes.auth),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingCubit, OnboardingState>(
      buildWhen: (a, b) => a.chosenChips != b.chosenChips,
      builder: (context, state) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(bottom: 3),
        child: Row(
          children: [
            for (final chip in personalizeChips) ...[
              if (chip != personalizeChips.first) const SizedBox(width: 6),
              ChipButton(
                label: chip,
                selected: state.chosenChips.contains(chip),
                onTap: () => context.read<OnboardingCubit>().toggleChip(chip),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
