import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:optolocum/features/clinic_owner/CO_verification_form.dart';

void main() {
  testWidgets(
    'Verification validates and supports practice and state selection',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaterialApp(home: COVerificationForm()));
      await tester.ensureVisible(find.text('Verify Account'));
      await tester.tap(find.text('Verify Account'));
      await tester.pumpAndSettle();
      expect(find.text('Select type of practice'), findsOneWidget);
      expect(find.text('Select state'), findsOneWidget);
      final practice = find.byKey(const Key('practice-type'));
      await tester.ensureVisible(practice);
      await tester.pumpAndSettle();
      await tester.tap(practice);
      await tester.pumpAndSettle();
      for (final option in COVerificationForm.practiceTypes) {
        expect(find.text(option).last, findsOneWidget);
      }
      await tester.tap(find.text('University/Training Institution').last);
      await tester.pumpAndSettle();
      final state = find.byKey(const Key('malaysian-state'));
      await tester.ensureVisible(state);
      await tester.pumpAndSettle();
      await tester.tap(state);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Johor').last);
      await tester.pumpAndSettle();
      expect(COVerificationForm.states.length, 13);
      expect(
        tester.widget<DropdownButtonFormField<String>>(state).initialValue,
        isNull,
      );
      final fields = find.byType(TextFormField);
      final values = [
        'Vision Clinic',
        '202401012345',
        '22 Jalan Merdeka',
        '0123456789',
        'clinic@example.com',
      ];
      for (var index = 0; index < values.length; index++) {
        await tester.ensureVisible(fields.at(index));
        await tester.enterText(fields.at(index), values[index]);
      }
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Verify Account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Verify Account'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Your details are ready. Verification submission is coming soon.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
