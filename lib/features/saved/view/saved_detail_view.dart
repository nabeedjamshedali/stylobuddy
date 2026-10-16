import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/outfit.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/app_modal.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/look_board.dart';
import '../../../shared/widgets/screen_head.dart';
import '../../builder/cubit/builder_cubit.dart';
import '../../calendar/cubit/planner_cubit.dart';
import '../../wardrobe/cubit/wardrobe_cubit.dart';
import '../cubit/outfits_cubit.dart';
import '../cubit/saved_view_cubit.dart';
import '../saved_tokens.dart';
import '../widgets/sl_action_grid.dart';
import '../widgets/sl_garment_row.dart';

/// Prototype `pages['saved-detail']`.
class SavedDetailView extends StatelessWidget {
  const SavedDetailView({super.key, required this.id});

  final int? id;

  @override
  Widget build(BuildContext context) {
    final outfit = id != null ? context.watch<OutfitsCubit>().byId(id!) : null;

    if (outfit == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ScreenHead(
              title: 'Saved Outfit',
              fallbackRoute: AppRoutes.saved,
            ),
            Text(
              'This outfit is no longer saved.',
              style: AppTextStyles.dmSans(size: 15, weight: FontWeight.w700),
            ),
            const SizedBox(height: 15),
            PrimaryButton(
              label: 'Back to my looks',
              onPressed: () => context.go(AppRoutes.saved),
              fullWidth: false,
            ),
          ],
        ),
      );
    }

    final wardrobe = context.watch<WardrobeCubit>();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ScreenHead(
            title: 'Outfit Details',
            fallbackRoute: AppRoutes.saved,
          ),
          Text(
            'SAVED / ${outfit.occasion.toUpperCase()}',
            style: AppTextStyles.dmSans(
              size: 9,
              weight: FontWeight.w800,
              letterSpacing: 1.6,
              color: SavedTokens.kicker,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            outfit.name,
            style: AppTextStyles.dmSans(
              size: 25,
              weight: FontWeight.w700,
              letterSpacing: -.8,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'An outfit made from ${outfit.items.length} pieces in your '
            'wardrobe.',
            style: AppTextStyles.dmSans(
              size: 11,
              height: 1.6,
              color: SavedTokens.subtitle,
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 19),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: SavedTokens.heroBg,
              border: Border.all(color: SavedTokens.heroBorder),
              borderRadius: BorderRadius.circular(14),
            ),
            child: LookBoard(
              ids: outfit.items,
              size: LookBoardSize.large,
              minHeight: 210,
              padding: EdgeInsets.zero,
              imageHeight: 120,
            ),
          ),
          Row(
            children: [
              _Tag(text: outfit.occasion),
              const SizedBox(width: 7),
              _Tag(text: '${outfit.worn} wears logged'),
            ],
          ),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pieces in this look',
                style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w700),
              ),
              Text(
                '${outfit.items.length} ITEMS',
                style: AppTextStyles.dmSans(
                  size: 9,
                  color: SavedTokens.listCount,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: [
              for (final itemId in outfit.items) ...[
                SlGarmentRow(
                  imageId: wardrobe.itemOrFallback(itemId).imageId,
                  name: wardrobe.itemOrFallback(itemId).name,
                  subtitle:
                      '${wardrobe.itemOrFallback(itemId).category} · '
                      '${wardrobe.itemOrFallback(itemId).color}',
                  onTap: () => context.push(AppRoutes.clothing(itemId)),
                ),
                if (itemId != outfit.items.last) const SizedBox(height: 8),
              ],
            ],
          ),
          const SizedBox(height: 23),
          if (outfit.why.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 22),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: SavedTokens.noteBg,
                border: Border.all(color: SavedTokens.noteBorder),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '✧ THE STYLE NOTE',
                    style: AppTextStyles.dmSans(
                      size: 9,
                      weight: FontWeight.w700,
                      letterSpacing: 1,
                      color: SavedTokens.noteLabel,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    outfit.why,
                    style: AppTextStyles.dmSans(
                      size: 11,
                      height: 1.7,
                      color: SavedTokens.noteBody,
                    ),
                  ),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Style journal',
                style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w700),
              ),
              GestureDetector(
                onTap: () {
                  context.read<SavedViewCubit>().setTab('History');
                  context.go(AppRoutes.saved);
                },
                child: Text(
                  'See all history →',
                  style: AppTextStyles.dmSans(
                    size: 10,
                    color: SavedTokens.sectionLink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _wearNote(outfit.worn),
            style: AppTextStyles.dmSans(
              size: 11,
              height: 1.6,
              color: SavedTokens.wearNote,
            ),
          ),
          const SizedBox(height: 13),
          PrimaryButton(
            label: '✓ Mark as Worn Today',
            onPressed: () => _markWorn(context, outfit.id),
          ),
          const SizedBox(height: 14),
          SlActionGrid(
            onPlan: () => _plan(context, outfit),
            onEdit: () => _edit(context, outfit.id),
            onShare: () => _share(context, outfit, wardrobe),
          ),
          Center(
            child: GestureDetector(
              onTap: () => _confirmRemove(context, outfit.id),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Remove from saved looks',
                  style: AppTextStyles.dmSans(
                    size: 11,
                    color: SavedTokens.deleteInk,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _wearNote(int worn) {
    if (worn == 0) return 'You haven’t logged a wear for this look yet.';
    final times = worn == 1 ? 'time' : 'times';
    return 'You have worn this look $worn $times.';
  }

  void _markWorn(BuildContext context, int outfitId) {
    context.read<OutfitsCubit>().logWear(outfitId);
    AppToast.show(context, 'Outfit wear recorded');
  }

  void _plan(BuildContext context, Outfit outfit) {
    context.read<PlannerCubit>().startScheduling(outfit.id, outfit.occasion);
    context.push(AppRoutes.calendarDate);
  }

  void _edit(BuildContext context, int id) {
    context.read<BuilderCubit>().start(editId: id);
    context.push(AppRoutes.builder);
  }

  Future<void> _share(
    BuildContext context,
    Outfit outfit,
    WardrobeCubit wardrobe,
  ) async {
    final itemNames = outfit.items
        .map((id) => wardrobe.itemOrFallback(id).name)
        .join(', ');
    final content =
        '${outfit.name} (${outfit.occasion}) — $itemNames. Styled with '
        'StyloBuddy.';
    try {
      await Clipboard.setData(ClipboardData(text: content));
      if (context.mounted) AppToast.show(context, 'Outfit description copied');
    } catch (_) {
      if (context.mounted) _showShareModal(context, content);
    }
  }

  void _showShareModal(BuildContext context, String content) {
    AppModal.show(
      context,
      title: 'Share your outfit',
      body: Builder(
        builder: (dialogContext) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Copy this look description and send it to a friend.',
              style: AppTextStyles.dmSans(size: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              height: 115,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: SavedTokens.searchBorder),
                borderRadius: BorderRadius.circular(9),
              ),
              child: SingleChildScrollView(
                child: Text(content, style: AppTextStyles.dmSans(size: 12)),
              ),
            ),
            const SizedBox(height: 10),
            PrimaryButton(
              label: 'Done',
              onPressed: () => AppModal.close(dialogContext),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRemove(BuildContext context, int id) {
    AppModal.show(
      context,
      title: 'Remove saved outfit?',
      body: Builder(
        builder: (dialogContext) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'This look will be removed from Saved. Recorded wear history '
              'will remain for your style insights.',
              style: AppTextStyles.dmSans(size: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 17),
            DangerButton(
              label: 'Remove outfit',
              onPressed: () => _removeOutfit(context, dialogContext, id),
            ),
            const SizedBox(height: 8),
            SecondaryButton(
              label: 'Keep outfit',
              onPressed: () => AppModal.close(dialogContext),
            ),
          ],
        ),
      ),
    );
  }

  void _removeOutfit(
    BuildContext context,
    BuildContext dialogContext,
    int id,
  ) {
    context.read<OutfitsCubit>().delete(id);
    AppModal.close(dialogContext);
    context.go(AppRoutes.saved);
    AppToast.show(context, 'Look removed');
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: SavedTokens.tagBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: AppTextStyles.dmSans(size: 10, color: SavedTokens.tagInk),
      ),
    );
  }
}
