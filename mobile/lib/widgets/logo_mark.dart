import 'package:flutter/material.dart';

/// The Career Ready logo mark: a rolled diploma with a briefcase-style
/// handle, a checkmark seal (certification), and three connected dots
/// (technology accent). Renders at any size via CustomPainter so it
/// stays crisp without shipping raster assets.
class LogoMark extends StatelessWidget {
  const LogoMark({
    super.key,
    this.size = 72,
    this.strokeColor = const Color(0xFF0F6E56),
    this.sealColor = const Color(0xFF185FA5),
    this.ribbonColor = const Color(0xFF185FA5),
    this.dotColor = const Color(0xFF1D9E75),
    this.checkColor = Colors.white,
  });

  final double size;
  final Color strokeColor;
  final Color sealColor;
  final Color ribbonColor;
  final Color dotColor;
  final Color checkColor;

  /// Convenience constructor for placing the mark on a dark/colored
  /// background (splash screen), matching the white-on-teal app icon.
  const LogoMark.onColor({super.key, this.size = 72})
      : strokeColor = Colors.white,
        sealColor = const Color(0xFF185FA5),
        ribbonColor = const Color(0xFFB5D4F4),
        dotColor = const Color(0xFFB5D4F4),
        checkColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _LogoPainter(
          strokeColor: strokeColor,
          sealColor: sealColor,
          ribbonColor: ribbonColor,
          dotColor: dotColor,
          checkColor: checkColor,
        ),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  _LogoPainter({
    required this.strokeColor,
    required this.sealColor,
    required this.ribbonColor,
    required this.dotColor,
    required this.checkColor,
  });

  final Color strokeColor;
  final Color sealColor;
  final Color ribbonColor;
  final Color dotColor;
  final Color checkColor;

  // Original art was authored in a 200x200 viewBox — scale to canvas.
  static const double _artSize = 200;

  Offset _p(double x, double y, Size canvas) {
    final scale = canvas.width / _artSize;
    return Offset(x * scale, y * scale);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / _artSize;

    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7 * scale
      ..strokeCap = StrokeCap.round;

    // Briefcase handle arc on top of the capsule.
    final handleRect = Rect.fromCenter(
      center: _p(100, 88, size),
      width: 40 * scale,
      height: 40 * scale,
    );
    canvas.drawArc(handleRect, 3.4, 3.05, false, strokePaint);

    // Rolled diploma capsule.
    final capsuleRect = Rect.fromLTWH(
      30 * scale,
      88 * scale,
      140 * scale,
      44 * scale,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(capsuleRect, Radius.circular(22 * scale)),
      strokePaint,
    );

    // Ribbon tails.
    final ribbonPaint = Paint()..color = ribbonColor;
    final leftTail = Path()
      ..moveTo(_p(90, 108, size).dx, _p(90, 108, size).dy)
      ..lineTo(_p(80, 134, size).dx, _p(80, 134, size).dy)
      ..lineTo(_p(94, 122, size).dx, _p(94, 122, size).dy)
      ..close();
    final rightTail = Path()
      ..moveTo(_p(110, 108, size).dx, _p(110, 108, size).dy)
      ..lineTo(_p(120, 134, size).dx, _p(120, 134, size).dy)
      ..lineTo(_p(106, 122, size).dx, _p(106, 122, size).dy)
      ..close();
    canvas.drawPath(leftTail, ribbonPaint);
    canvas.drawPath(rightTail, ribbonPaint);

    // Certification seal.
    final sealPaint = Paint()..color = sealColor;
    canvas.drawCircle(_p(100, 80, size), 24 * scale, sealPaint);

    // Checkmark inside seal.
    final checkPaint = Paint()
      ..color = checkColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final checkPath = Path()
      ..moveTo(_p(89, 80, size).dx, _p(89, 80, size).dy)
      ..lineTo(_p(97, 88, size).dx, _p(97, 88, size).dy)
      ..lineTo(_p(113, 68, size).dx, _p(113, 68, size).dy);
    canvas.drawPath(checkPath, checkPaint);

    // Technology accent — three connected dots.
    final dotPaint = Paint()..color = dotColor;
    final linePaint = Paint()
      ..color = dotColor
      ..strokeWidth = 2 * scale;
    final d1 = _p(145, 52, size);
    final d2 = _p(160, 64, size);
    final d3 = _p(153, 80, size);
    canvas.drawLine(d1, d2, linePaint);
    canvas.drawLine(d2, d3, linePaint);
    canvas.drawCircle(d1, 5 * scale, dotPaint);
    canvas.drawCircle(d2, 4 * scale, dotPaint);
    canvas.drawCircle(d3, 4 * scale, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _LogoPainter oldDelegate) {
    return oldDelegate.strokeColor != strokeColor ||
        oldDelegate.sealColor != sealColor ||
        oldDelegate.ribbonColor != ribbonColor ||
        oldDelegate.dotColor != dotColor ||
        oldDelegate.checkColor != checkColor;
  }
}
