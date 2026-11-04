import 'dart:async';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:optolocum/features/clinic_owner/CO_verification_form.dart';
import 'package:optolocum/features/locum/L_profile_data.dart';
import 'package:optolocum/features/locum/L_verification_form.dart';
import 'package:optolocum/services/locum_profile_service.dart';
import 'package:optolocum/services/verification_submission.dart';

class _Profiles extends Mock implements LocumProfileService {}

class _Client implements VerificationSubmissionClient {
  final received = <VerificationSubmission>[];
  Completer<void>? pending;
  bool fail = false;
  @override
  Future<void> submit(
    VerificationSubmission submission, {
    Future<void> Function()? saveProfile,
  }) async {
    received.add(submission);
    if (pending != null) await pending!.future;
    if (fail) throw StateError('Upload failed; retry.');
    if (saveProfile != null) await saveProfile();
  }
}

const _personal = {
  'Full Name': 'Test Locum',
  'Email': 'locum@example.com',
  'NRIC': '990101010101',
  'Phone Number': '0123456789',
  'Gender': 'Female',
  'Date of Birth': '1999-01-01',
  'Highest Education': 'Degree',
  'Course': 'Optometry',
};

Future<void> _openLocum(
  WidgetTester tester,
  _Profiles profiles,
  VerificationSubmissionClient submissions,
  Future<XFile?> Function() picker,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => LVerificationForm(
                  isEditing: true,
                  profileService: profiles,
                  submissions: submissions,
                  pickDocument: picker,
                ),
              ),
            ),
            child: const Text('Open form'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open form'));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Next'));
  await tester.tap(find.text('Next'));
  await tester.pumpAndSettle();
}

