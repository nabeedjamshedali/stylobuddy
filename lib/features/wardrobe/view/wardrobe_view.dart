import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../shared/models/clothing_item.dart';
import '../cubit/wardrobe_browse_cubit.dart';
import '../cubit/wardrobe_browse_state.dart';
import '../cubit/wardrobe_cubit.dart';
import '../cubit/wardrobe_state.dart';
import '../widgets/wardrobe_action_row.dart';
import '../widgets/wardrobe_ai_action.dart';
import '../widgets/wardrobe_category_chips.dart';
import '../widgets/wardrobe_grid.dart';
import '../widgets/wardrobe_header.dart';
import '../widgets/wardrobe_search.dart';
import '../widgets/wardrobe_section_header.dart';
import '../widgets/wardrobe_stats.dart';

/// Prototype `pages.wardrobe`.
class WardrobeView extends StatelessWidget {
  const WardrobeView({super.key});

  @override
  Widget build(BuildContext context) {
    final wardrobeState = context.watch<WardrobeCubit>().state;
    final browseState = context.watch<WardrobeBrowseCubit>().state;
    final browse = context.read<WardrobeBrowseCubit>();
    final items = wardrobeState.items;
    final filtered = _filtered(wardrobeState, browseState);
    final searching = browseState.search.isNotEmpty;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WardrobeHeader(onFilter: () => context.push(AppRoutes.filter)),
          const SizedBox(height: 15),
          WardrobeStats(items: items),
          const SizedBox(height: 15),
          WardrobeActionRow(
            onAddClothing: () => context.push(AppRoutes.import),
            onBuildOutfit: () => context.push(AppRoutes.builder),
          ),
          const SizedBox(height: 15),
          WardrobeSearchField(
            value: browseState.search,
            onChanged: browse.setSearch,
          ),
          const SizedBox(height: 12),
          WardrobeCategoryChips(
            selected: browseState.filter,
            onSelect: browse.setFilter,
          ),
          const SizedBox(height: 7),
          WardrobeSectionHeader(
            title: browseState.filter == 'All'
                ? 'All clothing'
                : browseState.filter,
            count: filtered.length,
            onFilter: () => context.push(AppRoutes.filter),
          ),
          const SizedBox(height: 13),
          filtered.isEmpty
              ? WardrobeEmptyState(
                  searching: searching,
                  onAction: () {
                    if (searching) {
                      browse.clearSearch();
                    } else {
                      context.push(AppRoutes.import);
                    }
                  },
                )
              : WardrobeGrid(
                  items: filtered,
                  onTap: (id) => context.push(AppRoutes.clothing(id)),
                ),
          const SizedBox(height: 20),
          WardrobeAiAction(onTap: () => context.push(AppRoutes.matching)),
        ],
      ),
    );
  }

  List<ClothingItem> _filtered(
    WardrobeState wardrobe,
    WardrobeBrowseState browse,
  ) {
    final search = browse.search.toLowerCase();
    return [
      for (final item in wardrobe.items)
        if ((browse.filter == 'All' || item.category == browse.filter) &&
            item.name.toLowerCase().contains(search))
          item,
    ];
  }
}
