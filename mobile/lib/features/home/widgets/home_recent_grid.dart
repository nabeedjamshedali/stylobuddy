import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/clothing_item.dart';
import '../../../shared/widgets/garment_image.dart';
import '../../../shared/widgets/section_title.dart';
import '../home_tokens.dart';

/// Prototype `.h-recent-grid`: up to 4 of the newest wardrobe items.
class HomeRecentGrid extends StatelessWidget {
  const HomeRecentGrid({super.key, required this.items});

  final List<ClothingItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          title: 'Recently added',
          linkLabel: 'See all',
          onLink: () => context.push(AppRoutes.wardrobe),
        ),
        if (items.isNotEmpty)
          Row(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: _RecentTile(item: items[i])),
              ],
            ],
          ),
      ],
    );
  }
}

class _RecentTile extends StatelessWidget {
  const _RecentTile({required this.item});

  final ClothingItem item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push(AppRoutes.clothing(item.id)),
      child: Column(
        children: [
          Container(
            height: 78,
            width: double.infinity,
            decoration: BoxDecoration(
              color: HomeTokens.recentPhotoBg,
              borderRadius: BorderRadius.circular(10),
            ),
            clipBehavior: Clip.antiAlias,
            child: GarmentImage(id: item.imageId),
          ),
          const SizedBox(height: 7),
          Text(
            item.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.dmSans(
              size: 9,
              height: 1.25,
              color: HomeTokens.recentName,
            ),
          ),
        ],
      ),
    );
  }
}
