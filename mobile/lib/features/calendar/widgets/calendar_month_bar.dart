import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../calendar_tokens.dart';

/// Prototype `.cp-month`: 'YOUR MONTH' label + month name, with prev/next
/// controls.
class CalendarMonthBar extends StatelessWidget {
  const CalendarMonthBar({
    super.key,
    required this.monthLabel,
    required this.onPrevious,
    required this.onNext,
  });

  final String monthLabel;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 17),
      decoration: BoxDecoration(
        border: Border.all(color: CalendarTokens.monthBorder),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'YOUR MONTH',
                style: AppTextStyles.dmSans(
                  size: 9,
                  weight: FontWeight.w700,
                  letterSpacing: 1,
                  color: CalendarTokens.monthLabel,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                monthLabel,
                style: AppTextStyles.dmSans(
                  size: 16,
                  weight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          Row(
            children: [
              _MonthButton(
                label: '‹',
                semanticLabel: 'Previous month',
                onTap: onPrevious,
              ),
              const SizedBox(width: 8),
              _MonthButton(
                label: '›',
                semanticLabel: 'Next month',
                onTap: onNext,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MonthButton extends StatelessWidget {
  const _MonthButton({
    required this.label,
    required this.semanticLabel,
    required this.onTap,
  });

  final String label;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      child: Material(
        color: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: CalendarTokens.monthControlBorder),
        ),
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 30,
            height: 30,
            child: Center(
              child: Text(label, style: AppTextStyles.dmSans(size: 22)),
            ),
          ),
        ),
      ),
    );
  }
}
