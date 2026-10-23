import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/brand_mark.dart';
import '../cubit/onboarding_cubit.dart';
import '../onboarding_tokens.dart';
import '../widgets/ob_photo.dart';
import '../widgets/ob_primary_button.dart';
import '../widgets/ob_text_button.dart';

/// Prototype `pages.welcome`.
class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key});

  void _start(BuildContext context) {
    context.read<OnboardingCubit>().start();
    context.go(AppRoutes.intro);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: _WelcomeCopy(),
              ),
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: 14),
                  // SizedBox.expand gives ObPhoto the Expanded's full area to
                  // fill (BoxFit.contain then scales the image up to that
                  // box, centered) instead of Align's shrink-to-intrinsic-
                  // size behavior, which left most of this space empty above
                  // a small, bottom-pinned image.
                  child: SizedBox.expand(child: ObPhoto(file: 'onboard-00-rack.png')),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
                child: Column(
                  children: [
                    ObPrimaryButton(
                      label: 'Get Started',
                      semanticLabel: 'Get Started →',
                      onPressed: () => _start(context),
                    ),
                    const SizedBox(height: 5),
                    Center(
                      child: ObTextButton(
                        label: 'Skip introduction',
                        size: 11,
                        color: OnboardingTokens.plainButton,
                        onTap: () => context.go(AppRoutes.auth),
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
  }
}

class _WelcomeCopy extends StatelessWidget {
  const _WelcomeCopy();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BrandMark(),
        const SizedBox(height: 24),
        Text(
          'Your AI-Powered\nPersonal Stylist',
          style: AppTextStyles.dmSans(
            size: 22,
            weight: FontWeight.w600,
            height: 1.32,
            letterSpacing: -.4,
            color: OnboardingTokens.welcomeTitle,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Organize your wardrobe,\nget smart recommendations,\nand dress your best, every day.',
          style: AppTextStyles.dmSans(
            size: 13,
            height: 1.75,
            color: OnboardingTokens.welcomeBody,
          ),
        ),
      ],
    );
  }
}
