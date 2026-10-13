import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:optolocum/features/locum/L_mainpage.dart';
import 'package:optolocum/features/locum/L_verify_popup.dart';
import 'package:optolocum/features/locum/L_verification_form.dart';

void main() {
  setUp(
    () => locumVerificationStatus.value = LocumVerificationStatus.unverified,
  );

  testWidgets(
    'Profile action opens verification and validates required fields',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LVerifyPopup(displayName: 'Sarah')),
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
    locumVerificationStatus.value = LocumVerificationStatus.verified;
    await tester.pumpWidget(const MaterialApp(home: LVerifyPopup()));
    await tester.pumpAndSettle();
    expect(find.text('My Applications'), findsOneWidget);
    expect(find.text('Complete Your Profile'), findsNothing);
    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    expect(find.text('Verification: verified'), findsOneWidget);
  });
}
