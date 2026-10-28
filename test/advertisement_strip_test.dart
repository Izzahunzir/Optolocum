import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:optolocum/widgets/advertisement_strip.dart';

void main() {
  testWidgets('Ads open the selected image and close on background tap', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AdvertisementStrip()),
      ),
    );
    await tester.runAsync(() async {
      final context = tester.element(find.byType(AdvertisementStrip));
      for (var index = 1; index <= 3; index++) {
        await precacheImage(AssetImage('assets/images/ads $index.jpg'), context);
      }
    });
    await tester.pumpAndSettle();
    for (var index = 0; index < 3; index++) {
      final ad = find.bySemanticsLabel('Open advertisement ${index + 1}');
      await tester.ensureVisible(ad);
      await tester.tap(ad);
      await tester.pumpAndSettle();

      final preview = find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(Image),
      );
      expect(
        (tester.widget<Image>(preview).image as AssetImage).assetName,
        'assets/images/ads ${index + 1}.jpg',
      );
      await tester.tap(preview);
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);

      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });
}
