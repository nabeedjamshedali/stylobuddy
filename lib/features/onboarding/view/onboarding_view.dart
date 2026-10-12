import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/widgets/gradient_backdrop.dart';
import '../../home/view/home_placeholder_view.dart';
import '../cubit/onboarding_cubit.dart';
import '../cubit/onboarding_state.dart';
import '../models/onboarding_page_data.dart';
import '../widgets/ai_stylist_page.dart';
import '../widgets/curated_picks_page.dart';
import '../widgets/hero_upload_page.dart';
import '../widgets/onboarding_bottom_controls.dart';

class OnboardingView extends StatelessWidget {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OnboardingCubit(),
      child: const _OnboardingScaffold(),
    );
  }
}

class _OnboardingScaffold extends StatefulWidget {
  const _OnboardingScaffold();

  @override
  State<_OnboardingScaffold> createState() => _OnboardingScaffoldState();
}

class _OnboardingScaffoldState extends State<_OnboardingScaffold> {
  final _controller = PageController();
  static const _pages = OnboardingPageData.pages;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomePlaceholderView()),
    );
  }

  void _next(OnboardingState state) {
    if (state.isLastPage) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackdrop(
        child: SafeArea(
          child: BlocBuilder<OnboardingCubit, OnboardingState>(
            builder: (context, state) {
              return Column(
                children: [
                  Expanded(
                    child: PageView(
                      controller: _controller,
                      onPageChanged: context.read<OnboardingCubit>().onPageChanged,
                      children: [
                        HeroUploadPage(data: _pages[0]),
                        AiStylistPage(data: _pages[1], onSkip: _finish),
                        CuratedPicksPage(data: _pages[2], onSkip: _finish),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                    child: OnboardingBottomControls(
                      controller: _controller,
                      pageCount: _pages.length,
                      ctaLabel: _pages[state.currentPage].ctaLabel,
                      onPressed: () => _next(state),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
