import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../cubit/profile_cubit.dart';
import '../widgets/pf_identity_card.dart';
import '../widgets/pf_menu_row.dart';
import '../widgets/pf_premium_banner.dart';
import '../widgets/pf_card.dart';
import '../widgets/pf_section_title.dart';

/// Prototype `pages.profile`, `P/app.js:272`.
class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ProfileCubit>().state;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PfSectionTitle('YOUR SPACE', kicker: true),
          Text(
            'My profile',
            style: AppTextStyles.dmSans(
              size: 25,
              letterSpacing: -.9,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          PfIdentityCard(
            name: state.name,
            email: state.email,
            onEdit: () => context.push(AppRoutes.editProfile),
          ),
          PfPremiumBanner(onTap: () => context.push(AppRoutes.premium)),
          const PfSectionTitle('YOUR STYLE HUB'),
          PfCard(
            children: [
              PfMenuRow(
                symbol: '▦',
                title: 'Outfit planner',
                subtitle: 'Plan looks ahead of time',
                onTap: () => context.push(AppRoutes.calendar),
              ),
              PfMenuRow(
                symbol: '▤',
                title: 'Packing assistant',
                subtitle: 'Build travel wardrobes',
                onTap: () => context.push(AppRoutes.packing),
              ),
              PfMenuRow(
                symbol: '♧',
                title: 'Shopping assistant',
                subtitle: 'Fill wardrobe gaps',
                onTap: () => context.push(AppRoutes.shopping),
              ),
              PfMenuRow(
                symbol: '◉',
                title: 'Style insights',
                subtitle: 'Understand your wardrobe',
                onTap: () => context.push(AppRoutes.insights),
              ),
            ],
          ),
          const PfSectionTitle('ACCOUNT & PREFERENCES'),
          PfCard(
            children: [
              PfMenuRow(
                symbol: '♙',
                title: 'Personal details',
                subtitle: 'Name and contact email',
                onTap: () => context.push(AppRoutes.editProfile),
              ),
              PfMenuRow(
                symbol: '✧',
                title: 'Style preferences',
                subtitle: state.styles.join(' · '),
                onTap: () => context.push(AppRoutes.editStyle),
              ),
              PfMenuRow(
                symbol: '⚙',
                title: 'Settings',
                subtitle: 'Notifications, privacy, billing',
                onTap: () => context.push(AppRoutes.settings),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
