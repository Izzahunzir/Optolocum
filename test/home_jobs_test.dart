import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:optolocum/features/clinic_owner/CO_mainpage.dart';
import 'package:optolocum/features/clinic_owner/CO_postingjob.dart';

void main() {
  testWidgets('Home updates with posts, searches and sorts by posting order', (
    tester,
  ) async {
    coJobPostings.value = const [];
    addTearDown(() => coJobPostings.value = const []);
    await tester.pumpWidget(const MaterialApp(home: COMainPage()));
    COJobPosting posting(String role, String location) => COJobPosting(
      placeName: 'Vision Clinic',
      location: location,
      role: role,
      date: DateTime(2026, 12, 1),
      start: const TimeOfDay(hour: 9, minute: 0),
      end: const TimeOfDay(hour: 17, minute: 0),
      pay: 65,
      payUnit: 'Per hour',
      description: 'Eye examinations',
      contactPerson: 'Natalie',
      contactNumber: '0123456789',
    );
    coJobPostings.value = [
      posting('Older role', 'Kuala Lumpur'),
      posting('Newer role', 'Johor'),
    ];
    await tester.pumpAndSettle();
    expect(
      tester
          .widgetList<COPostedJobCard>(find.byType(COPostedJobCard))
          .first
          .job
          .role,
      'Newer role',
    );
    await tester.tap(find.byTooltip('Filter jobs'));
    await tester.pumpAndSettle();
      await tester.tap(find.ancestor(of: find.text('Oldest to Recent'), matching: find.byType(CheckedPopupMenuItem<bool>)));
    await tester.pumpAndSettle();
    expect(
      tester
          .widgetList<COPostedJobCard>(find.byType(COPostedJobCard))
          .first
          .job
          .role,
      'Older role',
    );
    await tester.tap(find.byTooltip('Search jobs'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'JOHOR');
    await tester.pumpAndSettle();
    expect(find.byType(COPostedJobCard), findsOneWidget);
    expect(find.text('Newer role'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'no such job');
    await tester.pumpAndSettle();
    expect(find.text('No matching job posts'), findsOneWidget);
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    expect(
      tester.widgetList<COPostedJobCard>(find.byType(COPostedJobCard)).length,
      2,
    );
    expect(tester.takeException(), isNull);
  });
}
