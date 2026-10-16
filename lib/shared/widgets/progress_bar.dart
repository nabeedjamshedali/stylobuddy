import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'shared_tokens.dart';

/// Prototype `.progress`; [value] is 0..1.
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({super.key, required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 6,
        child: ColoredBox(
          color: SharedTokens.progressTrack,
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: value.clamp(0.0, 1.0),
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.green,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
