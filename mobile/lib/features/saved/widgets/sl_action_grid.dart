import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../saved_tokens.dart';

/// Prototype `.sl-action-grid`: Plan outfit / Edit look / Share.
class SlActionGrid extends StatelessWidget {
  const SlActionGrid({
    super.key,
    required this.onPlan,
    required this.onEdit,
    required this.onShare,
  });

  final VoidCallback onPlan;
  final VoidCallback onEdit;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(icon: '▦', label: 'Plan outfit', onTap: onPlan),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionButton(icon: '✎', label: 'Edit look', onTap: onEdit),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionButton(icon: '↗', label: 'Share', onTap: onShare),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final String icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
          decoration: BoxDecoration(
            border: Border.all(color: SavedTokens.actionBorder),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(
                icon,
                style: AppTextStyles.dmSans(
                  size: 18,
                  color: SavedTokens.actionInk,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTextStyles.dmSans(
                  size: 10,
                  color: SavedTokens.actionLabel,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
