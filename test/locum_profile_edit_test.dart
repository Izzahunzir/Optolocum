import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:optolocum/features/locum/L_mainpage.dart';
import 'package:optolocum/features/locum/L_profile_data.dart';
import 'package:optolocum/features/locum/L_verification_form.dart';

void main() {
  setUp(() {
    locumVerificationStatus.value = LocumVerificationStatus.verified;
    locumProfileData.value = LocumProfileData(
      fields: {
        'Full Name': 'Sarah',
        'Email': 'sarah@example.com',
        'NRIC': '000101011234',
        'Phone Number': '+60123456789',
        'Gender': 'Female',
        'Date of Birth': '2000-01-01',
        'Highest Education': 'Degree',
        'Course': 'Optometry',
      },
      documents: [XFile('existing-diploma.pdf')],
    );
  });
  tearDown(() {
    locumProfileData.value = null;
    locumVerificationStatus.value = LocumVerificationStatus.unverified;
  });

  testWidgets('Profile edit retains documents and commits on Update', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LMainPage()));
    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Account Verification'));
    await tester.tap(find.text('Account Verification'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<LVerificationForm>(find.byType(LVerificationForm))
          .isEditing,
      isTrue,
    );
    expect(find.text('sarah@example.com'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Sarah Updated');
    await tester.ensureVisible(find.text('Next'));
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('existing-diploma.pdf'), findsOneWidget);
    expect(locumProfileData.value!.fields['Full Name'], 'Sarah');
    await tester.ensureVisible(find.text('Update'));
    await tester.tap(find.text('Update'));
    await tester.pumpAndSettle();
    expect(find.byType(LVerificationForm), findsNothing);
    expect(find.text('Sarah Updated'), findsOneWidget);
    expect(locumVerificationStatus.value, LocumVerificationStatus.pending);
    expect(
      locumProfileData.value!.documents.single.name,
      'existing-diploma.pdf',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Leaving edit mode discards changes', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LMainPage()));
    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Account Verification'));
    await tester.tap(find.text('Account Verification'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Unsaved');
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(locumProfileData.value!.fields['Full Name'], 'Sarah');
    expect(locumVerificationStatus.value, LocumVerificationStatus.verified);
  });
}
