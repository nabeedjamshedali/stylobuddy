import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/screen_head.dart';
import '../cubit/import_cubit.dart';
import '../wardrobe_tokens.dart';

/// Prototype `pages['add-confirm']`.
class AddConfirmView extends StatelessWidget {
  const AddConfirmView({super.key});

  @override
  Widget build(BuildContext context) {
    final count = context.watch<ImportCubit>().state.lastImportCount;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ScreenHead(
            title: 'Import Complete',
            fallbackRoute: AppRoutes.wardrobe,
          ),
          Column(
            children: [
              Container(
                width: 65,
                height: 65,
                margin: const EdgeInsets.only(bottom: 24),
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: WardrobeTokens.completeCheckBg,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '✓',
                  style: AppTextStyles.dmSans(
                    size: 30,
                    color: WardrobeTokens.completeCheckInk,
                  ),
                ),
              ),
              Text(
                'WARDROBE UPDATED',
                style: AppTextStyles.dmSans(
                  size: 9,
                  weight: FontWeight.w800,
                  letterSpacing: 1.35,
                  color: WardrobeTokens.eyebrow,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                'Looking good already.',
                style: AppTextStyles.manrope(
                  size: 24,
                  weight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 11),
              Text(
                '$count ${count == 1 ? 'piece has' : 'pieces have'} been '
                'added to your wardrobe. You can edit details or start '
                'creating new looks anytime.',
                textAlign: TextAlign.center,
                style: AppTextStyles.dmSans(
                  size: 11,
                  color: WardrobeTokens.completeBody,
                  height: 1.7,
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 26, bottom: 8),
                padding: const EdgeInsets.all(19),
                decoration: BoxDecoration(
                  border: Border.all(color: WardrobeTokens.completeStatBorder),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Column(
                  children: [
                    Text(
                      '+$count',
                      style: AppTextStyles.dmSans(
                        size: 29,
                        weight: FontWeight.w700,
                        color: WardrobeTokens.eyebrow,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'New wardrobe items',
                      style: AppTextStyles.dmSans(
                        size: 10,
                        color: WardrobeTokens.completeBody,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          PrimaryButton(
            label: 'View my wardrobe',
            onPressed: () => context.go(AppRoutes.wardrobe),
          ),
          const SizedBox(height: 9),
          SecondaryButton(
            label: 'Add more clothing',
            onPressed: () => context.go(AppRoutes.import),
          ),
        ],
      ),
    );
  }
}
