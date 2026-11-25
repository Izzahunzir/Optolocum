import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:optolocum/services/real_backend_client.dart';
import 'package:optolocum/services/real_backend_workflows.dart';
import 'package:optolocum/services/verification_submission.dart';

class _Backend extends Mock implements RealBackendClient {}

class _Auth extends Mock implements FirebaseAuth {}

class _User extends Mock implements User {}

class _Credential extends Mock implements UserCredential {}

class _Db extends Mock implements FirebaseFirestore {}

// ignore: subtype_of_sealed_class
class _Collection extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class _Ref extends Mock implements DocumentReference<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class _Snapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

class _Storage extends Mock implements FlutterSecureStorage {}

void main() {
  late _Backend backend;
  late _Auth auth;
  late _User user;
  late _Db db;
  late _Storage storage;
  late _Snapshot snapshot;
  late RealBackendWorkflows service;
  late Map<String, String> saved;
  var status = 'unverified';
  var assignment = 'locum';
  setUpAll(() {
    registerFallbackValue(const GetOptions(source: Source.server));
    registerFallbackValue(Uint8List(0));
  });
  setUp(() {
    backend = _Backend();
    auth = _Auth();
    user = _User();
    db = _Db();
    storage = _Storage();
    snapshot = _Snapshot();
    final collection = _Collection();
    final ref = _Ref();
    final credential = _Credential();
    saved = {};
    status = 'unverified';
    assignment = 'locum';
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.uid).thenReturn('uid');
    when(() => user.getIdToken()).thenAnswer((_) async => 'token');
    when(() => user.getIdToken(true)).thenAnswer((_) async => 'token');
    when(() => credential.user).thenReturn(user);
    when(
      () => auth.signInWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => credential);
    when(() => auth.signOut()).thenAnswer((_) async {});
    when(() => db.collection(any())).thenReturn(collection);
    when(() => collection.doc(any())).thenReturn(ref);
    when(() => ref.get(any())).thenAnswer((_) async => snapshot);
    when(() => snapshot.data()).thenAnswer(
      (_) => {'verificationStatus': status, 'trustedAccountType': assignment},
    );
    when(() => storage.read(key: any(named: 'key')))
        .thenAnswer((i) async => saved[i.namedArguments[#key]]);
    when(
      () => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((i) async {
      saved[i.namedArguments[#key] as String] =
          i.namedArguments[#value] as String;
    });
    when(() => storage.delete(key: any(named: 'key'))).thenAnswer((i) async {
      saved.remove(i.namedArguments[#key]);
    });
    service = RealBackendWorkflows(
      backend,
      auth,
      db,
      storage: storage,
      enrollmentDelay: Duration.zero,
    );
  });
  VerificationSubmission submission(VerificationAccountType type) =>
      VerificationSubmission(
        uid: 'uid',
        accountType: type,
        fields: type == VerificationAccountType.locum
            ? {
                'fullName': 'Test',
                'email': 'test@example.com',
                'nric': '990101010101',
                'phoneNumber': '0123456789',
                'gender': 'Female',
                'dateOfBirth': '1999-01-01',
                'highestEducation': 'Degree',
                'course': 'Optometry',
              }
            : {
                'practiceType': 'Hospital',
                'clinicName': 'Clinic',
                'registrationNumber': '123',
                'address': 'Address',
                'state': 'Johor',
                'contactNumber': '0123456789',
                'companyEmail': 'test@example.com',
              },
        document: VerificationDocument.fromBytes(
          'file.pdf',
          Uint8List.fromList('%PDF-test'.codeUnits),
        ),
      );

  for (final type in VerificationAccountType.values) {
    test('$type initial verification uploads and finalizes', () async {
      final paths = <String>[];
      when(() => backend.postJson(any(), any(), token: any(named: 'token')))
          .thenAnswer((i) async {
            final path = i.positionalArguments[0] as String;
            paths.add(path);
            return {
              'data': {
                'submissionId': 'revision',
                'state': path.endsWith('draft') ? 'draft' : 'submitted',
              },
            };
          });
      when(
        () => backend.upload(any(), any(), any(), token: any(named: 'token')),
      ).thenAnswer(
        (_) async => {
          'data': {'submissionId': 'revision', 'documentUploaded': true},
        },
      );
      await service.submit(submission(type));
      expect(paths, ['/api/applicant/draft', '/api/applicant/finalize']);
      verify(
        () => backend.upload(any(), any(), 'application/pdf', token: 'token'),
      ).called(1);
    });
  }
  test('interrupted verification retries the same ID and duplicate recovers submitted revision', () async {
    final ids = <String>[];
    var fail = true;
    when(() => backend.postJson(any(), any(), token: any(named: 'token')))
        .thenAnswer((i) async {
          final body = i.positionalArguments[1] as Map;
          ids.add(body['requestId'] as String);
          if (fail) {
            fail = false;
            throw const BackendException('unavailable');
          }
          return {
            'data': {'submissionId': 'revision', 'state': 'submitted'},
          };
        });
    final s = submission(VerificationAccountType.locum);
    await expectLater(service.submit(s), throwsA(isA<BackendException>()));
    await service.submit(s);
    status = 'pending';
    await service.submit(s);
    expect(ids.toSet(), hasLength(1));
    verifyNever(
      () => backend.upload(any(), any(), any(), token: any(named: 'token')),
    );
  });
  test(
    'rejected submission gets a new ID; approved submission is blocked',
    () async {
      final ids = <String>[];
      when(() => backend.postJson(any(), any(), token: any(named: 'token')))
          .thenAnswer((i) async {
            ids.add((i.positionalArguments[1] as Map)['requestId'] as String);
            return {
              'data': {'submissionId': 'revision', 'state': 'submitted'},
            };
          });
      final s = submission(VerificationAccountType.locum);
      await service.submit(s);
      status = 'rejected';
      await service.submit(s);
      expect(ids[0], isNot(ids[1]));
      status = 'approved';
      await expectLater(service.submit(s), throwsStateError);
      expect(ids, hasLength(2));
    },
  );
  for (final type in ['locum', 'practice_owner']) {
    test(
      '$type enrollment preserves recovery when blocked and retries identical credentials',
      () async {
        final bodies = <Map<String, dynamic>>[];
        var blocked = true;
        when(() => backend.postJson('/api/enrollment', any()))
            .thenAnswer((i) async {
              bodies.add(
                Map<String, dynamic>.from(i.positionalArguments[1] as Map),
              );
              if (blocked) {
                blocked = false;
                throw const BackendException('blocked', statusCode: 503);
              }
              return {
                'data': {'uid': 'uid', 'accountType': type},
              };
            });
        assignment = type;
        final profile = type == 'locum'
            ? {'fullName': 'Test'}
            : {
                'fullName': 'Test',
                'phoneNumber': '0123456789',
                'role': 'Manager',
              };
        Future<void> enroll() => service.enroll(
          email: ' TEST@example.com ',
          password: 'password',
          accountType: type,
          profile: profile,
        );
        await expectLater(enroll(), throwsA(isA<BackendException>()));
        expect(jsonEncode(saved), isNot(contains('password')));
        await expectLater(
          enroll(),
          throwsStateError,
        ); // session endpoint is not active
        expect(bodies[0]['requestId'], bodies[1]['requestId']);
        expect(bodies[0]['recoverySecret'], bodies[1]['recoverySecret']);
        expect(bodies[1]['email'], 'test@example.com');
        verify(() => auth.signOut()).called(1);
      },
    );
  }
  test(
    'wrong account type and unavailable session validation both sign out',
    () async {
      assignment = 'practice_owner';
      await expectLater(
        service.signIn(
          email: 'test@example.com',
          password: 'password',
          accountType: 'locum',
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('selected account type'),
          ),
        ),
      );
      assignment = 'locum';
      await expectLater(
        service.signIn(
          email: 'test@example.com',
          password: 'password',
          accountType: 'locum',
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('not available'),
          ),
        ),
      );
      verify(() => auth.signOut()).called(2);
    },
  );
  test('invalid authentication never navigates and signs out', () async {
    when(
      () => auth.signInWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(FirebaseAuthException(code: 'user-disabled'));
    await expectLater(
      service.signIn(
        email: 'test@example.com',
        password: 'password',
        accountType: 'locum',
      ),
      throwsA(isA<FirebaseAuthException>()),
    );
    verify(() => auth.signOut()).called(1);
  });
}
