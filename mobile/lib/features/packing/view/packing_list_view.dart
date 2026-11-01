import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/app_modal.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/screen_head.dart';
import '../cubit/packing_cubit.dart';
import '../cubit/packing_state.dart';
import '../packing_format.dart';
import '../widgets/pk_checklist.dart';
import '../widgets/pk_count_card.dart';
import '../widgets/pk_empty_card.dart';
import '../packing_tokens.dart';
import '../widgets/pk_toolbar.dart';

/// Prototype `pages['packing-list']`.
class PackingListView extends StatelessWidget {
  const PackingListView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PackingCubit>();
    return BlocBuilder<PackingCubit, PackingState>(
      builder: (context, state) {
        final trip = state.selectedTrip;
        if (trip == null) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const ScreenHead(
                  title: 'Packing Checklist',
                  fallbackRoute: AppRoutes.packing,
                ),
                Text(
                  'Choose a trip first.',
                  style: AppTextStyles.dmSans(size: 12, color: AppColors.muted),
                ),
              ],
            ),
          );
        }
        final packed = trip.items.where((i) => i.packed).length;
        final total = trip.items.length;
        final percent = total == 0 ? 0 : (packed / total * 100).round();
        final meta = trip.destination.isNotEmpty ? trip.destination : trip.type;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ScreenHead(
                title: 'Packing Checklist',
                fallbackRoute: AppRoutes.packing,
              ),
              Text(
                'TRIP CHECKLIST',
                style: AppTextStyles.dmSans(
                  size: 9,
                  weight: FontWeight.w800,
                  letterSpacing: 1.6,
                  color: PackingTokens.eyebrow,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  trip.name,
                  style: AppTextStyles.manrope(
                    size: 23,
                    weight: FontWeight.w700,
                    letterSpacing: -0.7,
                    height: 1.18,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  '$meta · ${pkDateLabel(trip.start)} – '
                  '${pkDateLabel(trip.end)}',
                  style: AppTextStyles.dmSans(
                    size: 11,
                    color: PackingTokens.subtitle,
                    height: 1.7,
                  ),
                ),
              ),
              PkCountCard(percent: percent, packed: packed, total: total),
              PkToolbar(
                onEdit: () {
                  cubit.editTrip(trip.id);
                  context.push(AppRoutes.newTrip);
                },
                onAddItems: () => context.push(AppRoutes.packingAdd),
              ),
              if (trip.items.isEmpty)
                const PkEmptyCard(
                  title: 'Your list is empty',
                  body: 'Add clothing from your wardrobe to start packing.',
                )
              else
                PkChecklist(
                  items: trip.items,
                  onToggle: cubit.toggle,
                  onRemove: cubit.removeItem,
                ),
              const SizedBox(height: 14),
              SecondaryButton(
                label: '＋ Add clothing or essentials',
                onPressed: () => context.push(AppRoutes.packingAdd),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => _confirmDelete(context, cubit),
                  child: Text(
                    'Delete trip',
                    style: AppTextStyles.dmSans(
                      size: 10,
                      color: PackingTokens.deleteInk,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, PackingCubit cubit) {
    AppModal.show(
      context,
      title: 'Delete this trip?',
      body: Builder(
        builder: (dialogContext) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'This removes the trip and its checklist. Your wardrobe '
              'items stay safe.',
              style: AppTextStyles.dmSans(size: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 17),
            PrimaryButton(
              label: 'Delete trip',
              onPressed: () => _delete(context, dialogContext, cubit),
            ),
          ],
        ),
      ),
    );
  }

  void _delete(
    BuildContext context,
    BuildContext dialogContext,
    PackingCubit cubit,
  ) {
    cubit.deleteSelectedTrip();
    AppModal.close(dialogContext);
    context.go(AppRoutes.packing);
    AppToast.show(context, 'Trip removed');
  }
}
