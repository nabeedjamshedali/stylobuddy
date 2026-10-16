import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/garment_image.dart';
import '../home_tokens.dart';

/// Prototype `.h-suggestion`: "Today's suggestion" card.
class HomeSuggestionCard extends StatelessWidget {
  const HomeSuggestionCard({super.key, required this.onViewOutfits});

  final VoidCallback onViewOutfits;

  static const _mainGarment = 'white-shirt';
  static const _sideGarments = ['navy-chinos', 'white-sneakers', 'black-watch'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                "Today's suggestion",
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.dmSans(
                  size: 13,
                  weight: FontWeight.w700,
                  color: HomeTokens.ink,
                ),
              ),
            ),
            Text(
              '✧ AI selected',
              style: AppTextStyles.dmSans(
                size: 9,
                weight: FontWeight.w700,
                color: HomeTokens.matchLabel,
              ),
            ),
          ],
        ),
        const SizedBox(height: 11),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: HomeTokens.suggestionBorder),
            borderRadius: BorderRadius.circular(14),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 13, 14, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        '☀ Everyday · Smart casual',
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.dmSans(
                          size: 10,
                          weight: FontWeight.w600,
                          color: HomeTokens.occasion,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'From your wardrobe',
                      style: AppTextStyles.dmSans(
                        size: 9,
                        weight: FontWeight.w700,
                        color: HomeTokens.score,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(13, 2, 13, 9),
                child: SizedBox(
                  height: 172,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 118,
                        child: _GarmentBox(id: _mainGarment),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 100,
                        child: Column(
                          children: [
                            Expanded(child: _GarmentBox(id: _sideGarments[0])),
                            const SizedBox(height: 7),
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _GarmentBox(id: _sideGarments[1]),
                                  ),
                                  const SizedBox(width: 7),
                                  Expanded(
                                    child: _GarmentBox(id: _sideGarments[2]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(13, 11, 13, 13),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: HomeTokens.suggestionDivider),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Clean & effortless',
                            style: AppTextStyles.dmSans(
                              size: 12,
                              weight: FontWeight.w700,
                              color: HomeTokens.ink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'A crisp shirt, tailored chinos and everyday '
                            'essentials.',
                            style: AppTextStyles.dmSans(
                              size: 9.5,
                              height: 1.55,
                              color: HomeTokens.suggestionBody,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 7),
                    GestureDetector(
                      onTap: onViewOutfits,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: HomeTokens.wearBtnBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'View outfits →',
                          style: AppTextStyles.dmSans(
                            size: 10,
                            weight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GarmentBox extends StatelessWidget {
  const _GarmentBox({required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: HomeTokens.outfitBoardBg,
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: GarmentImage(id: id),
    );
  }
}
