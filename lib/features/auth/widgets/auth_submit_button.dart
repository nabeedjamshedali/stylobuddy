import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Prototype `.auth-submit`: centered label with a trailing arrow pinned
/// 17px from the right edge. Semantics read "<label> →".
class AuthSubmitButton extends StatelessWidget {
  const AuthSubmitButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.topMargin = 6,
  });

  final String label;
  final VoidCallback onPressed;
  final double topMargin;

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.dmSans(
      size: 12,
      weight: FontWeight.w700,
      color: AppColors.white,
    );
    return Padding(
      padding: EdgeInsets.only(top: topMargin),
      child: Semantics(
        button: true,
        label: '$label →',
        excludeSemantics: true,
        onTap: onPressed,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onPressed,
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.brandGreen,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(label, style: style),
                Positioned(
                  right: 17,
                  child: Text(
                    '→',
                    style: style.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
