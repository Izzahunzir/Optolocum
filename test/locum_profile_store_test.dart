import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:optolocum/features/locum/L_profile_data.dart';
import 'package:optolocum/services/locum_profile_store.dart';

class _Firestore extends Mock implements FirebaseFirestore {}

// SDK interface doubles are confined to this transaction unit test.
// ignore: subtype_of_sealed_class
class _Collection extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class _Reference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class _Transaction extends Mock implements Transaction {}

// Test double only; production code uses SDK snapshots returned by transactions.
// ignore: subtype_of_sealed_class
class _Snapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

void main() {
  setUpAll(() {
    registerFallbackValue(SetOptions(merge: true));
    registerFallbackValue((Transaction transaction) async {});
  });

  late _Firestore firestore;
  late _Transaction transaction;
  late _Snapshot snapshot;
  late List<Map<String, dynamic>> writes;
  late List<SetOptions> options;

  final profile = LocumProfileData(
    uid: 'test-locum',
    fields: const {'Full Name': 'Test Locum', 'Course': 'Optometry'},
    documents: const [],
    verificationStatus: 'pending',
  );

  setUp(() {
    firestore = _Firestore();
    final collection = _Collection();
    final reference = _Reference();
    transaction = _Transaction();
    snapshot = _Snapshot();
    writes = [];
    options = [];
    when(() => firestore.collection('locum_profiles')).thenReturn(collection);
    when(() => collection.doc('test-locum')).thenReturn(reference);
    when(() => transaction.get(reference)).thenAnswer((_) async => snapshot);
    when(() => transaction.set<Map<String, dynamic>>(reference, any(), any()))
        .thenAnswer((invocation) {
          writes.add(
            Map<String, dynamic>.from(invocation.positionalArguments[1] as Map),
          );
          options.add(invocation.positionalArguments[2] as SetOptions);
          return transaction;
        });
    when(() => firestore.runTransaction<void>(any()))
        .thenAnswer((invocation) async {
          final action =
              invocation.positionalArguments[0]
                  as Future<void> Function(Transaction);
          await action(transaction);
        });
  });

  test(
    'first creation includes server timestamps and all submitted fields',
    () async {
      when(() => snapshot.exists).thenReturn(false);
      await LocumProfileStore(firestore).save(profile);
      expect(writes.single, {
        ...profile.toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      expect(options.single.merge, isTrue);
    },
  );

  test(
    'repeated saves omit createdAt and merge existing backend fields',
    () async {
      when(() => snapshot.exists).thenReturn(true);
      final store = LocumProfileStore(firestore);
      await store.save(profile);
      await store.save(profile);
      final original = Timestamp.fromDate(DateTime.utc(2025, 1, 1));
      var persisted = <String, dynamic>{
        'createdAt': original,
        'adminNote': 'retain',
      };
      for (final write in writes) {
        expect(write.containsKey('createdAt'), isFalse);
        expect(write['updatedAt'], FieldValue.serverTimestamp());
        expect(write['verificationStatus'], 'pending');
        persisted = {...persisted, ...write};
      }
      expect(persisted['createdAt'], original);
      expect(persisted['adminNote'], 'retain');
      expect(options.every((option) => option.merge == true), isTrue);
    },
  );

  test(
    'legacy existing documents are not assigned guessed creation dates',
    () async {
      when(() => snapshot.exists).thenReturn(true);
      await LocumProfileStore(firestore).save(profile);
      expect(writes.single.containsKey('createdAt'), isFalse);
    },
  );

  test(
    'transaction retry rechecks existence after a competing creation',
    () async {
      when(() => snapshot.exists).thenReturn(false);
      when(() => firestore.runTransaction<void>(any()))
          .thenAnswer((invocation) async {
            final action =
                invocation.positionalArguments[0]
                    as Future<void> Function(Transaction);
            await action(transaction); // Simulate an aborted first attempt.
            when(() => snapshot.exists).thenReturn(true);
            await action(
              transaction,
            ); // The retry sees the other writer's document.
          });
      await LocumProfileStore(firestore).save(profile);
      expect(writes.first.containsKey('createdAt'), isTrue);
      expect(writes.last.containsKey('createdAt'), isFalse);
    },
  );
}
