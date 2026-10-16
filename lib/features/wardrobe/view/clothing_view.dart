import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/clothing_item.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/app_modal.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/garment_image.dart';
import '../../../shared/widgets/screen_head.dart';
import '../../stylist/cubit/stylist_cubit.dart';
import '../cubit/wardrobe_cubit.dart';
import '../wardrobe_tokens.dart';

/// Prototype `pages.clothing`: one item's details, reached as `/clothing?id=`.
class ClothingView extends StatelessWidget {
  const ClothingView({super.key, required this.id});

  final String id;

  void _findMatches(BuildContext context) {
    context.read<StylistCubit>().selectAndLock(id);
    context.push(AppRoutes.matchReview);
  }

  void _openMenu(BuildContext context) {
    AppModal.show(
      context,
      title: 'Clothing options',
      body: Builder(
        builder: (dialogContext) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _MenuAction(
              label: 'Edit clothing details',
              onTap: () {
                AppModal.close(dialogContext);
                context.push(AppRoutes.editItemFor(id));
              },
            ),
            const SizedBox(height: 9),
            _MenuAction(
              label: 'Remove this item',
              onTap: () {
                AppModal.close(dialogContext);
                _confirmRemove(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRemove(BuildContext context) {
    AppModal.show(
      context,
      title: 'Remove clothing?',
      body: Builder(
        builder: (dialogContext) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'This item will be removed from your wardrobe. Saved looks '
              'that used it may need adjusting.',
              style: AppTextStyles.dmSans(size: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 17),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'Cancel',
                    onPressed: () => AppModal.close(dialogContext),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DangerButton(
                    label: 'Remove item',
                    onPressed: () => _removeItem(context, dialogContext),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _removeItem(BuildContext context, BuildContext dialogContext) {
    context.read<WardrobeCubit>().removeItem(id);
    AppModal.close(dialogContext);
    AppToast.show(context, 'Item removed');
    context.go(AppRoutes.wardrobe);
  }

  @override
  Widget build(BuildContext context) {
    final item = context.watch<WardrobeCubit>().itemOrFallback(id);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScreenHead(
            title: 'Clothing Details',
            fallbackRoute: AppRoutes.wardrobe,
            action: Semantics(
              label: 'More clothing options',
              button: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _openMenu(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    border: Border.all(color: WardrobeTokens.moreButtonBorder),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  child: Text(
                    '⋯',
                    style: AppTextStyles.dmSans(
                      size: 18,
                      color: WardrobeTokens.moreButtonInk,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Stack(
            children: [
              Container(
                height: 280,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: WardrobeTokens.detailPhotoBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                clipBehavior: Clip.antiAlias,
                child: Center(child: GarmentImage(id: item.imageId)),
              ),
              Positioned(
                left: 11,
                bottom: 11,
                child: Container(
                  decoration: BoxDecoration(
                    color: WardrobeTokens.photoLabelBg,
                    border: Border.all(color: WardrobeTokens.photoLabelBorder),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  child: Text(
                    'IN MY WARDROBE',
                    style: AppTextStyles.dmSans(
                      size: 8,
                      weight: FontWeight.w800,
                      letterSpacing: 1,
                      color: WardrobeTokens.photoLabelInk,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 19),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.category,
                      style: AppTextStyles.dmSans(
                        size: 9,
                        weight: FontWeight.w800,
                        letterSpacing: 1.35,
                        color: WardrobeTokens.eyebrow,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      item.name,
                      style: AppTextStyles.manrope(
                        size: 23,
                        weight: FontWeight.w700,
                        letterSpacing: -0.8,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => context.push(AppRoutes.editItemFor(id)),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    border: Border.all(color: WardrobeTokens.moreButtonBorder),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  child: Text(
                    '✎',
                    style: AppTextStyles.dmSans(
                      size: 18,
                      color: WardrobeTokens.moreButtonInk,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _Attributes(item: item),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: WardrobeTokens.detailNoteBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Style this piece',
                  style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  'Find complete looks built around this item, using '
                  'clothes and accessories you already own.',
                  style: AppTextStyles.dmSans(
                    size: 11,
                    color: WardrobeTokens.detailNoteBody,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 17),
          PrimaryButton(
            label: '✧ Find matching outfits',
            onPressed: () => _findMatches(context),
          ),
          const SizedBox(height: 10),
          SecondaryButton(
            label: 'Edit item details',
            onPressed: () => context.push(AppRoutes.editItemFor(id)),
          ),
          const SizedBox(height: 18),
          Center(
            child: GestureDetector(
              onTap: () => _confirmRemove(context),
              child: Text(
                'Remove from wardrobe',
                style: AppTextStyles.dmSans(
                  size: 11,
                  color: WardrobeTokens.removeInk,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Attributes extends StatelessWidget {
  const _Attributes({required this.item});

  final ClothingItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: WardrobeTokens.attributesBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _Attr('COLOR', item.color, right: true, bottom: true),
              ),
              Expanded(
                child: _Attr('OCCASION', item.occasion, bottom: true),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _Attr('TIMES WORN', '${item.wears}', right: true),
              ),
              Expanded(child: _Attr('SEASON', item.season)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Attr extends StatelessWidget {
  const _Attr(
    this.label,
    this.value, {
    this.right = false,
    this.bottom = false,
  });

  final String label;
  final String value;
  final bool right;
  final bool bottom;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          right: right
              ? const BorderSide(color: WardrobeTokens.attributesBorder)
              : BorderSide.none,
          bottom: bottom
              ? const BorderSide(color: WardrobeTokens.attributesBorder)
              : BorderSide.none,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.dmSans(
              size: 9,
              letterSpacing: 1,
              color: WardrobeTokens.attributeLabel,
            ),
          ),
          const SizedBox(height: 7),
          Text(value, style: AppTextStyles.dmSans(size: 12)),
        ],
      ),
    );
  }
}

class _MenuAction extends StatelessWidget {
  const _MenuAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: WardrobeTokens.actionBorder),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text('$label →', style: AppTextStyles.dmSans(size: 12)),
      ),
    );
  }
}
