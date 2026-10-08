import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:optolocum/features/clinic_owner/CO_locum_activity.dart';
import 'package:optolocum/features/clinic_owner/CO_mainpage.dart';

void main() {
  testWidgets('Locum navigation opens all three empty activity tabs', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: COMainPage()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Locum'));
    await tester.pumpAndSettle();
    expect(find.text('Locum Activity'), findsOneWidget);
    expect(find.text('No pending applications yet'), findsOneWidget);
    await tester.tap(find.text('Current'));
    await tester.pumpAndSettle();
    expect(find.text('No current locum jobs yet'), findsOneWidget);
    await tester.tap(find.text('Completed'));
    await tester.pumpAndSettle();
    expect(find.text('No completed locum jobs yet'), findsOneWidget);
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
      expect(find.text('Applicant A'), findsOneWidget);
      expect(find.text('Applicant B'), findsNothing);
      await tester.ensureVisible(find.text('Approve'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Approve'));
      expect(actionId, 'Applicant A');
      await tester.tap(find.text('Current'));
      await tester.pumpAndSettle();
      expect(find.text('Applicant C'), findsOneWidget);
      await tester.ensureVisible(find.text('Message'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Message'));
      expect(actionId, 'job-1');
      expect(tester.takeException(), isNull);
    },
  );
}
