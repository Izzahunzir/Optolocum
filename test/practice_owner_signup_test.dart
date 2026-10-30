import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:optolocum/features/auth/CO_signup.dart';

void main() {
  testWidgets('Owner signup retains required fields and each supported role', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: CompanyOwnerSignupPage()));
    await tester.ensureVisible(find.text('Sign Up'));
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your full name'), findsOneWidget);
    expect(find.text('Enter a valid phone number'), findsOneWidget);
    expect(find.text('Select your role'), findsOneWidget);

    final fields = find.byType(TextFormField);
    final values = [
      'Test Owner',
      'owner@example.com',
      '+60123456789',
      'testpass123',
    ];
    for (var index = 0; index < values.length; index++) {
      await tester.ensureVisible(fields.at(index));
      await tester.enterText(fields.at(index), values[index]);
    }
    for (final role in ['HR', 'Manager', 'Optical Owner']) {
      final dropdown = find.byType(DropdownButtonFormField<String>);
      await tester.ensureVisible(dropdown);
      await tester.pumpAndSettle();
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text(role).last);
      await tester.pumpAndSettle();
      final state = tester.state<FormFieldState<String>>(dropdown);
      expect(state.value, role);
      // Validate without submitting to live Firebase.
      expect(tester.state<FormState>(find.byType(Form)).validate(), isTrue);
      await tester.pump();
      for (var index = 0; index < values.length; index++) {
        expect(
          tester.widget<TextFormField>(fields.at(index)).controller!.text,
          values[index],
        );
      }
    }
    expect(tester.takeException(), isNull);
  });
}
