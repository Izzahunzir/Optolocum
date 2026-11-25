import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// A conservative UX check. Firestore rules remain authoritative.
Future<void> requireApprovedAccount(
  FirebaseAuth auth,
  FirebaseFirestore db,
  String type,
) async {
  final uid = auth.currentUser?.uid;
  if (uid == null) throw StateError('Please sign in again.');
  final assignment = await db
      .collection('account_management')
      .doc(uid)
      .get(const GetOptions(source: Source.server));
  final profiles = type == 'locum'
      ? 'locum_profiles'
      : 'practice_owner_profiles';
  final profile = await db
      .collection(profiles)
      .doc(uid)
      .get(const GetOptions(source: Source.server));
  if (auth.currentUser?.uid != uid ||
      assignment.data()?['trustedAccountType'] != type ||
      profile.data()?['verificationStatus'] != 'approved') {
    throw StateError('An active approved account is required for this action.');
  }
}
