import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/screen_head.dart';
import '../cubit/stylist_cubit.dart';
import '../cubit/stylist_state.dart';
import '../widgets/stylist_page.dart';

/// Prototype `pages.generating` (and, with [match], `matching-progress`).
///
/// Replaces itself with the results route once generation finishes, but only
/// while it is still mounted: leaving the screen earlier cancels navigation.
class GeneratingView extends StatefulWidget {
  const GeneratingView({super.key, this.match = false});

  final bool match;

  @override
  State<GeneratingView> createState() => _GeneratingViewState();
}

class _GeneratingViewState extends State<GeneratingView> {
  String get _next =>
      widget.match ? AppRoutes.matchingResults : AppRoutes.results;

  @override
  void initState() {
    super.initState();
    // Nothing is generating (e.g. restored/deep-linked route): do not spin
    // forever, go straight to whatever results exist.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !context.read<StylistCubit>().state.isGenerating) {
        context.pushReplacement(_next);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<StylistCubit, StylistState>(
      listenWhen: (a, b) => a.isGenerating && !b.isGenerating,
      listener: (context, state) => context.pushReplacement(_next),
      child: StylistPage(
        children: [
          ScreenHead(
            title: widget.match ? 'Matching Your Clothes' : 'Finding Your Style',
            fallbackRoute: widget.match
                ? AppRoutes.matchOptions
                : AppRoutes.stylingOptions,
          ),
          LoadingView(
            title: widget.match
                ? 'Discovering your best combinations'
                : 'Putting looks together...',
            message: widget.match
                ? 'Comparing visual balance, garment cuts, formality, textures and the accessories you already own.'
                : 'Looking at silhouettes, fabrics, color harmony, and what fits your occasion.',
          ),
        ],
      ),
    );
  }
}
