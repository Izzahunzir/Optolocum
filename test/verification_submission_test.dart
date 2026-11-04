import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:optolocum/services/verification_submission.dart';
import 'package:optolocum/services/verification_submission_service.dart';

class _App extends Fake implements FirebaseApp {
  _App(this.projectId);
  final String projectId;
  @override
  FirebaseOptions get options => FirebaseOptions(
    apiKey: 'demo',
    appId: 'demo',
    messagingSenderId: 'demo',
    projectId: projectId,
  );
}

const personal = {
  'fullName': 'Test Locum',
  'email': 'locum@example.com',
  'nric': '990101010101',
  'phoneNumber': '0123456789',
  'gender': 'Female',
  'dateOfBirth': '1999-01-01',
  'highestEducation': 'Degree',
  'course': 'Optometry',
};
const practice = {
  'practiceType': 'Retail Optical Store',
  'clinicName': 'Vision',
  'registrationNumber': '12345',
  'address': '22 Jalan Test',
  'state': 'Johor',
  'contactNumber': '0123456789',
  'companyEmail': 'store@example.com',
};

VerificationDocument pdf() => VerificationDocument.fromBytes(
  'evidence.pdf',
  Uint8List.fromList('%PDF-1.7\nsynthetic test evidence'.codeUnits),
);
VerificationSubmission locum({String? id}) => VerificationSubmission(
  uid: 'locum',
  accountType: VerificationAccountType.locum,
  fields: personal,
  document: pdf(),
  id: id,
);

// Models persistence boundaries and uncertain outcomes; never creates Firebase.
class MemoryRepository implements VerificationRepository {
  @override
  String? currentUid = 'locum';
  final records = <String, Map<String, dynamic>>{};
  final uploads = <String, String>{};
  final events = <String>[];
  String? failAt;
  void _step(String step) {
    events.add(step);
    if (failAt == step) throw StateError('simulated $step failure');
  }

  @override
  Future<void> reserve(VerificationSubmission s) async {
    _step('reserve');
    final existing = records[s.id];
    if (existing != null && existing['fingerprint'] != s.fingerprint) {
      throw StateError('immutable revision');
    }
    records.putIfAbsent(s.id, () => {...s.payload, 'state': 'draft'});
  }

  @override
  Future<void> upload(VerificationSubmission s) async {
    _step('upload');
    uploads.putIfAbsent(s.documentPath, () => s.document!.sha256Hex);
  }

  @override
  Future<void> finalize(VerificationSubmission s) async {
    _step('finalize');
    records[s.id]!['state'] = 'submitted';
    _step('afterCommit');
  }
}

