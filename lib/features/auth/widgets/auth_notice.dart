import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_text_styles.dart';
import '../auth_tokens.dart';

/// Which glyph the circular success mark draws.
enum AuthMark { mail, shield }

const _mailSvg =
    '<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">'
    '<rect x="5" y="12" width="38" height="26" rx="6" stroke="#087F62" stroke-width="2"/>'
    '<path d="M7 15l17 14 17-14" stroke="#087F62" stroke-width="2" '
    'stroke-linecap="round" stroke-linejoin="round"/></svg>';

const _shieldSvg =
    '<svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">'
    '<path d="M24 5L8 12v12c0 10 7 16 16 20 9-4 16-10 16-20V12L24 5z" '
    'stroke="#087F62" stroke-width="2"/>'
    '<path d="M16 24l6 6 11-12" stroke="#087F62" stroke-width="2.4" '
    'stroke-linecap="round" stroke-linejoin="round"/></svg>';

/// `.auth-success-mark`: 92px tinted circle holding a 44px line icon.
class AuthSuccessMark extends StatelessWidget {
  const AuthSuccessMark({super.key, required this.mark});

  final AuthMark mark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.fromLTRB(0, 28, 0, 22),
        width: 92,
        height: 92,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AuthTokens.successBg,
          shape: BoxShape.circle,
          border: Border.all(color: AuthTokens.successBorder),
        ),
        child: SvgPicture.string(
          mark == AuthMark.mail ? _mailSvg : _shieldSvg,
          width: 44,
          height: 44,
        ),
      ),
    );
  }
}

/// `.auth-notice`: bordered card with a bold title and a sentence that embeds
/// the user's [email] in bold (falls back to "your email address").
class AuthNotice extends StatelessWidget {
  const AuthNotice({
    super.key,
    required this.title,
    required this.before,
    required this.email,
    required this.after,
  });

  final String title;
  final String before;
  final String email;
  final String after;

  static const emailFallback = 'your email address';

  @override
  Widget build(BuildContext context) {
    final body = AppTextStyles.dmSans(
      size: 11,
      height: 1.65,
      color: AuthTokens.noticeBody,
    );
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 17),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      decoration: BoxDecoration(
        color: AuthTokens.noticeBg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AuthTokens.noticeBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.dmSans(size: 12, weight: FontWeight.w700),
          ),
          const SizedBox(height: 9),
          Text.rich(
            TextSpan(
              style: body,
              children: [
                TextSpan(text: before),
                TextSpan(
                  text: email.isEmpty ? emailFallback : email,
                  style: body.copyWith(fontWeight: FontWeight.w700),
                ),
                TextSpan(text: after),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
