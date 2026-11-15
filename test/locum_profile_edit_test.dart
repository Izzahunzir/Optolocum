import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:optolocum/features/locum/L_mainpage.dart';
import 'package:optolocum/features/locum/L_profile_data.dart';
import 'package:optolocum/features/locum/L_verification_form.dart';
import 'package:optolocum/services/locum_profile_service.dart';

class _Profiles extends Mock implements LocumProfileService {}

void main() {
  late _Profiles profiles;
  late LocumProfileData savedProfile;
  setUpAll(
    () => registerFallbackValue(
      LocumProfileData(fields: const {}, documents: const []),
    ),
  );
  setUp(() {
    locumVerificationStatus.value = LocumVerificationStatus.approved;
    locumProfileData.value = LocumProfileData(
      uid: 'test-locum',
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
      documents: [
        XFile.fromData(
          Uint8List.fromList('%PDF-1.7\nexisting evidence'.codeUnits),
          path: 'existing-diploma.pdf',
          name: 'existing-diploma.pdf',
        ),
      ],
    );
    savedProfile = locumProfileData.value!;
    profiles = _Profiles();
    when(() => profiles.currentUid).thenReturn('test-locum');
    when(() => profiles.authStateChanges)
        .thenAnswer((_) => const Stream.empty());
    when(() => profiles.load('test-locum'))
        .thenAnswer((_) async => savedProfile);
    when(() => profiles.save(any())).thenAnswer((invocation) async {
      savedProfile = invocation.positionalArguments.single as LocumProfileData;
      locumProfileData.value = savedProfile;
      locumVerificationStatus.value = LocumVerificationStatus.pending;
    });
  });
  tearDown(() {
    locumProfileData.value = null;
    locumVerificationStatus.value = LocumVerificationStatus.unverified;
  });

  testWidgets('Profile edit retains documents and commits on Update', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LMainPage(
          jobsStream: const Stream.empty(),
          profileService: profiles,
          pickVerificationDocument: () async => XFile.fromData(
            Uint8List.fromList('%PDF-1.7\nexisting evidence'.codeUnits),
            path: 'existing-diploma.pdf',
            name: 'existing-diploma.pdf',
          ),
        ),
      ),
    );
    await tester.tap(find.text('Account'));
    await tester.pump(const Duration(milliseconds: 500));
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
    expect(find.text('Document Preview'), findsOneWidget);
    expect(
      locumProfileData.value!.documents.single.name,
      'existing-diploma.pdf',
    );
    // The existing document is loaded from the saved profile before the picker
    // is opened. Editing the form must not require selecting it again.
    expect(find.text('existing-diploma.pdf'), findsOneWidget);
    await tester.ensureVisible(find.text('Choose one document'));
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
    await tester.pumpWidget(
      MaterialApp(
        home: LMainPage(
          jobsStream: const Stream.empty(),
          profileService: profiles,
          pickVerificationDocument: () async => XFile.fromData(
            Uint8List.fromList('%PDF-1.7\nexisting evidence'.codeUnits),
            path: 'existing-diploma.pdf',
            name: 'existing-diploma.pdf',
          ),
        ),
      ),
    );
    await tester.tap(find.text('Account'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.ensureVisible(find.text('Account Verification'));
    await tester.tap(find.text('Account Verification'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Unsaved');
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(locumProfileData.value!.fields['Full Name'], 'Sarah');
    expect(locumVerificationStatus.value, LocumVerificationStatus.approved);
  });
}
