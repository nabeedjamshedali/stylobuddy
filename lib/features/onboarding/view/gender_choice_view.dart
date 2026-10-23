import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/genders.dart';
import '../../../shared/widgets/app_toast.dart';
import '../cubit/onboarding_cubit.dart';
import '../cubit/onboarding_state.dart';
import '../onboarding_tokens.dart';
import '../widgets/gender_card.dart';
import '../widgets/ob_primary_button.dart';
import '../widgets/ob_text_button.dart';

/// Prototype v26 `pages.gender` (app.js:307-311), F24: a required,
/// single-select choice between `/welcome` and `/intro`. The prototype's
/// "1 / 2" counter and "You can change this later." line are not ported
/// (F24 §12).
class GenderChoiceView extends StatelessWidget {
  const GenderChoiceView({super.key});

  static const noChoiceToast = 'Choose Male or Female to continue';

  void _continue(BuildContext context, String? gender) {
    if (gender == null) {
      AppToast.show(context, noChoiceToast);
      return;
    }
    context.go(AppRoutes.intro);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingCubit, OnboardingState>(
      buildWhen: (previous, current) => previous.gender != current.gender,
      builder: (context, state) {
        final cubit = context.read<OnboardingCubit>();
        return Scaffold(
          backgroundColor: AppColors.white,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _GenderCopy(),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 20, bottom: 8),
                      child: Column(
                        children: [
                          Expanded(
                            child: GenderCard(
                              key: const Key('gender-card-male'),
                              title: 'Male',
                              subtitle: 'Menswear and outfit inspiration',
                              image: 'onboard-gender-male.png',
                              selected: state.gender == Genders.male,
                              onTap: () => cubit.setGender(Genders.male),
                            ),
                          ),
                          const SizedBox(height: 13),
                          Expanded(
                            child: GenderCard(
                              key: const Key('gender-card-female'),
                              title: 'Female',
                              subtitle: 'Womenswear and outfit inspiration',
                              image: 'onboard-gender-female.png',
                              selected: state.gender == Genders.female,
                              onTap: () => cubit.setGender(Genders.female),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                    child: Column(
                      children: [
                        ObPrimaryButton(
                          label: 'Continue',
                          semanticLabel: 'Continue →',
                          enabled: state.gender != null,
                          onPressed: () => _continue(context, state.gender),
                        ),
                        const SizedBox(height: 2),
                        Center(
                          child: ObTextButton(
                            label: 'Back',
                            size: 10.5,
                            color: OnboardingTokens.backButton,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 8,
                            ),
                            onTap: () => context.go(AppRoutes.welcome),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GenderCopy extends StatelessWidget {
  const _GenderCopy();

  @override
  Widget build(BuildContext context) {
    final titleStyle = AppTextStyles.dmSans(
      size: 30,
      weight: FontWeight.w700,
      height: 1.09,
      letterSpacing: -1.2,
      color: OnboardingTokens.genderTitle,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'YOUR STYLE PROFILE',
            style: AppTextStyles.dmSans(
              size: 11,
              weight: FontWeight.w600,
              letterSpacing: 1.1,
              color: OnboardingTokens.genderOverline,
            ),
          ),
          const SizedBox(height: 18),
          Text.rich(
            TextSpan(
              text: 'Who are you\n',
              style: titleStyle,
              children: [
                TextSpan(
                  text: 'styling for?',
                  style: titleStyle.copyWith(
                    color: OnboardingTokens.genderAccent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Choose your wardrobe profile for relevant outfits and clothing categories.',
            style: AppTextStyles.dmSans(
              size: 13,
              height: 1.6,
              color: OnboardingTokens.genderBody,
            ),
          ),
        ],
      ),
    );
  }
}
