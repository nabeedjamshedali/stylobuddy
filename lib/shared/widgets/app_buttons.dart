import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'shared_tokens.dart';

class _AppButton extends StatelessWidget {
  const _AppButton({
    required this.label,
    required this.onPressed,
    required this.fullWidth,
    required this.background,
    required this.foreground,
    required this.radius,
    required this.padding,
    required this.textStyle,
    this.borderColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool fullWidth;
  final Color background;
  final Color foreground;
  final double radius;
  final EdgeInsets padding;
  final TextStyle textStyle;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: borderColor == null
          ? BorderSide.none
          : BorderSide(color: borderColor!),
    );
    final button = Opacity(
      opacity: onPressed == null ? .45 : 1,
      child: Material(
        color: background,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: padding,
            child: Center(
              widthFactor: 1,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: textStyle.copyWith(color: foreground),
              ),
            ),
          ),
        ),
      ),
    );
    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Prototype `.primary` (v2 override: flat #08775A, radius 9, 14/16 padding).
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) => _AppButton(
    label: label,
    onPressed: onPressed,
    fullWidth: fullWidth,
    background: AppColors.primaryButton,
    foreground: AppColors.white,
    radius: 9,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    textStyle: AppTextStyles.dmSans(size: 12, weight: FontWeight.w700),
  );
}

/// Prototype `.secondary` (radius 11, 12/15 padding, green text and border).
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) => _AppButton(
    label: label,
    onPressed: onPressed,
    fullWidth: fullWidth,
    background: AppColors.white,
    foreground: AppColors.green,
    borderColor: SharedTokens.secondaryBorder,
    radius: 11,
    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
    textStyle: AppTextStyles.dmSans(size: 12, weight: FontWeight.w700),
  );
}

/// Prototype `.danger` (red text, pink border, radius 10, 10px padding).
class DangerButton extends StatelessWidget {
  const DangerButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) => _AppButton(
    label: label,
    onPressed: onPressed,
    fullWidth: fullWidth,
    background: AppColors.white,
    foreground: SharedTokens.dangerInk,
    borderColor: SharedTokens.dangerBorder,
    radius: 10,
    padding: const EdgeInsets.all(10),
    textStyle: AppTextStyles.dmSans(size: 14),
  );
}
