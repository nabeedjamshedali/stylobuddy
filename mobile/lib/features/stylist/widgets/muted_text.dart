import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Prototype `p.muted` (12px, muted, line-height 1.6).
class MutedText extends StatelessWidget {
  const MutedText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: AppTextStyles.dmSans(size: 12, color: AppColors.muted, height: 1.6),
  );
}
