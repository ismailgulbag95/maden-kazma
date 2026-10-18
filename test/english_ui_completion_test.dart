import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tasin_alti/app/game_controller.dart';
import 'package:tasin_alti/crusher/localization.dart';
import 'package:tasin_alti/domain/models/game_state.dart';
import 'package:tasin_alti/ui/game_screen.dart';
import 'package:tasin_alti/ui/widgets/building_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('English tutorial sales goal translates its dynamic values', () {
    expect(
      gameTextForLanguage(
        'en',
        'Satış hedefi: 40 kasa • toplam satış: {sold}.',
        {'sold': '40'},
      ),
      'Sales target: 40 coins • total sales: 40.',
    );
  });

  test('English drill and miner investment templates translate cleanly', () {
    expect(
      gameTextForLanguage(
        'en',
        'Matkap {level}. kademe: {cost} kasa{materials}',
        {'level': 2, 'cost': '100', 'materials': ''},
      ),
      'Drill Tier 2: 100 coins',
    );
    expect(
      gameTextForLanguage('en', 'Sonraki madenci: {cost} kasa', {'cost': '50'}),
      'Next miner: 50 coins',
    );
    expect(
      gameTextForLanguage('en', '{drill} • {hire}', {
        'drill': 'Drill max',
        'hire': 'Next miner: 50 coins',
      }),
      'Drill max • Next miner: 50 coins',
    );
    expect(
      gameTextForLanguage('en', 'Danışman robotun görevini tamamlayınca bu sistem açılacak.'),
      'This system unlocks after completing the advisor drone\'s mission.',
    );
    expect(
      gameTextForLanguage('en', 'Bu sistem henüz açılmadı.'),
      'This system is not unlocked yet.',
    );
  });

  test('English boss names and guardian encounter templates translate cleanly', () {
    expect(gameTextForLanguage('en', 'Bazalt Yüreği'), 'Heart of Basalt');
    expect(gameTextForLanguage('en', 'Halkalı Arşivci'), 'Ringed Archivist');
    expect(gameTextForLanguage('en', '✓ Bazalt Yüreği'), '✓ Heart of Basalt');
    expect(
      gameTextForLanguage('en', '{speed} m/sn', {'speed': '10'}),
      '10 m/s',
    );
    expect(
      gameTextForLanguage('en', '+{reward} kasa', {'reward': '500'}),
      '+500 coins',
    );
  });

  testWidgets('English mine screen localizes the HUD and navigation', (
    tester,
  ) async {
    final state = GameState.newGame(seed: 812)
      ..openingComicSeen = true
      ..languageCode = 'en'
      ..depthMeters = 6000
      ..deepestMeters = 6000
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
    await tester.pump();

    expect(find.text('CARGO'), findsOneWidget);
    expect(find.text('Earth • Surface Outpost'), findsOneWidget);
    expect(find.text('TRADING'), findsWidgets);
    expect(find.text('WORKSHOP'), findsWidgets);
    expect(find.text('RESEARCH'), findsWidgets);
    expect(find.text('WAREHOUSE'), findsWidgets);
    expect(find.text('GOALS'), findsWidgets);
    expect(find.text('EXPEDITION'), findsWidgets);
    expect(find.text('BADGES'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('English workshop assembly cards do not fall back to Turkish', (
    tester,
  ) async {
    final state = GameState.newGame(seed: 813)
      ..languageCode = 'en'
      ..musicEnabled = false
      ..soundEffectsEnabled = false;
    final controller = GameController()..state = state;
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        home: Scaffold(
          body: BuildingDialog(controller: controller, buildingId: 'workshop'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('WORKSHOP'), findsOneWidget);
    expect(find.text('CLOSE'), findsOneWidget);
    expect(find.text('Known assembly blueprints'), findsOneWidget);
    expect(find.text('Total assembly power'), findsOneWidget);
    expect(find.textContaining('calculated based on depth'), findsOneWidget);
    expect(find.text('Assembly: Drill Bit • Lv 1/43'), findsOneWidget);
    expect(find.text('Assembly: Cooling Fan • Lv 1/43'), findsOneWidget);
    expect(find.text('Assembly: Drill Engine • Lv 1/43'), findsOneWidget);
    expect(find.textContaining('Next level: Lv 2'), findsNWidgets(3));
    expect(find.textContaining('No depth requirement'), findsNWidgets(3));
    expect(find.textContaining('Requires at least 1 miner'), findsNWidgets(3));
    expect(find.textContaining('No ore required'), findsNWidgets(3));
    expect(
      find.textContaining('Blueprint: Drill Bit • Lv 2 • archived'),
      findsOneWidget,
    );
    expect(find.textContaining('Montaj:'), findsNothing);
    expect(find.textContaining('Sonraki seviye'), findsNothing);
    expect(find.textContaining('Maden gerekmez'), findsNothing);
    expect(find.text('KAPAT'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
