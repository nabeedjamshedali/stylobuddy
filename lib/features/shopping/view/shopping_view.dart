import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/screen_head.dart';
import '../../wardrobe/cubit/wardrobe_cubit.dart';
import '../cubit/shopping_cubit.dart';
import '../cubit/shopping_state.dart';
import '../shopping_catalog.dart';
import '../shopping_tokens.dart';
import '../widgets/sh_empty_card.dart';
import '../widgets/sh_intro.dart';
import '../widgets/sh_phase_card.dart';
import '../widgets/sh_section_head.dart';
import '../widgets/sh_suggestion_card.dart';
import '../widgets/sh_tabs.dart';

/// Prototype `pages.shopping`.
class ShoppingView extends StatelessWidget {
  const ShoppingView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ShoppingCubit>();
    final wardrobeItems = context.watch<WardrobeCubit>().state.items;
    return BlocBuilder<ShoppingCubit, ShoppingState>(
      builder: (context, state) {
        final suggestions = ShoppingCatalog.suggestionsFor(wardrobeItems);
        final saved = [for (final id in state.wishlist) ShoppingCatalog.byId(id)];
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ScreenHead(
                title: 'Shopping Assistant',
                fallbackRoute: AppRoutes.home,
              ),
              const ShIntro(),
              ShTabs(
                tab: state.tab,
                discoverCount: suggestions.length,
                wishlistCount: state.wishlist.length,
                onSelect: cubit.setTab,
              ),
              if (state.tab == 'discover') ...[
                ShSectionHead(
                  title: 'Consider for your wardrobe',
                  count: 'Illustrative analysis',
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 14),
                  child: _IntroNote(),
                ),
                if (suggestions.isEmpty)
                  const ShEmptyCard(
                    title: 'Your wardrobe covers these categories',
                    body:
                        'Explore your clothing collection or return when '
                        'you add more items.',
                  )
                else
                  Column(
                    children: [
                      for (final entry in suggestions)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 11),
                          child: ShSuggestionCard(
                            entry: entry,
                            onTap: () {
                              cubit.select(entry.id);
                              context.push(AppRoutes.shopItem);
                            },
                          ),
                        ),
                    ],
                  ),
              ] else ...[
                ShSectionHead(
                  title: 'Your shopping wishlist',
                  count: '${saved.length} saved',
                ),
                if (saved.isEmpty)
                  ShEmptyCard(
                    icon: '♡',
                    title: 'Nothing saved yet',
                    body:
                        'Explore suggestions and save ideas you want to '
                        'remember.',
                    actionLabel: 'Explore suggestions',
                    onAction: () => cubit.setTab('discover'),
                  )
                else
                  Column(
                    children: [
                      for (final entry in saved)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 11),
                          child: ShSuggestionCard(
                            entry: entry,
                            onTap: () {
                              cubit.select(entry.id);
                              context.push(AppRoutes.shopItem);
                            },
                          ),
                        ),
                    ],
                  ),
              ],
              const ShPhaseCard(),
            ],
          ),
        );
      },
    );
  }
}

class _IntroNote extends StatelessWidget {
  const _IntroNote();

  @override
  Widget build(BuildContext context) {
    return Text(
      'These are sample wardrobe-gap ideas based on clothing '
      'categories—not live AI recommendations.',
      style: AppTextStyles.dmSans(
        size: 10.5,
        color: ShoppingTokens.introNote,
        height: 1.5,
      ),
    );
  }
}
