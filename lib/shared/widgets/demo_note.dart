import 'package:flutter/material.dart';

import '../../core/theme/app_text_styles.dart';
import 'shared_tokens.dart';

/// Flip to false to remove every demo/simulation disclaimer at once.
const bool kShowDemoNotes = true;

/// Which prototype disclaimer class to mimic.
enum DemoNoteStyle {
  /// `.w-demo-note`: 10px centered.
  standard,

  /// `.ai-disclaimer`: 9px left-aligned.
  ai,

  /// `.in-disclaimer`: 9px centered, 8px side margin.
  intro,

  /// `.sh-disclaimer`: 9.5px centered.
  share,
}

class DemoNote extends StatelessWidget {
  const DemoNote(this.text, {super.key, this.style = DemoNoteStyle.standard});

  final String text;
  final DemoNoteStyle style;

  @override
  Widget build(BuildContext context) {
    if (!kShowDemoNotes) return const SizedBox.shrink();
    final (size, color, height, margin, align) = switch (style) {
      DemoNoteStyle.standard => (
        10.0,
        SharedTokens.demoNote,
        1.5,
        const EdgeInsets.symmetric(vertical: 14),
        TextAlign.center,
      ),
      DemoNoteStyle.ai => (
        9.0,
        SharedTokens.aiNote,
        1.5,
        const EdgeInsets.symmetric(vertical: 19),
        TextAlign.start,
      ),
      DemoNoteStyle.intro => (
        9.0,
        SharedTokens.introNote,
        1.6,
        const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        TextAlign.center,
      ),
      DemoNoteStyle.share => (
        9.5,
        SharedTokens.shareNote,
        1.5,
        const EdgeInsets.symmetric(vertical: 13),
        TextAlign.center,
      ),
    };
    return Padding(
      padding: margin,
      child: SizedBox(
        width: double.infinity,
        child: Text(
          text,
          textAlign: align,
          style: AppTextStyles.dmSans(size: size, color: color, height: height),
        ),
      ),
    );
  }
}
