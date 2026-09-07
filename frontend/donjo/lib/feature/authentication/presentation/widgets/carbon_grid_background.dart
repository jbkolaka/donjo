import 'package:flutter/material.dart';
import 'package:donjo/core/theme/app_palette.dart';

/// Renders a subtle, animated Carbon 2x grid pattern in the background.
class CarbonGridBackground extends StatelessWidget {
  const CarbonGridBackground({
    super.key,
    required this.child,
    this.showDots = true,
  });

  final Widget child;
  final bool showDots;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _CarbonGridPainter(
              dotColor: p.isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.035),
              lineColor: p.isDark
                  ? Colors.white.withValues(alpha: 0.02)
                  : Colors.black.withValues(alpha: 0.02),
              spacing: 24,
              showDots: showDots,
            ),
          ),
        ),
        // Subtle ambient brand glow at the top
        Positioned(
          top: -120,
          right: -80,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  p.buttonPrimary.withValues(alpha: p.isDark ? 0.08 : 0.06),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

class _CarbonGridPainter extends CustomPainter {
  const _CarbonGridPainter({
    required this.dotColor,
    required this.lineColor,
    required this.spacing,
    required this.showDots,
  });

  final Color dotColor;
  final Color lineColor;
  final double spacing;
  final bool showDots;

  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        if (showDots) {
          canvas.drawCircle(Offset(x, y), 1.0, dotPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CarbonGridPainter oldDelegate) {
    return oldDelegate.dotColor != dotColor ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.spacing != spacing;
  }
}
