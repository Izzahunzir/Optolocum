import 'package:flutter/material.dart';

import '../auth/CO_header.dart';

class CompanyOwnerForgotPasswordPage extends StatefulWidget {
  const CompanyOwnerForgotPasswordPage({super.key});

  @override
  State<CompanyOwnerForgotPasswordPage> createState() =>
      _CompanyOwnerForgotPasswordPageState();
}

class _CompanyOwnerForgotPasswordPageState
    extends State<CompanyOwnerForgotPasswordPage> {
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
      backgroundColor: const Color(0xFFF2FAFE),
      body: Stack(
        children: [
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 270,
            child: ExcludeSemantics(
              child: CustomPaint(painter: CompanyOwnerHeaderPainter()),
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
                                backgroundColor: const Color(0xFF263C80),
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
