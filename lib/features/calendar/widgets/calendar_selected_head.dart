import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../calendar_tokens.dart';

/// Prototype `.cp-selected-head`: 'SELECTED DATE' label + value, with an
/// optional 'Remove' button when a plan exists.
class CalendarSelectedHead extends StatelessWidget {
  const CalendarSelectedHead({
    super.key,
    required this.label,
    this.onRemove,
  });

  final String label;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SELECTED DATE',
                style: AppTextStyles.dmSans(
                  size: 9,
                  weight: FontWeight.w700,
                  letterSpacing: 1,
                  color: CalendarTokens.monthLabel,
                ),
              ),
              const SizedBox(height: 4),
              Text(label, style: AppTextStyles.dmSans(size: 16)),
            ],
          ),
          if (onRemove != null)
            GestureDetector(
              onTap: onRemove,
              child: Text(
                'Remove',
                style: AppTextStyles.dmSans(
                  size: 11,
                  color: CalendarTokens.removeInk,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
