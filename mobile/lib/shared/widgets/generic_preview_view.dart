import 'package:flutter/material.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'screen_head.dart';

/// Prototype `pages.generic`: placeholder for any unbuilt/unknown route.
class GenericPreviewView extends StatelessWidget {
  const GenericPreviewView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 25),
          child: Column(
            children: [
              const ScreenHead(
                title: 'Feature Preview',
                fallbackRoute: AppRoutes.home,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 34,
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(15),
                      child: Text(
                        '✧',
                        style: AppTextStyles.dmSans(
                          size: 46,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Design preview only',
                      style: AppTextStyles.dmSans(
                        size: 16,
                        weight: FontWeight.w700,
                        letterSpacing: -.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This flow is represented in the design specification. Use the main tabs or screen directory to continue exploring.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.dmSans(
                        size: 12,
                        color: AppColors.muted,
                        height: 1.7,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
