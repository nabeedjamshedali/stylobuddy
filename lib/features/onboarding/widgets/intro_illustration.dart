import 'package:flutter/material.dart';

import '../models/intro_slide.dart';
import 'ob_photo.dart';

/// `.ob-illustration`: photograph sized as a fraction of the page height.
class IntroIllustration extends StatelessWidget {
  const IntroIllustration({
    super.key,
    required this.slide,
    required this.pageHeight,
  });

  final IntroSlide slide;
  final double pageHeight;

  @override
  Widget build(BuildContext context) {
    final height = (pageHeight * slide.heightFraction).clamp(
      slide.minHeight,
      double.infinity,
    );
    return Padding(
      padding: EdgeInsets.only(top: slide.topMargin),
      child: SizedBox(
        height: height,
        child: Center(
          child: FractionallySizedBox(
            widthFactor: slide.maxImageWidth,
            child: ObPhoto(file: slide.image!),
          ),
        ),
      ),
    );
  }
}
