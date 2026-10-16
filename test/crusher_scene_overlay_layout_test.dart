import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tasin_alti/app/game_controller.dart';
import 'package:tasin_alti/crusher/crusher_engine.dart';
import 'package:tasin_alti/crusher/crusher_scene.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpCrusher(
    WidgetTester tester, {
    required double width,
    required double height,
    required String language,
    String oreId = 'coal',
  }) async {
    final controller = GameController();
    controller.state.languageCode = language;
    controller.state.rawOreInventory
      ..clear()
      ..[oreId] = 4;
    final game = CrusherGame(controller);
    addTearDown(controller.dispose);
    addTearDown(game.dispose);
    expect(game.mostValuableRawOre?.id, oreId);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: width,
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: Color(0xff111923)),
                CrusherSceneHud(game: game),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('Turkish overlays fit together in the bottom-left on a phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 240);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpCrusher(
      tester,
      width: 320,
      height: 240,
      language: 'tr',
      oreId: 'black_opal',
    );

    expect(find.text('EN DEĞERLİ CEVHER: SİYAH OPAL'), findsOneWidget);
    expect(find.text('TAŞA DOKUN VE EZ'), findsOneWidget);
    expect(find.text('Kırıcı: 36 dev/dk'), findsOneWidget);
    expect(find.text('OTOMATİK HAT'), findsNothing);
    expect(tester.takeException(), isNull);

    final labelTopLeft = tester.getTopLeft(
      find.text('EN DEĞERLİ CEVHER: SİYAH OPAL'),
    );
    final hintRect = tester.getRect(find.text('TAŞA DOKUN VE EZ'));
    final rpmRect = tester.getRect(find.text('Kırıcı: 36 dev/dk'));
    expect(labelTopLeft.dx, lessThan(50));
    expect(labelTopLeft.dy, lessThan(32));
    expect(hintRect.left, lessThan(40));
    expect(hintRect.bottom, closeTo(rpmRect.bottom, 1));
    expect(hintRect.overlaps(rpmRect), isFalse);
  });

  testWidgets('English overlays fit together on a phone', (tester) async {
    tester.view.physicalSize = const Size(320, 240);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpCrusher(
      tester,
      width: 320,
      height: 240,
      language: 'en',
      oreId: 'red_diamond',
    );

    expect(find.text('MOST VALUABLE ORE: RED DIAMOND'), findsOneWidget);
    expect(find.text('TAP A ROCK TO CRUSH'), findsOneWidget);
    expect(find.text('Crusher: 36 rpm'), findsOneWidget);
    expect(find.text('AUTO LINE'), findsNothing);
    expect(tester.takeException(), isNull);

    final labelRect = tester.getRect(
      find.text('MOST VALUABLE ORE: RED DIAMOND'),
    );
    final hintRect = tester.getRect(find.text('TAP A ROCK TO CRUSH'));
    final rpmRect = tester.getRect(find.text('Crusher: 36 rpm'));
    expect(labelRect.left, greaterThanOrEqualTo(0));
    expect(labelRect.top, greaterThanOrEqualTo(0));
    expect(labelRect.right, lessThanOrEqualTo(320));
    expect(labelRect.bottom, lessThan(50));
    expect(hintRect.left, lessThan(40));
    expect(hintRect.bottom, closeTo(rpmRect.bottom, 1));
    expect(hintRect.overlaps(rpmRect), isFalse);
  });

  testWidgets('English overlays fit on a wide layout', (tester) async {
    tester.view.physicalSize = const Size(900, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpCrusher(
      tester,
      width: 900,
      height: 500,
      language: 'en',
      oreId: 'titan_cobalt',
    );

    expect(find.text('MOST VALUABLE ORE: TITAN COBALT'), findsOneWidget);
    expect(find.text('TAP A ROCK TO CRUSH'), findsOneWidget);
    expect(find.text('Crusher: 36 rpm'), findsOneWidget);
    expect(find.text('AUTO LINE'), findsNothing);
    expect(tester.takeException(), isNull);

    final hintRect = tester.getRect(find.text('TAP A ROCK TO CRUSH'));
    final rpmRect = tester.getRect(find.text('Crusher: 36 rpm'));
    expect(hintRect.bottom, closeTo(rpmRect.bottom, 1));
    expect(hintRect.overlaps(rpmRect), isFalse);
  });
}
