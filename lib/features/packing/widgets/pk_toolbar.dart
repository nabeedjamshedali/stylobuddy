import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../packing_tokens.dart';

/// Prototype `.pk-toolbar`: '✎ Edit trip' / '＋ Add items'.
class PkToolbar extends StatelessWidget {
  const PkToolbar({
    super.key,
    required this.onEdit,
    required this.onAddItems,
  });

  final VoidCallback onEdit;
  final VoidCallback onAddItems;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: _ToolbarButton(label: '✎ Edit trip', onTap: onEdit)),
          const SizedBox(width: 8),
          Expanded(
            child: _ToolbarButton(label: '＋ Add items', onTap: onAddItems),
          ),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            border: Border.all(color: PackingTokens.toolbarBorder),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.dmSans(
              size: 11,
              color: PackingTokens.toolbarInk,
            ),
          ),
        ),
      ),
    );
  }
}
