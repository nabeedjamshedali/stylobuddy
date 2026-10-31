import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/clothing_item.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/demo_note.dart';
import '../../../shared/widgets/garment_image.dart';
import '../models/style_result.dart';
import '../stylist_tokens.dart';
import 'muted_text.dart';

/// `.od-footnote`; honours the global demo-note switch.
class DetailFootnote extends StatelessWidget {
  const DetailFootnote({super.key, this.source = StyleResultSource.algorithm});

  /// Who produced the active look; decides which honest wording shows.
  final StyleResultSource source;

  @override
  Widget build(BuildContext context) {
    if (!kShowDemoNotes) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Text(
        source == StyleResultSource.ai
            ? 'Styled by AI from the pieces in your wardrobe.'
            : 'Outfit selections and styling explanations are simulated for design review.',
        textAlign: TextAlign.center,
        style: AppTextStyles.dmSans(
          size: 9,
          height: 1.5,
          color: StylistTokens.odFootnote,
        ),
      ),
    );
  }
}

/// Body of the "Plan this outfit" modal: day grid 15..31.
class PlanModalBody extends StatelessWidget {
  const PlanModalBody({
    super.key,
    required this.outfitName,
    required this.chosenDay,
    required this.onPick,
  });

  static const days = [
    15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, //
  ];

  final String outfitName;
  final int chosenDay;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text.rich(
          TextSpan(
            style: AppTextStyles.dmSans(
              size: 12,
              color: AppColors.muted,
              height: 1.6,
            ),
            children: [
              const TextSpan(text: 'Choose a date in October 2026 for '),
              TextSpan(
                text: outfitName,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const TextSpan(text: '.'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        for (var start = 0; start < days.length; start += 6) ...[
          if (start > 0) const SizedBox(height: 7),
          Row(
            children: [
              for (var c = 0; c < 6; c++) ...[
                if (c > 0) const SizedBox(width: 7),
                Expanded(
                  child: start + c < days.length
                      ? _Day(
                          day: days[start + c],
                          chosen: days[start + c] == chosenDay,
                          onTap: () => onPick(days[start + c]),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ],
        const SizedBox(height: 14),
      ],
    );
  }
}

class _Day extends StatelessWidget {
  const _Day({required this.day, required this.chosen, required this.onTap});

  final int day;
  final bool chosen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: chosen
              ? StylistTokens.odDayChosenBg
              : StylistTokens.odDayBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: chosen ? StylistTokens.odSave : StylistTokens.odLightBorder,
          ),
        ),
        child: Text(
          '$day',
          style: AppTextStyles.dmSans(size: 13, color: StylistTokens.odDayInk),
        ),
      ),
    );
  }
}

/// Body of the swap modal (alternatives from the same category).
class SwapModalBody extends StatelessWidget {
  const SwapModalBody({
    super.key,
    required this.category,
    required this.alternatives,
    required this.onPick,
  });

  final String category;
  final List<ClothingItem> alternatives;
  final ValueChanged<ClothingItem> onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MutedText(
          'Choose another ${category.toLowerCase()} from your wardrobe. Your other pieces will stay the same.',
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 310),
          child: GridView.count(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.2,
            children: [
              for (final it in alternatives)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onPick(it),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: StylistTokens.odSwapCardBorder),
                    ),
                    child: Column(
                      children: [
                        Expanded(child: GarmentImage(id: it.imageId)),
                        const SizedBox(height: 7),
                        Text(
                          it.name,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.dmSans(
                            size: 10,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Body of the "Share this look" modal.
class ShareModalBody extends StatelessWidget {
  const ShareModalBody({super.key, required this.summary, required this.onCopy});

  final String summary;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MutedText(
          'Copy the outfit details below and share them with someone.',
        ),
        Container(
          constraints: const BoxConstraints(minHeight: 150),
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: StylistTokens.odShareBorder),
          ),
          child: SelectableText(
            summary,
            style: AppTextStyles.dmSans(size: 11, height: 1.6),
          ),
        ),
        PrimaryButton(label: 'Copy look details', onPressed: onCopy),
      ],
    );
  }
}
