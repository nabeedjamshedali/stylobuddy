import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/progress_bar.dart';
import '../../../shared/widgets/screen_head.dart';
import '../wardrobe_tokens.dart';

/// Prototype `pages.analyzing` / `simulate('analyzing','review')`: advances
/// to `/review` after 1150 ms, but only while this screen is still mounted.
class AnalyzingView extends StatefulWidget {
  const AnalyzingView({super.key});

  static const delay = Duration(milliseconds: 1150);

  @override
  State<AnalyzingView> createState() => _AnalyzingViewState();
}

class _AnalyzingViewState extends State<AnalyzingView> {
  @override
  void initState() {
    super.initState();
    Future.delayed(AnalyzingView.delay, () {
      if (mounted) context.push(AppRoutes.review);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ScreenHead(
            title: 'Analyzing Items',
            fallbackRoute: AppRoutes.batch,
          ),
          LoadingView(
            title: 'Preparing your pieces',
            message: 'Removing backgrounds and identifying clothing '
                'details...',
          ),
          const SizedBox(height: 8),
          const AppProgressBar(value: 0.74),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'DEMO ANALYSIS',
              style: AppTextStyles.dmSans(
                size: 9,
                letterSpacing: 1.5,
                color: WardrobeTokens.processCaption,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
