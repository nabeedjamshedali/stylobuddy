import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../wardrobe_tokens.dart';

/// Prototype `.w-actions`: '+ Add clothing' / 'Build outfit ↗'.
class WardrobeActionRow extends StatelessWidget {
  const WardrobeActionRow({
    super.key,
    required this.onAddClothing,
    required this.onBuildOutfit,
  });

  final VoidCallback onAddClothing;
  final VoidCallback onBuildOutfit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 56,
          child: _ActionButton(
            onTap: onAddClothing,
            background: WardrobeTokens.addBg,
            foreground: AppColors.white,
            borderColor: WardrobeTokens.addBg,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '＋ ',
                    style: AppTextStyles.dmSans(
                      size: 18,
                      color: AppColors.white,
                    ),
                  ),
                  TextSpan(
                    text: 'Add clothing',
                    style: AppTextStyles.dmSans(
                      size: 11,
                      weight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 50,
          child: _ActionButton(
            onTap: onBuildOutfit,
            background: AppColors.white,
            foreground: WardrobeTokens.buildInk,
            borderColor: WardrobeTokens.buildBorder,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Build outfit ',
                    style: AppTextStyles.dmSans(
                      size: 11,
                      weight: FontWeight.w700,
                      color: WardrobeTokens.buildInk,
                    ),
                  ),
                  TextSpan(
                    text: '↗',
                    style: AppTextStyles.dmSans(
                      size: 11,
                      color: WardrobeTokens.buildInk,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.onTap,
    required this.background,
    required this.foreground,
    required this.borderColor,
    required this.child,
  });

  final VoidCallback onTap;
  final Color background;
  final Color foreground;
  final Color borderColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: borderColor),
          ),
          child: child,
        ),
      ),
    );
  }
}
