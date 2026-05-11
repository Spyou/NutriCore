import 'package:flutter/material.dart';

class GoogleGLogo extends StatelessWidget {
  final double size;
  const GoogleGLogo({super.key, this.size = 18});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  static const _blue = Color(0xFF4285F4);
  static const _green = Color(0xFF34A853);
  static const _yellow = Color(0xFFFBBC05);
  static const _red = Color(0xFFEA4335);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 24;
    canvas.scale(scale, scale);

    // Blue — right side + horizontal bar
    final blue = Path()
      ..moveTo(22.56, 12.25)
      ..cubicTo(22.56, 11.47, 22.49, 10.72, 22.36, 10.00)
      ..lineTo(12.00, 10.00)
      ..lineTo(12.00, 14.26)
      ..lineTo(17.92, 14.26)
      ..cubicTo(17.66, 15.63, 16.88, 16.79, 15.71, 17.57)
      ..lineTo(15.71, 20.34)
      ..lineTo(19.28, 20.34)
      ..cubicTo(21.36, 18.42, 22.56, 15.60, 22.56, 12.25)
      ..close();
    canvas.drawPath(blue, Paint()..color = _blue);

    // Green — bottom
    final green = Path()
      ..moveTo(12.00, 23.00)
      ..cubicTo(14.97, 23.00, 17.46, 22.02, 19.28, 20.34)
      ..lineTo(15.71, 17.57)
      ..cubicTo(14.73, 18.23, 13.48, 18.63, 12.00, 18.63)
      ..cubicTo(9.14, 18.63, 6.71, 16.70, 5.84, 14.10)
      ..lineTo(2.18, 14.10)
      ..lineTo(2.18, 16.94)
      ..cubicTo(3.99, 20.53, 7.70, 23.00, 12.00, 23.00)
      ..close();
    canvas.drawPath(green, Paint()..color = _green);

    // Yellow — left
    final yellow = Path()
      ..moveTo(5.84, 14.10)
      ..cubicTo(5.62, 13.43, 5.49, 12.72, 5.49, 12.00)
      ..cubicTo(5.49, 11.28, 5.62, 10.57, 5.84, 9.90)
      ..lineTo(5.84, 7.06)
      ..lineTo(2.18, 7.06)
      ..cubicTo(1.43, 8.55, 1.00, 10.22, 1.00, 12.00)
      ..cubicTo(1.00, 13.78, 1.43, 15.45, 2.18, 16.94)
      ..lineTo(5.84, 14.10)
      ..close();
    canvas.drawPath(yellow, Paint()..color = _yellow);

    // Red — top
    final red = Path()
      ..moveTo(12.00, 5.37)
      ..cubicTo(13.62, 5.37, 15.06, 5.93, 16.21, 7.02)
      ..lineTo(19.36, 3.87)
      ..cubicTo(17.45, 2.09, 14.97, 1.00, 12.00, 1.00)
      ..cubicTo(7.70, 1.00, 3.99, 3.47, 2.18, 7.06)
      ..lineTo(5.84, 9.90)
      ..cubicTo(6.71, 7.30, 9.14, 5.37, 12.00, 5.37)
      ..close();
    canvas.drawPath(red, Paint()..color = _red);
  }

  @override
  bool shouldRepaint(covariant _GoogleGPainter oldDelegate) => false;
}
