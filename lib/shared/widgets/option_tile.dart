import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'shared_tokens.dart';

/// Prototype `.option`: radio-style selectable row with optional description.
class OptionTile extends StatelessWidget {
  const OptionTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.description,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: selected ? SharedTokens.optionSelectedBg : AppColors.white,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: selected ? AppColors.green : SharedTokens.fieldBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? AppColors.green
                      : SharedTokens.optionRadioBorder,
                  width: selected ? 5 : 1,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.dmSans(size: 12)),
                  if (description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      description!,
                      style: AppTextStyles.dmSans(
                          size: 12, color: SharedTokens.optionDescription),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
