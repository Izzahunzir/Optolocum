import 'package:file_selector/file_selector.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:optolocum/features/locum/L_profile_data.dart';

void main() {
  test(
    'profile persistence excludes local document paths and cache ownership',
    () {
      final profile = LocumProfileData(
        uid: 'locum-123',
        fields: const {
          'Full Name': 'Test Locum',
          'Email': 'locum@example.com',
          'NRIC': '001122334455',
          'Phone Number': '+60123456789',
          'Gender': 'Female',
          'Date of Birth': '2000-01-01',
          'Highest Education': 'Degree',
          'Course': 'Optometry',
        },
        documents: [XFile('private/local/identity.pdf')],
        verificationStatus: 'pending',
      );

      final data = profile.toFirestore();
      expect(data.keys.toSet(), {
        'fullName',
        'email',
        'nric',
        'phoneNumber',
        'gender',
        'dateOfBirth',
        'highestEducation',
        'course',
        'verificationStatus',
      });
      expect(data.toString(), isNot(contains('private/local')));
      expect(data['verificationStatus'], 'pending');
      final restored = LocumProfileData.fromFirestore('locum-123', data);
      expect(restored.fields, profile.fields);
      expect(restored.documents, isEmpty);
      expect(restored.uid, 'locum-123');
    },
  );

  test(
    'loading uses document ownership and ignores persisted preview data',
    () {
      final profile = LocumProfileData.fromFirestore('current-locum', {
        'uid': 'another-locum',
        'fullName': null,
        'course': 42,
        'documents': ['another-account/private.pdf'],
        'verificationStatus': true,
      });
      expect(profile.uid, 'current-locum');
      expect(profile.fields['Full Name'], '');
      expect(profile.fields['Course'], '');
      expect(profile.documents, isEmpty);
      expect(profile.verificationStatus, 'unverified');
    },
  );
}
