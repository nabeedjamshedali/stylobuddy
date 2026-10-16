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

/// Prototype `pages.intro`: five slides driven by [OnboardingCubit.state].
class IntroView extends StatelessWidget {
  const IntroView({super.key});

  static String buttonLabel(int slide) => switch (slide) {
    0 => 'Get Started',
    OnboardingCubit.lastSlide => 'Create My Wardrobe',
    _ => 'Continue',
  };

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();
    return BlocConsumer<OnboardingCubit, OnboardingState>(
      listenWhen: (previous, current) => current.exit != OnboardingExit.none,
      listener: (context, state) {
        final exit = state.exit;
        cubit.clearExit();
        context.go(
          exit == OnboardingExit.finished
              ? AppRoutes.personalize
              : AppRoutes.welcome,
        );
      },
      builder: (context, state) {
        final slide = introSlides[state.slide];
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) cubit.back();
          },
          child: Scaffold(
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
                                  onToggle: cubit.toggleOccasion,
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
                      _Bottom(slide: state.slide, cubit: cubit),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
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
  const _Bottom({required this.slide, required this.cubit});

  final int slide;
  final OnboardingCubit cubit;

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
              onPressed: cubit.next,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: ObTextButton(
              label: 'Back',
              size: 10.5,
              color: OnboardingTokens.backButton,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              onTap: cubit.back,
            ),
          ),
        ],
      ),
    );
  }
}
