import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/localized_test_app.dart';

import 'package:tasin_alti/app/game_controller.dart';
import 'package:tasin_alti/domain/models/game_state.dart';
import 'package:tasin_alti/ui/game_screen.dart';
import 'package:tasin_alti/ui/widgets/loading_screen.dart';

void main() {
  testWidgets(
    'Oyun başlangıcında yüklenme animasyonu gösterilir ve yüklendikten 6 sn sonra oyuna geçer',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);

      final state = GameState.newGame()
        ..openingComicSeen = true
        ..musicEnabled = false
        ..soundEffectsEnabled = false;

      final controller = GameController()..state = state;
      // Initially, controller is NOT ready
      controller.isReady = false;
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('tr'),
          supportedLocales: testSupportedLocales,
          localizationsDelegates: testLocalizationDelegates,
          home: GameScreen(
            controller: controller,
            showLoadingScreen: true,
            postLoadDelay: const Duration(seconds: 6),
          ),
        ),
      );

      // Verify that MineLoadingScreen is displayed
      expect(find.byType(MineLoadingScreen), findsOneWidget);
      expect(find.text('MADEN HAZIRLANIYOR'), findsOneWidget);
      expect(find.text('YÜKLENİYOR...'), findsOneWidget);

      // Now the game finishes loading
      controller.isReady = true;
      controller.notifyListeners();
      await tester.pump();

      // After 3.0 seconds (halfway through the 6 seconds), still in loading screen
      await tester.pump(const Duration(milliseconds: 3000));
      expect(find.byType(MineLoadingScreen), findsOneWidget);
      expect(find.text('MADEN HAZIRLANIYOR'), findsOneWidget);

      // After 3.2 more seconds (total 6.2s > 6.0s), the loading finishes
      await tester.pump(const Duration(milliseconds: 3200));
      await tester.pump(const Duration(milliseconds: 100));

      // Now the game screen is displayed and loading screen is gone
      expect(find.byType(MineLoadingScreen), findsNothing);
      expect(find.byKey(const ValueKey('mine-game-screen')), findsOneWidget);
    },
  );

  testWidgets(
    'Hazır başlatılan kontrolcüde (test modu) yükleme animasyonu hemen oyuna geçer',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);

      final state = GameState.newGame()
        ..openingComicSeen = true
        ..musicEnabled = false
        ..soundEffectsEnabled = false;

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

      await tester.pump(const Duration(milliseconds: 100));

      // Should bypass loading screen and show the game immediately
      expect(find.byType(MineLoadingScreen), findsNothing);
      expect(find.byKey(const ValueKey('mine-game-screen')), findsOneWidget);
    },
  );
}
