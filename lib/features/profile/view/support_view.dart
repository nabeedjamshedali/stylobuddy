import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../shared/widgets/screen_head.dart';
import '../widgets/pf_card.dart';
import '../widgets/pf_menu_row.dart';
import '../widgets/pf_section_title.dart';

/// Prototype `pages.support`, `P/app.js:280`.
class SupportView extends StatelessWidget {
  const SupportView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ScreenHead(title: 'Help & Privacy', fallbackRoute: AppRoutes.settings),
          const PfSectionTitle('ASSISTANCE'),
          PfCard(
            children: [
              PfMenuRow(
                symbol: 'ⓘ',
                title: 'Help center',
                subtitle: 'Frequently asked questions',
                onTap: () => context.push(AppRoutes.supportDetail),
              ),
              PfMenuRow(
                symbol: '✉',
                title: 'Contact support',
                subtitle: 'Support channel placeholder',
                onTap: () => context.push(AppRoutes.supportDetail),
              ),
            ],
          ),
          const PfSectionTitle('YOUR DATA'),
          PfCard(
            children: [
              PfMenuRow(
                symbol: '◇',
                title: 'Privacy policy',
                subtitle: 'Production policy pending',
                onTap: () => context.push(AppRoutes.supportDetail),
              ),
              PfMenuRow(
                symbol: '▤',
                title: 'Terms of service',
                subtitle: 'Production terms pending',
                onTap: () => context.push(AppRoutes.supportDetail),
              ),
              PfMenuRow(
                symbol: '×',
                title: 'Delete account',
                subtitle: 'Review deletion information',
                onTap: () => context.push(AppRoutes.deleteAccount),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
