import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../features/clinic_owner/CO_verification_status.dart';
import '../features/locum/L_profile_data.dart';

/// Keeps the existing status notifiers aligned with the signed-in account.
class VerificationStatusSync {
  VerificationStatusSync(this.auth, this.firestore);

  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _locum;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _owner;
  int _generation = 0;

  void start() {
    _authSubscription ??= auth.authStateChanges().listen(_changeAccount);
  }

  void _changeAccount(User? user) {
    final generation = ++_generation;
    unawaited(_locum?.cancel());
    unawaited(_owner?.cancel());
    locumVerificationStatus.value = LocumVerificationStatus.unverified;
    coVerificationStatus.value = COVerificationStatus.unverified;
    if (user == null) return;
    _locum = firestore
        .collection('locum_profiles')
        .doc(user.uid)
        .snapshots()
        .listen(
          (snapshot) {
            if (generation != _generation) return;
            locumVerificationStatus.value = switch (snapshot
                .data()?['verificationStatus']) {
              'pending' => LocumVerificationStatus.pending,
              'approved' => LocumVerificationStatus.approved,
              'rejected' => LocumVerificationStatus.rejected,
              _ => LocumVerificationStatus.unverified,
            };
          },
          onError: (_) {
            if (generation == _generation) {
              locumVerificationStatus.value =
                  LocumVerificationStatus.unverified;
            }
          },
        );
    _owner = firestore
        .collection('practice_owner_profiles')
        .doc(user.uid)
        .snapshots()
        .listen(
          (snapshot) {
            if (generation != _generation) return;
            coVerificationStatus.value = switch (snapshot
                .data()?['verificationStatus']) {
              'pending' => COVerificationStatus.pending,
              'approved' => COVerificationStatus.approved,
              'rejected' => COVerificationStatus.rejected,
              _ => COVerificationStatus.unverified,
            };
          },
          onError: (_) {
            if (generation == _generation) {
              coVerificationStatus.value = COVerificationStatus.unverified;
            }
          },
        );
  }
}
