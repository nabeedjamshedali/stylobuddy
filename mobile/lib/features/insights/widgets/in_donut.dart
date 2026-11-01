import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../insights_tokens.dart';

/// Prototype `.in-donut`: a conic-gradient ring with a white centre hole
/// showing the total. CSS conic-gradient has no Flutter equivalent, so this
/// paints wedges directly (closest-look rule, `F12` edge cases).
class InDonut extends StatelessWidget {
  const InDonut({super.key, required this.cats, required this.total});

  final List<(String, int)> cats;
  final int total;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 134,
      height: 134,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(134, 134),
            painter: _DonutPainter(cats: cats, total: total),
          ),
          Container(
            width: 94,
            height: 94,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$total',
                  style: AppTextStyles.dmSans(
                    size: 28,
                    weight: FontWeight.w700,
                    color: InsightsTokens.donutValue,
                  ),
                ),
                Text(
                  'items',
                  style: AppTextStyles.dmSans(size: 10, color: InsightsTokens.donutLabel),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.cats, required this.total});

  final List<(String, int)> cats;
  final int total;

  @override
  void paint(Canvas canvas, Size size) {
    if (total <= 0 || cats.isEmpty) return;
    final rect = Offset.zero & size;
    var startFraction = 0.0;
    for (var i = 0; i < cats.length; i++) {
      final fraction = cats[i].$2 / total;
      final paint = Paint()
        ..color = InsightsTokens.palette[i % InsightsTokens.palette.length]
        ..style = PaintingStyle.fill;
      canvas.drawArc(
        rect,
        -math.pi / 2 + startFraction * 2 * math.pi,
        fraction * 2 * math.pi,
        true,
        paint,
      );
      startFraction += fraction;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.cats != cats || oldDelegate.total != total;
}
