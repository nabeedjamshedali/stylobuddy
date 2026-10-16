import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../profile_tokens.dart';

/// Prototype `.pf-form label` + `.pf-form input`.
class PfTextField extends StatelessWidget {
  const PfTextField({
    super.key,
    required this.label,
    required this.controller,
    this.maxLength,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final int? maxLength;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLength: maxLength,
          keyboardType: keyboardType,
          style: AppTextStyles.dmSans(size: 12, color: ProfileTokens.formInk),
          decoration: InputDecoration(
            isDense: true,
            counterText: '',
            filled: true,
            fillColor: AppColors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 13),
            constraints: const BoxConstraints(minHeight: 46),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: ProfileTokens.formBorder),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: ProfileTokens.formBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: ProfileTokens.formFocusBorder),
            ),
          ),
        ),
      ],
    );
  }
}
