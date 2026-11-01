import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../saved_tokens.dart';

/// Prototype `.sl-footer-action`: 'Create a look' / 'Get AI recommendations'.
class SlFooterActions extends StatelessWidget {
  const SlFooterActions({
    super.key,
    required this.onCreateLook,
    required this.onGetRecommendations,
  });

  final VoidCallback onCreateLook;
  final VoidCallback onGetRecommendations;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _FooterButton(label: '＋ Create a look', onTap: onCreateLook),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _FooterButton(
            label: '✧ Get AI recommendations',
            onTap: onGetRecommendations,
          ),
        ),
      ],
    );
  }
}

class _FooterButton extends StatelessWidget {
  const _FooterButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SavedTokens.footerBg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            border: Border.all(color: SavedTokens.footerBorder),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.dmSans(
              size: 10,
              weight: FontWeight.w600,
              color: SavedTokens.footerInk,
            ),
          ),
        ),
      ),
    );
  }
}
