import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ApplicationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> applyForJob(String jobId) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Please log in before applying.');
    }

    final applicationRef = _firestore
        .collection('applications')
        .doc('${jobId}_${user.uid}');

    final jobRef = _firestore.collection('job_postings').doc(jobId);

    await _firestore.runTransaction((transaction) async {
      final jobSnapshot = await transaction.get(jobRef);
      final applicationSnapshot = await transaction.get(applicationRef);

      if (!jobSnapshot.exists) {
        throw Exception('This job no longer exists.');
      }

      final job = jobSnapshot.data()!;

      if (job['status'] != 'available') {
        throw Exception('This job is no longer available.');
      }

      if (applicationSnapshot.exists) {
        throw Exception('You have already applied for this job.');
      }

      transaction.set(applicationRef, {
        'jobId': jobId,
        'locumId': user.uid,
        'clinicOwnerId': job['clinicOwnerId'],
        'status': 'pending',
        'appliedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
