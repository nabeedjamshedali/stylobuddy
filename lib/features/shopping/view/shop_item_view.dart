import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/demo_note.dart';
import '../../../shared/widgets/screen_head.dart';
import '../../wardrobe/cubit/wardrobe_cubit.dart';
import '../cubit/shopping_cubit.dart';
import '../cubit/shopping_state.dart';
import '../shopping_catalog.dart';
import '../shopping_tokens.dart';
import '../widgets/sh_art.dart';
import '../widgets/sh_owned_grid.dart';
import '../widgets/sh_tip_card.dart';

/// Prototype `pages['shop-item']`.
class ShopItemView extends StatelessWidget {
  const ShopItemView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ShoppingCubit>();
    final wardrobeItems = context.watch<WardrobeCubit>().state.items;
    return BlocBuilder<ShoppingCubit, ShoppingState>(
      builder: (context, state) {
        final entry = ShoppingCatalog.byId(state.selectedId);
        final saved = state.wishlist.contains(entry.id);
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ScreenHead(
                title: 'Wardrobe Suggestion',
                fallbackRoute: AppRoutes.shopping,
              ),
              SizedBox(
                height: 212,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: ShArt(id: entry.id, symbolSize: 83),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 19),
                child: Text(
                  entry.tag.toUpperCase(),
                  style: AppTextStyles.dmSans(
                    size: 9,
                    weight: FontWeight.w800,
                    color: ShoppingTokens.eyebrow,
                    letterSpacing: 1.8,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 9, bottom: 5),
                child: Text(
                  entry.title,
                  style: AppTextStyles.dmSans(
                    size: 23,
                    weight: FontWeight.w700,
                    height: 1.2,
                    letterSpacing: -.6,
                  ),
                ),
              ),
              Text(
                '${entry.tone} · ${entry.category}',
                style: AppTextStyles.dmSans(
                  size: 11,
                  color: ShoppingTokens.detailTone,
                ),
              ),
              _block('Why it could help', entry.description),
              Padding(
                padding: const EdgeInsets.only(top: 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Style with what you own',
                      style: AppTextStyles.dmSans(
                        size: 13,
                        weight: FontWeight.w700,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      child: Text(
                        'Pieces already in your wardrobe that could work '
                        'well with this addition:',
                        style: AppTextStyles.dmSans(
                          size: 11,
                          color: ShoppingTokens.detailMuted,
                          height: 1.65,
                        ),
                      ),
                    ),
                    ShOwnedGrid(pairIds: entry.pair, items: wardrobeItems),
                  ],
                ),
              ),
              ShTipCard(text: entry.tip),
              PrimaryButton(
                label: saved ? '✓ Saved · Remove from wishlist' : '♡ Save to wishlist',
                onPressed: () {
                  final added = cubit.toggleWishlist(entry.id);
                  AppToast.show(
                    context,
                    added ? 'Added to wishlist' : 'Removed from wishlist',
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: SecondaryButton(
                  label: 'I bought something like this · Add to wardrobe',
                  onPressed: () {
                    cubit.select(entry.id);
                    context.push(AppRoutes.import);
                  },
                ),
              ),
              DemoNote(
                'These are category-level suggestions, not real store '
                'products or guaranteed AI compatibility scores.',
                style: DemoNoteStyle.share,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _block(String title, String body) => Padding(
    padding: const EdgeInsets.only(top: 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w700)),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Text(
            body,
            style: AppTextStyles.dmSans(
              size: 11,
              color: ShoppingTokens.detailMuted,
              height: 1.65,
            ),
          ),
        ),
      ],
    ),
  );
}
