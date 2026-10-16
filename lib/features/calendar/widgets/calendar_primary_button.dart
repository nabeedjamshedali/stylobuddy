import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../calendar_tokens.dart';

/// Prototype `.cp-primary`: full-width button with a trailing arrow, used
/// for 'Plan an outfit' / 'Change planned outfit' / 'Confirm outfit plan'.
class CalendarPrimaryButton extends StatelessWidget {
  const CalendarPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CalendarTokens.primaryBg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
          child: Text(
            '$label →',
            textAlign: TextAlign.center,
            style: AppTextStyles.dmSans(
              size: 12,
              weight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
        ),
      ),
    );
  }
}
