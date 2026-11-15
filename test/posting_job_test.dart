import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mocktail/mocktail.dart';
import 'package:optolocum/features/clinic_owner/CO_mainpage.dart';
import 'package:optolocum/features/clinic_owner/CO_postingjob.dart';
import 'package:optolocum/services/job_service.dart';

class _JobService extends Mock implements JobService {}

// ignore: subtype_of_sealed_class
class _QuerySnapshot extends Mock
    implements QuerySnapshot<Map<String, dynamic>> {}

COJobPosting _posting() => COJobPosting(
  placeName: 'Vision Care Clinic',
  location: 'Central Mall',
  role: 'Optometrist',
  date: DateTime(2026, 12, 1),
  start: const TimeOfDay(hour: 9, minute: 0),
  end: const TimeOfDay(hour: 17, minute: 0),
  pay: 65,
  payUnit: 'Per hour',
  description: 'Eye examinations',
  contactPerson: 'Natalie',
  contactNumber: '0123456789',
);

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2026));
  });

  test('jobFromFirestore maps schema fields and rate units', () {
    final job = jobFromFirestore({
      'placeName': 'Vision Care Clinic',
      'location': 'Central Mall',
      'role': 'Optometrist',
      'jobDate': Timestamp.fromDate(DateTime(2026, 12, 1)),
      'startTime': '09:05',
      'endTime': '17:30',
      'payRate': 65,
      'payRateUnit': 'per_shift',
      'jobDescription': 'Eye examinations',
      'contactPerson': 'Natalie',
      'contactNumber': '0123456789',
      'status': 'available',
    }, jobId: 'job-1');

    expect(job.jobId, 'job-1');
    expect(job.start, const TimeOfDay(hour: 9, minute: 5));
    expect(job.end, const TimeOfDay(hour: 17, minute: 30));
    expect(job.payUnit, 'Per shift');
    expect(job.isAvailable, isTrue);
  });

  testWidgets('Successful form submission persists before showing success', (
    tester,
  ) async {
    final service = _JobService();
    when(
      () => service.createJob(
        placeName: any(named: 'placeName'),
        location: any(named: 'location'),
        role: any(named: 'role'),
        jobDate: any(named: 'jobDate'),
        startTime: any(named: 'startTime'),
        endTime: any(named: 'endTime'),
        payRate: any(named: 'payRate'),
        payRateUnit: any(named: 'payRateUnit'),
        jobDescription: any(named: 'jobDescription'),
        contactPerson: any(named: 'contactPerson'),
        contactNumber: any(named: 'contactNumber'),
      ),
    ).thenAnswer((_) async => 'job-id');

    await tester.pumpWidget(
      MaterialApp(
        home: COPostingJob(
          jobService: service,
          jobsStream: Stream.value(<COJobPosting>[]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Create Job Posting'));
    await tester.tap(find.text('Create Job Posting'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    final values = {
      0: 'Vision Care Clinic',
      1: 'Central Mall',
      2: 'Optometrist',
      6: '65',
      7: 'Eye examinations',
      8: 'Natalie',
      9: '0123456789',
    };
    for (final entry in values.entries) {
      await tester.ensureVisible(fields.at(entry.key));
      await tester.pumpAndSettle();
      await tester.enterText(fields.at(entry.key), entry.value);
    }
    await tester.ensureVisible(fields.at(3));
    await tester.tap(fields.at(3));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(fields.at(4));
    await tester.tap(fields.at(4));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(fields.at(5));
    await tester.tap(fields.at(5));
    await tester.pumpAndSettle();
    await tester.tap(find.text('PM'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Post Job'));
    await tester.tap(find.text('Post Job'));
    await tester.pumpAndSettle();

    verify(
      () => service.createJob(
        placeName: 'Vision Care Clinic',
        location: 'Central Mall',
        role: 'Optometrist',
        jobDate: any(named: 'jobDate'),
        startTime: any(named: 'startTime'),
        endTime: any(named: 'endTime'),
        payRate: 65,
        payRateUnit: 'per_hour',
        jobDescription: 'Eye examinations',
        contactPerson: 'Natalie',
        contactNumber: '0123456789',
      ),
    ).called(1);
    expect(find.text('Job Added Successfully!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Empty form validates without creating a job', (tester) async {
    final service = _JobService();
    await tester.pumpWidget(
      MaterialApp(
        home: COPostingJob(
          jobService: service,
          jobsStream: Stream.value(<COJobPosting>[]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Create Job Posting'));
    await tester.tap(find.text('Create Job Posting'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Post Job'));
    await tester.tap(find.text('Post Job'));
    await tester.pumpAndSettle();
    expect(find.text('Select a date'), findsOneWidget);
    expect(find.text('Select start time'), findsOneWidget);
    verifyNever(
      () => service.createJob(
        placeName: any(named: 'placeName'),
        location: any(named: 'location'),
        role: any(named: 'role'),
        jobDate: any(named: 'jobDate'),
        startTime: any(named: 'startTime'),
        endTime: any(named: 'endTime'),
        payRate: any(named: 'payRate'),
        payRateUnit: any(named: 'payRateUnit'),
        jobDescription: any(named: 'jobDescription'),
        contactPerson: any(named: 'contactPerson'),
        contactNumber: any(named: 'contactNumber'),
      ),
    );
    await tester.ensureVisible(find.text('Cancel'));
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Firestore stream displays owner job details', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: COPostingJob(jobsStream: Stream.value([_posting()]))),
    );
    await tester.pumpAndSettle();
    expect(find.text('Optometrist'), findsOneWidget);
    expect(find.text('Vision Care Clinic'), findsOneWidget);
    expect(find.text('RM 65.00 per hour'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('posting screen shows stream loading and error states', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: COPostingJob(jobsStream: const Stream.empty())),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: COPostingJob(
          jobsStream: Stream<List<COJobPosting>>.error(StateError('offline')),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('Failed to load jobs'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home plus opens postings using injected service', (
    tester,
  ) async {
    final service = _JobService();
    final snapshot = _QuerySnapshot();
    when(() => snapshot.docs).thenReturn([]);
    when(() => service.getMyJobs()).thenAnswer((_) => Stream.value(snapshot));
    await tester.pumpWidget(
      MaterialApp(
        home: COMainPage(
          jobService: service,
          jobsStream: Stream.value(<COJobPosting>[]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Post a job'));
    await tester.pumpAndSettle();
    expect(find.text('My Jobs Postings'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
