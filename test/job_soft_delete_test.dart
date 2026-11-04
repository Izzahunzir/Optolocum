import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:optolocum/services/job_availability.dart';
import 'package:optolocum/features/locum/L_jobDetails.dart';
import 'package:optolocum/features/locum/L_savedJob.dart';
import 'package:optolocum/features/clinic_owner/CO_postingjob.dart';

void main() {
  test('owner model excludes deleted postings from active count', () {
    final active = COJobPosting(
      placeName: 'Test',
      location: 'City',
      role: 'Optometrist',
      date: DateTime(2026, 11, 4),
      start: TimeOfDay(hour: 9, minute: 0),
      end: TimeOfDay(hour: 17, minute: 0),
      pay: 50,
      payUnit: 'hour',
      description: 'History',
      contactPerson: 'Owner',
      contactNumber: '000',
    );
    expect(active.isAvailable, true);
    final deleted = COJobPosting(
      status: 'deleted',
      placeName: 'Test',
      location: 'City',
      role: 'Optometrist',
      date: DateTime(2026, 11, 4),
      start: const TimeOfDay(hour: 9, minute: 0),
      end: const TimeOfDay(hour: 17, minute: 0),
      pay: 50,
      payUnit: 'hour',
      description: 'History',
      contactPerson: 'Owner',
      contactNumber: '000',
    );
    expect(deleted.isAvailable, false);
    expect([active, deleted].where((job) => job.isAvailable).length, 1);
  });
  testWidgets('stale open details disables Apply when job becomes deleted', (
    tester,
  ) async {
    final statuses = StreamController<String>();
    addTearDown(statuses.close);
    await tester.pumpWidget(
      MaterialApp(
        home: LJobDetails(
          jobId: 'synthetic-job',
          job: const {'status': 'available', 'role': 'Optometrist'},
          statusStream: statuses.stream,
        ),
      ),
    );
    statuses.add('available');
    await tester.pumpAndSettle();
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNotNull,
    );
    statuses.add('deleted');
    await tester.pumpAndSettle();
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNull,
    );
    expect(find.text('Posting deleted - unavailable'), findsOneWidget);
  });
  testWidgets('deleted saved job remains a clearly unavailable bookmark', (
    tester,
  ) async {
    locumSavedJobs.save(
      const SavedLocumJob(id: 'synthetic-job', title: 'Historical role'),
    );
    addTearDown(locumSavedJobs.clear);
    await tester.pumpWidget(
      MaterialApp(
        home: LSavedJob(
          onBack: () {},
          statusStream: (_) => Stream.value('deleted'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Historical role'), findsOneWidget);
    expect(find.text('Deleted - unavailable'), findsOneWidget);
  });
  testWidgets('availability errors fail closed', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: JobAvailability(
          jobId: 'job',
          statusStream: Stream.error(StateError('offline')),
          builder: (context, available, deleted) =>
              Text(available ? 'available' : 'unavailable'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('unavailable'), findsOneWidget);
  });
}
