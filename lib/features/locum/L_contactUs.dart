import 'package:flutter/material.dart';

class LContactUs extends StatelessWidget {
  const LContactUs({super.key, required this.onBack});

  final VoidCallback onBack;

  Widget _card(List<Widget> children) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFEBF6F4),
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 3,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Column(children: children),
  );

  Widget _info(String title, String detail, IconData icon) => ListTile(
    leading: Icon(icon, size: 30, color: Colors.black),
    title: Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
    ),
    subtitle: Text(
      detail,
      style: const TextStyle(fontSize: 14, color: Color(0xFF999999)),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7FCFB),
    appBar: AppBar(
      backgroundColor: const Color(0xFF237F7D),
      foregroundColor: Colors.white,
      centerTitle: false,
      leading: IconButton(
        tooltip: 'Back',
        onPressed: onBack,
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
      ),
      title: const Text(
        'Contact Us',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      ),
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 30, 16, 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Customer Support',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              _card([
                _info(
                  'Email Support',
                  'optolocum.support@gmail.com',
                  Icons.mail_outline,
                ),
                _info('Hotline', '+60 12-345 6789', Icons.phone_outlined),
                _info(
                  'Support Hours',
                  'Mon - Fri, 9:00 AM - 6:00 PM',
                  Icons.access_time,
                ),
              ]),
              const SizedBox(height: 32),
              const Text(
                'Office Information',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              _card([
                _info(
                  'Headquarters',
                  'Kuala Lumpur, Malaysia',
                  Icons.location_on,
                ),
                _info('Company', '+60 12-345 6789', Icons.business_outlined),
              ]),
              const SizedBox(height: 56),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFCBE2E0),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const ListTile(
                  leading: Icon(Icons.security, color: Colors.black),
                  title: Text(
                    'Your trust is our priority',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    'We are committed to providing the best experience for you',
                    style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
