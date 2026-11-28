import 'dart:convert';
import 'dart:math';
import 'dart:async';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'real_backend_client.dart';
import 'verification_submission.dart';

const realBackendEnabled = bool.fromEnvironment('OPT_REAL_BACKEND');
RealBackendWorkflows? realBackendWorkflows;

String _randomId(int bytes) {
  final random = Random.secure();
  return List.generate(
    bytes,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
}

/// Recovery entries contain no passwords or document bytes.
class RealBackendWorkflows implements VerificationSubmissionClient {
  RealBackendWorkflows(
    this.backend,
    this.auth,
    this.firestore, {
    FlutterSecureStorage? storage,
    this.enrollmentDelay = const Duration(seconds: 2),
  }) : storage = storage ?? const FlutterSecureStorage();
  final RealBackendClient backend;
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final FlutterSecureStorage storage;
  final Duration enrollmentDelay;
  bool _enrolling = false;
  bool _submitting = false;
  String? _activeUid;
  int _accountGeneration = 0;
  static const _enrollmentKey = 'real_enrollment_recovery_v1';
  static String _sessionKey(String uid) => 'real_session_hint_v1_$uid';

  /// Removes only the specified account's non-secret routing hint.
  Future<void> clearSessionHint(String uid) =>
      storage.delete(key: _sessionKey(uid));

  /// Watches external Firebase sign-outs and account switches as well as app logout.
  StreamSubscription<User?> watchAccountChanges({
    void Function()? onValidatedAccountChanged,
  }) {
    var previousUid = auth.currentUser?.uid;
    return auth.authStateChanges().listen((user) {
      final oldUid = previousUid;
      previousUid = user?.uid;
      if (oldUid != null && oldUid != user?.uid) {
        _accountGeneration++;
        unawaited(clearSessionHint(oldUid).catchError((Object _) {}));
        if (_activeUid == oldUid) {
          _activeUid = null;
          onValidatedAccountChanged?.call();
        }
      }
    });
  }

  Future<void> _validateAndRemember(User user, String accountType) async {
    final generation = _accountGeneration;
    await validateSession(accountType, expectedUser: user);
    try {
      await storage.write(key: _sessionKey(user.uid), value: accountType);
      if (auth.currentUser?.uid != user.uid ||
          generation != _accountGeneration) {
        await clearSessionHint(user.uid);
        throw StateError('Your account changed. Please sign in again.');
      }
      _activeUid = user.uid;
    } catch (_) {
      if (auth.currentUser?.uid != user.uid ||
          generation == _accountGeneration) {
        try {
          await clearSessionHint(user.uid);
        } catch (_) {}
      }
      if (auth.currentUser?.uid == user.uid &&
          generation == _accountGeneration) {
        await auth.signOut();
      }
      throw StateError(
        'Your session could not be saved. Please sign in again.',
      );
    }
  }

  /// A hint selects the request; only a successful server response grants entry.
  Future<({String uid, String accountType})?> restoreSession() async {
    final user = auth.currentUser;
    if (user == null) return null;
    final generation = _accountGeneration;
    try {
      final type = await storage.read(key: _sessionKey(user.uid));
      if (auth.currentUser?.uid != user.uid ||
          generation != _accountGeneration) {
        throw StateError('Your account changed. Please sign in again.');
      }
      if (type != 'locum' && type != 'practice_owner') {
        throw StateError('Please sign in again to confirm your account.');
      }
      await _validateAndRemember(user, type!);
      return (uid: user.uid, accountType: type);
    } catch (_) {
      if (auth.currentUser?.uid != user.uid ||
          generation == _accountGeneration) {
        try {
          await clearSessionHint(user.uid);
        } catch (_) {}
      }
      if (auth.currentUser?.uid == user.uid &&
          generation == _accountGeneration) {
        await auth.signOut();
      }
      rethrow;
    }
  }

  Future<void> signOut() async {
    final uid = auth.currentUser?.uid;
    if (uid == null) return;
    try {
      await clearSessionHint(uid);
    } finally {
      if (auth.currentUser?.uid == uid) await auth.signOut();
    }
  }

  /// Confirms both Firebase identity and trusted access before navigation.
  Future<void> validateSession(String accountType, {User? expectedUser}) async {
    final user = expectedUser ?? auth.currentUser;
    final generation = _accountGeneration;
    if (user == null ||
        !const ['locum', 'practice_owner'].contains(accountType)) {
      throw StateError(
        'Your session could not be confirmed. Please sign in again.',
      );
    }
    try {
      if (auth.currentUser?.uid != user.uid ||
          generation != _accountGeneration) {
        throw StateError('Your account changed. Please sign in again.');
      }
      final token = await user.getIdToken(true);
      if (token == null ||
          token.isEmpty ||
          auth.currentUser?.uid != user.uid ||
          generation != _accountGeneration) {
        throw StateError(
          'Your session could not be confirmed. Please sign in again.',
        );
      }
      final result = await backend.postJson('/api/session/validate', {
        'accountType': accountType,
      }, token: token);
      final data = result['data'];
      if (auth.currentUser?.uid != user.uid ||
          generation != _accountGeneration ||
          data is! Map ||
          data['uid'] is! String ||
          data['uid'] != user.uid ||
          data['accountType'] != accountType ||
          data['access'] != 'active') {
        throw StateError(
          'Your account access could not be confirmed. Please sign in again.',
        );
      }
    } catch (_) {
      if (auth.currentUser?.uid == user.uid && generation == _accountGeneration)
        await auth.signOut();
      rethrow;
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
    required String accountType,
  }) async {
    final previousUid = auth.currentUser?.uid;
    if (previousUid != null) await clearSessionHint(previousUid);
    late final UserCredential credential;
    try {
      credential = await auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException {
      if (previousUid != null && auth.currentUser?.uid == previousUid) {
        await auth.signOut();
      }
      rethrow;
    }
    final user = credential.user;
    if (user == null || auth.currentUser?.uid != user.uid) {
      throw StateError(
        'Your session could not be confirmed. Please sign in again.',
      );
    }
    await _validateAndRemember(user, accountType);
  }

  Future<void> enroll({
    required String email,
    required String password,
    required String accountType,
    required Map<String, String> profile,
  }) async {
    if (_enrolling) throw StateError('Signup is already in progress.');
    _enrolling = true;
    try {
      final normalized = email.trim().toLowerCase();
      final fields = {
        for (final key in (profile.keys.toList()..sort())) key: profile[key],
      };
      final fingerprint = sha256
          .convert(utf8.encode(jsonEncode([normalized, accountType, fields])))
          .toString();
      final saved = await storage.read(key: _enrollmentKey);
      Map<String, dynamic> attempt;
      if (saved == null) {
        attempt = {
          'id': _randomId(16),
          'secret': _randomId(32),
          'fingerprint': fingerprint,
        };
        await storage.write(key: _enrollmentKey, value: jsonEncode(attempt));
      } else {
        attempt = Map<String, dynamic>.from(jsonDecode(saved) as Map);
        if (attempt['fingerprint'] != fingerprint) {
          throw StateError(
            'A signup is awaiting confirmation. Retry with the original details and password or contact support.',
          );
        }
      }
      final result = await backend.postJson('/api/enrollment', {
        'requestId': attempt['id'],
        'recoverySecret': attempt['secret'],
        'email': normalized,
        'password': password,
        'accountType': accountType,
        'profile': profile,
      });
      final data = result['data'];
      if (data is! Map ||
          data['uid'] is! String ||
          (data['uid'] as String).isEmpty ||
          data['accountType'] != accountType) {
        throw StateError(
          'Signup could not be confirmed. Retry with the original details.',
        );
      }
      await Future<void>.delayed(enrollmentDelay);
      final previousUid = auth.currentUser?.uid;
      if (previousUid != null) await clearSessionHint(previousUid);
      final credential = await auth.signInWithEmailAndPassword(
        email: normalized,
        password: password,
      );
      if (credential.user?.uid != data['uid']) {
        if (auth.currentUser?.uid == credential.user?.uid) await auth.signOut();
        throw StateError(
          'The signed-in account did not match signup. Contact support.',
        );
      }
      await _validateAndRemember(credential.user!, accountType);
      await storage.delete(key: _enrollmentKey);
    } finally {
      _enrolling = false;
    }
  }

  @override
  Future<void> submit(
    VerificationSubmission submission, {
    Future<void> Function()? saveProfile,
  }) async {
    if (_submitting) throw StateError('Submission is already in progress.');
    _submitting = true;
    try {
      final user = auth.currentUser;
      if (user == null || user.uid != submission.uid) {
        throw StateError('Please sign in again.');
      }
      final token = await user.getIdToken();
      if (token == null || token.isEmpty || auth.currentUser?.uid != user.uid) {
        throw StateError('Please sign in again.');
      }
      final key = 'verification_recovery_${user.uid}_${submission.kind}';
      final saved = await storage.read(key: key);
      final profile = await firestore
          .collection(
            submission.kind == 'locum'
                ? 'locum_profiles'
                : 'practice_owner_profiles',
          )
          .doc(user.uid)
          .get(const GetOptions(source: Source.server));
      if (auth.currentUser?.uid != user.uid) {
        throw StateError('Your account changed. Reopen the form.');
      }
      final status = profile.data()?['verificationStatus'];
      if (status == 'approved') {
        throw StateError('Approved verification details are read-only.');
      }
      if (status == 'pending' &&
          (saved == null ||
              (jsonDecode(saved) as Map)['fingerprint'] !=
                  submission.fingerprint)) {
        throw StateError('Your verification is already awaiting review.');
      }
      Map<String, dynamic> attempt;
      if (saved == null) {
        attempt = {'id': _randomId(16), 'fingerprint': submission.fingerprint};
        await storage.write(key: key, value: jsonEncode(attempt));
      } else {
        attempt = Map<String, dynamic>.from(jsonDecode(saved) as Map);
        if (status == 'rejected' && attempt['completed'] == true) {
          attempt = {
            'id': _randomId(16),
            'fingerprint': submission.fingerprint,
          };
          await storage.write(key: key, value: jsonEncode(attempt));
        }
        if (attempt['fingerprint'] != submission.fingerprint) {
          if (attempt['completed'] != true) {
            throw StateError(
              'A submission is awaiting confirmation. Retry with the same details and document, or contact support.',
            );
          }
          attempt = {
            'id': _randomId(16),
            'fingerprint': submission.fingerprint,
          };
          await storage.write(key: key, value: jsonEncode(attempt));
        }
      }
      final id = attempt['id'] as String;
      final draft = await backend.postJson('/api/applicant/draft', {
        'requestId': id,
        'accountType': submission.kind,
        'submittedFields': submission.fields,
      }, token: token);
      final data = draft['data'];
      if (data is! Map ||
          data['submissionId'] is! String ||
          !['draft', 'submitted'].contains(data['state'])) {
        throw StateError(
          'Submission could not be confirmed. Retry with the same details.',
        );
      }
      if (auth.currentUser?.uid != user.uid) {
        throw StateError('Your account changed. Reopen the form.');
      }
      if (data['state'] != 'submitted') {
        final document = submission.document!;
        final upload = await backend.upload(
          id,
          document.bytes,
          document.contentType,
          token: token,
        );
        if (upload['data'] is! Map ||
            (upload['data'] as Map)['documentUploaded'] != true ||
            (upload['data'] as Map)['submissionId'] != data['submissionId']) {
          throw StateError(
            'Upload could not be confirmed. Retry with the same document.',
          );
        }
        if (auth.currentUser?.uid != user.uid) {
          throw StateError('Your account changed. Reopen the form.');
        }
        final result = await backend.postJson('/api/applicant/finalize', {
          'requestId': id,
        }, token: token);
        if (result['data'] is! Map ||
            (result['data'] as Map)['state'] != 'submitted' ||
            (result['data'] as Map)['submissionId'] != data['submissionId']) {
          throw StateError(
            'Submission could not be confirmed. Retry with the same details.',
          );
        }
      }
      if (auth.currentUser?.uid != user.uid) {
        throw StateError('Your account changed. Reopen the form.');
      }
      // Keep the request ID after success so reopening the form with the same
      // evidence recovers the submitted revision instead of creating another.
      await storage.write(
        key: key,
        value: jsonEncode({...attempt, 'completed': true}),
      );
      // The trusted server owns profile changes; never call saveProfile here.
    } finally {
      _submitting = false;
    }
  }
}
