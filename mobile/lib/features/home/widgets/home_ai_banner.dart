import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../home_tokens.dart';

/// Prototype `.h-ai-banner`.
class HomeAiBanner extends StatelessWidget {
  const HomeAiBanner({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: HomeTokens.bannerBg,
          border: Border.all(color: HomeTokens.bannerBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Text('✦', style: TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Have a few items in mind?',
                    style: AppTextStyles.dmSans(
                      size: 11,
                      weight: FontWeight.w700,
                      color: HomeTokens.bannerInk,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Let AI find the best matching combination.',
                    style: AppTextStyles.dmSans(
                      size: 9.5,
                      height: 1.4,
                      color: HomeTokens.bannerSub,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '→',
              style: AppTextStyles.dmSans(
                size: 18,
                color: HomeTokens.bannerInk,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
