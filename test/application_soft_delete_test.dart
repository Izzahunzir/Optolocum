import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:optolocum/services/application_service.dart';

class _Firestore extends Mock implements FirebaseFirestore {}

class _Auth extends Mock implements FirebaseAuth {}

class _User extends Mock implements User {}

// ignore: subtype_of_sealed_class
class _Collection extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class _Reference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class _Snapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

class _Transaction extends Mock implements Transaction {}

void main() {
  setUpAll(() => registerFallbackValue((Transaction transaction) async {}));

  for (final existingApplication in [false, true]) {
    test(
      'deleted job blocks submission with existing application: $existingApplication',
      () async {
        final firestore = _Firestore();
        final auth = _Auth();
        final user = _User();
        final jobs = _Collection();
        final applications = _Collection();
        final jobRef = _Reference();
        final applicationRef = _Reference();
        final job = _Snapshot();
        final application = _Snapshot();
        final transaction = _Transaction();
        when(() => auth.currentUser).thenReturn(user);
        when(() => user.uid).thenReturn('locum');
        when(() => firestore.collection('job_postings')).thenReturn(jobs);
        when(() => firestore.collection('applications'))
            .thenReturn(applications);
        when(() => jobs.doc('job')).thenReturn(jobRef);
        when(() => applications.doc('job_locum')).thenReturn(applicationRef);
        when(() => transaction.get(jobRef)).thenAnswer((_) async => job);
        when(() => transaction.get(applicationRef))
            .thenAnswer((_) async => application);
        when(() => job.exists).thenReturn(true);
        when(() => job.data()).thenReturn({'status': 'deleted'});
        when(() => application.exists).thenReturn(existingApplication);
        when(() => firestore.runTransaction<void>(any()))
            .thenAnswer((invocation) async {
              await (invocation.positionalArguments.first
                  as Future<void> Function(Transaction))(transaction);
            });
        await expectLater(
          ApplicationService(
            firestore: firestore,
            auth: auth,
          ).applyForJob('job'),
          throwsA(
            predicate(
              (Object error) =>
                  error.toString().contains('no longer available'),
            ),
          ),
        );
        // Reading both records is allowed; no writes or history deletion follow.
        verify(() => transaction.get(jobRef)).called(1);
        verify(() => transaction.get(applicationRef)).called(1);
        verifyNoMoreInteractions(transaction);
        verifyNoMoreInteractions(applicationRef);
        verifyNoMoreInteractions(jobRef);
      },
    );
  }
}