void main() {
  test(
    'Firebase repository rejects live projects and nonlocal emulator hosts',
    () async {
      await expectLater(
        FirebaseVerificationRepository.emulator(app: _App('optolocum-f314e')),
        throwsArgumentError,
      );
      await expectLater(
        FirebaseVerificationRepository.emulator(
          app: _App('demo-test'),
          host: 'example.com',
        ),
        throwsArgumentError,
      );
    },
  );
  test('exact fields, private reference, no decisions or local paths', () {
    final s = locum();
    expect(s.payload['fields'], personal);
    expect(s.payload['accountType'], 'locum');
    expect(s.payload['schemaVersion'], 1);
    expect((s.payload['document'] as Map)['path'], s.documentPath);
    expect(s.payload.keys, isNot(contains('verificationStatus')));
    expect(s.payload.keys, isNot(contains('role')));
    expect(() => s.fields['email'] = 'changed', throwsUnsupportedError);
    expect(() => s.document!.bytes[0] = 0, throwsUnsupportedError);
  });
  test('document validation accepts supported signatures and rejects spoofed types', () {
    for (final name in ['file.jpg', 'file.JPEG']) {
      expect(
        VerificationDocument.fromBytes(
          name,
          Uint8List.fromList([255, 216, 255, 1]),
        ).contentType,
        'image/jpeg',
      );
    }
    expect(
      VerificationDocument.fromBytes(
        'file.png',
        Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]),
      ).contentType,
      'image/png',
    );
    expect(
      () => VerificationDocument.fromBytes('file.exe', pdf().bytes),
      throwsFormatException,
    );
    expect(
      () => VerificationDocument.fromBytes('file.png', pdf().bytes),
      throwsFormatException,
    );
    expect(
      () => VerificationDocument.fromBytes('empty.pdf', Uint8List(0)),
      throwsFormatException,
    );
    expect(
      () => VerificationDocument.fromBytes(
        'large.pdf',
        Uint8List(VerificationDocument.maxBytes + 1),
      ),
      throwsFormatException,
    );
    expect(
      () => VerificationDocument.fromBytes('../file.pdf', pdf().bytes),
      throwsFormatException,
    );
  });
  test('missing Locum document, owner document, unknown fields and empty fields rejected', () {
    expect(
      () => VerificationSubmission(
        uid: 'locum',
        accountType: VerificationAccountType.locum,
        fields: personal,
      ),
      throwsFormatException,
    );
    expect(
      () => VerificationSubmission(
        uid: 'owner',
        accountType: VerificationAccountType.practiceOwner,
        fields: practice,
        document: pdf(),
      ),
      throwsFormatException,
    );
    expect(
      () => VerificationSubmission(
        uid: 'owner',
        accountType: VerificationAccountType.practiceOwner,
        fields: {...practice, 'verified': 'true'},
      ),
      throwsFormatException,
    );
    expect(
      () => VerificationSubmission(
        uid: 'owner',
        accountType: VerificationAccountType.practiceOwner,
        fields: {...practice, 'clinicName': ''},
      ),
      throwsFormatException,
    );
  });
  test('disabled client never calls profile persistence', () async {
    var saved = false;
    await expectLater(
      const DisabledVerificationSubmissions().submit(
        locum(),
        saveProfile: () async {
          saved = true;
        },
      ),
      throwsStateError,
    );
    expect(saved, false);
  });
  test(
    'Locum success waits for reserve, upload, profile and final commit',
    () async {
      final repo = MemoryRepository();
      final s = locum();
      await VerificationSubmissionService(repo).submit(
        s,
        saveProfile: () async {
          repo.events.add('profile');
        },
      );
      expect(repo.events, [
        'reserve',
        'upload',
        'profile',
        'finalize',
        'afterCommit',
      ]);
      expect(repo.records[s.id]!['state'], 'submitted');
    },
  );
  test(
    'Practice Owner persists exact fields without upload or document',
    () async {
      final repo = MemoryRepository()..currentUid = 'owner';
      final s = VerificationSubmission(
        uid: 'owner',
        accountType: VerificationAccountType.practiceOwner,
        fields: practice,
      );
      await VerificationSubmissionService(repo).submit(s);
      expect(repo.events, ['reserve', 'finalize', 'afterCommit']);
      expect(repo.records[s.id]!['fields'], practice);
      expect(repo.records[s.id]!.containsKey('document'), false);
    },
  );
  for (final stage in ['reserve', 'upload', 'finalize', 'afterCommit']) {
    test(
      'safe retry after $stage failure keeps the same revision and file',
      () async {
        final repo = MemoryRepository()..failAt = stage;
        final service = VerificationSubmissionService(repo);
        final s = locum();
        await expectLater(service.submit(s), throwsStateError);
        repo.failAt = null;
        await service.submit(s);
        expect(repo.records.length, 1);
        expect(repo.uploads.length, 1);
        expect(repo.records[s.id]!['state'], 'submitted');
      },
    );
  }
  test(
    'profile failure cannot finalize; completed upload is retained for retry',
    () async {
      final repo = MemoryRepository();
      final service = VerificationSubmissionService(repo);
      final s = locum();
      await expectLater(
        service.submit(
          s,
          saveProfile: () async {
            throw StateError('profile failed');
          },
        ),
        throwsStateError,
      );
      expect(repo.records[s.id]!['state'], 'draft');
      expect(repo.events, isNot(contains('finalize')));
      await service.submit(s, saveProfile: () async {});
      expect(repo.uploads.length, 1);
    },
  );
  test('account mismatch rejects before any persistence', () async {
    final repo = MemoryRepository()..currentUid = 'other';
    await expectLater(
      VerificationSubmissionService(repo).submit(locum()),
      throwsStateError,
    );
    expect(repo.events, isEmpty);
  });
  test('account switch during profile save blocks finalization', () async {
    final repo = MemoryRepository();
    await expectLater(
      VerificationSubmissionService(repo).submit(
        locum(),
        saveProfile: () async {
          repo.currentUid = 'other';
        },
      ),
      throwsStateError,
    );
    expect(repo.events, isNot(contains('finalize')));
  });
  test('new revisions do not mutate previously submitted evidence', () async {
    final repo = MemoryRepository();
    final service = VerificationSubmissionService(repo);
    final first = locum();
    final second = locum();
    await service.submit(first);
    await service.submit(second);
    expect(first.id, isNot(second.id));
    expect(repo.records.length, 2);
    expect(repo.uploads.length, 2);
  });
}
