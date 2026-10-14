import 'package:flutter/material.dart';

import '../auth/CO_header.dart';

class LocumForgotPasswordPage extends StatefulWidget {
  const LocumForgotPasswordPage({super.key});

  @override
  State<LocumForgotPasswordPage> createState() =>
      _LocumForgotPasswordPageState();
}

class _LocumForgotPasswordPageState extends State<LocumForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  void _resetPassword() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Password reset is not connected yet.')),
      );
  }

  InputDecoration _decoration(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    border: const OutlineInputBorder(borderSide: BorderSide.none),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECF6F5),
      body: Stack(
        children: [
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 270,
            child: ExcludeSemantics(
              child: CustomPaint(painter: LocumHeaderPainter()),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(24, 190, 24, 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(26, 34, 26, 30),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAEAEA),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: AutofillGroup(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Forgot Password',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Please enter your new password below to\nreset your account password.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF999999),
                              ),
                            ),
                            const SizedBox(height: 42),
                            const Text(
                              'Create New Password',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 22),
                            const Text(
                              'New Password',
                              style: TextStyle(fontSize: 13),
                            ),
                            const SizedBox(height: 5),
                            TextFormField(
                              controller: _password,
                              decoration: _decoration('Enter new password'),
                              obscureText: true,
                              autocorrect: false,
                              enableSuggestions: false,
                              autofillHints: const [AutofillHints.newPassword],
                              textInputAction: TextInputAction.next,
                              validator: (value) => (value ?? '').length < 8
                                  ? 'Use at least 8 characters'
                                  : null,
                            ),
                            const SizedBox(height: 22),
                            const Text(
                              'Confirm New Password',
                              style: TextStyle(fontSize: 13),
                            ),
                            const SizedBox(height: 5),
                            TextFormField(
                              decoration: _decoration('Confirm new password'),
                              obscureText: true,
                              autocorrect: false,
                              enableSuggestions: false,
                              autofillHints: const [AutofillHints.newPassword],
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _resetPassword(),
                              validator: (value) => (value ?? '').isEmpty
                                  ? 'Confirm your password'
                                  : value != _password.text
                                  ? 'Passwords do not match'
                                  : null,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _resetPassword,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF237F7D),
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(48),
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text('Reset Password'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: CompanyOwnerBackButton(),
            ),
          ),
        ],
      ),
    );
  }
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
