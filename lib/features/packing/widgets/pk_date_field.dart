import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../packing_tokens.dart';

/// Prototype `.pk-dates input[type=date]`: tapping opens the native date
/// picker; shows the raw `yyyy-MM-dd` value, blank when unset.
class PkDateField extends StatelessWidget {
  const PkDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;

  /// `yyyy-MM-dd`, or `''` when unset.
  final String value;
  final ValueChanged<String> onChanged;

  Future<void> _pick(BuildContext context) async {
    final initial = value.isEmpty ? DateTime.now() : DateTime.tryParse(value);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      final iso =
          '${picked.year.toString().padLeft(4, '0')}-'
          '${picked.month.toString().padLeft(2, '0')}-'
          '${picked.day.toString().padLeft(2, '0')}';
      onChanged(iso);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => _pick(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(color: PackingTokens.formBorder),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              value,
              style: AppTextStyles.dmSans(size: 10, color: PackingTokens.formInk),
            ),
          ),
        ),
      ],
    );
  }
}
