import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'shared_tokens.dart';

/// Prototype `.loading` block with the 48px `.spinner`.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 85),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _Spinner(),
          const SizedBox(height: 23),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.dmSans(
                size: 16, weight: FontWeight.w700, letterSpacing: -.8),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.dmSans(
                size: 12, color: AppColors.muted, height: 1.6),
          ),
        ],
      ),
    );
  }
}

class _Spinner extends StatefulWidget {
  const _Spinner();

  @override
  State<_Spinner> createState() => _SpinnerState();
}

class _SpinnerState extends State<_Spinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: const SizedBox(
        width: 48,
        height: 48,
        child: CustomPaint(painter: _SpinnerPainter()),
      ),
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  const _SpinnerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 4.0;
    final arcRect = (Offset.zero & size).deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = SharedTokens.spinnerTrack;
    canvas.drawOval(arcRect, paint);
    paint.color = AppColors.green;
    canvas.drawArc(arcRect, -math.pi * 3 / 4, math.pi / 2, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
