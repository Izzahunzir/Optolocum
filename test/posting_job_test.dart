import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:optolocum/features/clinic_owner/CO_mainpage.dart';
import 'package:optolocum/features/clinic_owner/CO_postingjob.dart';

void main() {
  setUp(() => coJobPostings.value = const []);
  tearDown(() => coJobPostings.value = const []);
  testWidgets(
    'Valid form submission creates a posting and shows its success banner',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: COPostingJob()));
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
      await tester.pumpAndSettle();
      await tester.ensureVisible(fields.at(3));
      await tester.pumpAndSettle();
      await tester.tap(fields.at(3));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(fields.at(4));
      await tester.pumpAndSettle();
      await tester.tap(fields.at(4));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(fields.at(5));
      await tester.pumpAndSettle();
      await tester.tap(fields.at(5));
      await tester.pumpAndSettle();
      await tester.tap(find.text('PM'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Post Job'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Post Job'));
      await tester.pumpAndSettle();
      expect(coJobPostings.value.length, 1);
      expect(find.text('Job Added Successfully!'), findsOneWidget);
      expect(find.text('Optometrist'), findsOneWidget);
      expect(find.text('0 locum applied'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.text('Job Added Successfully!'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Center plus opens postings and empty form validates without creating a job',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: COMainPage()));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Post a job'));
      await tester.pumpAndSettle();
      expect(find.text('My Jobs Postings'), findsOneWidget);
      await tester.ensureVisible(find.text('Create Job Posting'));
      await tester.tap(find.text('Create Job Posting'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Post Job'));
      await tester.tap(find.text('Post Job'));
      await tester.pumpAndSettle();
      expect(find.text('Select a date'), findsOneWidget);
      expect(find.text('Select start time'), findsOneWidget);
      expect(coJobPostings.value, isEmpty);
      await tester.ensureVisible(find.text('Cancel'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(coJobPostings.value, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Session postings display their actual clinic and job details', (
    tester,
  ) async {
    coJobPostings.value = [
      COJobPosting(
        placeName: 'Vision Care Clinic',
        location: 'Central Mall',
        role: 'Senior Optometrist',
        date: DateTime(2026, 12, 1),
        start: const TimeOfDay(hour: 9, minute: 0),
        end: const TimeOfDay(hour: 17, minute: 0),
        pay: 65,
        payUnit: 'Per hour',
        description: 'Assist with eye exams.',
        contactPerson: 'Natalie',
        contactNumber: '0123456789',
      ),
    ];
    await tester.pumpWidget(const MaterialApp(home: COPostingJob()));
    await tester.pumpAndSettle();
    expect(find.text('Senior Optometrist'), findsOneWidget);
    expect(find.text('Vision Care Clinic'), findsOneWidget);
    expect(find.text('RM 65.00 per hour'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
