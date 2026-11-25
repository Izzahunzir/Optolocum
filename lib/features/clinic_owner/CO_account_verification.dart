import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/real_backend_workflows.dart';

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
          COVerificationStatus.approved => (
            'Verified',
            'Your clinic account has been verified.',
            Icons.verified_user,
            const Color(0xFF237F7D),
          ),
          COVerificationStatus.rejected => (
            'Verification Needs Attention',
            'Your clinic verification was not approved. Update your details and submit again.',
            Icons.error_outline,
            Colors.red,
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
                  if (status == COVerificationStatus.approved &&
                      realBackendEnabled)
                    const _ApprovedPracticeDetails(),
                  const SizedBox(height: 24),
                  if (status == COVerificationStatus.unverified ||
                      status == COVerificationStatus.rejected)
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
              ),
            ),
          ),
        );
      },
    ),
  );
}

class _ApprovedPracticeDetails extends StatelessWidget {
  const _ApprovedPracticeDetails();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Text('Sign in to view your details.');
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('practice_owner_profiles')
          .doc(uid)
          .get(const GetOptions(source: Source.server)),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          );
        }
        final data = snapshot.data?.data();
        if (snapshot.hasError ||
            data == null ||
            FirebaseAuth.instance.currentUser?.uid != uid) {
          return const Text('Unable to load verification details.');
        }
        const labels = {
          'practiceType': 'Type of Practice',
          'clinicName': 'Clinic Name',
          'registrationNumber': 'Registration Number',
          'address': 'Address',
          'state': 'State',
          'contactNumber': 'Contact Number',
          'companyEmail': 'Company Email',
        };
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final entry in labels.entries)
              if (data[entry.key] is String &&
                  (data[entry.key] as String).isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text('${entry.value}: ${data[entry.key]}'),
                ),
          ],
        );
      },
    );
  }
}
