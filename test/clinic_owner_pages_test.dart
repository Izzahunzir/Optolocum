import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:optolocum/features/clinic_owner/CO_mainpage.dart';
import 'package:optolocum/features/clinic_owner/CO_verify_popup.dart';
import 'package:optolocum/main.dart';
import 'package:optolocum/features/clinic_owner/CO_verification_status.dart';

void main() {
  testWidgets('Empty jobs appears after approval, not while pending', (
    tester,
  ) async {
    coVerificationStatus.value = COVerificationStatus.unverified;
    addTearDown(
      () => coVerificationStatus.value = COVerificationStatus.unverified,
    );
    await tester.pumpWidget(const MaterialApp(home: COMainPage()));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.description_rounded), findsNothing);
    coVerificationStatus.value = COVerificationStatus.pending;
    await tester.pump(const Duration(minutes: 5));
    expect(find.byIcon(Icons.description_rounded), findsNothing);
    coVerificationStatus.value = COVerificationStatus.verified;
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
        const MaterialApp(home: COMainPage(isVerified: true)),
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
      await tester.pumpWidget(const MyApp());
      await tester.ensureVisible(find.text('Clinic Owner'));
      await tester.tap(find.text('Clinic Owner'));
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
