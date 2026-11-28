import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:optolocum/features/locum/L_profile.dart';
import 'package:optolocum/features/locum/L_profile_data.dart';
import 'package:optolocum/features/locum/L_verification_form.dart';
import 'package:optolocum/features/clinic_owner/CO_profile.dart';
import 'package:optolocum/services/locum_profile_service.dart';

class _Profiles extends Mock implements LocumProfileService {}

void main() {
  setUpAll(
    () => registerFallbackValue(
      LocumProfileData(fields: const {}, documents: const []),
    ),
  );
  tearDown(() {
    locumProfileData.value = null;
  });
  testWidgets('approved locum profile remains viewable and read-only', (
    tester,
  ) async {
    final profiles = _Profiles();
    final profile = LocumProfileData(
      uid: 'user',
      fields: {'Full Name': 'Sarah'},
      documents: const [],
      verificationStatus: 'approved',
    );
    when(() => profiles.currentUid).thenReturn('user');
    when(() => profiles.authStateChanges).thenAnswer((_) => Stream.value(null));
    when(() => profiles.load('user')).thenAnswer((_) async {
      locumProfileData.value = profile;
      return profile;
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LProfile(
            onLogout: () {},
            onContactUs: () {},
            onSavedJobs: () {},
            profileService: profiles,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sarah'), findsOneWidget);
    await tester.tap(find.text('Account Verification'));
    await tester.pumpAndSettle();
    expect(find.text('Approved'), findsOneWidget);
    expect(find.text('Full Name: Sarah'), findsOneWidget);
    expect(find.byType(LVerificationForm), findsNothing);
    expect(find.byType(TextField), findsNothing);
    verifyNever(() => profiles.save(any()));
  });
  testWidgets('owner profile shows details without edit controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: COProfile(name: 'Owner', role: 'Manager', clinicName: 'Clinic'),
      ),
    );
    expect(find.text('Owner'), findsOneWidget);
    expect(find.text('Manager'), findsOneWidget);
    expect(find.text('Clinic'), findsOneWidget);
    expect(find.text('Edit'), findsNothing);
    expect(find.byIcon(Icons.edit), findsNothing);
    expect(find.byType(TextField), findsNothing);
  });
}
