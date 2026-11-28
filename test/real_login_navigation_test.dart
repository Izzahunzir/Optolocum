import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:optolocum/features/auth/CO_signin.dart';
import 'package:optolocum/features/auth_locum/L_signin.dart';
import 'package:optolocum/services/real_backend_client.dart';
import 'package:optolocum/services/real_backend_workflows.dart';

class _Workflow extends Mock implements RealBackendWorkflows {}

void main() {
  for (final type in ['locum', 'practice_owner']) {
    for (final status in [0, 403, 503]) {
      testWidgets(
        '$type login ${status == 0 ? 'navigates' : 'rejects $status'}',
        (tester) async {
          final service = _Workflow();
          Future<void> call() => service.signIn(
            email: any(named: 'email'),
            password: any(named: 'password'),
            accountType: any(named: 'accountType'),
          );
          if (status == 0) {
            when(call).thenAnswer((_) async {});
          } else {
            when(call).thenThrow(
              BackendException(
                status == 403 ? 'Account access denied' : 'Backend unavailable',
                statusCode: status,
              ),
            );
          }
          Widget destination(BuildContext context) =>
              const Scaffold(body: Text('Protected destination'));
          await tester.pumpWidget(
            MaterialApp(
              home: type == 'locum'
                  ? LocumSigninPage(
                      workflows: service,
                      destination: destination,
                    )
                  : CompanyOwnerSigninPage(
                      workflows: service,
                      destination: destination,
                    ),
            ),
          );
          await tester.enterText(
            find.byType(TextFormField).at(0),
            'test@example.com',
          );
          await tester.enterText(
            find.byType(TextFormField).at(1),
            'password123',
          );
          await tester.ensureVisible(find.text('Login'));
          await tester.tap(find.text('Login'));
          await tester.pumpAndSettle();
          verify(
            () => service.signIn(
              email: 'test@example.com',
              password: 'password123',
              accountType: type,
            ),
          ).called(1);
          expect(
            find.text('Protected destination'),
            status == 0 ? findsOneWidget : findsNothing,
          );
          if (status != 0) {
            expect(
              find.text(
                status == 403 ? 'Account access denied' : 'Backend unavailable',
              ),
              findsOneWidget,
            );
          }
        },
      );
    }
  }
}
