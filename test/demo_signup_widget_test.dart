import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:optolocum/features/auth/CO_signup.dart';
import 'package:optolocum/services/demo_enrollment.dart';

void main() {
  testWidgets('demo owner signup uses enrollment once without client profile writes', (tester) async {
    expect(demoEnrollmentEnabled, isTrue);
    var calls = 0;
    var logins = 0;
    DemoEnrollment.instance = DemoEnrollment(
      post: (_, _, _) async { calls++; return http.Response('{"data":{"uid":"u","accountType":"practice_owner"}}', 200); },
      signIn: (_, _) async { logins++; return 'u'; },
      signOut: () async {}, wait: () async {},
    );
    await tester.pumpWidget(const MaterialApp(home: CompanyOwnerSignupPage()));
    final fields = find.byType(TextFormField);
    for (final (i, value) in ['Synthetic Owner', 'owner@example.invalid', '0123456789', 'synthetic-password'].indexed) {
      await tester.ensureVisible(fields.at(i));
      await tester.enterText(fields.at(i), value);
    }
    final dropdown = find.byType(DropdownButtonFormField<String>);
    await tester.ensureVisible(dropdown);
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Manager').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Sign Up'));
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(logins, 1);
    expect(find.text('Account created successfully. You can now log in.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    DemoEnrollment.instance = null;
  }, skip: !demoEnrollmentEnabled);
}
