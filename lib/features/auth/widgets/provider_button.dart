import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../auth_tokens.dart';

/// Prototype `.ob-auth-btn`: outlined row with a 24px icon slot and a label.
/// An empty [glyph] keeps the slot blank (the prototype's Apple icon).
class ProviderButton extends StatelessWidget {
  const ProviderButton({
    super.key,
    required this.glyph,
    required this.label,
    required this.onTap,
    this.glyphColor = AuthTokens.providerIcon,
  });

  final String glyph;
  final String label;
  final VoidCallback onTap;
  final Color glyphColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AuthTokens.providerBorder),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: Text(
                  glyph,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.dmSans(
                    size: 15,
                    weight: FontWeight.w700,
                    color: glyphColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: AppTextStyles.dmSans(
                  size: 12,
                  color: AuthTokens.providerInk,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `.ob-auth-divider`: hairline, "or", hairline.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    const line = Expanded(
      child: ColoredBox(color: AuthTokens.divider, child: SizedBox(height: 1)),
    );
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 14),
      child: Row(
        children: [
          line,
          const SizedBox(width: 12),
          Text(
            'or',
            style: AppTextStyles.dmSans(size: 11, color: AuthTokens.dividerInk),
          ),
          const SizedBox(width: 12),
          line,
        ],
      ),
    );
  }
}
