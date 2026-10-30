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
      transaction.set(reference, {
        ...profile.toFirestore(),
        // Test document existence, not field presence: older profiles must not
        // acquire a guessed registration date when they are next edited.
        if (!snapshot.exists) 'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }
}
