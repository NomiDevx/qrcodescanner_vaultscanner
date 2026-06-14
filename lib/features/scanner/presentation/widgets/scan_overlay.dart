import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

/// Custom painter that draws the scanner overlay:
/// - Semi-transparent dark background
/// - Clear scan window rectangle
/// - Four teal corner bracket decorations
/// - Animated horizontal scan line
class ScanOverlayPainter extends CustomPainter {
  const ScanOverlayPainter({
    required this.animation,
    required this.isDarkMode,
  });

  final double animation; // 0.0 to 1.0
  final bool isDarkMode;

  static const double _windowSize = AppConstants.scanWindowSize;
  static const double _cornerLength = 40.0;
  static const double _cornerStroke = 3.5;
  static const double _cornerRadius = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final left = cx - _windowSize / 2;
    final top = cy - _windowSize / 2;
    final right = cx + _windowSize / 2;
    final bottom = cy + _windowSize / 2;
    final scanWindow = Rect.fromLTRB(left, top, right, bottom);

    // 1. Dark overlay — exclude the scan window
    final overlayPaint = Paint()..color = AppColors.scanOverlayColor;
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(
        RRect.fromRectAndRadius(scanWindow, const Radius.circular(_cornerRadius)),
      );
    canvas.drawPath(
      path..fillType = PathFillType.evenOdd,
      overlayPaint,
    );

    // 2. Corner bracket decorations
    final cornerPaint = Paint()
      ..color = AppColors.scanCornerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _cornerStroke
      ..strokeCap = StrokeCap.round;

    _drawCorners(canvas, left, top, right, bottom, cornerPaint);

    // 3. Animated scan line
    final lineY = top + (_windowSize * animation);
    final linePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          AppColors.brandTeal.withValues(alpha: 0.8),
          AppColors.brandTealLight.withValues(alpha: 0.9),
          AppColors.brandTeal.withValues(alpha: 0.8),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTRB(left, lineY, right, lineY + 2));

    canvas.drawRect(
      Rect.fromLTRB(left + 8, lineY, right - 8, lineY + 2),
      linePaint,
    );

    // Glow below line
    final glowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.brandTeal.withValues(alpha: 0.15),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTRB(left, lineY, right, lineY + 20));
    canvas.drawRect(
      Rect.fromLTRB(left + 8, lineY + 2, right - 8, lineY + 20),
      glowPaint,
    );
  }

  void _drawCorners(
    Canvas canvas,
    double left,
    double top,
    double right,
    double bottom,
    Paint paint,
  ) {
    const cl = _cornerLength;
    const cr = _cornerRadius;

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(left + cr, top)
        ..lineTo(left + cl, top)
        ..moveTo(left, top + cr)
        ..lineTo(left, top + cl),
      paint,
    );

    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(right - cl, top)
        ..lineTo(right - cr, top)
        ..moveTo(right, top + cr)
        ..lineTo(right, top + cl),
      paint,
    );

    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(left, bottom - cl)
        ..lineTo(left, bottom - cr)
        ..moveTo(left + cr, bottom)
        ..lineTo(left + cl, bottom),
      paint,
    );

    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(right, bottom - cl)
        ..lineTo(right, bottom - cr)
        ..moveTo(right - cl, bottom)
        ..lineTo(right - cr, bottom),
      paint,
    );
  }

  @override
  bool shouldRepaint(ScanOverlayPainter oldDelegate) =>
      oldDelegate.animation != animation ||
      oldDelegate.isDarkMode != isDarkMode;
}

/// Animated scan overlay widget.
class ScanOverlay extends StatefulWidget {
  const ScanOverlay({super.key});

  @override
  State<ScanOverlay> createState() => _ScanOverlayState();
}

class _ScanOverlayState extends State<ScanOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          painter: ScanOverlayPainter(
            animation: _animation.value,
            isDarkMode: isDarkMode,
          ),
          child: child,
        );
      },
      child: const SizedBox.expand(),
    );
  }
}
