import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../calendar_tokens.dart';

const _dayNames = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];

/// Prototype `.cp-calendar` (`.cp-daynames` + `.cp-days`): day-of-week
/// labels, leading blanks, and one button per day of the month.
class CalendarDaysGrid extends StatelessWidget {
  const CalendarDaysGrid({
    super.key,
    required this.daysInMonth,
    required this.leadingBlanks,
    required this.activeDay,
    required this.isPlanned,
    required this.monthLabel,
    required this.onSelect,
  });

  final int daysInMonth;
  final int leadingBlanks;
  final int activeDay;
  final bool Function(int day) isPlanned;
  final String monthLabel;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 13),
      decoration: BoxDecoration(
        border: Border.all(color: CalendarTokens.monthBorder),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(13)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              for (final name in _dayNames)
                Expanded(
                  child: Center(
                    child: Text(
                      name,
                      style: AppTextStyles.dmSans(
                        size: 10,
                        weight: FontWeight.w700,
                        color: CalendarTokens.dayName,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 3,
            crossAxisSpacing: 3,
            childAspectRatio: 1.1,
            children: [
              for (var i = 0; i < leadingBlanks; i++) const CalendarBlankCell(),
              for (var day = 1; day <= daysInMonth; day++)
                CalendarDayButton(
                  day: day,
                  monthLabel: monthLabel,
                  active: day == activeDay,
                  planned: isPlanned(day),
                  onTap: () => onSelect(day),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Prototype `.cp-blank`: an empty leading cell before day 1.
class CalendarBlankCell extends StatelessWidget {
  const CalendarBlankCell({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Exposed for tests to count rendered day buttons.
class CalendarDayButton extends StatelessWidget {
  const CalendarDayButton({
    super.key,
    required this.day,
    required this.monthLabel,
    required this.active,
    required this.planned,
    required this.onTap,
  });

  final int day;
  final String monthLabel;
  final bool active;
  final bool planned;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$day $monthLabel',
      button: true,
      selected: active,
      child: Material(
        color: active ? CalendarTokens.dayActiveBg : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                '$day',
                style: AppTextStyles.dmSans(
                  size: 11,
                  weight: active ? FontWeight.w800 : FontWeight.w400,
                  color: active ? AppColors.white : CalendarTokens.dayInk,
                ),
              ),
              if (planned)
                Positioned(
                  bottom: 5,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active ? AppColors.white : CalendarTokens.dayMarker,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
