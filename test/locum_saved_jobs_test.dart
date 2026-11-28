import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:optolocum/features/locum/L_mainpage.dart';
import 'package:optolocum/features/locum/L_savedJob.dart';
import 'package:optolocum/services/locum_profile_service.dart';

class _Profiles extends Mock implements LocumProfileService {}

void main() {
  setUp(locumSavedJobs.clear);
  tearDown(locumSavedJobs.clear);

  test('Saving by posting ID avoids duplicates and supports removal', () {
    const job = SavedLocumJob(id: 'job-1', title: 'Optometrist');
    locumSavedJobs.save(job);
    locumSavedJobs.save(
      const SavedLocumJob(id: 'job-1', title: 'Updated title'),
    );
    expect(locumSavedJobs.value, hasLength(1));
    expect(locumSavedJobs.value.single.title, 'Updated title');
    locumSavedJobs.toggle(job);
    expect(locumSavedJobs.value, isEmpty);
  });

  testWidgets('Profile opens saved jobs and observes shared bookmark changes', (
    tester,
  ) async {
    final profiles = _Profiles();
    when(() => profiles.currentUid).thenReturn(null);
    when(() => profiles.authStateChanges).thenAnswer((_) => Stream.value(null));
    await tester.pumpWidget(
      MaterialApp(
        home: LMainPage(
          jobsStream: const Stream.empty(),
          profileService: profiles,
        ),
      ),
    );
    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Saved Job'));
    await tester.tap(find.text('Saved Job'));
    await tester.pumpAndSettle();
    expect(find.byType(LSavedJob), findsOneWidget);
    expect(find.byType(LocumSaveJobButton), findsNothing);

    locumSavedJobs.save(const SavedLocumJob(id: 'job-1', title: 'Optometrist'));
    await tester.pumpAndSettle();
    expect(find.text('Optometrist'), findsOneWidget);
    await tester.tap(find.byTooltip('Remove saved job'));
    await tester.pumpAndSettle();
    expect(find.text('Optometrist'), findsNothing);
    expect(locumSavedJobs.value, isEmpty);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(LSavedJob), findsNothing);
    expect(find.text('Job Process Guide'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
