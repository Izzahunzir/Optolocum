import 'package:flutter/material.dart';

import 'CO_header.dart';
import 'CO_signup.dart';
import '../clinic_owner/CO_verify_popup.dart';

class CompanyOwnerSigninPage extends StatefulWidget {
  const CompanyOwnerSigninPage({super.key});

  @override
  State<CompanyOwnerSigninPage> createState() => _CompanyOwnerSigninPageState();
}

class _CompanyOwnerSigninPageState extends State<CompanyOwnerSigninPage> {
  static const _blue = Color(0xFF263C80);
  final _formKey = GlobalKey<FormState>();

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _login() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const COVerifyPopup()));
  }

  InputDecoration _decoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF999999)),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _blue),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    isDense: true,
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
              padding: const EdgeInsets.fromLTRB(24, 56, 24, 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 60,
                        backgroundColor: Color(0xFFEAEAEA),
                        child: Icon(
                          Icons.person,
                          size: 90,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 72),
                      Container(
                        padding: const EdgeInsets.fromLTRB(26, 34, 26, 22),
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
                                  'Login as a',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 23,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const Text(
                                  'COMPANY OWNER',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 23,
                                    fontWeight: FontWeight.w700,
                                    color: _blue,
                                  ),
                                ),
                                const SizedBox(height: 28),
                                const Text(
                                  'Email',
                                  style: TextStyle(fontSize: 13),
                                ),
                                const SizedBox(height: 5),
                                TextFormField(
                                  decoration: _decoration('ali@gmail.com'),
                                  keyboardType: TextInputType.emailAddress,
                                  autofillHints: const [AutofillHints.username],
                                  textInputAction: TextInputAction.next,
                                  autocorrect: false,
                                  style: const TextStyle(fontSize: 14),
                                  validator: (value) =>
                                      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                          .hasMatch((value ?? '').trim())
                                      ? null
                                      : 'Enter a valid email address',
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Password',
                                  style: TextStyle(fontSize: 13),
                                ),
                                const SizedBox(height: 5),
                                TextFormField(
                                  decoration: _decoration(''),
                                  obscureText: true,
                                  autocorrect: false,
                                  enableSuggestions: false,
                                  autofillHints: const [AutofillHints.password],
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _login(),
                                  style: const TextStyle(fontSize: 14),
                                  validator: (value) => (value ?? '').isEmpty
                                      ? 'Enter your password'
                                      : null,
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () => _showMessage(
                                      'Password recovery is coming soon.',
                                    ),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.black,
                                    ),
                                    child: const Text(
                                      'Forgot Password?',
                                      style: TextStyle(
                                        fontSize: 12,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _blue,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size.fromHeight(48),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Text('Login'),
                                ),
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    const Text(
                                      "Don't have an account?",
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(context)
                                          .push(
                                            MaterialPageRoute<void>(
                                              builder: (_) =>
                                                  const CompanyOwnerSignupPage(),
                                            ),
                                          ),
                                      style: TextButton.styleFrom(
                                        foregroundColor: const Color(
                                          0xFFE64B57,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 5,
                                        ),
                                      ),
                                      child: const Text(
                                        'Sign up',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
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
