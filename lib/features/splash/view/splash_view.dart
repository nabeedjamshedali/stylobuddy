import 'package:flutter/material.dart';

import '../../../shared/widgets/gradient_backdrop.dart';
import '../../onboarding/view/onboarding_view.dart';
import '../widgets/splash_logo.dart';

/// First screen shown on launch. Displays the brand lockup over the
/// signature warm-glow backdrop, then auto-advances into onboarding.
class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingView()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackdrop(
        glowAlignment: Alignment.center,
        child: const Center(child: SplashLogo()),
      ),
    );
  }
}
