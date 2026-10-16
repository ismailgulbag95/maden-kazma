import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tasin_alti/app/game_controller.dart';
import 'package:tasin_alti/app/tasin_alti_app.dart';
import 'package:tasin_alti/crusher/localization.dart';
import 'package:tasin_alti/domain/models/game_state.dart';
import 'package:tasin_alti/domain/models/mr_mine_big_number.dart';
import 'package:tasin_alti/ui/game_screen.dart';
import 'package:tasin_alti/ui/widgets/building_dialog.dart';
import 'package:tasin_alti/ui/widgets/settings_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('language defaults to Turkish and survives save round trips', () {
    final state = GameState.newGame();
    expect(state.languageCode, 'tr');

    state.languageCode = 'en';
    final restored = GameState.fromJson(state.toJson());

    expect(restored.languageCode, 'en');
  });

  test('legacy debug save fields cannot restore debug privileges', () {
    final state = GameState.fromJson({
      'schema': 28,
      'coins': '0',
      'debugModeEnabled': true,
      'debugUnlimitedMoney': true,
    });

    expect(state.languageCode, 'tr');
    expect(state.canAfford(1), isFalse);
    expect(state.spendCoins(1), isFalse);
    expect(state.toJson().containsKey('debugModeEnabled'), isFalse);
    expect(state.toJson().containsKey('debugUnlimitedMoney'), isFalse);
  });

  test('a new game preserves the selected interface language', () {
    final controller = GameController();
    addTearDown(controller.dispose);

    controller.setLanguageCode('en');
    controller.startNewGame();

    expect(controller.state.languageCode, 'en');
  });

  testWidgets('app locale follows the saved language setting', (tester) async {
    final controller = GameController();

    await tester.pumpWidget(TasinAltiApp(controller: controller));
    await tester.pump();
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).locale,
      const Locale('tr'),
    );
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).title,
      'Taşın Altı',
    );

    controller.setLanguageCode('en');
    await tester.pump();
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).locale,
      const Locale('en'),
    );
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).title,
      'Beneath the Stone',
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('English screens use English thousands separators', (
    tester,
  ) async {
    final state = GameState.newGame(seed: 71)
      ..openingComicSeen = true
      ..languageCode = 'en'
      ..depthMeters = 5000
      ..deepestMeters = 5000
      ..coins = MrMineBigNumber.fromNum(1234567)
      ..musicEnabled = false
      ..soundEffectsEnabled = false;
    final controller = GameController()
      ..state = state
      ..isReady = true;
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: GameScreen(controller: controller),
      ),
    );

    expect(find.text('1,234,567'), findsOneWidget);
  });

  testWidgets('English challenge screen translates dynamic challenge text', (
    tester,
  ) async {
    expect(
      gameTextForLanguage(
        'en',
        '{challenge} İlerleme: {progress}/{target}. Ödül: {reward} kasa.',
        {
          'challenge': gameTextForLanguage('en', '25 cevher birimi çıkar.'),
          'progress': 0,
          'target': 25,
          'reward': 300,
        },
      ),
      'Mine 25 units of ore. Progress: 0/25. Reward: 300 coins.',
    );
    expect(
      gameTextForLanguage(
        'en',
        '25 cevher birimi çıkar. İlerleme: 0/25. Ödül: 300 kasa.',
      ),
      'Mine 25 units of ore. Progress: 0/25. Reward: 300 coins.',
    );

    final state = GameState.newGame(seed: 73)
      ..languageCode = 'en'
      ..dailyChallengeIds.add('ore_25')
      ..weeklyChallengeProgress = 12;
    final controller = GameController()..state = state;
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: Scaffold(
          body: BuildingDialog(controller: controller, buildingId: 'quests'),
        ),
      ),
    );

    expect(find.text('Shift Ore'), findsOneWidget);
    expect(find.textContaining('Mine 25 units of ore.'), findsOneWidget);
    expect(find.text('Weekly milestone'), findsOneWidget);
    expect(find.text('CLAIM REWARD'), findsOneWidget);
  });

  testWidgets('settings no longer expose the debug mode controls', (
    tester,
  ) async {
    final controller = GameController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(home: SettingsDialog(controller: controller)),
    );

    expect(find.byIcon(Icons.bug_report_rounded), findsNothing);
    expect(find.byIcon(Icons.language_rounded), findsOneWidget);
  });
}
