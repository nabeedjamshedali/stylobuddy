import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../calendar_tokens.dart';

/// Prototype `.cp-secondary-actions`: 'View saved looks ↗' / 'Ask AI for a
/// look' text buttons.
class CalendarSecondaryActions extends StatelessWidget {
  const CalendarSecondaryActions({
    super.key,
    required this.onViewSaved,
    required this.onAskAi,
  });

  final VoidCallback onViewSaved;
  final VoidCallback onAskAi;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 17),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: GestureDetector(
              onTap: onViewSaved,
              child: Text(
                'View saved looks ↗',
                style: AppTextStyles.dmSans(
                  size: 10,
                  color: CalendarTokens.secondaryInk,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: GestureDetector(
              onTap: onAskAi,
              child: Text(
                '✧ Ask AI for a look',
                style: AppTextStyles.dmSans(
                  size: 10,
                  color: CalendarTokens.secondaryInk,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
