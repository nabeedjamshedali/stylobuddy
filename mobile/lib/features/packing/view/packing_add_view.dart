import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/app_modal.dart';
import '../../../shared/widgets/screen_head.dart';
import '../../wardrobe/cubit/wardrobe_cubit.dart';
import '../cubit/packing_cubit.dart';
import '../cubit/packing_state.dart';
import '../widgets/pk_add_grid.dart';
import '../widgets/pk_heading.dart';
import '../widgets/pk_primary_button.dart';

/// Prototype `pages['packing-add']`.
class PackingAddView extends StatelessWidget {
  const PackingAddView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PackingCubit>();
    final wardrobe = context.watch<WardrobeCubit>();
    return BlocBuilder<PackingCubit, PackingState>(
      builder: (context, state) {
        final trip = state.selectedTrip;
        if (trip == null) {
          return const Padding(
            padding: EdgeInsets.fromLTRB(20, 14, 20, 26),
            child: ScreenHead(
              title: 'Add Packing Items',
              fallbackRoute: AppRoutes.packing,
            ),
          );
        }
        final addedIds = {
          for (final i in trip.items)
            if (i.wardrobeId != null) i.wardrobeId!,
        };
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ScreenHead(
                title: 'Add Packing Items',
                fallbackRoute: AppRoutes.packingList,
              ),
              const PkHeading(
                eyebrow: 'YOUR OWN WARDROBE',
                title: 'Add what you need.',
                subtitle:
                    'Select extra pieces or add travel essentials by name.',
              ),
              const SizedBox(height: 16),
              PkAddGrid(
                items: wardrobe.state.items,
                addedIds: addedIds,
                onAdd: cubit.addWardrobe,
              ),
              const SizedBox(height: 14),
              SecondaryButton(
                label: '＋ Add a non-wardrobe item',
                onPressed: () => _openCustomItemModal(context, cubit),
              ),
              const SizedBox(height: 10),
              PkPrimaryButton(
                label: 'Done',
                onPressed: () => context.go(AppRoutes.packingList),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openCustomItemModal(BuildContext context, PackingCubit cubit) {
    final controller = TextEditingController();
    AppModal.show(
      context,
      title: 'Add a travel essential',
      body: Builder(
        builder: (dialogContext) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Add items such as socks, toiletries, or chargers.',
              style: AppTextStyles.dmSans(size: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 13),
            Text(
              'Item name',
              style: AppTextStyles.dmSans(size: 11, weight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: controller,
              maxLength: 60,
              style: AppTextStyles.dmSans(size: 12),
              decoration: const InputDecoration(
                isDense: true,
                counterText: '',
                hintText: 'e.g. Phone charger',
                contentPadding: EdgeInsets.all(12),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 17),
            PrimaryButton(
              label: 'Add item',
              onPressed: () {
                cubit.addCustom(controller.text);
                if (controller.text.trim().isEmpty) return;
                AppModal.close(dialogContext);
              },
            ),
          ],
        ),
      ),
    );
  }
}
