import 'package:optolocum/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../auth/CO_header.dart';

import 'L_forgotpass.dart';
import '../locum/L_verify_popup.dart';

class LocumSignupPage extends StatefulWidget {
  const LocumSignupPage({super.key});

  @override
  State<LocumSignupPage> createState() => _LocumSignupPageState();
}

class _LocumSignupPageState extends State<LocumSignupPage> {
  static const _teal = Color(0xFF237F7D);
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isSubmitting = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  String _fullName = '';

  Future<void> _submit() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);
    try {
      await AuthService().signUp(
        email: emailController.text,
        password: passwordController.text,
      );
      if (!mounted) return;
      _formKey.currentState!.save();
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => LVerifyPopup(displayName: _fullName),
        ),
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('Signup failed: ${e.code}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Authentication failed: ${e.code}'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  InputDecoration _decoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF999999)),
    filled: true,
    fillColor: Colors.white,
    border: const OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide.none,
    ),
    enabledBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide.none,
    ),
    focusedBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: _teal),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    isDense: true,
  );

  Widget _field({
    required String label,
    required String hint,
    required String? Function(String?) validator,
    TextEditingController? controller,
    TextInputType? keyboardType,
    Iterable<String>? autofillHints,
    bool obscureText = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13)),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          decoration: _decoration(hint).copyWith(
            suffixIcon: obscureText
                ? IconButton(
                    tooltip: _obscurePassword
                        ? 'Show password'
                        : 'Hide password',
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  )
                : null,
          ),
          keyboardType: keyboardType,
          autofillHints: autofillHints,
          obscureText: obscureText && _obscurePassword,
          autocorrect: !obscureText,
          enableSuggestions: !obscureText,
          textCapitalization: label == 'Full Name'
              ? TextCapitalization.words
              : TextCapitalization.none,
          textInputAction: TextInputAction.next,
          style: const TextStyle(fontSize: 14),
          validator: validator,
          onSaved: label == 'Full Name'
              ? (value) => _fullName = (value ?? '').trim()
              : null,
        ),
      ],
    ),
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
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(24, 56, 24, 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.fromLTRB(26, 34, 26, 24),
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
                                    'Sign up as a',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 23,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const Text(
                                    'LOCUM',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 23,
                                      fontWeight: FontWeight.w700,
                                      color: _teal,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  _field(
                                    label: 'Full Name',
                                    hint: 'Nursarah Binti Zulkaedah',
                                    autofillHints: const [AutofillHints.name],
                                    validator: (value) =>
                                        (value ?? '').trim().isEmpty
                                        ? 'Enter your full name'
                                        : null,
                                  ),
                                  _field(
                                    label: 'Phone Number',
                                    hint: '+6011-2346578',
                                    keyboardType: TextInputType.phone,
                                    autofillHints: const [
                                      AutofillHints.telephoneNumber,
                                    ],
                                    validator: (value) =>
                                        RegExp(r'^\+?[0-9]{7,15}$').hasMatch(
                                          (value ?? '').replaceAll(
                                            RegExp(r'[\s()-]'),
                                            '',
                                          ),
                                        )
                                        ? null
                                        : 'Enter a valid phone number',
                                  ),
                                  _field(
                                    label: 'Email Address',
                                    controller: emailController,
                                    hint: 'sarahzulkaedah@gmail.com',
                                    keyboardType: TextInputType.emailAddress,
                                    autofillHints: const [AutofillHints.email],
                                    validator: (value) =>
                                        RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                            .hasMatch((value ?? '').trim())
                                        ? null
                                        : 'Enter a valid email address',
                                  ),
                                  _field(
                                    label: 'Password',
                                    controller: passwordController,
                                    hint: 'Enter your password',
                                    obscureText: true,
                                    autofillHints: const [
                                      AutofillHints.newPassword,
                                    ],
                                    validator: (value) =>
                                        (value ?? '').length < 8
                                        ? 'Use at least 8 characters'
                                        : null,
                                  ),
                                  FormField<bool>(
                                    initialValue: false,
                                    validator: (value) => value == true ? null : 'Please accept the terms and privacy policy',
                                    builder: (field) => Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Checkbox(
                                              value: field.value ?? false,
                                              activeColor: _teal,
                                              onChanged: (value) =>
                                                  field.didChange(value),
                                            ),
                                            Expanded(
                                              child: Wrap(
                                                crossAxisAlignment:
                                                    WrapCrossAlignment.center,
                                                children: [
                                                  const Text(
                                                    'I have read all the ',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  TextButton(
                                                    onPressed: () => showDialog<void>(
                                                      context: context,
                                                      builder: (context) =>
                                                          AlertDialog(
                                                            title: const Text(
                                                              'Terms & Privacy Policy',
                                                            ),
                                                            content: const Text(
                                                              'Terms and privacy policy content is not available yet.',
                                                            ),
                                                            actions: [
                                                              TextButton(
                                                                onPressed: () =>
                                                                    Navigator.of(
                                                                      context,
                                                                    ).pop(),
                                                                child:
                                                                    const Text(
                                                                      'Close',
                                                                    ),
                                                              ),
                                                            ],
                                                          ),
                                                    ),
                                                    style: TextButton.styleFrom(
                                                      foregroundColor:
                                                          Colors.black,
                                                      padding: EdgeInsets.zero,
                                                    ),
                                                    child: const Text(
                                                      'Terms & Privacy Policy',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        decoration:
                                                            TextDecoration
                                                                .underline,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (field.hasError)
                                          Text(
                                            field.errorText!,
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .error,
                                              fontSize: 12,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton(
                                    onPressed: _isSubmitting ? null : _submit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _teal,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size.fromHeight(48),
                                      elevation: 3,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: const Text('Sign Up'),
                                  ),
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      const Text(
                                        'Already have an account?',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).maybePop(),
                                        style: TextButton.styleFrom(
                                          foregroundColor: const Color(
                                            0xFFE64B57,
                                          ),
                                        ),
                                        child: const Text(
                                          'Login',
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
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: const CompanyOwnerBackButton(),
            ),
          ),
        ],
      ),
    );
  }
}
