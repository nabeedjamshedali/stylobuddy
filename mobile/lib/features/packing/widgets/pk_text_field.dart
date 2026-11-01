import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../packing_tokens.dart';

/// Prototype `.pk-form label` + `.pk-form input`: a single-line text field.
class PkTextField extends StatelessWidget {
  const PkTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.maxLength,
    required this.placeholder,
  });

  final String label;
  final TextEditingController controller;
  final int maxLength;
  final String placeholder;

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
        TextField(
          controller: controller,
          maxLength: maxLength,
          style: AppTextStyles.dmSans(size: 12, color: PackingTokens.formInk),
          decoration: InputDecoration(
            isDense: true,
            counterText: '',
            hintText: placeholder,
            filled: true,
            fillColor: AppColors.white,
            contentPadding: const EdgeInsets.all(12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: PackingTokens.formBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: PackingTokens.formBorder),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: PackingTokens.formBorder),
            ),
          ),
        ),
        const SizedBox(height: 7),
      ],
    );
  }
}
