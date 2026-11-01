import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/look_board.dart';
import '../matching_tokens.dart';

/// Prototype `.mm-intro`: kicker, sample board, headline and description,
/// all centered.
class MmIntro extends StatelessWidget {
  const MmIntro({super.key});

  static const sampleIds = [
    'white-shirt',
    'navy-chinos',
    'brown-loafers',
    'black-watch',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 22, 6, 14),
      child: Column(
        children: [
          Text(
            'YOUR WARDROBE, BETTER TOGETHER',
            textAlign: TextAlign.center,
            style: AppTextStyles.dmSans(
              size: 9,
              weight: FontWeight.w800,
              letterSpacing: 1.5,
              color: MatchingTokens.kicker,
            ),
          ),
          const SizedBox(height: 16),
          const SizedBox(
            width: 245,
            child: LookBoard(ids: sampleIds, size: LookBoardSize.third),
          ),
          const SizedBox(height: 22),
          Text(
            'Find the pieces that belong together.',
            textAlign: TextAlign.center,
            style: AppTextStyles.manrope(
              size: 22,
              weight: FontWeight.w800,
              height: 1.3,
              letterSpacing: -.7,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose a few options, lock anything you definitely want to '
            'wear, and discover looks made entirely from your wardrobe.',
            textAlign: TextAlign.center,
            style: AppTextStyles.dmSans(
              size: 12,
              height: 1.6,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Prototype `.mm-steps`: the three numbered onboarding steps.
class MmSteps extends StatelessWidget {
  const MmSteps({super.key});

  static const _steps = [
    (
      '01',
      'Select your candidates',
      'Pick tops, bottoms, dresses and layers to compare.',
    ),
    (
      '02',
      'Lock your must-wear pieces',
      'Required garments stay in every suggested look.',
    ),
    (
      '03',
      'Get your best three matches',
      'Complete outfits with owned footwear and accessories.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 22),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: MatchingTokens.stepsBorder),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          for (var i = 0; i < _steps.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: i == 0
                  ? null
                  : const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: MatchingTokens.stepsDivider),
                      ),
                    ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _steps[i].$1,
                    style: AppTextStyles.dmSans(
                      size: 13,
                      color: MatchingTokens.stepNumber,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _steps[i].$2,
                          style: AppTextStyles.dmSans(
                            size: 12,
                            weight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _steps[i].$3,
                          style: AppTextStyles.dmSans(
                            size: 10,
                            height: 1.5,
                            color: MatchingTokens.stepCaption,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
