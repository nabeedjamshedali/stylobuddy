import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../wardrobe/cubit/wardrobe_cubit.dart';
import '../../../shared/widgets/garment_image.dart';
import '../matching_tokens.dart';

/// Prototype `.mm-selection-summary`: "N selected" and a hint line.
class MmSelectionSummary extends StatelessWidget {
  const MmSelectionSummary({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: MatchingTokens.summaryBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$count selected',
            style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w700),
          ),
          Flexible(
            child: Text(
              count > 0
                  ? 'Your chosen pieces are shown below'
                  : 'Start with a shirt, trousers or dress',
              textAlign: TextAlign.right,
              style: AppTextStyles.dmSans(
                size: 10,
                color: MatchingTokens.summarySub,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Prototype `.mm-selection-strip`: a mini thumbnail per selected id, with a
/// '◆' badge on locked ones. Absent (not just empty) when nothing is
/// selected.
class MmSelectionStrip extends StatelessWidget {
  const MmSelectionStrip({
    super.key,
    required this.ids,
    required this.locked,
  });

  final List<String> ids;
  final Set<String> locked;

  @override
  Widget build(BuildContext context) {
    if (ids.isEmpty) return const SizedBox.shrink();
    final wardrobe = context.watch<WardrobeCubit>();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 3),
      child: SizedBox(
        height: 54,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: ids.length,
          separatorBuilder: (_, _) => const SizedBox(width: 7),
          itemBuilder: (context, i) {
            final id = ids[i];
            return Container(
              width: 54,
              height: 54,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: MatchingTokens.miniBg,
                border: Border.all(color: MatchingTokens.miniBorder),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: GarmentImage(id: wardrobe.itemOrFallback(id).imageId),
                  ),
                  if (locked.contains(id))
                    Positioned(
                      top: 1,
                      right: 1,
                      child: Text(
                        '◆',
                        style: AppTextStyles.dmSans(
                          size: 12,
                          color: MatchingTokens.miniLock,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
