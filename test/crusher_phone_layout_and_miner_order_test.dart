import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/localized_test_app.dart';

import 'package:tasin_alti/app/game_controller.dart';
import 'package:tasin_alti/crusher/crusher_view.dart';
import 'package:tasin_alti/domain/models/game_state.dart';
import 'package:tasin_alti/ui/game_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ambar dolu bildirimi ve satış aksiyonu telefona sığar', (
    tester,
  ) async {
    const size = Size(390, 844);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    final state = GameState.newGame(seed: 81);
    state.cargoUsed = state.effectiveCargoCapacity;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('tr'),
        supportedLocales: testSupportedLocales,
        localizationsDelegates: testLocalizationDelegates,
        home: Scaffold(
          body: CrusherCargoStatusBar(state: state, onSell: () {}),
        ),
      ),
    );

    expect(find.text('AMBAR DOLU (KIRICI DURDURULDU):'), findsOneWidget);
    expect(
      find.text(
        '${state.cargoUsed.toInt()} / ${state.effectiveCargoCapacity.toInt()} kg',
      ),
      findsOneWidget,
    );
    expect(find.text('TÜMÜNÜ SAT & ÇALIŞTIR'), findsOneWidget);

    final statusBar = tester.getRect(
      find.byKey(const ValueKey('crusher-cargo-status-bar')),
    );
    final sellAction = tester.getRect(
      find.byKey(const ValueKey('crusher-cargo-sell-action')),
    );
    expect(statusBar.left, greaterThanOrEqualTo(0));
    expect(statusBar.right, lessThanOrEqualTo(size.width));
    expect(sellAction.left, greaterThanOrEqualTo(0));
    expect(sellAction.right, lessThanOrEqualTo(size.width));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('işe alınan altı madenci sağ-sol sırasıyla içeri dizilir', (
    tester,
  ) async {
    const size = Size(390, 844);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    final state = GameState.newGame(seed: 82)
      ..openingComicSeen = true
      ..crewCount = 6
      ..worldMinerCounts['0'] = 6;
    final controller = _readyController(state);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('tr'),
        supportedLocales: testSupportedLocales,
        localizationsDelegates: testLocalizationDelegates,
        home: GameScreen(controller: controller),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));

    final floor = find.byKey(const ValueKey('mine-floor-0-4'));
    expect(floor, findsOneWidget);
    final floorRect = tester.getRect(floor);
    final shaftCenterX = floorRect.center.dx;
    final workerRects = [
      for (var hire = 0; hire < 6; hire++)
        tester.getRect(find.byKey(ValueKey('mine-worker-4-0-$hire'))),
    ];

    for (var hire = 0; hire < workerRects.length; hire++) {
      final onRight = workerRects[hire].center.dx > shaftCenterX;
      expect(
        onRight,
        hire.isEven,
        reason: 'madenci ${hire + 1} ${hire.isEven ? 'sağda' : 'solda'} olmalı',
      );
    }
    for (var hire = 2; hire < workerRects.length; hire++) {
      final sameSidePrevious = workerRects[hire - 2];
      expect(
        (workerRects[hire].center.dx - shaftCenterX).abs(),
        lessThan((sameSidePrevious.center.dx - shaftCenterX).abs()),
        reason: 'her yeni madenci kendi tarafında bir sıra içeri yerleşmeli',
      );
    }
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}

GameController _readyController(GameState state) {
  final controller = GameController()..state = state;
  controller.state
    ..musicEnabled = false
    ..soundEffectsEnabled = false;
  controller.isReady = true;
  return controller;
}
