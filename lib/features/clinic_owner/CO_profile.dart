import 'package:flutter/material.dart';

import '../intro/intro_page.dart';
import 'CO_contact_us.dart';
import 'CO_navigation.dart';
import 'CO_verification_status.dart';
import 'CO_account_verification.dart';
import 'CO_postingjob.dart';

class COProfile extends StatelessWidget {
  const COProfile({
    super.key,
    this.name = 'Clinic Owner',
    this.role = 'Practice Owner',
    this.clinicName = 'Clinic details not provided',
  });
  final String name, role, clinicName;

  void _help(BuildContext context) => showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'How to add Job?',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
              ),
              SizedBox(height: 28),
              Text('＋ Tap the “+” button to create a new job posting.'),
              SizedBox(height: 20),
              Text(
                '📝 Fill in the job details, including clinic information, shift date, working hours, and pay rate.',
              ),
              SizedBox(height: 20),
              Text(
                '📋 Add a short job description so locums can better understand the role.',
              ),
              SizedBox(height: 20),
              Text('📤 Tap “Post Job” once everything is ready.'),
              SizedBox(height: 20),
              Text(
                '🔔 Your posting will go live and become visible to locums on the platform.',
              ),
              SizedBox(height: 20),
              Text(
                '💬 Interested locums can then apply and contact you directly through the app.',
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Are you sure you want to sign out?',
                  textAlign: TextAlign.center,
                ),
              ),
              const Divider(height: 1),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Log Out'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true || !context.mounted) return;
    coVerificationStatus.value = COVerificationStatus.unverified;
    coJobPostings.value = const [];
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const IntroPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget option(String title, IconData icon, VoidCallback onTap) => Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Material(
        color: const Color(0xFFDDF0FF),
        borderRadius: BorderRadius.circular(18),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          leading: Icon(icon, color: Colors.black),
          title: Text(title, style: const TextStyle(fontSize: 16)),
          onTap: onTap,
        ),
      ),
    );
    return Scaffold(
      backgroundColor: const Color(0xFFF2FAFE),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 64, 24, 30),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 56,
                    backgroundColor: Color(0xFF263C80),
                    child: Icon(
                      Icons.person,
                      size: 90,
                      color: Color(0xFFF2FAFE),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    role,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 17),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    clinicName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 17),
                  ),
                  const SizedBox(height: 48),
                  option(
                    'Account Verification',
                    Icons.how_to_reg,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const COAccountVerification(),
                      ),
                    ),
                  ),
                  option('How to add Job', Icons.work, () => _help(context)),
                  option(
                    'Contact Us',
                    Icons.chat,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const COContactUs(),
                      ),
                    ),
                  ),
                  option('Logout', Icons.logout, () => _logout(context)),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: CONavigation(
        profileSelected: true,
        onHome: () => Navigator.pop(context),
        onProfile: () {},
      ),
    );
  }
}
