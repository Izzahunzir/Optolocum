import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:optolocum/services/job_service.dart';

class _Firestore extends Mock implements FirebaseFirestore {}

class _Auth extends Mock implements FirebaseAuth {}

class _User extends Mock implements User {}

// ignore: subtype_of_sealed_class
class _Collection extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class _Query extends Mock implements Query<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class _Reference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

void main() {
  test(
    'createJob stores owner, schema, status, and returns document ID',
    () async {
      final firestore = _Firestore();
      final auth = _Auth();
      final user = _User();
      final collection = _Collection();
      final reference = _Reference();
      when(() => auth.currentUser).thenReturn(user);
      when(() => user.uid).thenReturn('owner-1');
      when(() => firestore.collection('job_postings')).thenReturn(collection);
      when(() => reference.id).thenReturn('new-job');
      when(() => collection.add(any())).thenAnswer((_) async => reference);

      final id = await JobService(firestore: firestore, auth: auth).createJob(
        placeName: 'Vision Care Clinic',
        location: 'Central Mall',
        role: 'Optometrist',
        jobDate: DateTime(2026, 12, 1),
        startTime: '09:00',
        endTime: '17:00',
        payRate: 65,
        payRateUnit: 'per_hour',
        jobDescription: 'Eye examinations',
        contactPerson: 'Natalie',
        contactNumber: '0123456789',
      );

      expect(id, 'new-job');
      final data =
          verify(() => collection.add(captureAny())).captured.single
              as Map<String, dynamic>;
      expect(data['clinicOwnerId'], 'owner-1');
      expect(data['placeName'], 'Vision Care Clinic');
      expect(data['jobDate'], Timestamp.fromDate(DateTime(2026, 12, 1)));
      expect(data['payRateUnit'], 'per_hour');
      expect(data['status'], 'available');
      expect(data['createdAt'], isA<FieldValue>());
      expect(data['updatedAt'], isA<FieldValue>());
    },
  );

  test('createJob rejects unauthenticated owner', () async {
    final auth = _Auth();
    when(() => auth.currentUser).thenReturn(null);
    await expectLater(
      JobService(firestore: _Firestore(), auth: auth).createJob(
        placeName: 'Clinic',
        location: 'City',
        role: 'Optometrist',
        jobDate: DateTime(2026, 12, 1),
        startTime: '09:00',
        endTime: '17:00',
        payRate: 65,
        payRateUnit: 'per_hour',
        jobDescription: 'Description',
        contactPerson: 'Owner',
        contactNumber: '0123456789',
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('getMyJobs scopes the query to the authenticated owner', () {
    final firestore = _Firestore();
    final auth = _Auth();
    final user = _User();
    final collection = _Collection();
    final query = _Query();
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.uid).thenReturn('owner-1');
    when(() => firestore.collection('job_postings')).thenReturn(collection);
    when(() => collection.where('clinicOwnerId', isEqualTo: 'owner-1'))
        .thenReturn(query);
    when(() => query.snapshots()).thenAnswer((_) => const Stream.empty());

    JobService(firestore: firestore, auth: auth).getMyJobs();

    verify(() => collection.where('clinicOwnerId', isEqualTo: 'owner-1'))
        .called(1);
  });
}
