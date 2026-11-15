import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mocktail/mocktail.dart';
import 'package:optolocum/features/auth/CO_signin.dart';
import 'package:optolocum/features/clinic_owner/CO_mainpage.dart';
import 'package:optolocum/features/clinic_owner/CO_verify_popup.dart';
import 'package:optolocum/features/clinic_owner/CO_verification_status.dart';
import 'package:optolocum/services/auth_service.dart';

class _AuthService extends Mock implements AuthService {}

class _UserCredential extends Mock implements UserCredential {}

void main() {
  testWidgets('Empty jobs appears after approval, not while pending', (
    tester,
  ) async {
    coVerificationStatus.value = COVerificationStatus.unverified;
    addTearDown(
      () => coVerificationStatus.value = COVerificationStatus.unverified,
    );
    await tester.pumpWidget(
      MaterialApp(home: COMainPage(jobsStream: Stream.value([]))),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.description_rounded), findsNothing);
    coVerificationStatus.value = COVerificationStatus.pending;
    await tester.pump(const Duration(minutes: 5));
    expect(find.byIcon(Icons.description_rounded), findsNothing);
    coVerificationStatus.value = COVerificationStatus.approved;
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.description_rounded), findsOneWidget);
    expect(
      find.text(
        'Find qualified optometrists and staff by\ncreating your first job posting',
      ),
      findsOneWidget,
    );
  });
  for (final size in [const Size(320, 568), const Size(1440, 900)]) {
    testWidgets('Verified homepage adapts and ads scroll at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: COMainPage(isVerified: true, jobsStream: Stream.value([])),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('You haven’t posted any locum jobs yet'),
        findsOneWidget,
      );
      final ads = find.byKey(const Key('clinic-owner-ads'));
      final scrollable = find.descendant(
        of: ads,
        matching: find.byType(Scrollable),
      );
      final position = tester.state<ScrollableState>(scrollable).position;
      await tester.drag(ads, const Offset(-250, 0));
      await tester.pumpAndSettle();
      if (size.width < 700) expect(position.pixels, greaterThan(0));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Verification prompt overlays the unverified homepage', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var profileRequested = false;
    await tester.pumpWidget(
      MaterialApp(
        home: COVerifyPopup(
          displayName: 'Natalie Tan',
          jobsStream: Stream.value([]),
          onCompleteProfile: () => profileRequested = true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Hi, NATALIE TAN! 👋'), findsOneWidget);
    expect(find.text('You haven’t posted any locum jobs yet'), findsNothing);
    await tester.tap(find.text('Complete Your Profile'));
    await tester.pumpAndSettle();
    expect(profileRequested, isTrue);
    expect(find.byType(Dialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Sign-in preview opens verification without granting verified access',
    (tester) async {
      final authService = _AuthService();
      when(
        () => authService.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => _UserCredential());
      await tester.pumpWidget(
        MaterialApp(
          home: CompanyOwnerSigninPage(
            authService: authService,
            jobsStream: Stream.value([]),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'natalie@gmail.com');
      await tester.enterText(fields.at(1), 'password123');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Login'));
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();
      expect(find.text('Complete Your Profile'), findsOneWidget);
      await tester.tap(find.text('Complete Your Profile'));
      await tester.pumpAndSettle();
      expect(find.text('Account Verification'), findsOneWidget);
      expect(find.text('Company Information'), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
