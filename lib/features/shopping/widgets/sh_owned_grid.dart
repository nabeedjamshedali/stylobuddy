import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/clothing_item.dart';
import '../../../shared/widgets/garment_image.dart';
import '../shopping_tokens.dart';

/// Prototype `.sh-owned`: pieces already in the wardrobe that pair with a
/// suggestion. Ids not present in [items] are omitted, never shown as a
/// placeholder (F11-A12).
class ShOwnedGrid extends StatelessWidget {
  const ShOwnedGrid({super.key, required this.pairIds, required this.items});

  final List<String> pairIds;
  final List<ClothingItem> items;

  @override
  Widget build(BuildContext context) {
    final owned = [
      for (final id in pairIds)
        for (final item in items)
          if (item.id == id) item,
    ];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: .72,
      children: [
        for (final item in owned)
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: ShoppingTokens.ownedBg,
              border: Border.all(color: ShoppingTokens.ownedBorder),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 83, child: GarmentImage(id: item.imageId)),
                const SizedBox(height: 6),
                Text(
                  item.name,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.dmSans(
                    size: 9,
                    color: ShoppingTokens.ownedName,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
