import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/wear_event.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/app_modal.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/look_board.dart';
import '../../../shared/widgets/screen_head.dart';
import '../../wardrobe/cubit/wardrobe_cubit.dart';
import '../cubit/outfits_cubit.dart';
import '../saved_tokens.dart';
import '../widgets/sl_garment_row.dart';

/// Prototype `pages['wear-detail']`.
class WearDetailView extends StatelessWidget {
  const WearDetailView({super.key, required this.eventId, this.outfitIdHint});

  final int? eventId;
  final int? outfitIdHint;

  WearEvent? _resolve(OutfitsCubit outfits) {
    if (eventId != null) {
      for (final e in outfits.wearEvents()) {
        if (e.id == eventId) return e;
      }
    }
    if (outfitIdHint != null) {
      final events = outfits.wearEvents(outfitId: outfitIdHint);
      if (events.isNotEmpty) return events.first;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final outfits = context.watch<OutfitsCubit>();
    final event = _resolve(outfits);

    if (event == null) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(20, 14, 20, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScreenHead(title: 'Wear History', fallbackRoute: AppRoutes.saved),
            Text('Wear entry unavailable'),
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
            title: 'Wear Journal',
            fallbackRoute: AppRoutes.saved,
          ),
          Text(
            'YOUR OUTFIT DIARY',
            style: AppTextStyles.dmSans(
              size: 9,
              weight: FontWeight.w800,
              letterSpacing: 1.6,
              color: SavedTokens.kicker,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            DateFormat('EEEE, MMMM d').format(event.timestamp),
            style: AppTextStyles.dmSans(
              size: 25,
              weight: FontWeight.w700,
              letterSpacing: -.8,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            '${event.name} · ${event.occasion}',
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
              ids: event.items,
              size: LookBoardSize.large,
              minHeight: 210,
              padding: EdgeInsets.zero,
              imageHeight: 120,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Worn pieces',
                style: AppTextStyles.dmSans(size: 13, weight: FontWeight.w700),
              ),
              Text(
                '${event.items.length} ITEMS',
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
              for (final itemId in event.items) ...[
                SlGarmentRow(
                  imageId: wardrobe.itemOrFallback(itemId).imageId,
                  name: wardrobe.itemOrFallback(itemId).name,
                  subtitle: wardrobe.itemOrFallback(itemId).category,
                ),
                if (itemId != event.items.last) const SizedBox(height: 8),
              ],
            ],
          ),
          const SizedBox(height: 23),
          SecondaryButton(
            label: 'View saved look',
            onPressed: () => _viewSavedLook(context, event.outfitId),
          ),
          Center(
            child: GestureDetector(
              onTap: () => _confirmRemove(context, event.id),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Remove this wear entry',
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

  void _viewSavedLook(BuildContext context, int outfitId) {
    final outfit = context.read<OutfitsCubit>().byId(outfitId);
    if (outfit != null) {
      context.push(AppRoutes.savedDetail(outfit.id));
    } else {
      AppToast.show(context, 'Original outfit was removed');
    }
  }

  void _confirmRemove(BuildContext context, int eventId) {
    AppModal.show(
      context,
      title: 'Remove wear entry?',
      body: Builder(
        builder: (dialogContext) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'This will update your wear counts.',
              style: AppTextStyles.dmSans(size: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 17),
            DangerButton(
              label: 'Remove entry',
              onPressed: () => _removeEntry(context, dialogContext, eventId),
            ),
          ],
        ),
      ),
    );
  }

  void _removeEntry(
    BuildContext context,
    BuildContext dialogContext,
    int eventId,
  ) {
    context.read<OutfitsCubit>().removeWear(eventId);
    AppModal.close(dialogContext);
    AppToast.show(context, 'Wear entry removed');
  }
}
