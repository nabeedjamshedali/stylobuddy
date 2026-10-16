import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/outfit.dart';
import '../../../shared/models/wear_event.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../builder/cubit/builder_cubit.dart';
import '../../wardrobe/cubit/wardrobe_cubit.dart';
import '../cubit/outfits_cubit.dart';
import '../cubit/saved_view_cubit.dart';
import '../saved_tokens.dart';
import '../widgets/sl_empty_state.dart';
import '../widgets/sl_footer_actions.dart';
import '../widgets/sl_look_card.dart';
import '../widgets/sl_search_field.dart';
import '../widgets/sl_stats.dart';
import '../widgets/sl_tabs.dart';
import '../widgets/sl_wear_card.dart';

/// Prototype `pages.saved`. [initialTab] preselects a tab (e.g. from
/// Insights' "View wear history" link) without disturbing normal in-shell
/// navigation, which keeps the tab the user last picked.
class SavedView extends StatefulWidget {
  const SavedView({super.key, this.initialTab});

  final String? initialTab;

  @override
  State<SavedView> createState() => _SavedViewState();
}

class _SavedViewState extends State<SavedView> {
  @override
  void initState() {
    super.initState();
    final tab = widget.initialTab;
    if (tab != null) {
      context.read<SavedViewCubit>().setTab(tab);
    }
  }

