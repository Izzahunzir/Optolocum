import 'package:flutter/material.dart';

import '../auth/password_reset_page.dart';

class LocumForgotPasswordPage extends StatelessWidget {
  const LocumForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) => const ForgotPasswordPage(
    color: Color(0xFF237F7D),
    backgroundColor: Color(0xFFECF6F5),
    headerPainter: LocumHeaderPainter(),
  );
}

class LocumHeaderPainter extends CustomPainter {
  const LocumHeaderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF147B78), Color(0xFF9DE4E0)],
        ).createShader(bounds),
    );
    final wave = Path()
      ..moveTo(0, size.height * 0.9)
      ..cubicTo(
        size.width * 0.32,
        size.height * 1.18,
        size.width * 0.22,
        size.height * 0.56,
        size.width * 0.50,
        size.height * 0.56,
      )
      ..cubicTo(
        size.width * 0.65,
        size.height * 0.56,
        size.width * 0.68,
        size.height * 0.10,
        size.width,
        size.height * 0.36,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(wave, Paint()..color = const Color(0xFFECF6F5));
  }

  @override
  bool shouldRepaint(LocumHeaderPainter oldDelegate) => false;
}
