import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../calendar_tokens.dart';

/// Prototype `.cp-form`: date input (defaults to the selected key) and the
/// occasion select.
class CalendarDateForm extends StatelessWidget {
  const CalendarDateForm({
    super.key,
    required this.dateValue,
    required this.initialDate,
    required this.onDateChanged,
    required this.occasion,
    required this.occasionOptions,
    required this.onOccasionChanged,
  });

  final String dateValue;
  final DateTime initialDate;
  final ValueChanged<DateTime> onDateChanged;
  final String occasion;
  final List<String> occasionOptions;
  final ValueChanged<String> onOccasionChanged;

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) onDateChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Date',
            style: AppTextStyles.dmSans(
              size: 11,
              weight: FontWeight.w600,
              color: CalendarTokens.formLabel,
            ),
          ),
          const SizedBox(height: 9),
          GestureDetector(
            onTap: () => _pickDate(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(color: CalendarTokens.formBorder),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                dateValue,
                style: AppTextStyles.dmSans(
                  size: 12,
                  color: CalendarTokens.formInk,
                ),
              ),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            'Occasion',
            style: AppTextStyles.dmSans(
              size: 11,
              weight: FontWeight.w600,
              color: CalendarTokens.formLabel,
            ),
          ),
          const SizedBox(height: 9),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(color: CalendarTokens.formBorder),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: occasion,
                isExpanded: true,
                isDense: true,
                dropdownColor: AppColors.white,
                borderRadius: BorderRadius.circular(10),
                style: AppTextStyles.dmSans(
                  size: 12,
                  color: CalendarTokens.formInk,
                ),
                items: [
                  for (final o in {...occasionOptions, occasion})
                    DropdownMenuItem(value: o, child: Text(o)),
                ],
                onChanged: (v) {
                  if (v != null) onOccasionChanged(v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
