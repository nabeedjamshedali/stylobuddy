import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../builder_tokens.dart';

/// Prototype `.mb-form`: outfit name field and 'Best for' occasion select.
class MbForm extends StatelessWidget {
  const MbForm({
    super.key,
    required this.nameController,
    required this.occasion,
    required this.occasionOptions,
    required this.onOccasionChanged,
  });

  static const defaultName = 'My custom look';

  final TextEditingController nameController;
  final String occasion;
  final List<String> occasionOptions;
  final ValueChanged<String> onOccasionChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Outfit name',
            style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: nameController,
            maxLength: 60,
            style: AppTextStyles.dmSans(size: 12),
            decoration: InputDecoration(
              isDense: true,
              counterText: '',
              hintText: 'e.g. Friday smart casual',
              contentPadding: const EdgeInsets.all(12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(color: BuilderTokens.fieldBorder),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(color: BuilderTokens.fieldBorder),
              ),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            'Best for',
            style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: BuilderTokens.fieldBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: occasion,
                isExpanded: true,
                isDense: true,
                dropdownColor: AppColors.white,
                borderRadius: BorderRadius.circular(9),
                style: AppTextStyles.dmSans(size: 12),
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
