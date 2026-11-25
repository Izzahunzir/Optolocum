import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:optolocum/features/clinic_owner/CO_verification_status.dart';
import 'package:optolocum/features/locum/L_profile_data.dart';
import 'package:optolocum/services/verification_status_sync.dart';

class _Auth extends Mock implements FirebaseAuth {}

class _User extends Mock implements User {}

class _Db extends Mock implements FirebaseFirestore {}

// ignore: subtype_of_sealed_class
class _Collection extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class _Ref extends Mock implements DocumentReference<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class _Snapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

void main() {
  test('status sync maps canonical status and resets on sign out', () async {
    final auth = _Auth(), db = _Db(), user = _User();
    final locum = _Collection(), owner = _Collection();
    final locumRef = _Ref(), ownerRef = _Ref();
    final authEvents = StreamController<User?>(),
        locumEvents =
            StreamController<DocumentSnapshot<Map<String, dynamic>>>(),
        ownerEvents =
            StreamController<DocumentSnapshot<Map<String, dynamic>>>();
    when(() => auth.authStateChanges()).thenAnswer((_) => authEvents.stream);
    when(() => user.uid).thenReturn('uid');
    when(() => db.collection('locum_profiles')).thenReturn(locum);
    when(() => db.collection('practice_owner_profiles')).thenReturn(owner);
    when(() => locum.doc('uid')).thenReturn(locumRef);
    when(() => owner.doc('uid')).thenReturn(ownerRef);
    when(() => locumRef.snapshots()).thenAnswer((_) => locumEvents.stream);
    when(() => ownerRef.snapshots()).thenAnswer((_) => ownerEvents.stream);
    final locumSnapshot = _Snapshot(), ownerSnapshot = _Snapshot();
    when(() => locumSnapshot.data())
        .thenReturn({'verificationStatus': 'verified'});
    when(() => ownerSnapshot.data())
        .thenReturn({'verificationStatus': 'approved'});
    VerificationStatusSync(auth, db).start();
    authEvents.add(user);
    await Future<void>.delayed(Duration.zero);
    locumEvents.add(locumSnapshot);
    ownerEvents.add(ownerSnapshot);
    await Future<void>.delayed(Duration.zero);
    expect(locumVerificationStatus.value, LocumVerificationStatus.unverified);
    expect(coVerificationStatus.value, COVerificationStatus.approved);
    when(() => locumSnapshot.data())
        .thenReturn({'verificationStatus': 'rejected'});
    locumEvents.add(locumSnapshot);
    await Future<void>.delayed(Duration.zero);
    expect(locumVerificationStatus.value, LocumVerificationStatus.rejected);
    authEvents.add(null);
    await Future<void>.delayed(Duration.zero);
    expect(locumVerificationStatus.value, LocumVerificationStatus.unverified);
    expect(coVerificationStatus.value, COVerificationStatus.unverified);
    await authEvents.close();
    await locumEvents.close();
    await ownerEvents.close();
  });
}
