import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:optolocum/features/locum/L_mainpage.dart';

class _Document extends Fake
    implements QueryDocumentSnapshot<Map<String, dynamic>> {
  _Document(this.id, this.values);
  @override
  final String id;
  final Map<String, dynamic> values;
  @override
  Map<String, dynamic> data() => values;
}

class _Snapshot extends Fake implements QuerySnapshot<Map<String, dynamic>> {
  _Snapshot(this.docs);
  @override
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
}

void main() {
  testWidgets('only available jobs appear and deletion updates immediately', (
    tester,
  ) async {
    final snapshots = StreamController<QuerySnapshot<Map<String, dynamic>>>();
    addTearDown(snapshots.close);
    await tester.pumpWidget(
      MaterialApp(home: LMainPage(jobsStream: snapshots.stream)),
    );
    _Snapshot jobs(String status) => _Snapshot([
      _Document('live', {'status': status, 'role': 'Live role'}),
      for (final status in ['deleted', 'closed', 'filled', 'unknown', null])
        _Document('$status', {'status': status, 'role': 'Unavailable role'}),
    ]);
    snapshots.add(jobs('available'));
    await tester.pumpAndSettle();
    expect(find.byType(LocumJobCard), findsOneWidget);
    expect(find.text('Unavailable role'), findsNothing);
    snapshots.add(jobs('deleted'));
    await tester.pumpAndSettle();
    expect(find.byType(LocumJobCard), findsNothing);
    expect(find.text('No jobs available'), findsOneWidget);
  });
  testWidgets('Locum search combines with location and clears correctly', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LMainPage(
          jobsStream: Stream.value(
            _Snapshot([
              _Document('1', {
                'status': 'available',
                'role': 'Optometrist',
                'placeName': 'Vision Clinic',
                'location': 'Johor',
              }),
              _Document('2', {
                'status': 'available',
                'role': 'Assistant',
                'placeName': 'Eye Clinic',
                'location': 'Kuala Lumpur',
              }),
            ]),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Search jobs'));
    await tester.tap(find.byTooltip('Search jobs'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '  CLINIC  ');
    await tester.pumpAndSettle();
    expect(find.byType(LocumJobCard), findsNWidgets(2));
    await tester.ensureVisible(find.byTooltip('Filter jobs'));
    await tester.tap(find.byTooltip('Filter jobs'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PopupMenuItem<String>, 'Johor'));
    await tester.pumpAndSettle();
    expect(find.byType(LocumJobCard), findsOneWidget);
    expect(tester.widget<LocumJobCard>(find.byType(LocumJobCard)).jobId, '1');
    await tester.enterText(find.byType(TextField), 'assistant');
    await tester.pumpAndSettle();
    expect(find.text('No matching jobs'), findsOneWidget);
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    expect(find.byType(LocumJobCard), findsOneWidget);
    await tester.tap(find.byIcon(Icons.cancel));
    await tester.pumpAndSettle();
    expect(find.byType(LocumJobCard), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}
