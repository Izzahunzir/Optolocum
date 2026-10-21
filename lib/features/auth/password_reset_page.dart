import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:optolocum/services/auth_service.dart';

import 'CO_header.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({
    super.key,
    required this.color,
    required this.backgroundColor,
    required this.headerPainter,
  });

  final Color color;
  final Color backgroundColor;
  final CustomPainter headerPainter;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_sending || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final email = _email.text.trim();
    setState(() => _sending = true);
    try {
      await AuthService().resetPassword(email);
      if (!mounted) return;
      final reset = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => CreateNewPasswordPage(
            email: email,
            color: widget.color,
            backgroundColor: widget.backgroundColor,
            headerPainter: widget.headerPainter,
          ),
        ),
      );
      if (!mounted) return;
      if (reset == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password updated. Log in with your new password.'),
          ),
        );
        Navigator.of(context).pop();
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message ?? 'Unable to send reset email. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => _ResetLayout(
    backgroundColor: widget.backgroundColor,
    headerPainter: widget.headerPainter,
    child: Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Forgot Password',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          const Text(
            'Enter your account email address. We will send you a password reset link.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          TextFormField(
            controller: _email,
            decoration: _decoration(
              'Email Address',
              'Enter your email address',
            ),
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            autocorrect: false,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _continue(),
            validator: (value) =>
                RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                    .hasMatch((value ?? '').trim())
                ? null
                : 'Enter a valid email address',
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _sending ? null : _continue,
            style: _buttonStyle(widget.color),
            child: Text(_sending ? 'Sending...' : 'Continue'),
          ),
        ],
      ),
    ),
  );
}

class CreateNewPasswordPage extends StatefulWidget {
  const CreateNewPasswordPage({
    super.key,
    required this.email,
    required this.color,
    required this.backgroundColor,
    required this.headerPainter,
  });

  final String email;
  final Color color;
  final Color backgroundColor;
  final CustomPainter headerPainter;

  @override
  State<CreateNewPasswordPage> createState() => _CreateNewPasswordPageState();
}

class _CreateNewPasswordPageState extends State<CreateNewPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _link = TextEditingController();
  final _password = TextEditingController();
  bool _saving = false;

  String? get _code =>
      Uri.tryParse(_link.text.trim())?.queryParameters['oobCode'];

  @override
  void dispose() {
    _link.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final code = _code!;
    final password = _password.text;
    setState(() => _saving = true);
    try {
      await AuthService().confirmPasswordReset(
        email: widget.email,
        code: code,
        password: password,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message ?? 'Unable to reset password. Request a new reset email and try again.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => _ResetLayout(
    backgroundColor: widget.backgroundColor,
    headerPainter: widget.headerPainter,
    child: Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Create New Password',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          Text(
            'If an account exists for ${widget.email}, a reset email has been sent. Copy the reset link from that email and paste it below without opening it. Check your spam folder too.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          TextFormField(
            controller: _link,
            decoration: _decoration(
              'Password Reset Link',
              'Paste the link from your email',
            ),
            keyboardType: TextInputType.url,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.next,
            validator: (_) => (_code ?? '').isEmpty
                ? 'Paste a valid password reset link from your email'
                : null,
          ),
          const SizedBox(height: 22),
          TextFormField(
            controller: _password,
            decoration: _decoration('New Password', 'Enter new password'),
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            autofillHints: const [AutofillHints.newPassword],
            textInputAction: TextInputAction.next,
            validator: (value) =>
                (value ?? '').length < 8 ? 'Use at least 8 characters' : null,
          ),
          const SizedBox(height: 22),
          TextFormField(
            decoration: _decoration(
              'Confirm New Password',
              'Confirm new password',
            ),
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            autofillHints: const [AutofillHints.newPassword],
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _reset(),
            validator: (value) => (value ?? '').isEmpty
                ? 'Confirm your password'
                : value != _password.text
                ? 'Passwords do not match'
                : null,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saving ? null : _reset,
            style: _buttonStyle(widget.color),
            child: Text(_saving ? 'Updating...' : 'Reset Password'),
          ),
        ],
      ),
    ),
  );
}

InputDecoration _decoration(String label, String hint) => InputDecoration(
  labelText: label,
  hintText: hint,
  filled: true,
  fillColor: Colors.white,
  border: const OutlineInputBorder(borderSide: BorderSide.none),
);

ButtonStyle _buttonStyle(Color color) => ElevatedButton.styleFrom(
  backgroundColor: color,
  foregroundColor: Colors.white,
  minimumSize: const Size.fromHeight(48),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
);

class _ResetLayout extends StatelessWidget {
  const _ResetLayout({
    required this.backgroundColor,
    required this.headerPainter,
    required this.child,
  });
  final Color backgroundColor;
  final CustomPainter headerPainter;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: backgroundColor,
    body: Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 270,
          child: ExcludeSemantics(child: CustomPaint(painter: headerPainter)),
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
                  child: AutofillGroup(child: child),
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