Future<void> _fillPractice(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpAndSettle();
  for (final entry in [
    ('practice-type', 'Retail Optical Store'),
    ('malaysian-state', 'Johor'),
  ]) {
    final dropdown = find.byKey(Key(entry.$1));
    await tester.ensureVisible(dropdown);
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text(entry.$2).last);
    await tester.pumpAndSettle();
  }
  final fields = find.byType(TextFormField);
  final values = [
    'Vision Clinic',
    '202401012345',
    '22 Jalan Test',
    '0123456789',
    'clinic@example.com',
  ];
  for (var i = 0; i < values.length; i++) {
    await tester.ensureVisible(fields.at(i));
    await tester.enterText(fields.at(i), values[i]);
  }
  await tester.ensureVisible(find.text('Verify Account'));
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(
    () => registerFallbackValue(
      LocumProfileData(fields: _personal, documents: const []),
    ),
  );
  late _Profiles profiles;
  setUp(() {
    profiles = _Profiles();
    when(() => profiles.currentUid).thenReturn('locum');
    when(() => profiles.authStateChanges)
        .thenAnswer((_) => const Stream.empty());
    when(() => profiles.load('locum')).thenAnswer(
      (_) async => LocumProfileData(
        uid: 'locum',
        fields: _personal,
        documents: const [],
      ),
    );
    when(() => profiles.save(any())).thenAnswer((_) async {});
  });
  XFile file(String name) => XFile.fromData(
    Uint8List.fromList('%PDF-1.7\nsynthetic'.codeUnits),
    name: name,
    path: name,
  );

  testWidgets('Practice Owner account switch blocks stale form submission', (
    tester,
  ) async {
    final client = _Client();
    String? uid = 'owner';
    await tester.pumpWidget(
      MaterialApp(
        home: COVerificationForm(submissions: client, currentUid: () => uid),
      ),
    );
    await _fillPractice(tester);
    uid = 'other';
    await tester.tap(find.text('Verify Account'));
    await tester.pumpAndSettle();
    expect(client.received, isEmpty);
    expect(
      find.text('Your account changed. Please reopen the form.'),
      findsOneWidget,
    );
  });

  testWidgets('Locum requires one document and replaces previous selection', (
    tester,
  ) async {
    final client = _Client();
    var count = 0;
    await _openLocum(
      tester,
      profiles,
      client,
      () async => file('evidence${++count}.pdf'),
    );
    await tester.ensureVisible(find.text('Update'));
    await tester.tap(find.text('Update'));
    await tester.pumpAndSettle();
    expect(
      find.text('Choose exactly one PDF, JPG, JPEG, or PNG.'),
      findsOneWidget,
    );
    expect(client.received, isEmpty);
    for (var i = 0; i < 2; i++) {
      await tester.ensureVisible(find.text('Choose one document'));
      await tester.tap(find.text('Choose one document'));
      await tester.pumpAndSettle();
    }
    expect(find.text('evidence1.pdf'), findsNothing);
    expect(find.text('evidence2.pdf'), findsOneWidget);
    await tester.ensureVisible(find.text('Update'));
    await tester.tap(find.text('Update'));
    await tester.pumpAndSettle();
    expect(client.received.single.document!.name, 'evidence2.pdf');
    expect(client.received.single.fields['nric'], '990101010101');
    verify(() => profiles.save(any())).called(1);
    expect(find.text('Open form'), findsOneWidget);
  });
  testWidgets(
    'Locum failure stays on form; retry keeps ID; success waits for persistence',
    (tester) async {
      final client = _Client()..fail = true;
      await _openLocum(
        tester,
        profiles,
        client,
        () async => file('evidence.pdf'),
      );
      await tester.ensureVisible(find.text('Choose one document'));
      await tester.tap(find.text('Choose one document'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Update'));
      await tester.tap(find.text('Update'));
      await tester.pumpAndSettle();
      expect(find.byType(LVerificationForm), findsOneWidget);
      expect(
        find.text('Your details and document have been submitted for review.'),
        findsNothing,
      );
      verifyNever(() => profiles.save(any()));
      client.fail = false;
      client.pending = Completer<void>();
      await tester.tap(find.text('Update'));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(LVerificationForm), findsOneWidget);
      expect(
        find.text('Your details and document have been submitted for review.'),
        findsNothing,
      );
      expect(client.received[0].id, client.received[1].id);
      client.pending!.complete();
      await tester.pumpAndSettle();
      verify(() => profiles.save(any())).called(1);
      expect(find.text('Open form'), findsOneWidget);
    },
  );
  testWidgets(
    'disabled Locum integration preserves profile-only saving and labels it honestly',
    (tester) async {
      await _openLocum(
        tester,
        profiles,
        const DisabledVerificationSubmissions(),
        () async => file('evidence.pdf'),
      );
      await tester.ensureVisible(find.text('Choose one document'));
      await tester.tap(find.text('Choose one document'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Update'));
      await tester.tap(find.text('Update'));
      await tester.pumpAndSettle();
      verify(() => profiles.save(any())).called(1);
      expect(
        find.text(
          'Profile saved. Your document has not been uploaded or submitted for verification.',
        ),
        findsOneWidget,
      );
      expect(
        find.text('Your details and document have been submitted for review.'),
        findsNothing,
      );
    },
  );
  testWidgets(
    'Practice Owner submits all existing fields and waits for commit',
    (tester) async {
      final client = _Client()..pending = Completer<void>();
      await tester.pumpWidget(
        MaterialApp(
          home: COVerificationForm(
            submissions: client,
            currentUid: () => 'owner',
          ),
        ),
      );
      await _fillPractice(tester);
      await tester.tap(find.text('Verify Account'));
      await tester.pump();
      expect(client.received.single.document, isNull);
      expect(client.received.single.fields, {
        'practiceType': 'Retail Optical Store',
        'clinicName': 'Vision Clinic',
        'registrationNumber': '202401012345',
        'address': '22 Jalan Test',
        'state': 'Johor',
        'contactNumber': '0123456789',
        'companyEmail': 'clinic@example.com',
      });
      expect(
        find.text('Your practice details have been submitted for review.'),
        findsNothing,
      );
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull,
      );
      client.pending!.complete();
      await tester.pumpAndSettle();
      expect(
        find.text('Your practice details have been submitted for review.'),
        findsOneWidget,
      );
    },
  );
  testWidgets('Practice Owner failure keeps form and retries same revision', (
    tester,
  ) async {
    final client = _Client()..fail = true;
    await tester.pumpWidget(
      MaterialApp(
        home: COVerificationForm(
          submissions: client,
          currentUid: () => 'owner',
        ),
      ),
    );
    await _fillPractice(tester);
    await tester.tap(find.text('Verify Account'));
    await tester.pumpAndSettle();
    expect(
      find.text('Your practice details have been submitted for review.'),
      findsNothing,
    );
    client.fail = false;
    await tester.tap(find.text('Verify Account'));
    await tester.pumpAndSettle();
    expect(client.received[0].id, client.received[1].id);
    expect(
      find.text('Your practice details have been submitted for review.'),
      findsOneWidget,
    );
  });
}
