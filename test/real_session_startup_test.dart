import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:optolocum/main.dart';
import 'package:optolocum/features/locum/L_savedJob.dart';
import 'package:optolocum/services/real_backend_client.dart';
import 'package:optolocum/services/real_backend_workflows.dart';

class _Backend extends Mock implements RealBackendClient {}

class _Auth extends Mock implements FirebaseAuth {}

class _User extends Mock implements User {}

class _Database extends Mock implements FirebaseFirestore {}

class _Storage extends Mock implements FlutterSecureStorage {}

void main() {
  late _Backend backend;
  late _Auth auth;
  late _User user;
  late _Storage storage;
  late RealBackendWorkflows workflow;
  late Map<String, String> saved;
  late User? current;
  late StreamController<User?> changes;
  setUp(() {
    backend = _Backend();
    auth = _Auth();
    user = _User();
    storage = _Storage();
    changes = StreamController<User?>.broadcast();
    saved = {};
    current = user;
    when(() => user.uid).thenReturn('uid');
    when(() => user.getIdToken(true)).thenAnswer((_) async => 'id-token');
    when(() => auth.currentUser).thenAnswer((_) => current);
    Stream<User?> authChanges() async* {
      yield current;
      yield* changes.stream;
    }

    when(() => auth.authStateChanges()).thenAnswer((_) => authChanges());
    when(() => auth.signOut()).thenAnswer((_) async {
      current = null;
      changes.add(null);
    });
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
    when(
      () => backend.postJson(
        '/api/session/validate',
        any(),
        token: any(named: 'token'),
      ),
    ).thenAnswer(
      (i) async => {
        'data': {
          'uid': 'uid',
          'accountType': (i.positionalArguments[1] as Map)['accountType'],
          'access': 'active',
        },
      },
    );
    workflow = RealBackendWorkflows(
      backend,
      auth,
      _Database(),
      storage: storage,
    );
  });
  tearDown(() => changes.close());
  Widget app() => MaterialApp(
    home: RealSessionStartup(
      workflows: workflow,
      introBuilder: (_) => const Scaffold(body: Text('Sign in page')),
      homeBuilder: (_, type) => Scaffold(body: Text('Home $type')),
    ),
  );

  for (final type in ['locum', 'practice_owner']) {
    testWidgets('restores $type only after trusted validation', (tester) async {
      saved['real_session_hint_v1_uid'] = type;
      final pending = Completer<Map<String, dynamic>>();
      when(
        () => backend.postJson(
          '/api/session/validate',
          any(),
          token: any(named: 'token'),
        ),
      ).thenAnswer((_) => pending.future);
      await tester.pumpWidget(app());
      await tester.pump();
      expect(find.text('Home $type'), findsNothing);
      pending.complete({
        'data': {'uid': 'uid', 'accountType': type, 'access': 'active'},
      });
      await tester.pumpAndSettle();
      expect(find.text('Home $type'), findsOneWidget);
      verify(
        () => backend.postJson('/api/session/validate', {
          'accountType': type,
        }, token: 'id-token'),
      ).called(1);
      expect(saved, {'real_session_hint_v1_uid': type});
    });
  }
  for (final hint in [null, 'wrong']) {
    testWidgets('missing or invalid hint $hint fails closed', (tester) async {
      if (hint != null) saved['real_session_hint_v1_uid'] = hint;
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.text('Sign in page'), findsOneWidget);
      expect(find.textContaining('Home '), findsNothing);
      expect(current, isNull);
      expect(saved, isEmpty);
      verifyNever(
        () => backend.postJson(any(), any(), token: any(named: 'token')),
      );
    });
  }
  testWidgets(
    'a hint belonging to a different UID cannot restore this account',
    (tester) async {
      saved['real_session_hint_v1_other'] = 'locum';
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.text('Sign in page'), findsOneWidget);
      expect(find.textContaining('Home '), findsNothing);
      expect(current, isNull);
      verifyNever(
        () => backend.postJson(any(), any(), token: any(named: 'token')),
      );
    },
  );
  for (final status in [401, 403, 503]) {
    testWidgets('session error $status fails closed', (tester) async {
      saved['real_session_hint_v1_uid'] = 'locum';
      when(
        () => backend.postJson(
          '/api/session/validate',
          any(),
          token: any(named: 'token'),
        ),
      ).thenThrow(BackendException('Session unavailable', statusCode: status));
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.text('Sign in page'), findsOneWidget);
      expect(find.text('Session unavailable'), findsOneWidget);
      expect(find.textContaining('Home '), findsNothing);
      expect(current, isNull);
      expect(saved, isEmpty);
    });
  }
  testWidgets('mismatched account type fails closed', (tester) async {
    saved['real_session_hint_v1_uid'] = 'locum';
    when(
      () => backend.postJson(
        '/api/session/validate',
        any(),
        token: any(named: 'token'),
      ),
    ).thenAnswer(
      (_) async => {
        'data': {
          'uid': 'uid',
          'accountType': 'practice_owner',
          'access': 'active',
        },
      },
    );
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.text('Sign in page'), findsOneWidget);
    expect(current, isNull);
  });
  for (final response in [
    {'uid': 'uid', 'accountType': 'locum', 'access': 'disabled'},
    {'uid': 'other', 'accountType': 'locum', 'access': 'active'},
  ]) {
    testWidgets('invalid trusted session response $response fails closed', (
      tester,
    ) async {
      saved['real_session_hint_v1_uid'] = 'locum';
      when(
        () => backend.postJson(
          '/api/session/validate',
          any(),
          token: any(named: 'token'),
        ),
      ).thenAnswer((_) async => {'data': response});
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.text('Sign in page'), findsOneWidget);
      expect(find.textContaining('Home '), findsNothing);
      expect(current, isNull);
      expect(saved, isEmpty);
    });
  }
  testWidgets('stale Firebase session cannot reach the backend or home', (
    tester,
  ) async {
    saved['real_session_hint_v1_uid'] = 'locum';
    when(() => user.getIdToken(true)).thenThrow(
      FirebaseAuthException(code: 'user-token-expired'),
    );
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.text('Sign in page'), findsOneWidget);
    expect(find.textContaining('Home '), findsNothing);
    expect(current, isNull);
    expect(saved, isEmpty);
    verifyNever(
      () => backend.postJson(any(), any(), token: any(named: 'token')),
    );
  });
  testWidgets('logout clears hint and restored home', (tester) async {
    saved['real_session_hint_v1_uid'] = 'locum';
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.text('Home locum'), findsOneWidget);
    await workflow.signOut();
    await tester.pumpAndSettle();
    expect(saved, isEmpty);
    expect(find.text('Sign in page'), findsOneWidget);
    current = user;
    changes.add(user);
    await tester.pumpAndSettle();
    expect(find.text('Sign in page'), findsOneWidget);
    expect(find.text('Home locum'), findsNothing);
  });
  testWidgets('switching a restored account removes protected child routes', (
    tester,
  ) async {
    saved['real_session_hint_v1_uid'] = 'locum';
    await tester.pumpWidget(
      MaterialApp(
        home: RealSessionStartup(
          workflows: workflow,
          introBuilder: (_) => const Scaffold(body: Text('Sign in page')),
          homeBuilder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const Scaffold(body: Text('Private child')),
                ),
              ),
              child: const Text('Open private child'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open private child'));
    await tester.pumpAndSettle();
    expect(find.text('Private child'), findsOneWidget);
    locumSavedJobs.save(const SavedLocumJob(id: 'job', title: 'Private job'));
    final other = _User();
    when(() => other.uid).thenReturn('other');
    current = other;
    changes.add(other);
    await tester.pumpAndSettle();
    expect(find.text('Private child'), findsNothing);
    expect(find.text('Sign in page'), findsOneWidget);
    expect(saved, isEmpty);
    expect(locumSavedJobs.value, isEmpty);
  });
  testWidgets(
    'switching away and back during validation cannot reuse the response',
    (tester) async {
      saved['real_session_hint_v1_uid'] = 'locum';
      final pending = Completer<Map<String, dynamic>>();
      when(
        () => backend.postJson(
          '/api/session/validate',
          any(),
          token: any(named: 'token'),
        ),
      ).thenAnswer((_) => pending.future);
      await tester.pumpWidget(app());
      await tester.pump();
      final other = _User();
      when(() => other.uid).thenReturn('other');
      current = other;
      changes.add(other);
      await tester.pump();
      current = user;
      changes.add(user);
      await tester.pump();
      pending.complete({
        'data': {'uid': 'uid', 'accountType': 'locum', 'access': 'active'},
      });
      await tester.pumpAndSettle();
      expect(find.text('Sign in page'), findsOneWidget);
      expect(find.text('Home locum'), findsNothing);
      expect(current, same(user));
      verifyNever(() => auth.signOut());
    },
  );
  testWidgets(
    'account switching during validation never signs out the replacement',
    (tester) async {
      saved['real_session_hint_v1_uid'] = 'locum';
      final pending = Completer<Map<String, dynamic>>();
      when(
        () => backend.postJson(
          '/api/session/validate',
          any(),
          token: any(named: 'token'),
        ),
      ).thenAnswer((_) => pending.future);
      await tester.pumpWidget(app());
      await tester.pump();
      final other = _User();
      when(() => other.uid).thenReturn('other');
      current = other;
      changes.add(other);
      await tester.pump();
      pending.complete({
        'data': {'uid': 'uid', 'accountType': 'locum', 'access': 'active'},
      });
      await tester.pumpAndSettle();
      expect(find.text('Sign in page'), findsOneWidget);
      expect(current, same(other));
      expect(saved, isEmpty);
      verifyNever(() => auth.signOut());
    },
  );
}
