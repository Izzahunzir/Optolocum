import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:optolocum/features/clinic_owner/CO_mainpage.dart';
import 'package:optolocum/features/clinic_owner/CO_verification_status.dart';

void main() {
  testWidgets(
    'Profile supports help, contact, live status and confirmed logout',
    (tester) async {
      coVerificationStatus.value = COVerificationStatus.unverified;
      addTearDown(
        () => coVerificationStatus.value = COVerificationStatus.unverified,
      );
      await tester.pumpWidget(const MaterialApp(home: COMainPage()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('How to add Job'));
      await tester.tap(find.text('How to add Job'));
      await tester.pumpAndSettle();
      expect(find.text('How to add Job?'), findsOneWidget);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      await tester.tap(find.text('Account Verification'));
      await tester.pumpAndSettle();
      expect(find.text('Not Verified'), findsOneWidget);
      coVerificationStatus.value = COVerificationStatus.pending;
      await tester.pumpAndSettle();
      expect(find.text('Pending Verification'), findsOneWidget);
      coVerificationStatus.value = COVerificationStatus.verified;
      await tester.pumpAndSettle();
      expect(find.text('Verified'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Contact Us'));
      await tester.tap(find.text('Contact Us'));
      await tester.pumpAndSettle();
      expect(find.text('optolocum.support@gmail.com'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Logout'));
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(coVerificationStatus.value, COVerificationStatus.verified);
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Log Out'));
      await tester.pumpAndSettle();
      expect(find.text('Welcome to\nOptolocum'), findsOneWidget);
      expect(coVerificationStatus.value, COVerificationStatus.unverified);
      expect(tester.takeException(), isNull);
    },
  );
}
