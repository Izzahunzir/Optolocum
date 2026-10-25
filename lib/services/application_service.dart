import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Only the applicant fields that a clinic owner may display.
class ApplicantSummary {
  const ApplicantSummary({
    required this.fullName,
    required this.highestEducation,
    required this.course,
  });

  factory ApplicantSummary.fromFirestore(Map<String, dynamic>? data) {
    String field(String key) {
      final value = data?[key];
      return value is String ? value.trim() : '';
    }

    return ApplicantSummary(
      fullName: field('fullName'),
      highestEducation: field('highestEducation'),
      course: field('course'),
    );
  }

  final String fullName;
  final String highestEducation;
  final String course;

  String get displayName => fullName.isEmpty ? 'Locum Applicant' : fullName;

  String get qualification {
    if (highestEducation.isEmpty && course.isEmpty) {
      return 'Qualification not available';
    }
    if (highestEducation.isEmpty) return course;
    if (course.isEmpty) return highestEducation;
    return '$highestEducation in $course';
  }

  String get selfReportedQualification =>
      highestEducation.isEmpty && course.isEmpty
      ? qualification
      : '$qualification (self-reported)';

  Map<String, String> toFirestore() => {
    'fullName': fullName,
    'highestEducation': highestEducation,
    'course': course,
  };
}

class ApplicationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Read only the Locum-published, application-scoped summary. Private
  /// locum_profiles documents are never requested by clinic-owner pages.
  Stream<ApplicantSummary> watchApplicantSummary({
    required String applicationId,
    required String locumId,
  }) {
    if (_auth.currentUser == null || applicationId.isEmpty || locumId.isEmpty) {
      return Stream.value(ApplicantSummary.fromFirestore(null));
    }
    return _firestore
        .collection('application_applicant_summaries')
        .doc(applicationId)
        .snapshots()
        .map((snapshot) => ApplicantSummary.fromFirestore(snapshot.data()));
  }

  void _checkSummaryAccount(String uid) {
    if (_auth.currentUser?.uid != uid) {
      throw StateError('Your account changed. Please retry from your profile.');
    }
  }

  Future<Map<String, String>?> _mySummaryFields(String uid) async {
    _checkSummaryAccount(uid);
    final snapshot = await _firestore
        .collection('locum_profiles')
        .doc(uid)
        .get();
    _checkSummaryAccount(uid);
    final profile = snapshot.data();
    if (profile == null) return null;
    // Preserve saved values exactly so the rules can compare them with the
    // private profile. Never copy the complete profile or local file paths.
    return {
      for (final key in ['fullName', 'highestEducation', 'course'])
        key: profile[key] is String ? profile[key] as String : '',
    };
  }

  Future<void> publishApplicantSummary(
    String applicationId, {
    required String expectedUid,
  }) async {
    final fields = await _mySummaryFields(expectedUid);
    if (fields == null) return;
    _checkSummaryAccount(expectedUid);
    await _firestore
        .collection('application_applicant_summaries')
        .doc(applicationId)
        .set(fields);
  }

  /// Existing applications are synchronized by their own Locum, using the
  /// already-permitted applications query. No private profile is read by a CO.
  Future<void> refreshMyApplicantSummaries({
    required String expectedUid,
  }) async {
    final fields = await _mySummaryFields(expectedUid);
    if (fields == null) return;
    _checkSummaryAccount(expectedUid);
    final applications = await _firestore
        .collection('applications')
        .where('locumId', isEqualTo: expectedUid)
        .get();
    _checkSummaryAccount(expectedUid);
    var failures = 0;
    for (final application in applications.docs) {
      _checkSummaryAccount(expectedUid);
      try {
        // Individual writes keep each rules evaluation within its access-call
        // limit; one invalid/deleted job must not prevent other summaries.
        await _firestore
            .collection('application_applicant_summaries')
            .doc(application.id)
            .set(fields);
      } on FirebaseException {
        failures++;
      }
    }
    if (failures > 0) {
      debugPrint(
        'Applicant summary refresh incomplete ($failures writes failed). '
        'It will be retried when the Locum next opens or saves their profile.',
      );
    }
  }

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

    // The application is already committed. Missing summary rules, connectivity
    // or profile data must not turn a successful application into a failure.
    unawaited(
      publishApplicantSummary(
        applicationRef.id,
        expectedUid: user.uid,
      ).catchError((Object error) {
        debugPrint(
          'Applicant summary not published; retry from the Locum profile.',
        );
      }),
    );
  }
}
