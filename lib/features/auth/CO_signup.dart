import 'package:flutter/material.dart';

import 'CO_header.dart';

class CompanyOwnerSignupPage extends StatefulWidget {
  const CompanyOwnerSignupPage({super.key});

  @override
  State<CompanyOwnerSignupPage> createState() => _CompanyOwnerSignupPageState();
}

class _CompanyOwnerSignupPageState extends State<CompanyOwnerSignupPage> {
  static const _blue = Color(0xFF263C80);
  final _formKey = GlobalKey<FormState>();

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Your details are ready. Account registration is coming soon.',
        ),
      ),
    );
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
      borderSide: BorderSide(color: _blue),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    isDense: true,
  );

  Widget _field({
    required String label,
    required String hint,
    required String? Function(String?) validator,
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
          decoration: _decoration(hint),
          keyboardType: keyboardType,
          autofillHints: autofillHints,
          obscureText: obscureText,
          autocorrect: !obscureText,
          enableSuggestions: !obscureText,
          textCapitalization: label == 'Full Name'
              ? TextCapitalization.words
              : TextCapitalization.none,
          textInputAction: TextInputAction.next,
          style: const TextStyle(fontSize: 14),
          validator: validator,
        ),
      ],
    ),
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
                        const CircleAvatar(
                          radius: 60,
                          backgroundColor: Color(0xFFEAEAEA),
                          child: Icon(
                            Icons.person,
                            size: 90,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 42),
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
                                    'COMPANY OWNER',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 23,
                                      fontWeight: FontWeight.w700,
                                      color: _blue,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  _field(
                                    label: 'Full Name',
                                    hint: 'Ali Bin Abu',
                                    autofillHints: const [AutofillHints.name],
                                    validator: (value) =>
                                        (value ?? '').trim().isEmpty
                                        ? 'Enter your full name'
                                        : null,
                                  ),
                                  _field(
                                    label: 'Email Address',
                                    hint: 'ali@gmail.com',
                                    keyboardType: TextInputType.emailAddress,
                                    autofillHints: const [AutofillHints.email],
                                    validator: (value) =>
                                        RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                            .hasMatch((value ?? '').trim())
                                        ? null
                                        : 'Enter a valid email address',
                                  ),
                                  _field(
                                    label: 'Phone Number',
                                    hint: '+0123456789',
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
                                    label: 'Password',
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
                                  const Text(
                                    'Role',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                  const SizedBox(height: 5),
                                  DropdownButtonFormField<String>(
                                    decoration: _decoration('Select'),
                                    hint: const Text(
                                      'Select',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    isExpanded: true,
                                    dropdownColor: Colors.white,
                                    items:
                                        const ['HR', 'Manager', 'Optical Owner']
                                            .map(
                                              (role) => DropdownMenuItem(
                                                value: role,
                                                child: Text(
                                                  role,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                    onChanged: (_) {},
                                    validator: (value) => value == null
                                        ? 'Select your role'
                                        : null,
                                  ),
                                  const SizedBox(height: 32),
                                  ElevatedButton(
                                    onPressed: _submit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _blue,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size.fromHeight(48),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: const Text('Sign Up'),
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
