import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../profile_tokens.dart';

/// Prototype `menuRow(symbol,title,subtitle,route)`, `P/app.js:271`.
class PfMenuRow extends StatelessWidget {
  const PfMenuRow({
    super.key,
    required this.symbol,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String symbol;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              Container(
                width: 33,
                height: 33,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ProfileTokens.menuIconBg,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  symbol,
                  style: const TextStyle(
                    fontSize: 18,
                    color: ProfileTokens.menuIconInk,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.dmSans(
                        size: 12,
                        weight: FontWeight.w700,
                        color: ProfileTokens.menuRowInk,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTextStyles.dmSans(
                        size: 10,
                        color: ProfileTokens.menuSubtitle,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                '›',
                style: TextStyle(fontSize: 23, color: ProfileTokens.chevron),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
