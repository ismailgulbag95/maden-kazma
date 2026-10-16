import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/localized_test_app.dart';

import 'package:tasin_alti/app/game_controller.dart';
import 'package:tasin_alti/crusher/crusher_engine.dart';
import 'package:tasin_alti/crusher/crusher_scene.dart';
import 'package:tasin_alti/data/save_store.dart';
import 'package:tasin_alti/domain/models/game_state.dart';
import 'package:tasin_alti/services/sound_service.dart';
import 'package:tasin_alti/ui/game_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'main audio button mutes and unmutes music and effects together',
    (tester) async {
      final state = GameState.newGame(seed: 14)
        ..openingComicSeen = true
        ..musicEnabled = true
        ..soundEffectsEnabled = false;
      final controller = GameController(saveStore: _MemorySaveStore())
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

      expect(controller.allAudioEnabled, isTrue);
      await tester.tap(find.byTooltip('Tüm sesleri kapat'));
      await tester.pump();
      expect(controller.state.musicEnabled, isFalse);
      expect(controller.state.soundEffectsEnabled, isFalse);
      expect(find.byTooltip('Tüm sesleri aç'), findsOneWidget);

      await tester.tap(find.byTooltip('Tüm sesleri aç'));
      await tester.pump();
      expect(controller.state.musicEnabled, isTrue);
      expect(controller.state.soundEffectsEnabled, isTrue);
      expect(find.byTooltip('Tüm sesleri kapat'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('crusher hides the repetitive raw-ore added popup only', (
    tester,
  ) async {
    final controller = GameController(saveStore: _MemorySaveStore());
    final game = CrusherGame(controller);
    addTearDown(game.dispose);
    addTearDown(controller.dispose);

    game
      ..messageKey = 'crushed'
      ..messageAmount = 1
      ..messageLife = 1;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('tr'),
        supportedLocales: testSupportedLocales,
        localizationsDelegates: testLocalizationDelegates,
        home: Scaffold(
          body: AnimatedBuilder(
            animation: game,
            builder: (context, _) => Center(child: CrusherPopup(game: game)),
          ),
        ),
      ),
    );
    expect(find.textContaining('Ambara Eklendi'), findsNothing);

    game.messageKey = 'cargoFull';
    game.messageId++;
    game.notifyListeners();
    await tester.pump();
    expect(find.text('AMBAR DOLU! KIRICI DURDU'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('muted button wrapper still runs the control action silently', () {
    final audio = SoundService.instance;
    final wasEnabled = audio.sfxEnabled;
    audio.sfxEnabled = false;
    var actionCalls = 0;

    withButtonTapSound(() {
      actionCalls++;
    })!();

    expect(actionCalls, 1);
    expect(audio.sfxEnabled, isFalse);
    audio.sfxEnabled = wasEnabled;
  });
}

class _MemorySaveStore implements SaveStore {
  String? value;

  @override
  bool get recoveredBackup => false;

  @override
  Future<String?> load() async => value;

  @override
  Future<void> save(String value) async {
    this.value = value;
  }

  @override
  Future<void> clear() async {
    value = null;
  }
}
