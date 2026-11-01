import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../stylist_tokens.dart';

/// `.od-eyebrow`, `.od-heading` (index, name, tagline) and the heart button.
class DetailHeading extends StatelessWidget {
  const DetailHeading({
    super.key,
    required this.index,
    required this.total,
    required this.name,
    required this.onSave,
  });

  final int index;
  final int total;
  final String name;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 15),
          child: Text(
            'STYLOBUDDY / THE STYLE EDIT',
            style: AppTextStyles.dmSans(
              size: 9,
              weight: FontWeight.w800,
              letterSpacing: 2.1,
              color: StylistTokens.odEyebrow,
            ),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    // Prototype pads the index but not the total ("OF 3").
                    'LOOK ${(index + 1).toString().padLeft(2, '0')} OF $total',
                    style: AppTextStyles.dmSans(
                      size: 10,
                      weight: FontWeight.w700,
                      letterSpacing: 1.3,
                      color: StylistTokens.odIndex,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 6),
                    child: Text(
                      name,
                      style: AppTextStyles.dmSans(
                        size: 25,
                        weight: FontWeight.w700,
                        height: 1.18,
                        letterSpacing: -.9,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'A complete look, styled from your own wardrobe.',
                      style: AppTextStyles.dmSans(
                        size: 11,
                        height: 1.6,
                        color: StylistTokens.odSub,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Semantics(
              button: true,
              label: 'Save outfit',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onSave,
                child: Container(
                  width: 35,
                  height: 35,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: StylistTokens.odHeartBorder),
                  ),
                  child: Text(
                    '♡',
                    style: AppTextStyles.dmSans(
                      size: 23,
                      color: StylistTokens.odHeartInk,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
