import 'package:flutter/material.dart';

import '../auth/CO_header.dart';
import '../auth/password_reset_page.dart';

class CompanyOwnerForgotPasswordPage extends StatelessWidget {
  const CompanyOwnerForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) => ForgotPasswordPage(
    color: const Color(0xFF263C80),
    backgroundColor: const Color(0xFFF2FAFE),
    headerPainter: CompanyOwnerHeaderPainter(),
  );
}
