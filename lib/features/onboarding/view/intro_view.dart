import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../cubit/onboarding_cubit.dart';
import '../cubit/onboarding_state.dart';
import '../models/intro_slide.dart';
import '../onboarding_tokens.dart';
import '../widgets/intro_dots.dart';
import '../widgets/intro_headline.dart';
import '../widgets/intro_illustration.dart';
import '../widgets/ob_primary_button.dart';
import '../widgets/ob_text_button.dart';
import '../widgets/occasion_list.dart';

/// Prototype `pages.intro`: five slides driven by [OnboardingCubit.state],
/// resolved for the gender chosen on `/gender` (F24). With no gender (a
/// fresh shell landing on `/intro`) it renders a blank page and redirects to
/// `/gender` once; it never renders a slide without a gender.
class IntroView extends StatelessWidget {
  const IntroView({super.key});

  static String buttonLabel(int slide) => switch (slide) {
    0 => 'Get Started',
    OnboardingCubit.lastSlide => 'Create My Wardrobe',
    _ => 'Continue',
  };

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OnboardingCubit, OnboardingState>(
      listenWhen: (previous, current) => current.exit != OnboardingExit.none,
      listener: (context, state) {
        final exit = state.exit;
        context.read<OnboardingCubit>().clearExit();
        context.go(
          exit == OnboardingExit.finished
              ? AppRoutes.personalize
              : AppRoutes.gender,
        );
      },
      builder: (context, state) {
        final gender = state.gender;
        if (gender == null) return const _RedirectToGender();
        final slide = introSlidesFor(gender)[state.slide];
        return Scaffold(
          backgroundColor: AppColors.white,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => Padding(
                padding: const EdgeInsets.fromLTRB(17, 8, 17, 2),
                child: Column(
                  children: [
                    _TopRow(
                      slide: state.slide,
                      onSkip: () => context.go(AppRoutes.personalize),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: slide.isOccasions
                            ? OccasionList(
                                chosen: state.chosenOccasions,
                                onToggle: context
                                    .read<OnboardingCubit>()
                                    .toggleOccasion,
                              )
                            : Column(
                                children: [
                                  IntroIllustration(
                                    slide: slide,
                                    pageHeight: constraints.maxHeight,
                                  ),
                                  IntroHeadline(
                                    title: slide.title,
                                    description: slide.description,
                                  ),
                                ],
                              ),
                      ),
                    ),
                    _Bottom(slide: state.slide),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// F24 null-gender guard: blank white page, one post-frame `go('/gender')`.
class _RedirectToGender extends StatefulWidget {
  const _RedirectToGender();

  @override
  State<_RedirectToGender> createState() => _RedirectToGenderState();
}

class _RedirectToGenderState extends State<_RedirectToGender> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go(AppRoutes.gender);
    });
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(backgroundColor: AppColors.white);
}

class _TopRow extends StatelessWidget {
  const _TopRow({required this.slide, required this.onSkip});

  final int slide;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 2, 6, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${slide + 1}/5',
            style: AppTextStyles.dmSans(
              size: 11,
              color: OnboardingTokens.topInk,
            ),
          ),
          ObTextButton(
            label: 'Skip',
            size: 11,
            color: OnboardingTokens.skipInk,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            onTap: onSkip,
          ),
        ],
      ),
    );
  }
}

class _Bottom extends StatelessWidget {
  const _Bottom({required this.slide});

  final int slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
      child: Column(
        children: [
          IntroDots(active: slide),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: ObPrimaryButton(
              label: IntroView.buttonLabel(slide),
              onPressed: () => context.read<OnboardingCubit>().next(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: ObTextButton(
              label: 'Back',
              size: 10.5,
              color: OnboardingTokens.backButton,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              onTap: () => context.read<OnboardingCubit>().back(),
            ),
          ),
        ],
      ),
    );
  }
}
