import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../shared/widgets/screen_head.dart';
import '../cubit/packing_cubit.dart';
import '../cubit/packing_state.dart';
import '../widgets/pk_empty_card.dart';
import '../widgets/pk_feature_card.dart';
import '../widgets/pk_heading.dart';
import '../widgets/pk_primary_button.dart';
import '../widgets/pk_section_row.dart';
import '../widgets/pk_trip_card.dart';

/// Prototype `pages.packing`.
class PackingView extends StatelessWidget {
  const PackingView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PackingCubit>();
    return BlocBuilder<PackingCubit, PackingState>(
      builder: (context, state) {
        final trips = state.trips;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ScreenHead(
                title: 'Packing Assistant',
                fallbackRoute: AppRoutes.home,
              ),
              const PkHeading(
                eyebrow: 'TRAVEL, WELL STYLED',
                title: 'Pack smart.\nTravel light.',
                subtitle:
                    'Create a trip and build a packing list using clothes '
                    'you already own.',
              ),
              const PkFeatureCard(
                icon: '✦',
                title: 'Your wardrobe goes with you.',
                body:
                    'Plan complete looks for the days ahead. Check off each '
                    'piece as you pack.',
              ),
              PkSectionRow(
                title: 'Your trips',
                count: '${trips.length} ${trips.length == 1 ? 'trip' : 'trips'}',
              ),
              if (trips.isEmpty)
                const PkEmptyCard(
                  icon: '✈',
                  title: 'No trips planned yet',
                  body:
                      'Create your first trip to get a personalized packing '
                      'checklist.',
                )
              else
                Column(
                  children: [
                    for (final trip in trips)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: PkTripCard(
                          trip: trip,
                          onTap: () {
                            cubit.selectTrip(trip.id);
                            context.push(AppRoutes.packingList);
                          },
                        ),
                      ),
                  ],
                ),
              PkPrimaryButton(
                label: '＋ Create a trip',
                onPressed: () {
                  cubit.newTrip();
                  context.push(AppRoutes.newTrip);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
