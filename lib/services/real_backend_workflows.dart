import 'dart:convert';
import 'dart:math';

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
  static const _enrollmentKey = 'real_enrollment_recovery_v1';

  /// Fail closed until the trusted session-validation endpoint is implemented.
  Future<void> signIn({
    required String email,
    required String password,
    required String accountType,
  }) async {
    try {
      final credential = await auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null || auth.currentUser?.uid != user.uid) {
        throw StateError(
          'Your session could not be confirmed. Please sign in again.',
        );
      }
      final token = await user.getIdToken(true);
      if (token == null || token.isEmpty || auth.currentUser?.uid != user.uid) {
        throw StateError(
          'Your session could not be confirmed. Please sign in again.',
        );
      }
      final assignment = await firestore
          .collection('account_management')
          .doc(user.uid)
          .get(const GetOptions(source: Source.server));
      if (auth.currentUser?.uid != user.uid ||
          assignment.data()?['trustedAccountType'] != accountType) {
        throw StateError(
          'This account is not assigned to the selected account type.',
        );
      }
      throw StateError(
        'Account access validation is not available yet. Please try again later.',
      );
    } on FirebaseAuthException {
      await auth.signOut();
      rethrow;
    } on StateError {
      await auth.signOut();
      rethrow;
    } catch (_) {
      await auth.signOut();
      throw StateError(
        'Account access could not be confirmed. Please try again later.',
      );
    }
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
      final credential = await auth.signInWithEmailAndPassword(
        email: normalized,
        password: password,
      );
      if (credential.user?.uid != data['uid']) {
        await auth.signOut();
        throw StateError(
          'The signed-in account did not match signup. Contact support.',
        );
      }
      try {
        final assignment = await firestore
            .collection('account_management')
            .doc(data['uid'] as String)
            .get(const GetOptions(source: Source.server));
        if (assignment.data()?['trustedAccountType'] != accountType ||
            auth.currentUser?.uid != data['uid']) {
          throw StateError('Account assignment was not confirmed.');
        }
      } catch (_) {
        await auth.signOut();
        throw StateError(
          'Signup is saved, but account access could not be confirmed. Retry or contact support.',
        );
      }
      // An assignment alone does not confirm that account access is active or
      // that the session has not been revoked. Keep recovery until validated.
      await auth.signOut();
      throw StateError(
        'Signup is saved, but account access validation is not available yet. Retry later.',
      );
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
