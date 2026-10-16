import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../profile_tokens.dart';

/// Prototype `.pf-identity`: avatar initial, name, email, subtitle and the
/// edit-profile pencil (`P/app.js:272`).
class PfIdentityCard extends StatelessWidget {
  const PfIdentityCard({
    super.key,
    required this.name,
    required this.email,
    required this.onEdit,
  });

  final String name;
  final String email;
  final VoidCallback onEdit;

  /// Prototype `(S.profileName||'A').slice(0,1).toUpperCase()`: missing name
  /// falls back to 'A'; an empty string also falls back (not blank).
  String get _initial =>
      (name.isNotEmpty ? name : 'A').substring(0, 1).toUpperCase();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: const BoxDecoration(
              color: ProfileTokens.avatarBg,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              _initial,
              style: AppTextStyles.dmSans(
                size: 22,
                weight: FontWeight.w700,
                color: ProfileTokens.avatarInk,
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: AppTextStyles.dmSans(size: 15, letterSpacing: -.3),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: AppTextStyles.dmSans(
                    size: 10,
                    color: ProfileTokens.identitySubtitle,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Personal wardrobe profile',
                  style: AppTextStyles.dmSans(
                    size: 10,
                    color: ProfileTokens.identitySubtitle,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(11),
              side: const BorderSide(color: ProfileTokens.editIconBorder),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(11),
              onTap: onEdit,
              child: const SizedBox(
                width: 34,
                height: 34,
                child: Center(
                  child: Text(
                    '✎',
                    semanticsLabel: 'Edit profile',
                    style: TextStyle(
                      fontSize: 14,
                      color: ProfileTokens.editIconInk,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
