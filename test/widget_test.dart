import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:optolocum/main.dart';
import 'package:optolocum/features/intro/intro_page.dart';

void main() {
  for (final size in [
    const Size(390, 868),
    const Size(320, 568),
    const Size(1440, 900),
  ]) {
    testWidgets('Intro is the startup page at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MyApp());
      expect(find.text('Welcome to\nOptolocum'), findsOneWidget);
      expect(find.text('Locum'), findsOneWidget);
      expect(find.text('Clinic Owner'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Locum'));
      await tester.tap(find.text('Locum'));
      await tester.pump();
      expect(
        find.text('Locum selected. Registration is coming soon.'),
        findsOneWidget,
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await tester.ensureVisible(find.text('Clinic Owner'));
      await tester.tap(find.text('Clinic Owner'));
      await tester.pumpAndSettle();
      expect(find.text('Login as a'), findsOneWidget);
      expect(find.text('Sign up'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('Intro accommodates large accessibility text', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(2)),
          child: child!,
        ),
        home: const IntroPage(),
      ),
    );
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Clinic Owner'));
    await tester.tap(find.text('Clinic Owner'));
    await tester.pumpAndSettle();
    expect(find.text('COMPANY OWNER'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Clinic owner signup validates fields and selects a role', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.ensureVisible(find.text('Clinic Owner'));
    await tester.tap(find.text('Clinic Owner'));
    await tester.pumpAndSettle();
    expect(find.text('Login as a'), findsOneWidget);
    await tester.ensureVisible(find.text('Login'));
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
    await tester.ensureVisible(find.text('Sign up'));
    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Sign Up'));
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your full name'), findsOneWidget);
    expect(find.text('Select your role'), findsOneWidget);
    final fields = find.byType(TextFormField);
    for (final entry in [
      'Natalie Tan',
      'natalie@gmail.com',
      '0123456789',
      'password123',
    ].asMap().entries) {
      await tester.ensureVisible(fields.at(entry.key));
      await tester.enterText(fields.at(entry.key), entry.value);
    }
    final roleDropdown = find.byType(DropdownButtonFormField<String>);
    await tester.ensureVisible(roleDropdown);
    await tester.pumpAndSettle();
    await tester.tap(roleDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Optical Owner').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Sign Up'));
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();
    expect(
      find.text('Your details are ready. Account registration is coming soon.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Login as a'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to\nOptolocum'), findsOneWidget);
  });
}
