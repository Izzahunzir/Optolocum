import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:optolocum/services/demo_enrollment.dart';

void main() {
  for (final type in ['locum', 'practice_owner']) {
    test('$type enrollment sends exact contract and signs in', () async {
      final profile = type == 'locum' ? {'fullName': 'Synthetic'} :
        {'fullName': 'Synthetic', 'phoneNumber': '0123456789', 'role': 'Manager'};
      var signedIn = false;
      final service = DemoEnrollment(
        post: (uri, headers, body) async {
          expect(uri.toString(), 'http://127.0.0.1:8787/api/enrollment');
          final data = jsonDecode(body) as Map<String, dynamic>;
          expect(data.keys.toSet(), {'requestId', 'recoverySecret', 'email', 'password', 'accountType', 'profile'});
          expect(data['requestId'], matches(RegExp(r'^[a-f0-9]{32}$')));
          expect(data['recoverySecret'], matches(RegExp(r'^[a-f0-9]{64}$')));
          expect(data['email'], 'synthetic@example.invalid');
          expect(data['profile'], profile);
          return http.Response(jsonEncode({'data': {'uid': 'demo-uid', 'accountType': type}}), 200);
        },
        signIn: (email, password) async { signedIn = true; return 'demo-uid'; },
        signOut: () async {}, wait: () async {},
      );
      await service.enroll(email: ' Synthetic@example.invalid ', password: 'synthetic-password', accountType: type, profile: profile);
      expect(signedIn, isTrue);
    });
  }

  test('interrupted signup retries the same intent and rejects conflicting details', () async {
    final requests = <Map<String, dynamic>>[];
    final service = DemoEnrollment(
      post: (uri, headers, body) async {
        requests.add(jsonDecode(body) as Map<String, dynamic>);
        if (requests.length == 1) throw StateError('unavailable');
        return http.Response('{"data":{"uid":"u","accountType":"locum"}}', 200);
      }, signIn: (_, _) async => 'u', signOut: () async {}, wait: () async {},
    );
    Future<void> submit(String type) => service.enroll(email: 'a@example.invalid', password: 'synthetic-password', accountType: type, profile: {'fullName': 'Synthetic'});
    await expectLater(submit('locum'), throwsA(isA<DemoEnrollmentException>()));
    await expectLater(submit('practice_owner'), throwsA(isA<DemoEnrollmentException>()));
    await submit('locum');
    expect(requests, hasLength(2));
    expect(requests[0]['requestId'], requests[1]['requestId']);
    expect(requests[0]['recoverySecret'], requests[1]['recoverySecret']);
  });

  test('duplicate email or conflicting server state is reported without signing in', () async {
    final service = DemoEnrollment(post: (_, _, _) async => http.Response('{}', 409),
      signIn: (_, _) async => fail('should not sign in'), signOut: () async {}, wait: () async {});
    await expectLater(service.enroll(email: 'a@example.invalid', password: 'synthetic-password', accountType: 'locum', profile: {'fullName': 'Synthetic'}), throwsA(isA<DemoEnrollmentException>()));
  });

  test('unexpected signed-in identity is signed out', () async {
    var signedOut = false;
    final service = DemoEnrollment(
      post: (_, _, _) async => http.Response('{"data":{"uid":"expected","accountType":"locum"}}', 200),
      signIn: (_, _) async => 'different',
      signOut: () async { signedOut = true; }, wait: () async {},
    );
    await expectLater(service.enroll(email: 'a@example.invalid', password: 'synthetic-password',
      accountType: 'locum', profile: {'fullName': 'Synthetic'}), throwsA(isA<DemoEnrollmentException>()));
    expect(signedOut, isTrue);
  });

  test('unconfirmed session signs out and keeps the same retry intent', () async {
    final ids = <String>[];
    var attempts = 0;
    var signedOut = false;
    final service = DemoEnrollment(
      post: (_, _, body) async {
        ids.add((jsonDecode(body) as Map<String, dynamic>)['requestId'] as String);
        return http.Response('{"data":{"uid":"u","accountType":"locum"}}', 200);
      },
      signIn: (_, _) async => 'u', signOut: () async { signedOut = true; },
      wait: () async {}, verifySession: (_, _) async {
        if (attempts++ == 0) throw StateError('stale session');
      },
    );
    Future<void> submit() => service.enroll(email: 'a@example.invalid', password: 'synthetic-password', accountType: 'locum', profile: {'fullName': 'Synthetic'});
    await expectLater(submit(), throwsA(isA<DemoEnrollmentException>()));
    expect(signedOut, isTrue);
    await submit();
    expect(ids[0], ids[1]);
  });
}
