import 'package:flutter/material.dart';

import 'CO_navigation.dart';

class COContactUs extends StatelessWidget {
  const COContactUs({super.key});

  @override
  Widget build(BuildContext context) {
    Widget card(List<Widget> children) => Container(
      decoration: BoxDecoration(
        color: const Color(0xFFDDF0FF),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 3,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(children: children),
    );
    Widget info(String title, String detail, IconData icon) => ListTile(
      leading: Icon(icon, color: Colors.black, size: 30),
      title: Text(
        title,
        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        detail,
        style: const TextStyle(fontSize: 15, color: Color(0xFF888888)),
      ),
    );
    return Scaffold(
      backgroundColor: const Color(0xFFF2FAFE),
      appBar: AppBar(
        title: const Text(
          'Contact Us',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF3B4E92),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 18),
                  const Text(
                    'Customer Support',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  card([
                    info(
                      'Email Support',
                      'optolocum.support@gmail.com',
                      Icons.mail_outline,
                    ),
                    info('Hotline', '+60 12-345 6789', Icons.phone_outlined),
                    info(
                      'Support Hours',
                      'Mon - Fri, 9:00 AM - 6:00 PM',
                      Icons.access_time,
                    ),
                  ]),
                  const SizedBox(height: 36),
                  const Text(
                    'Office Information',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  card([
                    info(
                      'Headquarters',
                      'Kuala Lumpur, Malaysia',
                      Icons.location_on,
                    ),
                    info('Company', '+60 12-345 6789', Icons.business_outlined),
                  ]),
                  const SizedBox(height: 56),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9DDFD),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const ListTile(
                      leading: Icon(Icons.security, color: Colors.black),
                      title: Text(
                        'Your trust is our priority',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        'We are committed to providing the best experience for you',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF888888),
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
      bottomNavigationBar: CONavigation(
        profileSelected: true,
        onHome: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
        onProfile: () => Navigator.pop(context),
      ),
    );
  }
}
