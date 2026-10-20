import 'package:flutter/material.dart';

import 'L_jobProcessGuide.dart';
import 'L_profile_data.dart';
import 'L_verification_form.dart';

/// Account tab content; the main page owns navigation and logout.
class LProfile extends StatelessWidget {
  const LProfile({
    super.key,
    required this.onLogout,
    required this.onContactUs,
    required this.onSavedJobs,
    this.name = 'Nursarah Zulkaedah',
    this.shiftHours = 0,
  });

  final VoidCallback onLogout;
  final VoidCallback onContactUs;
  final VoidCallback onSavedJobs;
  final String name;
  final int shiftHours;

  static const _teal = Color(0xFF237F7D);
  static const _card = Color(0xFFEBF6F4);

  Widget _option(String label, IconData icon, {VoidCallback? onTap}) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Material(
      color: _card,
      elevation: 3,
      shadowColor: const Color(0x55000000),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: Icon(icon, color: Colors.black),
        title: Text(
          label,
          style: const TextStyle(fontSize: 16, color: Colors.black),
        ),
        onTap: onTap,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(12, 32, 12, 28),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          children: [
            const Icon(Icons.account_circle, size: 120, color: _teal),
            const SizedBox(height: 20),
            ValueListenableBuilder<LocumProfileData?>(
              valueListenable: locumProfileData,
              builder: (context, profile, _) => Text(
                profile?.fields['Full Name'] ?? name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(18),
              ),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Current\nShift Hours',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                    const VerticalDivider(
                      color: Colors.black,
                      thickness: 1,
                      width: 1,
                    ),
                    Expanded(
                      child: Text(
                        '$shiftHours hours',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _option(
              'Account Verification',
              Icons.how_to_reg,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  // Reuse the onboarding form, but prefill it and show Update.
                  builder: (_) => const LVerificationForm(isEditing: true),
                ),
              ),
            ),
            _option(
              'Job Process Guide',
              Icons.work,
              onTap: () => showLJobProcessGuide(context),
            ),
            _option('Contact Us', Icons.chat, onTap: onContactUs),
            _option('Saved Job', Icons.bookmark, onTap: onSavedJobs),
            _option('Logout', Icons.logout, onTap: onLogout),
          ],
        ),
      ),
    ),
  );
}
