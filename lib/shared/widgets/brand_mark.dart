import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_text_styles.dart';
import 'shared_tokens.dart';

/// Hanger logo + "StyloBuddy" wordmark (`.ob-brand`).
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.iconSize = 38, this.fontSize = 24});

  final double iconSize;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.string(
          SharedTokens.hangerSvg,
          width: iconSize,
          height: iconSize,
        ),
        SizedBox(width: fontSize / 3),
        Text(
          'StyloBuddy',
          style: AppTextStyles.dmSans(
            size: fontSize,
            weight: FontWeight.w500,
            color: SharedTokens.brandInk,
            letterSpacing: -fontSize / 20,
          ),
        ),
      ],
    );
  }
}
