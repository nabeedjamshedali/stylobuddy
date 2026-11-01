import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'shared_tokens.dart';

/// Prototype `selectField()`: `.field` label above a bordered dropdown.
class SelectField extends StatelessWidget {
  const SelectField({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final List<String> options;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: SharedTokens.fieldBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                isDense: true,
                dropdownColor: AppColors.white,
                borderRadius: BorderRadius.circular(11),
                style: AppTextStyles.dmSans(size: 12),
                items: [
                  for (final o in {...options, value})
                    DropdownMenuItem(value: o, child: Text(o)),
                ],
                onChanged: (v) {
                  if (v != null) onChanged(v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
