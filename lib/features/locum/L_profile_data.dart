import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';

enum LocumVerificationStatus { unverified, pending, verified }

/// Set verified only from persisted backend review results.
final locumVerificationStatus = ValueNotifier(
  LocumVerificationStatus.unverified,
);

/// Firestore-backed fields with session-only document previews.
class LocumProfileData {
  LocumProfileData({
    required Map<String, String> fields,
    required List<XFile> documents,
    this.uid = '',
    this.verificationStatus = 'unverified',
  }) : fields = Map.unmodifiable(fields),
       documents = List.unmodifiable(documents);

  final Map<String, String> fields;
  final List<XFile> documents;
  final String uid;
  final String verificationStatus;

  static const fieldKeys = {
    'Full Name': 'fullName',
    'Email': 'email',
    'NRIC': 'nric',
    'Phone Number': 'phoneNumber',
    'Gender': 'gender',
    'Date of Birth': 'dateOfBirth',
    'Highest Education': 'highestEducation',
    'Course': 'course',
  };

  factory LocumProfileData.fromFirestore(
    String uid,
    Map<String, dynamic> data,
  ) => LocumProfileData(
    uid: uid,
    fields: {
      for (final entry in fieldKeys.entries)
        entry.key: data[entry.value] is String
            ? data[entry.value] as String
            : '',
    },
    verificationStatus: data['verificationStatus'] is String
        ? data['verificationStatus'] as String
        : 'unverified',
    documents: const [],
  );

  Map<String, dynamic> toFirestore() => {
    for (final entry in fieldKeys.entries) entry.value: fields[entry.key] ?? '',
    'verificationStatus': verificationStatus,
  };
}

final locumProfileData = ValueNotifier<LocumProfileData?>(null);
