import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/screen_head.dart';
import '../cubit/packing_cubit.dart';
import '../widgets/pk_date_field.dart';
import '../widgets/pk_heading.dart';
import '../widgets/pk_primary_button.dart';
import '../widgets/pk_select_field.dart';
import '../widgets/pk_text_area.dart';
import '../widgets/pk_text_field.dart';

/// Prototype `pages['new-trip']`.
class NewTripView extends StatefulWidget {
  const NewTripView({super.key});

  @override
  State<NewTripView> createState() => _NewTripViewState();
}

class _NewTripViewState extends State<NewTripView> {
  static const typeOptions = [
    'Vacation',
    'Business',
    'City break',
    'Beach',
    'Formal event',
    'Other',
  ];

  late PackingCubit _cubit;
  late TextEditingController _name;
  late TextEditingController _destination;
  late TextEditingController _notes;
  late String _start;
  late String _end;
  late String _type;
  late bool _editing;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<PackingCubit>();
    final draft = _cubit.state.draft;
    _editing = _cubit.state.selectedTripId != null;
    _name = TextEditingController(text: draft?.name ?? '');
    _destination = TextEditingController(text: draft?.destination ?? '');
    _notes = TextEditingController(text: draft?.notes ?? '');
    _start = draft?.start ?? '';
    _end = draft?.end ?? '';
    _type = draft?.type ?? 'Vacation';
  }

  @override
  void dispose() {
    _name.dispose();
    _destination.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _save() {
    final result = _cubit.saveDraft(
      name: _name.text,
      destination: _destination.text,
      start: _start,
      end: _end,
      type: _type,
      notes: _notes.text,
    );
    if (!result.success) {
      AppToast.show(context, result.errorMessage!);
      return;
    }
    if (result.wasEditing) {
      context.go(AppRoutes.packingList);
    } else {
      context.push(AppRoutes.packingPreview);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScreenHead(
            title: _editing ? 'Edit Trip' : 'New Trip',
            fallbackRoute:
                _editing ? AppRoutes.packingList : AppRoutes.packing,
          ),
          PkHeading(
            eyebrow: 'TRIP DETAILS',
            title: _editing ? 'Update your getaway.' : 'Where to next?',
            subtitle:
                'A few details help us suggest pieces suited to your plans.',
          ),
          const SizedBox(height: 16),
          PkTextField(
            label: 'Trip name *',
            controller: _name,
            maxLength: 60,
            placeholder: 'Weekend escape',
          ),
          PkTextField(
            label: 'Destination',
            controller: _destination,
            maxLength: 70,
            placeholder: 'e.g. Istanbul',
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: PkDateField(
                  key: const Key('pk-start-date'),
                  label: 'Start date *',
                  value: _start,
                  onChanged: (v) => setState(() => _start = v),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PkDateField(
                  key: const Key('pk-end-date'),
                  label: 'End date *',
                  value: _end,
                  onChanged: (v) => setState(() => _end = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          PkSelectField(
            label: 'Type of trip',
            options: typeOptions,
            value: _type,
            onChanged: (v) => setState(() => _type = v),
          ),
          const SizedBox(height: 9),
          PkTextArea(
            label: 'Activities or notes',
            controller: _notes,
            placeholder: 'Dining out, hiking, work meetings...',
          ),
          const SizedBox(height: 16),
          PkPrimaryButton(
            label: _editing ? 'Save changes' : 'Continue to packing plan',
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
