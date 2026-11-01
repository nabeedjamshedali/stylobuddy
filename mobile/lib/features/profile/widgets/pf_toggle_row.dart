import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../profile_tokens.dart';

/// Prototype `prefRow(label,description,enabled,handler)`, `P/app.js:270`.
class PfToggleRow extends StatelessWidget {
  const PfToggleRow({
    super.key,
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 17),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTextStyles.dmSans(
                    size: 10,
                    color: ProfileTokens.menuSubtitle,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 15),
          Checkbox(
            value: value,
            onChanged: (v) => onChanged(v ?? false),
            activeColor: ProfileTokens.toggleAccent,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}
