import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/clothing_item.dart';
import '../../../shared/widgets/garment_image.dart';
import '../builder_tokens.dart';

/// Prototype `.mb-summary-row`: icon, name/category and a `Change` button.
class MbSummaryRow extends StatelessWidget {
  const MbSummaryRow({super.key, required this.item, required this.onChange});

  final ClothingItem item;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: BuilderTokens.summaryRowBorder),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: BuilderTokens.summaryIconBg,
              borderRadius: BorderRadius.circular(9),
            ),
            clipBehavior: Clip.antiAlias,
            child: Center(child: GarmentImage(id: item.imageId)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.category} · ${item.color}',
                  style: AppTextStyles.dmSans(
                    size: 9,
                    color: BuilderTokens.summarySub,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: onChange,
            child: Text(
              'Change',
              style: AppTextStyles.dmSans(
                size: 10,
                color: BuilderTokens.summaryChange,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