  @override
  Widget build(BuildContext context) {
    final outfitsState = context.watch<OutfitsCubit>().state;
    final viewState = context.watch<SavedViewCubit>().state;
    final wardrobe = context.watch<WardrobeCubit>();
    final view = context.read<SavedViewCubit>();
    final outfits = context.read<OutfitsCubit>();

    final query = viewState.search.trim().toLowerCase();
    final matchingOutfits = [
      for (final o in outfitsState.outfits)
        if (_matchesOutfit(o, query, wardrobe)) o,
    ];
    final matchingEvents = [
      for (final e in outfits.wearEvents())
        if (_matchesEvent(e, query)) e,
    ];
    final saved = viewState.tab == 'Saved';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'YOUR STYLE ARCHIVE',
            style: AppTextStyles.dmSans(
              size: 9,
              weight: FontWeight.w800,
              letterSpacing: 1.6,
              color: SavedTokens.kicker,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        style: AppTextStyles.manrope(
                          size: 29,
                          weight: FontWeight.w700,
                          letterSpacing: -1.2,
                        ),
                        children: [
                          const TextSpan(text: 'My Looks'),
                          TextSpan(
                            text: '.',
                            style: AppTextStyles.manrope(
                              size: 29,
                              weight: FontWeight.w700,
                              letterSpacing: -1.2,
                              color: SavedTokens.greenAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Everything you love wearing, in one place.',
                      style: AppTextStyles.dmSans(
                        size: 11,
                        height: 1.6,
                        color: SavedTokens.subtitle,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  Text(
                    '${outfitsState.outfits.length}',
                    style: AppTextStyles.dmSans(
                      size: 21,
                      weight: FontWeight.w800,
                      color: SavedTokens.total,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'saved looks',
                    style: AppTextStyles.dmSans(
                      size: 9,
                      color: SavedTokens.totalLabel,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 19),
          SlStats(
            saved: outfitsState.outfits.length,
            wearsLogged: outfitsState.wearLog.length,
            wornLooks: outfitsState.outfits.where((o) => o.worn > 0).length,
          ),
          const SizedBox(height: 23),
          SlTabs(tab: viewState.tab, onSelect: view.setTab),
          const SizedBox(height: 16),
          SlSearchField(
            value: viewState.search,
            placeholder:
                saved ? 'Search your looks' : 'Search wear history',
            onChanged: view.setSearch,
          ),
          const SizedBox(height: 20),
          if (saved)
            _SavedList(
              outfits: matchingOutfits,
              searching: query.isNotEmpty,
              onOpen: (id) => context.push(AppRoutes.savedDetail(id)),
              onExplore: () => context.push(AppRoutes.stylist),
            )
          else
            _HistoryList(
              events: matchingEvents,
              searching: query.isNotEmpty,
              onOpen: (e) => context.push(
                AppRoutes.wearDetail(e.id, outfitId: e.outfitId),
              ),
              onBrowseSaved: () => view.setTab('Saved'),
            ),
          const SizedBox(height: 22),
          SlFooterActions(
            onCreateLook: () {
              context.read<BuilderCubit>().start();
              context.push(AppRoutes.builder);
            },
            onGetRecommendations: () => context.push(AppRoutes.stylist),
          ),
        ],
      ),
    );
  }

  bool _matchesOutfit(Outfit o, String query, WardrobeCubit wardrobe) {
    if (query.isEmpty) return true;
    final itemNames = o.items
        .map((id) => wardrobe.itemOrFallback(id).name)
        .join(' ');
    return '${o.name} ${o.occasion} $itemNames'.toLowerCase().contains(query);
  }

  bool _matchesEvent(WearEvent e, String query) {
    if (query.isEmpty) return true;
    return '${e.name} ${e.occasion}'.toLowerCase().contains(query);
  }
}

class _SavedList extends StatelessWidget {
  const _SavedList({
    required this.outfits,
    required this.searching,
    required this.onOpen,
    required this.onExplore,
  });

  final List<Outfit> outfits;
  final bool searching;
  final ValueChanged<int> onOpen;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Saved collection',
              style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w700),
            ),
            Text(
              '${outfits.length} looks',
              style: AppTextStyles.dmSans(
                size: 9,
                color: SavedTokens.listCount,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (outfits.isEmpty)
          SlEmptyState(
            icon: '♡',
            title: searching ? 'No matching outfits' : 'Your looks start here',
            body: searching
                ? 'Try a different search.'
                : 'Save an AI recommendation or build your own outfit to '
                    'begin your collection.',
            action: searching
                ? null
                : PrimaryButton(
                    label: 'Explore AI Stylist',
                    onPressed: onExplore,
                    fullWidth: false,
                  ),
          )
        else
          Column(
            children: [
              for (var i = 0; i < outfits.length; i += 2) ...[
                if (i > 0) const SizedBox(height: 12),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _cell(outfits[i])),
                      const SizedBox(width: 12),
                      Expanded(
                        child: i + 1 < outfits.length
                            ? _cell(outfits[i + 1])
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
      ],
    );
  }

  Widget _cell(Outfit o) => SlLookCard(
    items: o.items,
    name: o.name,
    occasion: o.occasion,
    worn: o.worn,
    onTap: () => onOpen(o.id),
  );
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({
    required this.events,
    required this.searching,
    required this.onOpen,
    required this.onBrowseSaved,
  });

  final List<WearEvent> events;
  final bool searching;
  final ValueChanged<WearEvent> onOpen;
  final VoidCallback onBrowseSaved;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Outfits you wore',
              style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w700),
            ),
            Text(
              '${events.length} entries',
              style: AppTextStyles.dmSans(
                size: 9,
                color: SavedTokens.listCount,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (events.isEmpty)
          SlEmptyState(
            icon: '✓',
            title: searching
                ? 'No matching entries'
                : 'Your outfit diary starts here',
            body: searching
                ? null
                : 'Open a saved look and tap “Mark as Worn” to build your '
                    'personal style history.',
            action: searching
                ? null
                : SecondaryButton(
                    label: 'Browse saved looks',
                    onPressed: onBrowseSaved,
                    fullWidth: false,
                  ),
          )
        else
          Column(
            children: [
              for (final e in events) ...[
                SlWearCard(
                  firstItemId: e.items.isNotEmpty ? e.items.first : '',
                  timestamp: e.timestamp,
                  name: e.name,
                  occasion: e.occasion,
                  pieceCount: e.items.length,
                  onTap: () => onOpen(e),
                ),
                if (e != events.last) const SizedBox(height: 10),
              ],
            ],
          ),
      ],
    );
  }
}

