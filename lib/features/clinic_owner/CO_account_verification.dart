import 'package:flutter/material.dart';

import 'CO_verification_status.dart';
import 'CO_verification_form.dart';

class COAccountVerification extends StatelessWidget {
  const COAccountVerification({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF2FAFE),
    appBar: AppBar(
      title: const Text('Account Verification'),
      backgroundColor: const Color(0xFF3B4E92),
      foregroundColor: Colors.white,
    ),
    body: ValueListenableBuilder<COVerificationStatus>(
      valueListenable: coVerificationStatus,
      builder: (context, status, _) {
        final (title, message, icon, color) = switch (status) {
          COVerificationStatus.unverified => (
            'Not Verified',
            'Complete your company information to request account verification.',
            Icons.shield_outlined,
            const Color(0xFF3B4E92),
          ),
          COVerificationStatus.pending => (
            'Pending Verification',
            'Your clinic information is awaiting review. Your account will be updated once verification is confirmed.',
            Icons.hourglass_top,
            Colors.orange,
          ),
          COVerificationStatus.verified => (
            'Verified',
            'Your clinic account has been verified.',
            Icons.verified_user,
            const Color(0xFF237F7D),
          ),
        };
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 88, color: color),
                  const SizedBox(height: 24),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF666666),
                    ),
                  ),
                  if (status == COVerificationStatus.unverified) ...[
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const COVerificationForm(),
                        ),
                      ),
                      child: const Text('Complete Your Profile'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
