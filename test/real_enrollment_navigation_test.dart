import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:optolocum/features/auth/CO_signup.dart';
import 'package:optolocum/features/auth_locum/L_signup.dart';
import 'package:optolocum/services/real_backend_client.dart';
import 'package:optolocum/services/real_backend_workflows.dart';

class _Workflow extends Mock implements RealBackendWorkflows {}

void main() {
  for (final type in ['locum', 'practice_owner']) {
    for (final failFirst in [false, true]) {
      testWidgets(
        '$type enrollment ${failFirst ? 'failure remains and retry navigates' : 'navigates after success'}',
        (tester) async {
          final workflow = _Workflow();
          var attempts = 0;
          when(
            () => workflow.enroll(
              email: any(named: 'email'),
              password: any(named: 'password'),
              accountType: any(named: 'accountType'),
              profile: any(named: 'profile'),
            ),
          ).thenAnswer((_) async {
            attempts++;
            if (failFirst && attempts == 1) {
              throw const BackendException(
                'Validation unavailable',
                statusCode: 503,
              );
            }
          });
          Widget destination(BuildContext context) =>
              const Scaffold(body: Text('Enrollment destination'));
          await tester.pumpWidget(
            MaterialApp(
              home: type == 'locum'
                  ? LocumSignupPage(
                      workflows: workflow,
                      destination: destination,
                    )
                  : CompanyOwnerSignupPage(
                      workflows: workflow,
                      destination: destination,
                    ),
            ),
          );
          final fields = find.byType(TextFormField);
          final values = type == 'locum'
              ? ['Test User', '0123456789', 'test@example.com', 'password123']
              : ['Test User', 'test@example.com', '0123456789', 'password123'];
          for (var i = 0; i < values.length; i++) {
            await tester.ensureVisible(fields.at(i));
            await tester.enterText(fields.at(i), values[i]);
          }
          if (type == 'locum') {
            await tester.ensureVisible(find.byType(Checkbox));
            await tester.tap(find.byType(Checkbox));
          } else {
            final dropdown = find.byType(DropdownButtonFormField<String>);
            await tester.ensureVisible(dropdown);
            await tester.tap(dropdown);
            await tester.pumpAndSettle();
            await tester.tap(find.text('Manager').last);
            await tester.pumpAndSettle();
          }
          await tester.ensureVisible(find.text('Sign Up'));
          await tester.tap(find.text('Sign Up'));
          await tester.pumpAndSettle();
          if (failFirst) {
            expect(find.text('Enrollment destination'), findsNothing);
            expect(find.text('Validation unavailable'), findsOneWidget);
            await tester.ensureVisible(find.text('Sign Up'));
            await tester.tap(find.text('Sign Up'));
            await tester.pumpAndSettle();
          }
          expect(find.text('Enrollment destination'), findsOneWidget);
          expect(attempts, failFirst ? 2 : 1);
          verify(
            () => workflow.enroll(
              email: 'test@example.com',
              password: 'password123',
              accountType: type,
              profile: any(named: 'profile'),
            ),
          ).called(failFirst ? 2 : 1);
        },
      );
    }
  }
}
