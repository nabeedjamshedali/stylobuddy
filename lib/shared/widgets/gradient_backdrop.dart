import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// The warm radial "glow fading to black" backdrop used behind the splash
/// screen and every onboarding page in the reference design.
class GradientBackdrop extends StatelessWidget {
  final Widget child;
  final Alignment glowAlignment;

  const GradientBackdrop({
    super.key,
    required this.child,
    this.glowAlignment = const Alignment(0, -0.4),
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: glowAlignment,
          radius: 1.2,
          colors: AppColors.heroGradient,
          stops: const [0.0, 0.35, 0.7, 1.0],
        ),
      ),
      child: child,
    );
  }
}
