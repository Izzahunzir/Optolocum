import 'package:flutter_test/flutter_test.dart';
import 'package:optolocum/services/application_service.dart';

void main() {
  test('summary maps approved and legacy verified statuses consistently', () {
    expect(applicantSummaryStatus('approved'), 'verified');
    expect(applicantSummaryStatus('verified'), 'verified');
    expect(applicantSummaryStatus('pending'), 'pending');
    expect(applicantSummaryStatus('rejected'), 'unverified');
  });
  test('applicant summary exposes only permitted profile fields', () {
    final summary = ApplicantSummary.fromFirestore({
      'fullName': '  Test Locum  ',
      'highestEducation': "Bachelor's Degree",
      'course': 'Optometry',
      'verificationStatus': 'unverified',
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
      'verificationStatus': 'unverified',
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
