import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../profile/cubit/profile_cubit.dart';
import '../../profile/cubit/profile_state.dart';
import '../../stylist/cubit/stylist_cubit.dart';
import '../../wardrobe/cubit/wardrobe_cubit.dart';
import '../../wardrobe/cubit/wardrobe_state.dart';
import '../home_tokens.dart';
import '../widgets/home_ai_banner.dart';
import '../widgets/home_explore_grid.dart';
import '../widgets/home_header.dart';
import '../widgets/home_recent_grid.dart';
import '../widgets/home_shortcuts.dart';
import '../widgets/home_suggestion_card.dart';

/// Prototype `pages.home`: the dashboard.
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  void _viewOutfits(BuildContext context) {
    final stylist = context.read<StylistCubit>();
    stylist.setOccasion('Everyday');
    stylist.generateAutomatic();
    context.push(AppRoutes.generating);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BlocBuilder<ProfileCubit, ProfileState>(
            buildWhen: (a, b) => a.name != b.name,
            builder: (context, state) => HomeHeader(name: state.name),
          ),
          const SizedBox(height: 21),
          Text(
            'QUICK ACTIONS',
            style: AppTextStyles.dmSans(
              size: 10,
              weight: FontWeight.w700,
              letterSpacing: 0.3,
              color: HomeTokens.ink,
            ),
          ),
          const SizedBox(height: 10),
          const HomeShortcuts(),
          const SizedBox(height: 23),
          HomeSuggestionCard(onViewOutfits: () => _viewOutfits(context)),
          const SizedBox(height: 12),
          HomeAiBanner(onTap: () => context.push(AppRoutes.matching)),
          const SizedBox(height: 23),
          BlocBuilder<WardrobeCubit, WardrobeState>(
            buildWhen: (a, b) => a.items != b.items,
            builder: (context, state) =>
                HomeRecentGrid(items: state.items.take(4).toList()),
          ),
          const SizedBox(height: 18),
          Text(
            'Explore more',
            style: AppTextStyles.dmSans(
              size: 13,
              weight: FontWeight.w700,
              color: HomeTokens.ink,
            ),
          ),
          const SizedBox(height: 11),
          const HomeExploreGrid(),
        ],
      ),
    );
  }
}
