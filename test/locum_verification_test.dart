import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:optolocum/features/locum/L_mainpage.dart';
import 'package:optolocum/features/locum/L_verify_popup.dart';
import 'package:optolocum/features/locum/L_verification_form.dart';
import 'package:optolocum/services/locum_profile_service.dart';

class _Profiles extends Mock implements LocumProfileService {}

void main() {
  late _Profiles profiles;
  setUp(() {
    locumVerificationStatus.value = LocumVerificationStatus.unverified;
    profiles = _Profiles();
    when(() => profiles.currentUid).thenReturn('test-locum');
    when(() => profiles.authStateChanges)
        .thenAnswer((_) => const Stream.empty());
    when(() => profiles.load('test-locum')).thenAnswer((_) async => null);
  });

  testWidgets(
    'Profile action opens verification and validates required fields',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LVerifyPopup(
            displayName: 'Sarah',
            jobsStream: const Stream.empty(),
            profileService: profiles,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Hi, SARAH! 👋'), findsOneWidget);
      await tester.tap(find.text('Complete Your Profile'));
      await tester.pumpAndSettle();
      expect(find.byType(LVerificationForm), findsOneWidget);
      await tester.ensureVisible(find.text('Next'));
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a valid email'), findsOneWidget);
      expect(locumVerificationStatus.value, LocumVerificationStatus.unverified);
      expect(find.text('Upload Documents'), findsNothing);
    },
  );

  testWidgets('Verified account opens homepage without verification dialog', (
    tester,
  ) async {
    locumVerificationStatus.value = LocumVerificationStatus.approved;
    await tester.pumpWidget(
      MaterialApp(
        home: LVerifyPopup(
          jobsStream: const Stream.empty(),
          profileService: profiles,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('My Applications'), findsOneWidget);
    expect(find.text('Complete Your Profile'), findsNothing);
    await tester.tap(find.text('Account'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Current\nShift Hours'), findsOneWidget);
    expect(find.text('0 hours'), findsOneWidget);
    expect(find.text('Account Verification'), findsOneWidget);
  });
}
