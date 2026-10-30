import 'package:cloud_firestore/cloud_firestore.dart';

class PracticeOwnerProfileService {
  Future<void> create({
    required String uid,
    required String fullName,
    required String email,
    required String phoneNumber,
    required String role,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final reference = firestore.collection('practice_owner_profiles').doc(uid);
    // A retry after an uncertain network result must not reset an existing
    // profile's creation timestamp or admin-controlled verification status.
    await firestore.runTransaction((transaction) async {
      final existing = await transaction.get(reference);
      if (existing.exists) return;
      transaction.set(reference, {
        'fullName': fullName.trim(),
        'email': email.trim(),
        'phoneNumber': phoneNumber.trim(),
        'role': role,
        'verificationStatus': 'unverified',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
