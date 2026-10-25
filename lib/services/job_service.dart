import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class JobService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> createJob({
    required String placeName,
    required String location,
    required String role,
    required DateTime jobDate,
    required String startTime,
    required String endTime,
    required double payRate,
    required String payRateUnit,
    required String jobDescription,
    required String contactPerson,
    required String contactNumber,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Please log in before posting a job.');
    }

    final document = await _firestore.collection('job_postings').add({
      'clinicOwnerId': user.uid,
      'placeName': placeName,
      'location': location,
      'role': role,
      'jobDate': Timestamp.fromDate(jobDate),
      'startTime': startTime,
      'endTime': endTime,
      'payRate': payRate,
      'payRateUnit': payRateUnit,
      'jobDescription': jobDescription,
      'contactPerson': contactPerson,
      'contactNumber': contactNumber,
      'status': 'available',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return document.id;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getMyJobs() {
    final user = _auth.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('job_postings')
        .where('clinicOwnerId', isEqualTo: user.uid)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getAvailableJobs() {
    return _firestore
        .collection('job_postings')
        .where('status', isEqualTo: 'available')
        .snapshots();
  }
}
