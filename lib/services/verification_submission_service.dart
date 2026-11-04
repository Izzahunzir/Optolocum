import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'verification_submission.dart';

/// Persistence boundary also used by offline failure/retry tests.
abstract interface class VerificationRepository {
  String? get currentUid;
  Future<void> reserve(VerificationSubmission submission);
  Future<void> upload(VerificationSubmission submission);
  Future<void> finalize(VerificationSubmission submission);
}

class VerificationSubmissionService implements VerificationSubmissionClient {
  VerificationSubmissionService(this.repository);
  final VerificationRepository repository;

  void _check(String uid) {
    if (repository.currentUid != uid) {
      throw StateError('Your account changed. Please reopen the form.');
    }
  }

  @override
  Future<void> submit(
    VerificationSubmission submission, {
    Future<void> Function()? saveProfile,
  }) async {
    _check(submission.uid);
    await repository.reserve(submission);
    _check(submission.uid);
    if (submission.document != null) await repository.upload(submission);
    _check(submission.uid);
    if (saveProfile != null) await saveProfile();
    _check(submission.uid);
    await repository.finalize(submission);
    _check(submission.uid);
  }
}

/// No production factory in Phase 1. All three SDKs use the same demo app and
/// loopback emulators. Creating this repository cannot target live Firebase.
class FirebaseVerificationRepository implements VerificationRepository {
  FirebaseVerificationRepository._(this._firestore, this._auth, this._storage);
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

  static Future<FirebaseVerificationRepository> emulator({
    required FirebaseApp app,
    String host = '127.0.0.1',
    int firestorePort = 8188,
    int authPort = 9198,
    int storagePort = 9298,
  }) async {
    if (!app.options.projectId.startsWith('demo-') ||
        !['127.0.0.1', 'localhost', '10.0.2.2'].contains(host)) {
      throw ArgumentError(
        'Verification requires a demo project and local emulators.',
      );
    }
    final firestore = FirebaseFirestore.instanceFor(app: app);
    final auth = FirebaseAuth.instanceFor(app: app);
    final storage = FirebaseStorage.instanceFor(app: app);
    firestore.settings = const Settings(persistenceEnabled: false);
    firestore.useFirestoreEmulator(host, firestorePort);
    await auth.useAuthEmulator(host, authPort);
    await storage.useStorageEmulator(host, storagePort);
    return FirebaseVerificationRepository._(firestore, auth, storage);
  }

  @override
  String? get currentUid => _auth.currentUser?.uid;
  DocumentReference<Map<String, dynamic>> _ref(VerificationSubmission s) =>
      _firestore
          .collection('verification_submissions')
          .doc(s.uid)
          .collection('revisions')
          .doc(s.id);

  void _check(VerificationSubmission s) {
    if (currentUid != s.uid) {
      throw StateError('Your account changed. Reopen the form.');
    }
  }

  void _same(VerificationSubmission s, Map<String, dynamic> data) {
    // Compare the complete immutable payload, not just a client-supplied hash.
    for (final entry in s.payload.entries) {
      if (jsonEncode(data[entry.key]) != jsonEncode(entry.value)) {
        // Firestore map ordering is not stable; compare canonical structures.
        if (jsonEncode(_canonical(data[entry.key])) !=
            jsonEncode(_canonical(entry.value))) {
          throw StateError(
            'This revision contains different details. Start a new revision.',
          );
        }
      }
    }
    if (!['draft', 'submitted'].contains(data['state'])) {
      throw StateError('Invalid submission state.');
    }
  }

  static dynamic _canonical(dynamic value) {
    if (value is Map) {
      final keys = value.keys.cast<String>().toList()..sort();
      return {for (final key in keys) key: _canonical(value[key])};
    }
    return value;
  }

  @override
  Future<void> reserve(VerificationSubmission s) async {
    _check(s);
    await _firestore.runTransaction<void>((tx) async {
      final existing = await tx.get(_ref(s));
      _check(s);
      if (existing.exists) {
        _same(s, existing.data()!);
        return;
      }
      tx.set(_ref(s), {
        ...s.payload,
        'state': 'draft',
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  bool _matches(FullMetadata metadata, VerificationDocument doc) =>
      metadata.size == doc.bytes.length &&
      metadata.contentType == doc.contentType &&
      metadata.customMetadata?['sha256'] == doc.sha256Hex;

  @override
  Future<void> upload(VerificationSubmission s) async {
    _check(s);
    final doc = s.document!;
    final reference = _storage.ref(s.documentPath);
    try {
      final existing = await reference.getMetadata();
      if (!_matches(existing, doc)) {
        throw StateError('Existing document differs. Start a new revision.');
      }
      return; // A completed upload can survive a failed finalization/restart.
    } on FirebaseException catch (error) {
      if (error.code != 'object-not-found') rethrow;
    }
    _check(s);
    await reference.putData(
      doc.bytes,
      SettableMetadata(
        contentType: doc.contentType,
        cacheControl: 'private, no-store',
        customMetadata: {'sha256': doc.sha256Hex},
      ),
    );
    _check(s);
    if (!_matches(await reference.getMetadata(), doc)) {
      throw StateError('Document upload could not be confirmed.');
    }
  }

  @override
  Future<void> finalize(VerificationSubmission s) async {
    _check(s);
    await _firestore.runTransaction<void>((tx) async {
      final existing = await tx.get(_ref(s));
      _check(s);
      if (!existing.exists) throw StateError('Submission draft is missing.');
      final data = existing.data()!;
      _same(s, data);
      if (data['state'] == 'submitted') return; // Uncertain commit: safe retry.
      tx.update(_ref(s), {
        'state': 'submitted',
        'submittedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
