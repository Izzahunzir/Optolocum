import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../features/locum/L_profile_data.dart';
import 'application_service.dart';
import 'locum_profile_store.dart';

class LocumProfileService {
  LocumProfileService._() {
    _syncAccount(_auth.currentUser?.uid);
    // App-lifetime subscription: also clear caches when no profile page is open.
    _auth.authStateChanges().listen((user) => _syncAccount(user?.uid));
  }

  static final instance = LocumProfileService._();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  String? _uid;
  int _generation = 0;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  String? get currentUid {
    _syncAccount(_auth.currentUser?.uid);
    return _uid;
  }

  void _syncAccount(String? uid) {
    if (_uid == uid &&
        (locumProfileData.value == null ||
            locumProfileData.value!.uid == uid)) {
      return;
    }
    _uid = uid;
    clearCache();
  }

  void clearCache() {
    _generation++;
    locumProfileData.value = null;
    locumVerificationStatus.value = LocumVerificationStatus.unverified;
  }

  void _checkAccount(String uid, int generation) {
    if (currentUid != uid || _generation != generation) {
      throw StateError('Your account changed. Please reopen your profile.');
    }
  }

  void _cache(LocumProfileData? profile) {
    locumProfileData.value = profile;
    locumVerificationStatus.value = switch (profile?.verificationStatus) {
      'pending' => LocumVerificationStatus.pending,
      'verified' => LocumVerificationStatus.verified,
      _ => LocumVerificationStatus.unverified,
    };
  }

  void _refreshApplicantSummaries(String uid) {
    // Summary sync is independent of profile loading/saving. In particular,
    // denied summary writes before the manual rules update cannot break either.
    unawaited(
      ApplicationService()
          .refreshMyApplicantSummaries(expectedUid: uid)
          .catchError((Object error) {
            debugPrint(
              'Applicant summaries could not be refreshed. '
              'Retry by reopening or saving the Locum profile.',
            );
          }),
    );
  }

  Future<LocumProfileData?> load(String uid) async {
    final generation = _generation;
    _checkAccount(uid, generation);
    final snapshot = await _firestore
        .collection('locum_profiles')
        .doc(uid)
        .get();
    _checkAccount(uid, generation);
    final data = snapshot.data();
    final profile = data == null
        ? null
        : LocumProfileData.fromFirestore(uid, data);
    // Preserve previews only for this authenticated account, never in Firestore.
    final previews = locumProfileData.value;
    final result = profile == null
        ? null
        : LocumProfileData(
            uid: uid,
            fields: profile.fields,
            verificationStatus: profile.verificationStatus,
            documents: previews?.uid == uid ? previews!.documents : const [],
          );
    _cache(result);
    if (result != null) _refreshApplicantSummaries(uid);
    return result;
  }

  Future<void> save(LocumProfileData profile) async {
    final generation = _generation;
    _checkAccount(profile.uid, generation);
    if (profile.verificationStatus != 'pending') {
      throw ArgumentError('Profile submissions must remain pending.');
    }
    await LocumProfileStore(_firestore).save(profile);
    _checkAccount(profile.uid, generation);
    _cache(profile);
    _refreshApplicantSummaries(profile.uid);
  }

  Future<void> signOut() async {
    clearCache();
    await _auth.signOut();
  }
}
