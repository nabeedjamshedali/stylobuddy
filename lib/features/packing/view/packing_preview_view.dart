import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/demo_copy.dart';
import '../../../shared/widgets/screen_head.dart';
import '../../wardrobe/cubit/wardrobe_cubit.dart';
import '../cubit/packing_cubit.dart';
import '../cubit/packing_state.dart';
import '../packing_format.dart';
import '../widgets/pk_heading.dart';
import '../widgets/pk_info_card.dart';
import '../widgets/pk_preview_grid.dart';
import '../widgets/pk_primary_button.dart';
import '../widgets/pk_section_row.dart';

/// Prototype `pages['packing-preview']`.
class PackingPreviewView extends StatelessWidget {
  const PackingPreviewView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PackingCubit>();
    final wardrobe = context.watch<WardrobeCubit>();
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
                  title: 'Packing Plan',
                  fallbackRoute: AppRoutes.packing,
                ),
                Text(
                  'No trip selected.',
                  style: AppTextStyles.dmSans(size: 12, color: AppColors.muted),
                ),
              ],
            ),
          );
        }
        final suggestions = cubit.suggestions(trip, wardrobe.state.items);
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ScreenHead(
                title: 'Packing Plan',
                fallbackRoute: AppRoutes.newTrip,
              ),
              PkHeading(
                eyebrow: 'YOUR TRAVEL EDIT',
                title: 'A thoughtful starting point.',
                subtitle:
                    'Based on your owned wardrobe and ${trip.days}-day '
                    '${trip.type.toLowerCase()} trip.'
                    '${DemoCopy.packingPreviewDemoClause}',
              ),
              const SizedBox(height: 15),
              PkInfoCard(
                name: trip.name,
                subtitle:
                    '${pkDateLabel(trip.start)} – ${pkDateLabel(trip.end)} · '
                    '${trip.days} days',
              ),
              PkSectionRow(
                title: 'Suggested pieces',
                count: '${suggestions.length} items',
              ),
              PkPreviewGrid(items: suggestions),
              const SizedBox(height: 16),
              PkPrimaryButton(
                label: 'Create packing checklist',
                onPressed: () {
                  cubit.generateChecklist(wardrobe.state.items);
                  context.push(AppRoutes.packingList);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
