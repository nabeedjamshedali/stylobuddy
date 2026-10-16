import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/screen_head.dart';
import '../../wardrobe/cubit/wardrobe_cubit.dart';
import '../cubit/builder_cubit.dart';
import '../cubit/builder_state.dart';
import '../widgets/mb_final_preview.dart';
import '../widgets/mb_form.dart';
import '../widgets/mb_intro.dart';
import '../widgets/mb_summary_row.dart';

/// Prototype `pages['manual-preview']`.
class ManualPreviewView extends StatefulWidget {
  const ManualPreviewView({super.key});

  @override
  State<ManualPreviewView> createState() => _ManualPreviewViewState();
}

class _ManualPreviewViewState extends State<ManualPreviewView> {
  /// Prototype `['Everyday','Office','Casual','Party','Wedding','Date
  /// Night','Vacation']` (manual-preview's own `<select>`, distinct from
  /// the wardrobe's occasion list).
  static const occasionOptions = [
    'Everyday',
    'Office',
    'Casual',
    'Party',
    'Wedding',
    'Date Night',
    'Vacation',
  ];

  late BuilderCubit _cubit;
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<BuilderCubit>();
    final current = _cubit.state.name;
    final initialName = current.isEmpty ? MbForm.defaultName : current;
    _nameController = TextEditingController(text: initialName);
    if (current.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _cubit.setName(initialName);
      });
    }
    _nameController.addListener(_onNameChanged);
  }

  void _onNameChanged() => _cubit.setName(_nameController.text);

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    super.dispose();
  }

  void _save(BuildContext context) {
    final result = _cubit.save();
    AppToast.show(context, result.message);
    if (result.succeeded) {
      context.go(AppRoutes.savedDetail(result.outfitId!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final wardrobe = context.watch<WardrobeCubit>();
    return BlocBuilder<BuilderCubit, BuilderState>(
      bloc: _cubit,
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ScreenHead(
                title: state.isEditing
                    ? 'Edit Custom Outfit'
                    : 'Your Custom Outfit',
                fallbackRoute: AppRoutes.builder,
              ),
              const MbIntro(
                kicker: 'YOUR OWN STYLE',
                title: 'Looks good together.',
                body:
                    'Review your selections, name your outfit and save it '
                    'to your collection.',
              ),
              MbFinalPreview(picked: state.picked),
              Text(
                'Pieces in this outfit',
                style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w700),
              ),
              for (final id in state.picked)
                MbSummaryRow(
                  item: wardrobe.itemOrFallback(id),
                  onChange: () => context.push(AppRoutes.builder),
                ),
              MbForm(
                nameController: _nameController,
                occasion: state.occasion,
                occasionOptions: occasionOptions,
                onOccasionChanged: _cubit.setOccasion,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 14, bottom: 16),
                child: Column(
                  children: [
                    PrimaryButton(
                      label: state.isEditing
                          ? 'Save Changes'
                          : 'Save to My Looks',
                      onPressed: () => _save(context),
                    ),
                    const SizedBox(height: 9),
                    SecondaryButton(
                      label: 'Change Items',
                      onPressed: () => context.push(AppRoutes.builder),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
