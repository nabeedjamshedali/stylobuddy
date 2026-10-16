import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../auth_tokens.dart';

/// Prototype `authField`: label above a 48px input; password fields get a
/// Show/Hide control (starts obscured).
class AuthField extends StatefulWidget {
  const AuthField({
    super.key,
    required this.label,
    required this.controller,
    required this.placeholder,
    this.isPassword = false,
    this.keyboardType,
    this.invalid = false,
  });

  final String label;
  final TextEditingController controller;
  final String placeholder;
  final bool isPassword;
  final TextInputType? keyboardType;
  final bool invalid;

  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  bool _obscured = true;

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: color),
  );

  @override
  Widget build(BuildContext context) {
    final base = widget.invalid ? AuthTokens.invalid : AuthTokens.inputBorder;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: AppTextStyles.dmSans(
            size: 11,
            weight: FontWeight.w700,
            color: AuthTokens.label,
          ),
        ),
        const SizedBox(height: 7),
        Stack(
          alignment: Alignment.centerRight,
          children: [
            SizedBox(
              height: 48,
              child: TextField(
                controller: widget.controller,
                obscureText: widget.isPassword && _obscured,
                keyboardType: widget.keyboardType,
                autocorrect: false,
                enableSuggestions: !widget.isPassword,
                style: AppTextStyles.dmSans(
                  size: 12,
                  color: AuthTokens.inputInk,
                ),
                cursorColor: AuthTokens.green,
                decoration: InputDecoration(
                  hintText: widget.placeholder,
                  hintStyle: AppTextStyles.dmSans(
                    size: 12,
                    color: AuthTokens.placeholder,
                  ),
                  filled: true,
                  fillColor: AppColors.white,
                  contentPadding: EdgeInsets.fromLTRB(
                    14,
                    0,
                    widget.isPassword ? 60 : 14,
                    0,
                  ),
                  enabledBorder: _border(base),
                  focusedBorder: _border(
                    widget.invalid ? AuthTokens.invalid : AuthTokens.green,
                  ),
                ),
              ),
            ),
            if (widget.isPassword)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _obscured = !_obscured),
                  child: Padding(
                    padding: const EdgeInsets.all(7),
                    child: Text(
                      _obscured ? 'Show' : 'Hide',
                      style: AppTextStyles.dmSans(
                        size: 11,
                        weight: FontWeight.w600,
                        color: AuthTokens.green,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
