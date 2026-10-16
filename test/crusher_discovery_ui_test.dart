import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/localized_test_app.dart';

import 'package:tasin_alti/app/game_controller.dart';
import 'package:tasin_alti/domain/models/game_state.dart';
import 'package:tasin_alti/ui/game_screen.dart';

void main() {
  testWidgets('8 km keşfi rehber dronunu kırıcı çiftine yönlendirir', (
    tester,
  ) async {
    const size = Size(390, 844);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    final state = GameState.newGame(seed: 872)
      ..openingComicSeen = true
      ..musicEnabled = false
      ..soundEffectsEnabled = false
      ..depthMeters = 7999
      ..deepestMeters = 7999
      ..crewCount = 2
      ..worldMinerCounts['0'] = 2;
    final controller = GameController()
      ..state = state
      ..isReady = true;
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('tr'),
        supportedLocales: testSupportedLocales,
        localizationsDelegates: testLocalizationDelegates,
        home: GameScreen(controller: controller),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.byKey(const ValueKey('crusher-discovery-callout')),
      findsNothing,
    );

    state
      ..depthMeters = 8000
      ..deepestMeters = 8000;
    controller.notifyListeners();
    await tester.pump(const Duration(milliseconds: 300));

    final leftStation = find.byKey(const ValueKey('crusher-station-7km-Sol'));
    final rightStation = find.byKey(const ValueKey('crusher-station-7km-Sağ'));
    final drone = find.byKey(const ValueKey('crusher-discovery-drone'));

    expect(leftStation, findsOneWidget);
    expect(rightStation, findsOneWidget);
    expect(
      find.byKey(const ValueKey('crusher-discovery-highlight-Sol')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('crusher-discovery-highlight-Sağ')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('crusher-discovery-callout')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('crusher-discovery-message')),
      findsOneWidget,
    );
    expect(find.text('YENİ KEŞİF!'), findsOneWidget);
    expect(find.text('Taş kırma istasyonu bulundu'), findsOneWidget);
    expect(drone, findsOneWidget);

    final droneRect = tester.getRect(drone);
    final leftStationRect = tester.getRect(leftStation);
    final rightStationRect = tester.getRect(rightStation);
    final messageRect = tester.getRect(
      find.byKey(const ValueKey('crusher-discovery-message')),
    );
    final calloutRect = tester.getRect(
      find.byKey(const ValueKey('crusher-discovery-callout')),
    );
    expect(droneRect.bottom, lessThanOrEqualTo(leftStationRect.top + 1));
    expect(droneRect.center.dx, closeTo(leftStationRect.center.dx, 1));
    expect(messageRect.left, closeTo(droneRect.right + 6, 1));
    expect(messageRect.top, closeTo(droneRect.top, 1));
    expect(messageRect.left, greaterThanOrEqualTo(0));
    expect(messageRect.right, lessThanOrEqualTo(size.width));
    expect(messageRect.top, greaterThanOrEqualTo(0));
    expect(messageRect.bottom, lessThanOrEqualTo(size.height));
    expect(messageRect.bottom, lessThanOrEqualTo(leftStationRect.top));
    expect(messageRect.bottom, lessThanOrEqualTo(rightStationRect.top));
    expect(calloutRect.top, greaterThanOrEqualTo(rightStationRect.top));
    expect(calloutRect.bottom, lessThanOrEqualTo(rightStationRect.bottom));
    expect(tester.takeException(), isNull);
  });
}
