import 'package:flutter_test/flutter_test.dart';
import 'package:optolocum/services/application_service.dart';

void main() {
  test('applicant summary exposes only the three permitted profile fields', () {
    final summary = ApplicantSummary.fromFirestore({
      'fullName': '  Test Locum  ',
      'highestEducation': "Bachelor's Degree",
      'course': 'Optometry',
      'nric': 'private-nric',
      'dateOfBirth': '2000-01-01',
      'phoneNumber': 'private-phone',
      'email': 'private@example.com',
    });
    expect(summary.displayName, 'Test Locum');
    expect(summary.qualification, "Bachelor's Degree in Optometry");
    expect(summary.toFirestore(), {
      'fullName': 'Test Locum',
      'highestEducation': "Bachelor's Degree",
      'course': 'Optometry',
    });
  });

  test('missing or malformed profiles use neutral display text', () {
    final missing = ApplicantSummary.fromFirestore(null);
    expect(missing.displayName, 'Locum Applicant');
    expect(missing.qualification, 'Qualification not available');
    final malformed = ApplicantSummary.fromFirestore({
      'fullName': 123,
      'highestEducation': null,
      'course': '  ',
    });
    expect(malformed.displayName, 'Locum Applicant');
    expect(malformed.qualification, 'Qualification not available');
    expect(
      ApplicantSummary.fromFirestore({'course': 'Optometry'}).qualification,
      'Optometry',
    );
    expect(
      ApplicantSummary.fromFirestore({'highestEducation': 'Diploma'})
          .qualification,
      'Diploma',
    );
  });
}
