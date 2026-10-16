import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tasin_alti/ui/widgets/opening_comic.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final size in const [Size(390, 844), Size(320, 568)]) {
    testWidgets('opening comic content stays inside ${size.width}px phone', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(home: OpeningComicOverlay(onFinish: () {})),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      for (final type in [
        find.byType(Text),
        find.byType(TextButton),
        find.byType(FilledButton),
        find.byType(OutlinedButton),
      ]) {
        final count = type.evaluate().length;
        for (var index = 0; index < count; index++) {
          final rect = tester.getRect(type.at(index));
          expect(
            rect.left,
            greaterThanOrEqualTo(0),
            reason: 'content begins outside the left edge: $rect at $size',
          );
          expect(
            rect.right,
            lessThanOrEqualTo(size.width),
            reason: 'content extends outside the right edge: $rect at $size',
          );
        }
      }
    });
  }
}
