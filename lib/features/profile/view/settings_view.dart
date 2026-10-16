import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/screen_head.dart';
import '../profile_tokens.dart';
import '../widgets/pf_card.dart';
import '../widgets/pf_menu_row.dart';
import '../widgets/pf_section_title.dart';

/// Prototype `pages.settings`, `P/app.js:277`.
class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ScreenHead(title: 'Settings', fallbackRoute: AppRoutes.profile),
          const PfSectionTitle('PERSONALIZATION'),
          PfCard(
            children: [
              PfMenuRow(
                symbol: '♧',
                title: 'Notifications',
                subtitle: 'Daily looks and outfit reminders',
                onTap: () => context.push(AppRoutes.notifications),
              ),
              PfMenuRow(
                symbol: '☼',
                title: 'Weather preferences',
                subtitle: 'Optional context for recommendations',
                onTap: () => context.push(AppRoutes.weatherSettings),
              ),
            ],
          ),
          const PfSectionTitle('SUBSCRIPTION'),
          PfCard(
            children: [
              PfMenuRow(
                symbol: '✦',
                title: 'Subscription & billing',
                subtitle: 'Free plan · Plans not yet priced',
                onTap: () => context.push(AppRoutes.subscription),
              ),
            ],
          ),
          const PfSectionTitle('SUPPORT & ACCOUNT'),
          PfCard(
            children: [
              PfMenuRow(
                symbol: 'ⓘ',
                title: 'Help, privacy & legal',
                subtitle: 'Policies and support',
                onTap: () => context.push(AppRoutes.support),
              ),
              PfMenuRow(
                symbol: '↪',
                title: 'Sign out',
                subtitle: 'Leave the current demo session',
                onTap: () => context.push(AppRoutes.signout),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 26),
            child: Text(
              'StyloBuddy · Interface prototype V19',
              textAlign: TextAlign.center,
              style: AppTextStyles.dmSans(size: 10, color: ProfileTokens.version),
            ),
          ),
        ],
      ),
    );
  }
}
