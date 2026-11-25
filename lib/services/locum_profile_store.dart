import 'package:cloud_firestore/cloud_firestore.dart';

import '../features/locum/L_profile_data.dart';

/// Persists profile submissions without replacing fields managed by the backend.
class LocumProfileStore {
  LocumProfileStore(this.firestore);

  final FirebaseFirestore firestore;

  Future<void> save(LocumProfileData profile) async {
    final reference = firestore.collection('locum_profiles').doc(profile.uid);
    await firestore.runTransaction<void>((transaction) async {
      final snapshot = await transaction.get(reference);
      final existingStatus = snapshot.data()?['verificationStatus'];
      if (existingStatus == 'approved') {
        throw StateError('Approved verification details are read-only.');
      }
      final preserveApproval =
          existingStatus == 'verified' || existingStatus == 'approved';
      final fields = profile.toFirestore();
      if (preserveApproval) fields.remove('verificationStatus');
      transaction.set(reference, {
        ...fields,
        // Test document existence, not field presence: older profiles must not
        // acquire a guessed registration date when they are next edited.
        if (!snapshot.exists) 'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }
}
