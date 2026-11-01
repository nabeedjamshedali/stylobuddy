import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/clothing_item.dart';
import '../../../shared/widgets/demo_note.dart';
import '../../../shared/widgets/screen_head.dart';
import '../../saved/cubit/outfits_cubit.dart';
import '../../wardrobe/cubit/wardrobe_cubit.dart';
import '../insights_tokens.dart';
import '../models/insight_stats.dart';
import '../widgets/in_bars_card.dart';
import '../widgets/in_callout.dart';
import '../widgets/in_empty_state.dart';
import '../widgets/in_garment_row.dart';
import '../widgets/in_mix_card.dart';
import '../widgets/in_occasions_card.dart';
import '../widgets/in_section_head.dart';
import '../widgets/in_stat_cards.dart';
import '../widgets/in_wear_activity_card.dart';

/// Prototype `pages.insights`, `P/app.js:331`.
class InsightsView extends StatelessWidget {
  const InsightsView({super.key});

  @override
  Widget build(BuildContext context) {
    final items = context.watch<WardrobeCubit>().state.items;
    final wearLog = context.watch<OutfitsCubit>().state.wearLog;
    final stats = InsightStats.from(items);

    if (stats.count == 0) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ScreenHead(title: 'Style Insights', fallbackRoute: AppRoutes.profile),
            InEmptyState(onAddClothing: () => context.push(AppRoutes.import)),
          ],
        ),
      );
    }

    final unused = stats.count - stats.worn;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 7, 20, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'YOUR PERSONAL STYLE REPORT',
            style: AppTextStyles.dmSans(
              size: 9,
              weight: FontWeight.w800,
              letterSpacing: 1.7,
              color: InsightsTokens.kicker,
            ),
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              style: AppTextStyles.manrope(size: 27, weight: FontWeight.w700, letterSpacing: -1.4),
              children: [
                const TextSpan(text: 'Style Insights'),
                TextSpan(
                  text: '.',
                  style: AppTextStyles.manrope(
                    size: 27,
                    weight: FontWeight.w700,
                    letterSpacing: -1.4,
                    color: InsightsTokens.headingSpan,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'A clearer picture of what you own and wear.',
            style: AppTextStyles.dmSans(size: 11, color: InsightsTokens.headingBody),
          ),
          const SizedBox(height: 18),
          InStatCards(
            wardrobe: stats.count,
            loggedWears: wearLog.length,
            everWorn: stats.worn,
          ),
          InSectionHead(title: 'Your wardrobe mix', caption: '${stats.cats.length} categories'),
          InMixCard(cats: stats.cats, count: stats.count),
          InSectionHead(title: 'Category breakdown', caption: 'Items owned'),
          InBarsCard(cats: stats.cats),
          InSectionHead(title: 'Wear activity', caption: 'Recorded manually'),
          InWearActivityCard(
            worn: stats.worn,
            count: stats.count,
            unused: unused,
            onViewHistory: () => context.push('${AppRoutes.saved}?tab=History'),
          ),
          InSectionHead(title: 'Most-worn pieces', caption: 'Top items'),
          Column(
            children: [
              for (final it in stats.top.take(4)) ...[
                InGarmentRow(
                  itemId: it.id,
                  name: it.name,
                  subtitle: '${it.wears} recorded wears · ${it.category}',
                  onTap: () => context.push(AppRoutes.clothing(it.id)),
                ),
                if (it != stats.top.take(4).last) const SizedBox(height: 8),
              ],
            ],
          ),
          InSectionHead(title: 'Rediscover your wardrobe', caption: 'Underused pieces'),
          Column(
            children: [
              for (final it in _underused(stats)) ...[
                InGarmentRow(
                  itemId: it.id,
                  name: it.name,
                  subtitle: '${it.wears} recorded wears · Try styling this piece',
                  onTap: () => context.push(AppRoutes.clothing(it.id)),
                ),
                if (it != _underused(stats).last) const SizedBox(height: 8),
              ],
            ],
          ),
          InSectionHead(title: 'Occasion readiness', caption: 'Wardrobe labels'),
          InOccasionsCard(occasions: stats.occasions),
          InCallout(onMatch: () => context.push(AppRoutes.matching)),
          const DemoNote(
            'Insights are based on wardrobe details and manually recorded '
            'wears. No external fashion model is connected in this demo.',
            style: DemoNoteStyle.intro,
          ),
        ],
      ),
    );
  }

  /// `d.least.length ? d.least : d.top.slice().reverse().slice(0,4)`
  /// (`P/app.js:339`).
  List<ClothingItem> _underused(InsightStats stats) {
    if (stats.least.isNotEmpty) return stats.least;
    return stats.top.reversed.take(4).toList();
  }
}
