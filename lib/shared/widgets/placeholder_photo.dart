import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Stand-in for a real photograph/illustration asset. The reference shot's
/// hero photos are copyrighted stock/AI-generated images we can't
/// reproduce — this renders a styled placeholder (gradient block + icon)
/// in the same position/shape so the layout is final and a real asset
/// can drop straight in later. See docs note shared with the team about
/// swapping these for real assets.
class PlaceholderPhoto extends StatelessWidget {
  final IconData icon;
  final BorderRadius borderRadius;
  final List<Color>? gradientOverride;

  const PlaceholderPhoto({
    super.key,
    required this.icon,
    this.borderRadius = BorderRadius.zero,
    this.gradientOverride,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradientOverride ??
                const [
                  Color(0xFF3A2E27),
                  Color(0xFF221A15),
                ],
          ),
        ),
        child: Center(
          child: Icon(
            icon,
            size: 56,
            color: AppColors.textMuted.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}
