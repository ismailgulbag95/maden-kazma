import 'package:flutter_test/flutter_test.dart';
import 'package:tasin_alti/app/game_controller.dart';
import 'package:tasin_alti/data/save_store.dart';
import 'package:tasin_alti/domain/models/advisor_guide.dart';
import 'package:tasin_alti/domain/models/game_state.dart';
import 'package:tasin_alti/domain/models/quest_definition.dart';
import 'package:tasin_alti/domain/simulation/game_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ilk vardiya baştan sona öğretir ve her sistemi sırayla açar', () {
    final controller = GameController(saveStore: _MemorySaveStore());
    addTearDown(controller.dispose);
    final state = controller.state;
    state
      ..musicEnabled = false
      ..soundEffectsEnabled = false;

    expect(state.depthMeters, GameState.startingDepthMeters);
    expect(state.deepestMeters, GameState.startingDepthMeters);
    expect(state.coins.toDouble(), 0);
    expect(state.activeMinerCount, 0);
    expect(state.oreDeposits.values, hasLength(4));
    expect(
      state.oreDeposits.values.every(
        (deposit) => deposit.floorIndex == 5 && deposit.resourceId == 'coal',
      ),
      isTrue,
    );
    expect(controller.currentQuest.id, 0);
    expect(AdvisorGuideCatalog.currentFor(state)?.id, 'tutorial_mine');

    final firstVein = state.oreDeposits.values.first;
    expect(controller.mineDeposit(firstVein.id), isTrue);
    expect(controller.currentQuestReady, isTrue);
    expect(AdvisorGuideCatalog.currentFor(state)?.id, 'tutorial_mine');
    controller.claimCurrentQuest();
    expect(controller.currentQuest.id, 1);
    expect(AdvisorGuideCatalog.currentFor(state)?.id, 'tutorial_sell');

    var miningAttempts = 0;
    while (state.totalSold.toDouble() < 40 && miningAttempts < 100) {
      for (final deposit in state.oreDeposits.values.toList()) {
        while (!state.oreDeposits[deposit.id]!.depleted &&
            miningAttempts < 100) {
          expect(controller.mineDeposit(deposit.id), isTrue);
          miningAttempts++;
        }
      }
      controller.sellAll();
    }
    expect(state.totalSold.toDouble(), greaterThanOrEqualTo(40));
    expect(controller.currentQuestReady, isTrue);
    controller.claimCurrentQuest();

    expect(controller.currentQuest.id, 2);
    expect(QuestCatalog.all[2].target, 1);
    expect(GameEngine.minerCost(state), 50);
    expect(controller.hireMiner(), isTrue);
    expect(controller.currentQuestReady, isTrue);
    expect(state.activeMinerCount, 1);
    controller.claimCurrentQuest();
    expect(AdvisorGuideCatalog.currentFor(state)?.id, 'tutorial_upgrade');

    expect(GameEngine.upgradeCost(state, 'drill'), 150);
    expect(controller.upgrade('drill'), isTrue);
    expect(controller.currentQuestReady, isTrue);
    controller.claimCurrentQuest();
    expect(controller.currentQuest.id, 4);
    expect(AdvisorGuideCatalog.currentFor(state)?.id, 'tutorial_drill');

    for (
      var second = 0;
      state.deepestMeters - state.questDepthBaselineMeters < 80 && second < 30;
      second++
    ) {
      GameEngine.advance(
        state,
        const Duration(seconds: 1),
        allowRandomEvents: false,
      );
    }
    expect(state.deepestMeters, greaterThanOrEqualTo(5080));
    expect(state.tutorialStep, 5);
    expect(controller.currentQuestReady, isTrue);
    controller.claimCurrentQuest();
    expect(state.initialTutorialComplete, isTrue);
    expect(state.claimedQuestIds, containsAll([0, 1, 2, 3, 4]));

    expect(AdvisorGuideCatalog.currentFor(state)?.id, 'ongoing_quests');
    controller.acknowledgeAdvisorGuide('ongoing_quests');
    expect(state.canOpenBuilding('quests'), isTrue);
    expect(AdvisorGuideCatalog.currentFor(state)?.id, 'achievement_book');
    controller.acknowledgeAdvisorGuide('achievement_book');
    expect(state.canOpenBuilding('achievements'), isTrue);

    const progressionGuideIds = [
      'elevator',
      'first_depth_chest',
      'mine_events',
      'super_miners',
      'trader',
      'caves',
      'scientists',
      'chest_collector',
      'repair_robot',
      'underground_city',
      'gem_forge',
      'armory',
      'deep_core',
      'chest_compressor',
      'moon_world',
      'lunar_trader',
      'reactor',
      'buff_lab',
      'robot_mk2',
      'titan_world',
      'titan_trader',
      'robot_mk3',
    ];
    for (final id in progressionGuideIds) {
      final guide = AdvisorGuideCatalog.byId[id]!;
      state
        ..deepestMeters = guide.requiredDepthMeters.toDouble()
        ..depthMeters = guide.requiredDepthMeters.toDouble();
      expect(
        AdvisorGuideCatalog.currentFor(state)?.id,
        id,
        reason: 'Danışman $id sistemini sıradaki hedef olarak göstermeli.',
      );
      controller.acknowledgeAdvisorGuide(id);
      if (guide.unlockBuildingId != null) {
        expect(state.unlockedBuildings, contains(guide.unlockBuildingId));
      }
      if (guide.targetPanel != null) {
        expect(state.canOpenBuilding(guide.targetPanel!), isTrue);
      }
    }

    expect(AdvisorGuideCatalog.currentFor(state), isNull);
    final finalGuide = AdvisorGuideCatalog.byId['final_descent']!;
    state
      ..deepestMeters = finalGuide.requiredDepthMeters.toDouble()
      ..depthMeters = finalGuide.requiredDepthMeters.toDouble();
    expect(AdvisorGuideCatalog.currentFor(state)?.id, 'final_descent');
    controller.acknowledgeAdvisorGuide('final_descent');
    expect(AdvisorGuideCatalog.currentFor(state), isNull);
  });

  test('eski kayıtta madenci görev sayacı eski başlangıç sayısını korur', () {
    final state = GameState(crewCount: 2);
    final restored = GameState.fromJson(
      Map<String, Object?>.from(state.toJson())
        ..remove('questCrewBaselineCount'),
    );

    expect(restored.questCrewBaselineCount, 1);
    expect(restored.progressFor(QuestCatalog.all[2]), 1);
  });

  test('yeni vardiya ilk saniyede eski derinlik ödülünü ödemez', () {
    final controller = GameController(saveStore: _MemorySaveStore())
      ..state = GameState.newGame(seed: 54321);
    addTearDown(controller.dispose);

    controller.startNewGame();

    expect(controller.state.coins.toDouble(), 0);
    expect(controller.state.unlockedAchievements, contains('depth_1k'));
  });
}

class _MemorySaveStore implements SaveStore {
  String? _value;

  @override
  bool get recoveredBackup => false;

  @override
  Future<void> clear() async => _value = null;

  @override
  Future<String?> load() async => _value;

  @override
  Future<void> save(String value) async => _value = value;
}
