import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../packing_tokens.dart';

/// Prototype `.pk-form textarea`: 'Activities or notes'.
class PkTextArea extends StatelessWidget {
  const PkTextArea({
    super.key,
    required this.label,
    required this.controller,
    required this.placeholder,
  });

  final String label;
  final TextEditingController controller;
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
          minLines: 3,
          maxLines: 6,
          style: AppTextStyles.dmSans(size: 12, color: PackingTokens.formInk),
          decoration: InputDecoration(
            isDense: true,
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
      ],
    );
  }
}
