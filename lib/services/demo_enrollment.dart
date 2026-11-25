import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// This switch never changes the default production configuration.
const demoEnrollmentEnabled = bool.fromEnvironment('OPT_ISOLATED_DEMO');
const demoProjectId = 'demo-optolocum-account-management';

class DemoEnrollmentException implements Exception {
  const DemoEnrollmentException(this.message);
  final String message;
}

/// Recovery material is held only in this browser session, never preferences.
class DemoEnrollment {
  DemoEnrollment({required this.post, required this.signIn, required this.signOut,
    Future<void> Function()? wait, Future<void> Function(String, String)? verifySession})
    : wait = wait ?? (() => Future<void>.delayed(const Duration(seconds: 2))),
      verifySession = verifySession ?? ((_, _) async {});

  final Future<http.Response> Function(Uri, Map<String, String>, String) post;
  final Future<String?> Function(String, String) signIn;
  final Future<void> Function() signOut;
  final Future<void> Function() wait;
  final Future<void> Function(String, String) verifySession;
  _Attempt? _attempt;
  bool _busy = false;

  static DemoEnrollment? instance;

  static void configure(FirebaseApp app) {
    if (!demoEnrollmentEnabled || !kIsWeb ||
        Uri.base.origin != 'http://localhost:5174' ||
        app.options.projectId != demoProjectId) {
      throw StateError('Isolated enrollment requires the local demo environment.');
    }
    final auth = FirebaseAuth.instanceFor(app: app);
    instance = DemoEnrollment(
      post: (uri, headers, body) => http.post(uri, headers: headers, body: body),
      signIn: (email, password) async =>
          (await auth.signInWithEmailAndPassword(email: email, password: password)).user?.uid,
      signOut: auth.signOut,
      verifySession: (uid, type) async {
        final doc = await FirebaseFirestore.instanceFor(app: app)
            .collection('account_management').doc(uid)
            .get(const GetOptions(source: Source.server));
        if (!doc.exists || doc.data()?['trustedAccountType'] != type) {
          throw StateError('Account assignment was not confirmed.');
        }
      },
    );
  }

  Future<void> enroll({required String email, required String password,
    required String accountType, required Map<String, String> profile}) async {
    if (_busy) throw const DemoEnrollmentException('Signup is already in progress.');
    _busy = true;
    try {
      final normalized = email.trim().toLowerCase();
      final fields = Map<String, String>.unmodifiable(profile);
      final previous = _attempt;
      if (previous != null && (previous.email != normalized || previous.type != accountType ||
          !mapEquals(previous.profile, fields))) {
        throw const DemoEnrollmentException('A signup is awaiting confirmation. Retry with the original email, account type and details, or contact support.');
      }
      final attempt = _attempt ??= _Attempt(normalized, accountType, fields);
      http.Response response;
      try {
        response = await post(Uri.parse('http://127.0.0.1:8787/api/enrollment'),
          {'content-type': 'application/json'}, jsonEncode({
            'requestId': attempt.id, 'recoverySecret': attempt.secret,
            'email': normalized, 'password': password, 'accountType': accountType,
            'profile': fields,
          })).timeout(const Duration(seconds: 20));
      } catch (_) {
        throw const DemoEnrollmentException('Signup could not be confirmed. Keep this page open and retry with the same details and password.');
      }
      if (response.statusCode != 200) {
        if (response.statusCode == 409 || response.statusCode == 403) {
          throw const DemoEnrollmentException('Signup could not be completed. The email may already be registered or the request conflicts; contact support.');
        }
        throw const DemoEnrollmentException('Signup could not be completed. Retry with the same details or contact support.');
      }
      dynamic data;
      try { data = jsonDecode(response.body)['data']; } catch (_) { data = null; }
      if (data is! Map || data['uid'] is! String || (data['uid'] as String).isEmpty || data['accountType'] != accountType) {
        throw const DemoEnrollmentException('Signup could not be confirmed. Retry with the same details.');
      }
      // The server cutoff is in whole seconds. Sign in after it, rather than
      // reusing an Auth session created before enrollment completed.
      await wait();
      final uid = await signIn(normalized, password);
      if (uid != data['uid']) {
        await signOut();
        throw const DemoEnrollmentException('The signed-in account did not match signup. Contact support.');
      }
      try {
        await verifySession(uid!, accountType);
      } catch (_) {
        await signOut();
        throw const DemoEnrollmentException('Signup is saved, but your session could not be confirmed. Retry with the same details.');
      }
      _attempt = null;
    } finally { _busy = false; }
  }
}

class _Attempt {
  _Attempt(this.email, this.type, this.profile) : id = _randomHex(16), secret = _randomHex(32);
  final String email, type, id, secret;
  final Map<String, String> profile;
  static String _randomHex(int length) {
    final random = Random.secure();
    return List.generate(length, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }
}
