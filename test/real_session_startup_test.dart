import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:optolocum/main.dart';
import 'package:optolocum/services/real_backend_client.dart';
import 'package:optolocum/services/real_backend_workflows.dart';

class _Backend extends Mock implements RealBackendClient {}
class _Auth extends Mock implements FirebaseAuth {}
class _User extends Mock implements User {}
class _Database extends Mock implements FirebaseFirestore {}
class _Storage extends Mock implements FlutterSecureStorage {}

void main() {
  testWidgets('startup signs out a persisted session and shows sign in', (tester) async {
    final auth = _Auth();
    final user = _User();
    final storage = _Storage();
    final backend = _Backend();
    User? current = user;
    when(() => user.uid).thenReturn('uid');
    when(() => auth.currentUser).thenAnswer((_) => current);
    when(() => auth.authStateChanges()).thenAnswer((_) => Stream.value(current));
    when(() => auth.signOut()).thenAnswer((_) async => current = null);
    when(() => storage.delete(key: any(named: 'key'))).thenAnswer((_) async {});
    final workflow = RealBackendWorkflows(backend, auth, _Database(), storage: storage);
    await tester.pumpWidget(MaterialApp(home: RealSessionStartup(
      workflows: workflow,
      introBuilder: (_) => const Scaffold(body: Text('Sign in')),
      homeBuilder: (_, _) => const Scaffold(body: Text('Home')),
    )));
    await tester.pumpAndSettle();
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Home'), findsNothing);
    verify(() => auth.signOut()).called(1);
    verify(() => storage.delete(key: 'real_session_hint_v1_uid')).called(1);
    verifyNever(() => backend.postJson(any(), any(), token: any(named: 'token')));
  });
}
