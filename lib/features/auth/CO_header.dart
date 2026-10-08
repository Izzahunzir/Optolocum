import 'package:flutter/material.dart';

class CompanyOwnerHeaderPainter extends CustomPainter {
  const CompanyOwnerHeaderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF263C80), Color(0xFF6F86B8), Color(0xFFF2FAFE)],
        ).createShader(bounds),
    );
    final wave = Path()
      ..moveTo(0, size.height * 0.9)
      ..cubicTo(
        size.width * 0.32,
        size.height * 1.18,
        size.width * 0.32,
        size.height * 0.32,
        size.width * 0.76,
        size.height * 0.28,
      )
      ..cubicTo(
        size.width * 0.84,
        size.height * 0.26,
        size.width * 0.92,
        size.height * 0.32,
        size.width,
        size.height * 0.36,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(wave, Paint()..color = const Color(0xFFF2FAFE));
  }

  @override
  bool shouldRepaint(CompanyOwnerHeaderPainter oldDelegate) => false;
}
