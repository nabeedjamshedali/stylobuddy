import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../shared/demo_copy.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/screen_head.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../cubit/profile_cubit.dart';
import '../widgets/pf_form_intro.dart';
import '../widgets/pf_helper_text.dart';
import '../widgets/pf_text_field.dart';

/// Prototype `pages['edit-profile']` + `saveProfile()`, `P/app.js:273-274`.
class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  static final _emailPattern = RegExp(r'^\S+@\S+\.\S+$');

  late TextEditingController _name;
  late TextEditingController _email;

  @override
  void initState() {
    super.initState();
    final state = context.read<ProfileCubit>().state;
    _name = TextEditingController(text: state.name);
    _email = TextEditingController(text: state.email);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    final email = _email.text.trim();
    if (name.isEmpty || !_emailPattern.hasMatch(email)) {
      AppToast.show(context, 'Please enter a name and valid email');
      return;
    }
    context.read<ProfileCubit>().updateDetails(name, email);
    context.go(AppRoutes.profile);
    AppToast.show(context, DemoCopy.editProfileSavedToast);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ScreenHead(
            title: 'Personal Details',
            fallbackRoute: AppRoutes.profile,
          ),
          const PfFormIntro(
            title: 'A little about you.',
            body: 'Keep your profile details up to date.',
          ),
          PfTextField(label: 'Display name', controller: _name, maxLength: 64),
          const SizedBox(height: 15),
          PfTextField(
            label: 'Email address',
            controller: _email,
            keyboardType: TextInputType.emailAddress,
          ),
          const PfHelperText(DemoCopy.editProfileHelper),
          PrimaryButton(label: 'Save changes', onPressed: _save),
        ],
      ),
    );
  }
}
