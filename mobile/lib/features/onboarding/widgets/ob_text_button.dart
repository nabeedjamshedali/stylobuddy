import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';

/// Bare text button used for `.ob-plain`, `.ob-back` and the `Skip` link.
class ObTextButton extends StatelessWidget {
  const ObTextButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.size,
    required this.color,
    this.padding = const EdgeInsets.all(9),
  });

  final String label;
  final VoidCallback onTap;
  final double size;
  final Color color;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: padding,
        child: Text(
          label,
          style: AppTextStyles.dmSans(size: size, color: color),
        ),
      ),
    );
  }
}
