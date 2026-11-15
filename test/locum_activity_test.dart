import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:optolocum/features/clinic_owner/CO_locum_activity.dart';
import 'package:optolocum/features/clinic_owner/CO_mainpage.dart';

void main() {
  testWidgets('Locum navigation opens all three empty activity tabs', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: COMainPage(
          jobsStream: Stream.value([]),
          activityAuthStream: Stream.value(null),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Locum'));
    await tester.pumpAndSettle();
    expect(find.text('Locum Activity'), findsOneWidget);
    expect(find.text('Please sign in to view applications.'), findsOneWidget);
    await tester.tap(find.text('Current'));
    await tester.pumpAndSettle();
    expect(find.text('Please sign in to view applications.'), findsOneWidget);
    await tester.tap(find.text('Completed'));
    await tester.pumpAndSettle();
    expect(find.text('Please sign in to view applications.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Application cards filter by owner and pass the job-linked application to actions',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      COLocumApplication entry(
        String id,
        String owner,
        COLocumActivityStatus status,
      ) => COLocumApplication(
        id: id,
        jobId: 'job-1',
        clinicOwnerId: owner,
        status: status,
        name: id,
        qualification: 'BOptom (Hons)',
        verificationStatus: 'unverified',
        jobDate: '12 May 2026',
        time: '9:00 AM - 5:00 PM',
        location: 'Vision Care Clinic, Central Mall',
        position: 'Senior Optometrist',
        rating: 4.9,
        reviewCount: 32,
      );
      String? actionId;
      await tester.pumpWidget(
        MaterialApp(
          home: COLocumActivity(
            clinicOwnerId: 'owner-1',
            authStream: Stream.value(null),
            applications: [
              entry('Applicant A', 'owner-1', COLocumActivityStatus.pending),
              entry('Applicant B', 'owner-2', COLocumActivityStatus.pending),
              entry('Applicant C', 'owner-1', COLocumActivityStatus.current),
            ],
            onApprove: (application) => actionId = application.id,
            onMessage: (application) => actionId = application.jobId,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Please sign in to view applications.'), findsOneWidget);
      expect(find.text('Applicant B'), findsNothing);
      expect(actionId, isNull);
      expect(tester.takeException(), isNull);
    },
  );
}
