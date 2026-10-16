import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../calendar_tokens.dart';

/// Prototype `.cp-alt`: '+ Build a new outfit' / '✧ Generate an AI outfit'.
class CalendarAltButton extends StatelessWidget {
  const CalendarAltButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: CalendarTokens.altBg,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onPressed,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: CalendarTokens.altBorder),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.dmSans(
                size: 11,
                weight: FontWeight.w600,
                color: CalendarTokens.altInk,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
