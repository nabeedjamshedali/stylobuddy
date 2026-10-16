import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/demo_note.dart';
import '../../../shared/widgets/screen_head.dart';
import '../cubit/import_cubit.dart';
import '../wardrobe_tokens.dart';

/// Prototype `pages.import`.
class ImportView extends StatelessWidget {
  const ImportView({super.key});

  void _choose(BuildContext context, String source) {
    context.read<ImportCubit>().setSource(source);
    context.push(AppRoutes.importSource);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ScreenHead(
            title: 'Add Clothing',
            fallbackRoute: AppRoutes.wardrobe,
          ),
          Column(
            children: [
              Container(
                width: 54,
                height: 54,
                margin: const EdgeInsets.only(bottom: 20),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: WardrobeTokens.importMonogramBg,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  '✧',
                  style: AppTextStyles.dmSans(
                    size: 29,
                    color: WardrobeTokens.eyebrow,
                  ),
                ),
              ),
              Text(
                'YOUR DIGITAL CLOSET',
                style: AppTextStyles.dmSans(
                  size: 9,
                  weight: FontWeight.w800,
                  letterSpacing: 1.35,
                  color: WardrobeTokens.eyebrow,
                ),
              ),
              const SizedBox(height: 13),
              Text(
                'Every great look starts here.',
                textAlign: TextAlign.center,
                style: AppTextStyles.manrope(
                  size: 24,
                  weight: FontWeight.w700,
                  letterSpacing: -0.8,
                  height: 1.19,
                ),
              ),
              const SizedBox(height: 13),
              Text(
                'Add one piece or an entire batch. StyloBuddy will help '
                'organize photos and suggest clothing details for your '
                'approval.',
                textAlign: TextAlign.center,
                style: AppTextStyles.dmSans(
                  size: 11,
                  color: WardrobeTokens.importChoiceSub,
                  height: 1.7,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          _Choice(
            icon: '◎',
            title: 'Take a photo',
            subtitle: 'Capture one item with your camera',
            onTap: () => _choose(context, 'camera'),
          ),
          const SizedBox(height: 11),
          _Choice(
            icon: '▧',
            title: 'Choose from gallery',
            subtitle: 'Add one or multiple pieces',
            onTap: () => _choose(context, 'gallery'),
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 20),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            decoration: BoxDecoration(
              color: WardrobeTokens.infoLineBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '✧',
                  style: AppTextStyles.dmSans(
                    size: 10,
                    color: WardrobeTokens.infoLineInk,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI suggestions are editable before anything is saved.',
                    style: AppTextStyles.dmSans(
                      size: 10,
                      color: WardrobeTokens.infoLineInk,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const DemoNote(
            'Prototype preview uses sample garment photos. No device camera '
            'or AI service is connected.',
          ),
        ],
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: WardrobeTokens.importChoiceBorder),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          children: [
            Container(
              width: 43,
              height: 43,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: WardrobeTokens.importChoiceIconBg,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Text(
                icon,
                style: AppTextStyles.dmSans(
                  size: 23,
                  color: WardrobeTokens.eyebrow,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.dmSans(
                      size: 13,
                      weight: FontWeight.w700,
                      color: WardrobeTokens.importChoiceInk,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: AppTextStyles.dmSans(
                      size: 10,
                      color: WardrobeTokens.importChoiceSub,
                    ),
                  ),
                ],
              ),
            ),
            Text('→', style: AppTextStyles.dmSans(size: 14)),
          ],
        ),
      ),
    );
  }
}
