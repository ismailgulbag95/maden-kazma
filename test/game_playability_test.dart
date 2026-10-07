import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tasin_alti/app/game_controller.dart';
import 'package:tasin_alti/data/save_store.dart';
import 'package:tasin_alti/domain/models/game_state.dart';
import 'package:tasin_alti/domain/models/mr_mine_big_number.dart';
import 'package:tasin_alti/domain/models/daily_challenge_definition.dart';
import 'package:tasin_alti/domain/models/cave_exploration_definition.dart';
import 'package:tasin_alti/domain/models/gem_definition.dart';
import 'package:tasin_alti/domain/models/quest_definition.dart';
import 'package:tasin_alti/domain/models/resource_definition.dart';
import 'package:tasin_alti/domain/models/scientist_definition.dart';
import 'package:tasin_alti/domain/models/special_worker_definition.dart';
import 'package:tasin_alti/domain/models/upgrade_definition.dart';
import 'package:tasin_alti/domain/models/ore_deposit.dart';
import 'package:tasin_alti/domain/simulation/game_engine.dart';
import 'package:tasin_alti/ui/game_screen.dart';
import 'package:tasin_alti/ui/widgets/atlas_sprite.dart';
import 'package:tasin_alti/ui/widgets/building_dialog.dart';

void main() {
  group('oynanış güvenliği', () {
    test('elmas beşinci tarif ve boss bonusu olarak çalışır', () {
      expect(GemCatalog.all, hasLength(5));
      expect(GemCatalog.byId['diamond']?.recipe, {
        'star_crystal': 4,
        'platinum': 8,
      });

      final state = GameState()..gems['diamond'] = 1;
      final baseDamage = GameEngine.bossAttackDamage(state);
      expect(GameEngine.toggleGemEquipment(state, 'diamond'), isTrue);
      expect(
        GameEngine.bossAttackDamage(state) / baseDamage,
        closeTo(1.12, 0.001),
      );
      expect(GameState.fromJson(state.toJson()).equippedGems, {'diamond'});
    });

    test(
      'kalıntı kopyası hurdalanır ve yükseltilmiş pasif etkisi kaydolur',
      () {
        final state = GameState(coins: 0, relicScrap: 10);
        GameEngine.recordRelicFound(state, 'relic_1');
        GameEngine.recordRelicFound(state, 'relic_1');

        expect(state.relicDuplicates['relic_1'], 1);
        expect(GameEngine.dismantleRelicDuplicate(state, 'relic_1'), isTrue);
        expect(state.relicScrap, 11);
        expect(GameEngine.upgradeRelic(state, 'relic_1'), isTrue);
        expect(state.relicLevel('relic_1'), 2);
        state.equippedRelics.add('relic_1');
        final upgradedRate = state.drillRateMetersPerSecond;
        final restored = GameState.fromJson(state.toJson());
        expect(restored.relicLevels['relic_1'], 2);
        expect(restored.relicScrap, 8);
        expect(restored.unlockedRelics, {'relic_1'});
        restored.equippedRelics.add('relic_1');
        expect(restored.drillRateMetersPerSecond, upgradedRate);
      },
    );

    test(
      'bilim insanının yinelenen yaralanması ölümcül, nadir mühür canlandırır',
      () {
        final now = DateTime.utc(2030, 6, 1);
        final scientist = ScientistState(
          id: 'scientist_qa',
          name: 'Ada',
          rarityId: 'common',
          traitId: 'careful',
        );
        final state = GameState(
          coins: 100000,
          depthMeters: 1782000,
          deepestMeters: 1782000,
          scientists: 1,
          revivalTokens: 1,
          scientistRoster: [scientist],
        );
        final mission = ScientistExpeditionCatalog.byId['survey']!;

        expect(
          GameEngine.scientistMissionSuccessChance(scientist, mission),
          closeTo(.97, .001),
        );
        expect(
          GameEngine.startScientistExpedition(
            state,
            scientist.id,
            mission.id,
            now,
          ),
          isTrue,
        );
        expect(state.scientistExpeditionReadyAt, now.add(mission.duration));

        state
          ..scientistExpeditionOutcome = 'injury'
          ..scientistExpeditionReadyAt = now.subtract(
            const Duration(seconds: 1),
          );
        final saved = GameState.fromJson(state.toJson());
        expect(saved.scientistExpeditionOutcome, 'injury');
        expect(GameEngine.claimScientistExpedition(saved, now), isTrue);
        final injured = saved.scientistById(scientist.id)!;
        expect(injured.injuryCount, 1);
        expect(injured.dead, isFalse);
        expect(injured.injuredUntil, now.add(const Duration(minutes: 10)));
        expect(saved.scientists, 1);

        injured.injuredUntil = DateTime.now().subtract(
          const Duration(seconds: 1),
        );
        saved
          ..activeScientistId = scientist.id
          ..activeScientistMissionId = mission.id
          ..scientistExpeditionOutcome = 'injury'
          ..scientistExpeditionReadyAt = now.subtract(
            const Duration(seconds: 1),
          );
        expect(GameEngine.claimScientistExpedition(saved, now), isTrue);
        expect(injured.injuryCount, 2);
        expect(injured.dead, isTrue);
        expect(saved.scientists, 0);

        expect(GameEngine.reviveScientist(saved, scientist.id), isTrue);
        expect(saved.revivalTokens, 0);
        expect(injured.dead, isFalse);
        expect(injured.injuryCount, 0);
        expect(saved.scientists, 1);
      },
    );

    test('derin sandıklar nadir canlandırma mührü verebilir', () {
      var foundRevivalSeal = false;
      for (var seed = 0; seed < 100 && !foundRevivalSeal; seed++) {
        final state = GameState(
          coins: 0,
          depthMeters: 1782000,
          deepestMeters: 1782000,
          deepChests: 1,
          cargoCapacity: 1000,
        )..seed = seed;
        GameEngine.openChestTier(state, 'deep');
        foundRevivalSeal = state.revivalTokens > 0;
      }
      expect(foundRevivalSeal, isTrue);
    });

    test('özel madenci hurdayla gelişir ve otomatik satışta rezervi korur', () {
      final worker = SpecialWorkerState(
        id: 'worker_auto_seller',
        name: 'Lodos',
        rarityId: 'common',
        abilityId: 'auto_seller',
        assignedWorld: 0,
        assignedFloor: 0,
        selectedResourceId: 'coal',
      );
      final state = GameState(
        crewCount: 0,
        coins: 0,
        depthMeters: 0,
        deepestMeters: 0,
        cargoCapacity: 24,
        cargoUsed: 24,
        inventory: {'coal': 24, 'copper': 0},
        reserves: {'coal': 3},
        workerScrap: 3,
        specialWorkerRoster: [worker],
      );

      expect(GameEngine.upgradeSpecialWorker(state, worker.id), isTrue);
      expect(worker.level, 2);
      expect(GameEngine.moveSpecialWorker(state, worker.id, 0, 0), isTrue);
      expect(worker.autoMove, isFalse);
      expect(GameEngine.advance(state, const Duration(seconds: 1)).mined, 0);
      expect(state.amount('coal'), 4);
      expect(state.reserve('coal'), 3);
      expect(state.coins, MrMineBigNumber(20));
      expect(state.workerScrap, 0);

      final restored = GameState.fromJson(state.toJson());
      expect(restored.specialWorkerRoster.single.level, 2);
      expect(restored.specialWorkerRoster.single.autoMove, isFalse);
    });

    test('özel madenci yalnızca açılmış dünyalara ve katlara atanır', () {
      final worker = SpecialWorkerState(
        id: 'worker_move',
        name: 'Kanca',
        rarityId: 'rare',
        abilityId: 'drill_booster',
      );
      final state = GameState(
        activeWorldIndex: 1,
        depthMeters: 1035000,
        deepestMeters: 1100000,
        specialWorkerRoster: [worker],
      );
      final drillRateBeforeAssignment = state.drillRateMetersPerSecond;

      expect(GameEngine.moveSpecialWorker(state, worker.id, 1, 10), isTrue);
      expect((worker.assignedWorld, worker.assignedFloor), (1, 10));
      expect(GameEngine.moveSpecialWorker(state, worker.id, 2, 18), isFalse);
      expect(state.activeSpecialWorkerPower('drill_booster'), greaterThan(0));
      expect(
        state.drillRateMetersPerSecond / drillRateBeforeAssignment,
        closeTo(1 + worker.power * .06, 1e-9),
      );
      expect(
        GameEngine.setSpecialWorkerAutoMove(state, worker.id, true),
        isTrue,
      );
      expect(worker.autoMove, isTrue);
    });

    test('üç günlük hedef sabit seçilir, kaydolur ve haftalığa sayılır', () {
      final now = DateTime(2030, 4, 8, 12);
      final dayKey = GameEngine.dailyChallengeKey(now);
      final state = GameState(coins: 0);
      GameEngine.prepareChallengeWindows(state, now);

      expect(state.dailyChallengeIds, hasLength(3));
      expect(state.dailyChallengeIds.toSet(), hasLength(3));
      expect(DailyChallengeCatalog.idsForDate(dayKey), state.dailyChallengeIds);

      final id = state.dailyChallengeIds.first;
      final challenge = DailyChallengeCatalog.byId[id]!;
      GameEngine.recordDailyProgress(
        state,
        challenge.kind,
        challenge.target,
        now: now,
      );
      expect(GameEngine.claimDailyChallenge(state, id, now: now), isTrue);
      expect(state.dailyChallengeProgress[id], challenge.target);
      expect(state.weeklyChallengeProgress, 1);
      expect(GameEngine.claimDailyChallenge(state, id, now: now), isFalse);

      final restored = GameState.fromJson(state.toJson());
      expect(restored.dailyChallengeIds, state.dailyChallengeIds);
      expect(restored.claimedDailyChallengeIds, {id});
      expect(restored.weeklyChallengeProgress, 1);
    });

    test('gün değişimi üç hedefi, yeni haftaysa haftalık sayacı yeniler', () {
      final sunday = DateTime(2030, 4, 14, 22);
      final monday = DateTime(2030, 4, 15, 0, 1);
      final state = GameState();
      GameEngine.prepareChallengeWindows(state, sunday);
      state.weeklyChallengeProgress = 7;
      state.claimedDailyChallengeIds.add(state.dailyChallengeIds.first);

      GameEngine.prepareChallengeWindows(state, monday);

      expect(state.dailyChallengeDate, GameEngine.dailyChallengeKey(monday));
      expect(state.dailyChallengeIds, hasLength(3));
      expect(state.claimedDailyChallengeIds, isEmpty);
      expect(state.weeklyChallengeProgress, 0);
      expect(state.weeklyChallengeClaimed, isFalse);
    });

    test('haftalık kilometre taşı tek seferlik kasa ve çekirdek verir', () {
      final state = GameState(coins: 0, coreShards: 0);
      GameEngine.prepareChallengeWindows(state, DateTime.now());
      state.weeklyChallengeProgress = DailyChallengeCatalog.weeklyTarget;

      expect(GameEngine.claimWeeklyChallenge(state), isTrue);
      expect(
        state.coins,
        MrMineBigNumber(DailyChallengeCatalog.weeklyRewardCoins),
      );
      expect(state.coreShards, DailyChallengeCatalog.weeklyRewardCoreShards);
      expect(GameEngine.claimWeeklyChallenge(state), isFalse);
    });

    test('maden olayı zamanında doğar, kaydolur ve ödülü verir', () {
      final now = DateTime(2030, 4, 8, 12);
      final state = GameState(
        coins: 0,
        miningSeconds: 119,
        nextMineEventAtSeconds: 120,
      );

      final result = GameEngine.advance(
        state,
        const Duration(seconds: 1),
        now: now,
      );
      expect(state.activeMineEventId, isNotNull);
      expect(
        result.events.any((event) => event.startsWith('Maden olayı:')),
        isTrue,
      );
      expect(
        GameState.fromJson(state.toJson()).activeMineEventId,
        state.activeMineEventId,
      );

      state.activeMineEventId = 'gold_rush';
      expect(GameEngine.resolveMineEvent(state), isTrue);
      expect(state.coins, greaterThan(0));
      expect(state.activeMineEventId, isNull);
      expect(state.nextMineEventAtSeconds, greaterThan(state.miningSeconds));
    });

    test('çevrimdışı vardiya rastgele olay başlatmaz', () {
      final state = GameState(miningSeconds: 119, nextMineEventAtSeconds: 120);

      GameEngine.advance(
        state,
        const Duration(minutes: 5),
        now: DateTime(2030, 4, 8, 12),
        allowRandomEvents: false,
      );

      expect(state.activeMineEventId, isNull);
      expect(state.nextMineEventAtSeconds, greaterThan(state.miningSeconds));
    });

    test('kilitli gezegene geçiş engellenir', () {
      final state = GameState(depthMeters: 1031999, deepestMeters: 1031999);

      expect(GameEngine.switchWorld(state, 1), isFalse);
      expect(state.currentWorldIndex, 0);
      expect(state.depthMeters, 1031999);
    });

    test('boss kataloğu her dünyaya özgü karşılaşma ve sandık verir', () {
      expect(
        GameEngine.bosses
            .where((boss) => GameEngine.bossWorldIndex(boss) == 0)
            .length,
        6,
      );
      expect(
        GameEngine.bosses
            .where((boss) => GameEngine.bossWorldIndex(boss) == 1)
            .length,
        3,
      );
      expect(
        GameEngine.bosses
            .where((boss) => GameEngine.bossWorldIndex(boss) == 2)
            .length,
        3,
      );

      final moon = GameState(
        activeWorldIndex: 1,
        depthMeters: 1032000,
        deepestMeters: 2100000,
      );
      expect(GameEngine.availableBossIndex(moon), 6);
      moon.bossDamage = GameEngine.bosses[6].health;
      GameEngine.attackBoss(moon);
      expect(moon.goldChests, 1);
      expect(moon.chestsFound, 0);
    });

    test('dünya ilerlemesi ayrıdır, ambar ve yükseltmeler ortaktır', () {
      final state = GameState(
        coins: 987,
        depthMeters: 1032500,
        deepestMeters: 1032500,
        cargoCapacity: 100,
        cargoUsed: 4,
        inventory: {'coal': 3, 'copper': 1},
        reserves: {'coal': 1},
        upgrades: {'drill': 4, 'lift': 1, 'warehouse': 1},
      );

      expect(GameEngine.switchWorld(state, 1), isTrue);
      expect(state.currentWorldIndex, 1);
      expect(state.depthMeters, GameState.worldEntryDepths[1]);
      expect(state.inventory, {'coal': 3, 'copper': 1});
      expect(state.cargoUsed, 4);
      expect(state.oreDeposits, isEmpty);
      expect(state.coins, MrMineBigNumber(987));
      expect(state.upgradeLevel('drill'), 4);

      expect(
        GameEngine.rollForMineralDepositSpawn(
          state,
          Random(5),
          metersAdvanced: 1,
          chancePerMeter: 1,
        ),
        isTrue,
      );
      final moonDeposit = state.oreDeposits.values.lastWhere(
        (deposit) => deposit.worldIndex == 1 && !deposit.depleted,
      );
      expect(GameEngine.tapMineDeposit(state, moonDeposit.id), isTrue);
      expect(state.oreDeposits.keys, contains('1:0:0'));
      final moonDepth = state.depthMeters;
      final moonInventory = Map<String, int>.from(state.inventory);
      final moonCargoUsed = moonInventory.entries.fold<double>(0, (
        total,
        entry,
      ) {
        final resource = ResourceCatalog.byId[entry.key];
        if (resource == null || !resource.countsTowardsCapacityAndValue) {
          return total;
        }
        return total + entry.value * max(1, resource.weight);
      });
      final serialized = state.toJson();

      expect(GameEngine.switchWorld(state, 0), isTrue);
      expect(state.depthMeters, 1032500);
      expect(state.inventory, moonInventory);
      expect(state.reserves, {'coal': 1});
      expect(state.cargoUsed, moonCargoUsed);
      expect(state.upgradeLevel('drill'), 4);

      final restored = GameState.fromJson(serialized);
      expect(restored.currentWorldIndex, 1);
      expect(restored.depthMeters, moonDepth);
      expect(restored.inventory, moonInventory);
      expect(GameEngine.switchWorld(restored, 0), isTrue);
      expect(restored.inventory, moonInventory);
      expect(GameEngine.switchWorld(restored, 1), isTrue);
      expect(restored.depthMeters, moonDepth);
      expect(restored.inventory, moonInventory);
    });

    test('yeni vardiya elle maden kırıp satmadan işçi kiralayamaz', () {
      final state = GameState.newGame();
      GameEngine.ensureOpenMineDeposits(state);

      expect(state.coins.toDouble(), 0);
      expect(state.crewCount, 0);
      expect(GameState().coins.toDouble(), 240);
      expect(GameState().crewCount, 1);
      final restoredNewGame = GameState.fromJson(state.toJson());
      expect(restoredNewGame.crewCount, 0);
      expect(restoredNewGame.oreDeposits.keys, contains('0:5:0'));
      expect(GameEngine.hireMiner(state), isFalse);
      expect(state.crewCount, 0);

      final starterVeins = state.oreDeposits.values.toList();
      expect(starterVeins, hasLength(4));
      for (final vein in starterVeins) {
        expect(vein.resourceId, 'coal');
        for (var hit = 0; hit < vein.hitPoints; hit++) {
          expect(GameEngine.nextMineDepositYield(state, vein), 2);
          expect(GameEngine.tapMineDeposit(state, vein.id), isTrue);
        }
        expect(vein.depleted, isTrue);
      }
      GameEngine.sellAll(state);
      expect(state.coins.toDouble(), 40);
      expect(GameEngine.hireMiner(state), isFalse);
      state.addCoins(10);
      expect(GameEngine.minerCost(state), 50);
      expect(GameEngine.hireMiner(state), isTrue);
      expect(state.crewCount, 1);
      expect(GameEngine.minerCost(state), 500);
    });

    test('yeni oyun controller sıfır kaynakla başlar ve yeni seed üretir', () {
      final controller = GameController(saveStore: _MemorySaveStore())
        ..state = GameState(coins: 777, crewCount: 6);
      addTearDown(controller.dispose);

      controller.startNewGame();
      final firstNewGame = controller.state;
      expect(firstNewGame.coins.toDouble(), 0);
      expect(firstNewGame.crewCount, 0);
      expect(firstNewGame.depthMeters, 5000);
      expect(firstNewGame.deepestMeters, 5000);
      expect(firstNewGame.questDepthBaselineMeters, 5000);
      expect(firstNewGame.seed, isNot(91827));
      expect(firstNewGame.oreDeposits, isNotEmpty);

      controller.startNewGame();
      expect(controller.state.coins.toDouble(), 0);
      expect(controller.state.crewCount, 0);
      expect(controller.state.seed, isNot(firstNewGame.seed));
    });

    test('yeni oyun seed açıkça verildiğinde deterministiktir', () {
      expect(GameState.newGame(seed: 1234).seed, 1234);
      expect(GameState.newGame(seed: 5678).seed, 5678);
    });

    test(
      'yığınlar derinlik ilerledikçe olasılıkla doğar ve beş vuruş sürer',
      () {
        final starterState = GameState.newGame(seed: 82);
        GameEngine.ensureOpenMineDeposits(starterState);
        final starterVeins = starterState.oreDeposits.values
            .where((deposit) => deposit.floorIndex == 5 && !deposit.depleted)
            .toList();
        expect(starterVeins, hasLength(4));
        expect(
          starterVeins.every((deposit) => deposit.resourceId == 'coal'),
          isTrue,
        );

        // Crossing new floors during the opening tutorial must not copy the
        // guaranteed starter veins onto every floor. Also clean the duplicate
        // coal groups saved by older builds that did exactly that.
        for (var floor = 6; floor <= 10; floor++) {
          starterState.depthMeters = (floor * GameEngine.mineFloorMeters)
              .toDouble();
          GameEngine.ensureOpenMineDeposits(starterState);
        }
        for (var floor = 6; floor <= 10; floor++) {
          final id = '0:$floor:legacy';
          starterState.oreDeposits[id] = OreDepositState(
            id: id,
            worldIndex: 0,
            floorIndex: floor,
            resourceId: 'coal',
            amount: 10,
            hitPoints: 5,
            side: 0,
            pocket: 0,
            spawnDepthMeters: floor * GameEngine.mineFloorMeters.toDouble(),
          );
        }
        GameEngine.ensureOpenMineDeposits(starterState);
        final visibleStarterVeins = starterState.oreDeposits.values
            .where((deposit) => !deposit.depleted)
            .toList();
        expect(visibleStarterVeins, hasLength(4));
        expect(
          visibleStarterVeins.every((deposit) => deposit.floorIndex == 5),
          isTrue,
        );

        final state = GameState(depthMeters: 100200, deepestMeters: 100200)
          ..seed = 82;
        GameEngine.ensureOpenMineDeposits(state);
        expect(state.oreDeposits, isEmpty);

        final shallowState = GameState(depthMeters: 100, deepestMeters: 100)
          ..seed = 83;
        expect(
          GameEngine.rollForMineralDepositSpawn(
            shallowState,
            Random(1),
            metersAdvanced: 1,
            chancePerMeter: 1,
          ),
          isFalse,
        );
        final fullState = GameState(
          depthMeters: 100200,
          deepestMeters: 100200,
          cargoCapacity: 1,
          cargoUsed: 1,
        );
        fullState.seed = 84;
        expect(
          GameEngine.rollForMineralDepositSpawn(
            fullState,
            Random(1),
            metersAdvanced: 1,
            chancePerMeter: 1,
          ),
          isFalse,
        );

        final random = Random(1729);
        expect(
          GameEngine.rollForMineralDepositSpawn(
            state,
            random,
            metersAdvanced: 1,
            chancePerMeter: 0,
          ),
          isFalse,
        );
        expect(state.oreDeposits, isEmpty);
        expect(
          GameEngine.rollForMineralDepositSpawn(
            state,
            random,
            metersAdvanced: 1,
            chancePerMeter: 1,
          ),
          isTrue,
        );

        final spawned = state.oreDeposits.values.single;
        expect(spawned.hitPoints, 5);
        expect(spawned.amount % spawned.hitPoints, 0);
        expect(spawned.spawnDepthMeters, inInclusiveRange(200, 100200));
        expect(spawned.side, inInclusiveRange(0, 1));
        expect(spawned.pocket, inInclusiveRange(0, 4));
        expect(
          ResourceCatalog.byId[spawned.resourceId]!.minDepthMeters,
          lessThanOrEqualTo(spawned.spawnDepthMeters!),
        );
        final expectedYield = spawned.amount ~/ spawned.hitPoints;
        for (var hit = 0; hit < spawned.hitPoints; hit++) {
          expect(
            GameEngine.nextMineDepositYield(state, spawned),
            expectedYield,
          );
          expect(GameEngine.tapMineDeposit(state, spawned.id), isTrue);
        }
        expect(spawned.depleted, isTrue);
        expect(GameEngine.tapMineDeposit(state, spawned.id), isFalse);
        final restoredSpawn = GameState.fromJson(state.toJson())
            .oreDeposits[spawned.id]!;
        expect(restoredSpawn.damage, 5);
        expect(restoredSpawn.spawnDepthMeters, spawned.spawnDepthMeters);
        final legacyDeposit = OreDepositState.fromJson('old', {
          'worldIndex': 0,
          'floorIndex': 0,
          'resourceId': 'coal',
          'amount': 10,
          'hitPoints': 5,
          'side': 0,
          'pocket': 0,
        });
        expect(legacyDeposit.spawnDepthMeters, isNull);
      },
    );

    test('cevher her vuruşta verir ve damar hasarı kayıtla korunur', () {
      final state = GameState.newGame();
      GameEngine.ensureOpenMineDeposits(state);
      final deposit = state.oreDeposits['0:5:0']!;

      for (var hit = 0; hit < deposit.hitPoints - 1; hit++) {
        final beforeTap = state.amount('coal');
        final expectedYield = GameEngine.nextMineDepositYield(state, deposit);
        expect(expectedYield, greaterThan(0));
        expect(GameEngine.tapMineDeposit(state, deposit.id), isTrue);
        expect(state.amount('coal') - beforeTap, expectedYield);
      }
      final collectedBeforeFinalHit = state.amount('coal');
      expect(collectedBeforeFinalHit, greaterThan(0));
      expect(deposit.damage, deposit.hitPoints - 1);

      final restored = GameState.fromJson(state.toJson());
      final restoredDeposit = restored.oreDeposits[deposit.id]!;
      expect(restoredDeposit.damage, deposit.damage);
      expect(restoredDeposit.side, deposit.side);
      expect(restoredDeposit.pocket, deposit.pocket);
      expect(restoredDeposit.resourceId, deposit.resourceId);
      expect(restoredDeposit.amount, deposit.amount);
      expect(restored.amount('coal'), collectedBeforeFinalHit);

      final finalHitYield = GameEngine.nextMineDepositYield(
        restored,
        restoredDeposit,
      );
      expect(GameEngine.tapMineDeposit(restored, deposit.id), isTrue);
      expect(restoredDeposit.depleted, isTrue);
      expect(restored.amount('coal'), deposit.amount);
      expect(restored.amount('coal') - collectedBeforeFinalHit, finalHitYield);
      expect(GameEngine.tapMineDeposit(restored, deposit.id), isFalse);
      expect(restored.amount('coal'), deposit.amount);
    });

    test('otomatik madenciler her açık kilometreden maden toplar', () {
      final state = GameState(
        crewCount: 2,
        depthMeters: 5000,
        deepestMeters: 5000,
        miningSeconds: 3,
        cargoCapacity: 100,
        worldMinerCounts: {'0': 2},
      );
      GameEngine.ensureOpenMineDeposits(state);
      expect(state.oreDeposits, isEmpty);

      final result = GameEngine.advance(
        state,
        const Duration(minutes: 1),
        allowRandomEvents: false,
      );
      expect(result.mined, greaterThan(0));
      expect(
        state.inventory.values.fold<int>(0, (total, amount) => total + amount),
        state.totalMined,
      );
      expect(state.cargoUsed, greaterThan(0));
    });

    test('depo doluyken çok katlı otomatik kazı kapasiteyi aşmaz', () {
      final state = GameState(
        crewCount: 2,
        depthMeters: 5000,
        deepestMeters: 5000,
        miningSeconds: 3,
        cargoCapacity: 2,
        worldMinerCounts: {'0': 2},
      );

      GameEngine.advance(
        state,
        const Duration(minutes: 1),
        allowRandomEvents: false,
      );
      expect(state.cargoUsed, greaterThan(0));
      expect(state.totalMined, greaterThan(0));
      expect(state.cargoUsed, lessThanOrEqualTo(state.effectiveCargoCapacity));
    });

    test('ekip rollerinin kapasite ve satış katkısı çalışır', () {
      final state = GameState(
        crewCount: 4,
        cargoCapacity: 200,
        cargoUsed: 25,
        inventory: {'copper': 25},
      );

      expect(GameEngine.assignWorkerRole(state, 'transport', 1), isTrue);
      expect(GameEngine.assignWorkerRole(state, 'scanner', 1), isTrue);
      expect(GameEngine.assignWorkerRole(state, 'sorting', 1), isTrue);
      expect(state.diggingWorkers, 1);
      expect(state.effectiveCargoCapacity, 208);
      expect(GameEngine.sellAll(state), MrMineBigNumber(51));

      final restored = GameState.fromJson(state.toJson());
      expect(restored.workerAssignments, state.workerAssignments);
      expect(restored.diggingWorkers, 1);

      final priorityState = GameState();
      expect(
        GameEngine.assignWorkerRole(priorityState, 'transport', 1),
        isTrue,
      );
      expect(
        GameEngine.setWorkerRolePriority(priorityState, 'scanner', 1),
        isTrue,
      );
      expect(GameEngine.assignWorkerRole(priorityState, 'scanner', 1), isFalse);
      expect(
        GameEngine.setWorkerRolePriority(priorityState, 'scanner', 2),
        isTrue,
      );
      expect(GameEngine.assignWorkerRole(priorityState, 'scanner', 1), isTrue);
      expect(priorityState.transportWorkers, 0);
      expect(priorityState.scannerWorkers, 1);
    });

    test('derin mağara rotası güvenli haritalı keşif açar ve kaydolur', () {
      final now = DateTime.utc(2030);
      final state = GameState(
        depthMeters: 45000,
        deepestMeters: 45000,
        drones: 3,
        caveDroneCount: 3,
        caveRoute: 'deep',
      );

      expect(GameEngine.startCaveExpedition(state, now), isTrue);
      expect(state.caveReadyAt, isNull);
      expect(state.caveExploring, isTrue);
      expect(state.caveNodeMap, hasLength(4));
      expect(state.caveNodeMap.every((row) => row.length == 3), isTrue);
      final restored = GameState.fromJson(state.toJson());
      expect(restored.caveRoute, 'deep');
      expect(restored.caveDroneCount, 3);
      expect(restored.caveExploring, isTrue);
      expect(restored.caveNodeMap, state.caveNodeMap);
      expect(restored.caveDroneHealth, 138);
    });

    test('mağara yolu bitişik düğümler seçtirir ve ganimetle erken döner', () {
      final now = DateTime.utc(2030);
      final state = GameState(
        depthMeters: 60000,
        deepestMeters: 60000,
        cargoCapacity: 100,
      );
      expect(GameEngine.startCaveExpedition(state, now), isTrue);
      state.caveNodeMap
        ..clear()
        ..addAll(List.generate(4, (_) => ['mineral', 'mineral', 'mineral']));

      expect(GameEngine.chooseCaveNode(state, 0, now: now), isTrue);
      expect(GameEngine.chooseCaveNode(state, 2, now: now), isFalse);
      expect(GameEngine.chooseCaveNode(state, 1, now: now), isTrue);
      expect(state.cavePathLanes, [0, 1]);
      expect(state.pendingCaveLoot.values.first, greaterThanOrEqualTo(2));
      expect(GameEngine.retreatCave(state), isTrue);
      expect(GameEngine.claimCaveExpedition(state, now), isTrue);
      expect(state.cavesCompleted, 1);
      expect(state.caveNodeMap, isEmpty);
      expect(state.caveExploring, isFalse);
      expect(state.inventory.values.any((amount) => amount > 0), isTrue);
    });

    test(
      'uçan, mıknatıslı ve onarıcı drone yetenekleri yol hesabına katılır',
      () {
        final state = GameState(depthMeters: 60000, deepestMeters: 60000);
        expect(GameEngine.selectCaveDrone(state, 'magnet'), isTrue);
        expect(
          GameEngine.startCaveExpedition(state, DateTime.utc(2030)),
          isTrue,
        );
        expect(state.caveDroneFuel, 4);
        expect(GameEngine.chooseCaveNode(state, 0), isTrue);
        expect(GameEngine.chooseCaveNode(state, 2), isTrue);
        expect(GameEngine.selectCaveDrone(state, 'flying'), isFalse);

        state.caveExploring = false;
        state.caveCompletedPending = false;
        state.caveNodeMap.clear();
        expect(GameEngine.selectCaveDrone(state, 'healer'), isTrue);
        expect(CaveDroneCatalog.byId['flying']?.vision, 2);
        expect(CaveDroneCatalog.byId['magnet']?.collectionRange, 1);
        expect(CaveDroneCatalog.byId['healer']?.health, greaterThan(0));
      },
    );

    test('yükseltme kataloğu sekiz ailede yüz seviye tanımlar', () {
      expect(UpgradeCatalog.tracks, hasLength(8));
      expect(UpgradeCatalog.levels, hasLength(800));
      expect(UpgradeCatalog.next('drill', 0)?.level, 1);
      expect(UpgradeCatalog.next('workers', 99)?.level, 100);
      expect(UpgradeCatalog.next('drill', 100), isNull);
    });

    test('sonraki sondaj şeması kasa ve cevher tarifini birlikte ister', () {
      final state = GameState(coins: 149);
      expect(GameEngine.upgradeCost(state, 'drill'), 150);
      expect(GameEngine.buyUpgrade(state, 'drill'), isFalse);
      state.coins = 150;
      expect(GameEngine.buyUpgrade(state, 'drill'), isTrue);
      expect(state.upgradeLevel('drill'), 2);

      state.coins = 3500;
      expect(GameEngine.upgradeCost(state, 'drill'), 3500);
      expect(GameEngine.upgradeMaterialRequirements(state, 'drill'), {
        'coal': 20,
        'copper': 3,
        'silver': 1,
      });
      expect(GameEngine.upgradeMaterialDeficits(state, 'drill'), {
        'coal': 20,
        'copper': 3,
        'silver': 1,
      });
      expect(GameEngine.buyUpgrade(state, 'drill'), isFalse);

      state.inventory.addAll({'coal': 20, 'copper': 3, 'silver': 1});
      state.cargoUsed = 24;
      expect(GameEngine.upgradeMaterialDeficits(state, 'drill'), isEmpty);
      expect(GameEngine.buyUpgrade(state, 'drill'), isTrue);
      expect(state.upgradeLevel('drill'), 3);
      expect(state.amount('coal'), 0);
      expect(state.amount('copper'), 0);
      expect(state.amount('silver'), 0);
      expect(state.cargoUsed, 0);
    });

    test('ilk sondaj yükseltmesi ilk madenciden önce kilitli kalır', () {
      final state = GameState.newGame()
        ..coins = 150
        ..tutorialStep = 3;

      expect(GameEngine.buyUpgrade(state, 'drill'), isFalse);
      expect(state.coins, MrMineBigNumber(150));
      expect(state.upgradeLevel('drill'), 1);

      state.crewCount = 1;
      state.worldMinerCounts['0'] = 1;
      expect(GameEngine.buyUpgrade(state, 'drill'), isTrue);
      expect(state.coins, MrMineBigNumber.zero);
      expect(state.upgradeLevel('drill'), 2);
    });

    test('ambar doluyken sandık korunur ve yer açılınca açılır', () {
      final state = GameState(
        cargoCapacity: 5,
        cargoUsed: 5,
        inventory: {'coal': 5},
      )..chestsFound = 1;

      expect(GameEngine.openChest(state), 0);
      expect(state.chestsFound, 1);
      expect(state.chestsOpened, 0);

      GameEngine.sellResource(state, 'coal');
      expect(GameEngine.openChest(state), greaterThan(0));
      expect(state.chestsFound, 0);
      expect(state.chestsOpened, 1);
      expect(state.cargoUsed, lessThanOrEqualTo(state.effectiveCargoCapacity));
    });

    test('otomatik satış eşiği kilitli ve rezerve cevheri korur', () {
      final state = GameState(
        coins: 0,
        cargoCapacity: 10,
        cargoUsed: 10,
        inventory: {'coal': 4, 'copper': 4, 'gold': 2},
        reserves: {'coal': 1},
        lockedResources: {'copper', 'gold'},
        autoSellEnabled: true,
        autoSellThreshold: .6,
      );

      final result = GameEngine.advance(
        state,
        const Duration(seconds: 1),
        now: DateTime.utc(2030),
      );

      expect(state.amount('coal'), 1);
      expect(state.amount('copper'), 4);
      expect(state.amount('gold'), 2);
      expect(state.cargoUsed, 7);
      expect(state.coins, MrMineBigNumber(3));
      expect(result.events.single, contains('Otomatik satış +3 kasa'));
      expect(GameEngine.sellAll(state), MrMineBigNumber.zero);
      expect(GameEngine.sellResource(state, 'gold'), MrMineBigNumber.zero);
    });

    test('kısmi satış rezerve ve kilitli kaynakları atlar', () {
      final state = GameState(
        cargoCapacity: 100,
        inventory: {'coal': 8, 'copper': 4},
        reserves: {'coal': 2},
        lockedResources: {'copper'},
      );

      expect(GameEngine.sellFraction(state, .5), MrMineBigNumber(3));
      expect(state.amount('coal'), 5);
      expect(state.amount('copper'), 4);
    });

    test('sandık sıkıştırıcı kuyrukta ilerler ve çevrimdışı tamamlanır', () {
      final startedAt = DateTime.utc(2030);
      final state = GameState(
        coins: 100000,
        unlockedBuildings: {
          'elevator',
          'workshop',
          'warehouse',
          'trade',
          'research',
          'expedition',
          'chest_compressor',
        },
      );
      state.chestsFound = GameEngine.chestCompressionBasicCost(state);

      expect(
        GameEngine.startChestCompression(state, 'gold', now: startedAt),
        isTrue,
      );
      expect(state.chestsFound, 0);
      expect(state.chestCompressionQueue, ['gold']);
      final restored = GameState.fromJson(state.toJson());
      expect(restored.chestCompressionQueue, ['gold']);
      expect(restored.chestCompressionReadyAt, state.chestCompressionReadyAt);

      final result = GameEngine.advance(
        restored,
        const Duration(minutes: 5),
        now: startedAt.add(const Duration(minutes: 5)),
      );
      expect(restored.goldChests, 1);
      expect(restored.chestCompressionQueue, isEmpty);
      expect(
        result.events.any((event) => event.contains('altın sandık üretti')),
        isTrue,
      );

      restored.goldChests = GameEngine.chestCompressionGoldCost(restored);
      expect(
        GameEngine.startChestCompression(
          restored,
          'deep',
          now: startedAt.add(const Duration(minutes: 5)),
        ),
        isTrue,
      );
      GameEngine.advance(
        restored,
        const Duration(minutes: 20),
        now: startedAt.add(const Duration(minutes: 25)),
      );
      expect(restored.deepChests, 1);
    });

    test(
      'mücevher ocağı kaynak tüketir, iş yüküyle tamamlanır ve bonus verir',
      () {
        final state = GameState(
          coins: 0,
          cargoCapacity: 100,
          inventory: {'gold': 3, 'copper': 4},
          unlockedBuildings: {
            'elevator',
            'workshop',
            'warehouse',
            'trade',
            'research',
            'expedition',
            'gem_forge',
          },
        );

        expect(GameEngine.startGemCraft(state, 'ruby'), isTrue);
        expect(state.amount('gold'), 0);
        expect(state.amount('copper'), 0);
        GameEngine.adjustGemWorkload(state, 'ruby', 25);
        expect(
          state.gemWorkload.values.fold<int>(0, (sum, value) => sum + value),
          100,
        );
        expect(state.gemWorkload['ruby'], 45);

        final restored = GameState.fromJson(state.toJson());
        final result = GameEngine.advance(
          restored,
          const Duration(minutes: 4),
          now: DateTime.utc(2030).add(const Duration(minutes: 4)),
        );
        expect(restored.gems['ruby'], 1);
        expect(restored.gemCraftRemainingSeconds, isEmpty);
        expect(
          result.events.any((event) => event.contains('Kor Yakutu dövüldü')),
          isTrue,
        );
        expect(GameEngine.toggleGemEquipment(restored, 'ruby'), isTrue);

        restored.inventory['coal'] = 10;
        restored.cargoUsed = 10;
        expect(
          GameEngine.sellResource(restored, 'coal'),
          MrMineBigNumber.fromNum(10.8),
        );
      },
    );

    test('ambar doluyken mağara ganimeti ve kalıntı beklemede kalır', () {
      final now = DateTime.utc(2030);
      GameState? completedState;
      for (var candidate = 0; candidate < 100; candidate++) {
        final candidateState = GameState(
          depthMeters: 60000,
          deepestMeters: 60000,
          cargoCapacity: 1,
          cargoUsed: 1,
          inventory: {'coal': 1},
          caveTripsStarted: 1,
          caveReadyAt: now.subtract(const Duration(seconds: 1)),
        )..seed = candidate;
        GameEngine.advance(
          candidateState,
          const Duration(seconds: 1),
          now: now,
        );
        if (candidateState.pendingCaveLoot.keys.any(
          (id) => id.startsWith('relic_'),
        )) {
          completedState = candidateState;
          break;
        }
      }
      expect(completedState, isNotNull);
      final state = completedState!;

      expect(state.caveCompletedPending, isTrue);
      expect(GameEngine.claimCaveExpedition(state, now), isFalse);
      expect(state.caveCompletedPending, isTrue);
      expect(state.relicsFound, 0);
      expect(state.unlockedRelics, isEmpty);
      expect(
        state.pendingCaveLoot.keys.any((id) => id.startsWith('relic_')),
        isTrue,
      );

      state.cargoCapacity = 1000;
      expect(GameEngine.claimCaveExpedition(state, now), isTrue);
      expect(state.relicsFound, 1);
      expect(state.unlockedRelics, hasLength(1));
      expect(state.cavesCompleted, 1);
      expect(state.pendingCaveLoot, isEmpty);
    });

    test(
      'geç oyun kilometre taşları gerçek üretim ve sandık etkisi sağlar',
      () {
        final oilState = GameState(cargoCapacity: 100)
          ..unlockedBuildings.add('underground_city');
        GameEngine.advance(
          oilState,
          const Duration(minutes: 1),
          now: DateTime.utc(2030),
        );
        expect(oilState.amount('oil'), 12);
        expect(oilState.cargoUsed, lessThan(oilState.effectiveCargoCapacity));
        oilState.inventory['oil'] = 5;
        expect(GameEngine.refineOil(oilState), isTrue);
        expect(oilState.amount('oil'), 0);
        expect(oilState.amount('building_material'), 2);

        final ordinaryChest = GameState(cargoCapacity: 100)..chestsFound = 1;
        final compressedChest = GameState(cargoCapacity: 100, goldChests: 1);
        final ordinaryReward = GameEngine.openChest(ordinaryChest);
        final compressedReward = GameEngine.openChestTier(
          compressedChest,
          'gold',
        );
        expect(compressedReward, greaterThan(ordinaryReward));
        expect(compressedChest.cargoUsed, greaterThan(ordinaryChest.cargoUsed));

        final collectorState = GameState(cargoCapacity: 10000)
          ..unlockedBuildings.add('chest_collector');
        final collectorResult = GameEngine.advance(
          collectorState,
          const Duration(minutes: 30),
          now: DateTime.utc(2030),
        );
        expect(collectorState.collectorStoredChests, greaterThanOrEqualTo(1));
        expect(
          collectorResult.events.any(
            (event) => event.contains('Otomatik toplayıcı'),
          ),
          isTrue,
        );
      },
    );
  });

  test('kayıt yüklemesi kapasiteyi toparlar ve yeni şemayı reddeder', () {
    final corrupted = Map<String, Object?>.from(GameState().toJson())
      ..['schema'] = 13
      ..['coins'] = -20
      ..['crewCount'] = 0
      ..['cargoCapacity'] = 2
      ..['inventory'] = {'coal': 100, 'copper': -4};

    final restored = GameState.fromJson(corrupted);
    expect(restored.coins, MrMineBigNumber.zero);
    expect(restored.crewCount, 1);
    expect(restored.amount('copper'), 0);
    expect(restored.cargoUsed, lessThanOrEqualTo(restored.cargoCapacity));

    expect(
      isValidGameSave(jsonEncode({...GameState().toJson(), 'schema': 999})),
      isFalse,
    );
    expect(
      () => GameState.fromJson({...GameState().toJson(), 'schema': 999}),
      throwsFormatException,
    );
  });

  test('bozuk ekip ve damar verisi yüklenirken güvenli sınırlara çekilir', () {
    final malformed =
        Map<String, Object?>.from(GameState(crewCount: 2).toJson())
          ..['schema'] = 13
          ..['workerAssignments'] = {
            'transport': 1,
            'scanner': 1,
            'sorting': 1,
            'unknown': 80,
          }
          ..['workerRolePriority'] = ['scanner', 'scanner', 'unknown']
          ..['oreVeinDamage'] = {'coal': 180, 'not_an_ore': 15};

    final restored = GameState.fromJson(malformed);
    expect(restored.diggingWorkers, greaterThanOrEqualTo(0));
    expect(
      restored.transportWorkers +
          restored.scannerWorkers +
          restored.sortingWorkers,
      lessThanOrEqualTo(restored.crewCount),
    );
    expect(restored.workerRolePriority.toSet(), hasLength(4));
    expect(restored.oreVeinDamage['coal'], 100);
    expect(restored.oreVeinDamage.containsKey('not_an_ore'), isFalse);
  });

  test('şema 2 kaydı derinliğe göre dünyayı seçer ve ortak ambarı korur', () {
    final legacy =
        Map<String, Object?>.from(
            GameState(
              depthMeters: 1100000,
              deepestMeters: 1100000,
              cargoCapacity: 100,
              inventory: {'coal': 5},
              cargoUsed: 5,
            ).toJson(),
          )
          ..['schema'] = 2
          ..remove('activeWorldIndex')
          ..remove('worldDepths')
          ..remove('worldPressures')
          ..remove('worldCargoUsed')
          ..remove('worldInventories')
          ..remove('worldReserves');

    final migrated = GameState.fromJson(legacy);

    expect(migrated.currentWorldIndex, 1);
    expect(migrated.depthMeters, 1100000);
    expect(migrated.amount('coal'), 5);
    expect(migrated.worldDepths['1'], 1100000);
    expect(migrated.inventory, {'coal': 5});
    expect(GameState.fromJson(migrated.toJson()).amount('coal'), 5);
  });

  testWidgets('sefer panelindeki Ay kartı dünyayı gerçekten değiştirir', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    final controller = GameController()
      ..state = GameState(depthMeters: 1032000, deepestMeters: 1032000);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BuildingDialog(
            controller: controller,
            buildingId: 'expedition',
          ),
        ),
      ),
    );
    expect(find.byType(BuildingDialog), findsOneWidget);
    expect(find.text('SEFER GARAJI'), findsWidgets);
    expect(find.text('BÖLGELER'), findsOneWidget);
    expect(find.text('Ay'), findsOneWidget);
    await tester.ensureVisible(find.text('Ay'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ay'));
    await tester.pump();

    expect(controller.state.currentWorldIndex, 1);
    expect(controller.state.depthMeters, GameState.worldEntryDepths[1]);
  });

  testWidgets('bilim kadrosu portre atlası yaralanma durumunu gösterir', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    final scientist = ScientistState(
      id: 'scientist_visual',
      name: 'Ada',
      rarityId: 'rare',
      traitId: 'careful',
      injuredUntil: DateTime.now().add(const Duration(minutes: 10)),
      injuryCount: 1,
    );
    final controller = GameController()
      ..state = GameState(scientists: 1, scientistRoster: [scientist]);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BuildingDialog(controller: controller, buildingId: 'research'),
        ),
      ),
    );
    await tester.ensureVisible(find.textContaining('Ada •'));
    await tester.pump(const Duration(milliseconds: 80));

    expect(find.byType(AtlasSprite), findsWidgets);
    expect(find.textContaining('Yaralı • iyileşmesine'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('özel madencinin yetenek portresi atölyede hareket eder', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    final worker = SpecialWorkerState(
      id: 'worker_visual',
      name: 'Poyraz',
      rarityId: 'legendary',
      abilityId: 'support',
      autoMove: false,
    );
    final state = GameState(specialWorkerRoster: [worker])
      ..unlockedBuildings.add('super_miners');
    final controller = GameController()..state = state;
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BuildingDialog(controller: controller, buildingId: 'workshop'),
        ),
      ),
    );
    await tester.ensureVisible(find.textContaining('Poyraz •'));
    await tester.pump(const Duration(milliseconds: 80));

    expect(find.textContaining('İskele Ustası'), findsOneWidget);
    expect(find.byType(AtlasSprite), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  for (final size in const [Size(390, 844), Size(800, 1180)]) {
    testWidgets(
      'atölye ekip dağılımı ${size.width}x${size.height} içinde işler',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);

        final controller = GameController()..state = GameState(crewCount: 3);
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BuildingDialog(
                controller: controller,
                buildingId: 'workshop',
              ),
            ),
          ),
        );

        expect(find.text('EKİP GÖREV DAĞILIMI'), findsOneWidget);
        final assignButton = find.byTooltip('Bir kazıcıyı bu göreve ata').first;
        await tester.ensureVisible(assignButton);
        await tester.tap(assignButton);
        await tester.pump();

        expect(controller.state.transportWorkers, 1);
        expect(controller.state.diggingWorkers, 2);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final size in const [Size(390, 844)]) {
    testWidgets(
      'günlük ve haftalık hedefler ${size.width}x${size.height} içinde görünür',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);

        final controller = GameController()..state = GameState(coins: 0);
        GameEngine.prepareChallengeWindows(controller.state, DateTime.now());
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BuildingDialog(
                controller: controller,
                buildingId: 'quests',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('BUGÜN •'), findsOneWidget);
        expect(find.text('Haftalık kilometre taşı'), findsOneWidget);
        expect(find.text('VARDİYA GÖREVLERİ'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final size in const [Size(390, 844)]) {
    testWidgets(
      'maden olayı bannerı ${size.width}x${size.height} içinde ödül verir',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);

        final controller = _readyController(state: GameState());
        controller.state.activeMineEventId = 'merchant';
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          MaterialApp(home: GameScreen(controller: controller)),
        );
        await tester.pump(const Duration(milliseconds: 250));

        expect(find.text('Gezgin tüccar kuyuda!'), findsOneWidget);
        await tester.tap(find.text('Gezgin tüccar kuyuda!'));
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.text('KUYU OLAYI'), findsOneWidget);
        expect(find.text('ÖDÜLÜ AL'), findsOneWidget);
        await tester.tap(find.text('ÖDÜLÜ AL'));
        await tester.pump(const Duration(milliseconds: 250));

        expect(controller.state.activeMineEventId, isNull);
        expect(tester.takeException(), isNull);
      },
    );
  }

  test('ilk görev hattı öğretici sırayı ve benzersiz metinleri korur', () {
    final tutorial = QuestCatalog.all.take(5).toList();

    expect(QuestCatalog.all, hasLength(112));
    expect(tutorial.map((quest) => quest.kind), [
      QuestKind.mine,
      QuestKind.sell,
      QuestKind.hire,
      QuestKind.upgrade,
      QuestKind.depth,
    ]);
    expect(tutorial.map((quest) => quest.target), [1, 40, 1, 4, 80]);
    expect(
      QuestCatalog.all.map((quest) => quest.title).toSet(),
      hasLength(112),
    );
    expect(
      QuestCatalog.all.map((quest) => quest.description).toSet(),
      hasLength(112),
    );
  });

  testWidgets(
    'yüzey binaları sabit durur, asansör ortalanır ve tabanlar hizalanır',
    (tester) async {
      const size = Size(390, 844);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);

      final controller = _readyController(state: GameState());
      await tester.pumpWidget(
        MaterialApp(home: GameScreen(controller: controller)),
      );
      await tester.pump(const Duration(milliseconds: 250));

      final buildingLayer = find.byKey(
        const ValueKey('surface-building-layer'),
      );
      expect(buildingLayer, findsOneWidget);
      expect(
        find.descendant(of: buildingLayer, matching: find.byType(Scrollable)),
        findsNothing,
      );

      const ids = [
        'workshop',
        'warehouse',
        'trade',
        'elevator',
        'research',
        'expedition',
      ];
      final layerRect = tester.getRect(buildingLayer);
      double? sharedGround;
      for (final id in ids) {
        final button = find.byKey(ValueKey('surface-building-$id'));
        final label = find.byKey(ValueKey('surface-building-label-$id'));
        final sprite = find.byKey(ValueKey('surface-building-sprite-$id'));
        expect(button, findsOneWidget);
        expect(label, findsOneWidget);
        expect(sprite, findsOneWidget);

        final buttonRect = tester.getRect(button);
        final labelRect = tester.getRect(label);
        final spriteRect = tester.getRect(sprite);
        expect(buttonRect.left, greaterThanOrEqualTo(layerRect.left));
        expect(buttonRect.right, lessThanOrEqualTo(layerRect.right));
        expect(labelRect.top, greaterThanOrEqualTo(buttonRect.top));
        expect(labelRect.bottom, lessThan(buttonRect.bottom - 10));
        sharedGround ??= spriteRect.bottom;
        expect(spriteRect.bottom, closeTo(sharedGround, .01));
      }

      final elevatorRect = tester.getRect(
        find.byKey(const ValueKey('surface-building-elevator')),
      );
      expect(elevatorRect.center.dx, closeTo(size.width / 2, .01));
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    },
  );

  testWidgets('cevher damarları kaya ceplerinde ve kuyu dışında durur', (
    tester,
  ) async {
    const size = Size(390, 844);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    final controller =
        _readyController(
            state: GameState(
              depthMeters: 50000,
              deepestMeters: 50000,
              tutorialStep: 5,
            ),
          )
          ..state.oreDeposits.addAll({
            for (final entry in [
              ('0:50:0', 'gold', 0, 0),
              ('0:50:1', 'sapphire', 1, 0),
              ('0:50:2', 'oil_shale', 0, 1),
            ])
              entry.$1: OreDepositState(
                id: entry.$1,
                worldIndex: 0,
                floorIndex: 50,
                resourceId: entry.$2,
                amount: 25,
                hitPoints: 5,
                side: entry.$3,
                pocket: entry.$4,
                spawnDepthMeters: 50000,
              ),
          });
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(home: GameScreen(controller: controller)),
    );
    await tester.pump(const Duration(milliseconds: 300));

    final world = find.byKey(const ValueKey('mine-world'));
    final worldRect = tester.getRect(world);
    final activeFloor = find.byKey(const ValueKey('mine-floor-0-50'));
    final floorRect = tester.getRect(activeFloor);
    final activeDeposits = controller.state.oreDeposits.values
        .where(
          (deposit) =>
              deposit.worldIndex == 0 &&
              deposit.floorIndex == 50 &&
              !deposit.depleted,
        )
        .toList();
    final ores = find.byWidgetPredicate(
      (widget) =>
          widget.key is ValueKey &&
          (widget.key as ValueKey).value.toString().startsWith(
            'ore-node-0:50:',
          ),
    );
    expect(ores, findsNWidgets(activeDeposits.length));
    expect(find.byKey(const ValueKey('mine-floor-label-0-49')), findsOneWidget);
    expect(find.byKey(const ValueKey('mine-floor-label-0-50')), findsNothing);

    final galleryFloors = [floorRect.height * .92];
    final shaftLeft = (worldRect.width - 86) / 2;
    for (var index = 0; index < activeDeposits.length; index++) {
      final ore = tester.getRect(ores.at(index));
      final relativeLeft = ore.left - floorRect.left;
      final relativeCenterY = ore.center.dy - floorRect.top;
      final side = index % 2;
      final lane = index ~/ 2;
      final laneOffset = lane * (ore.width + 4);
      final expectedLeft = side == 0
          ? 4 + laneOffset
          : worldRect.width - 4 - ore.width - laneOffset;
      final distanceToFloor = galleryFloors
          .map((floor) => (relativeCenterY - floor).abs())
          .reduce((left, right) => left < right ? left : right);

      expect(relativeLeft, closeTo(expectedLeft, .01));
      expect(
        ore.right <= floorRect.left + shaftLeft ||
            ore.left >= floorRect.left + shaftLeft + 86,
        isTrue,
      );
      expect(distanceToFloor, greaterThan(ore.height / 2 + 7));
    }

    expect(tester.takeException(), isNull);
  });

  testWidgets('cevher yuvaları ve tüm madenciler küçük ekranlarda görünür', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    for (final size in const [
      Size(320, 568),
      Size(390, 844),
      Size(800, 1180),
    ]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      final state = GameState.newGame(seed: 2468)
        ..crewCount = 5
        ..worldMinerCounts['0'] = 5;
      state.oreDeposits.addAll({
        for (var index = 0; index < 4; index++)
          '0:5:$index': OreDepositState(
            id: '0:5:$index',
            worldIndex: 0,
            floorIndex: 5,
            resourceId: index.isEven ? 'coal' : 'copper',
            amount: 8,
            hitPoints: 4,
            side: 0,
            pocket: index == 0
                ? 2
                : index == 3
                ? 4
                : 3,
          ),
      });
      final controller = _readyController(state: state);

      await tester.pumpWidget(
        MaterialApp(home: GameScreen(controller: controller)),
      );
      await tester.pump(const Duration(milliseconds: 250));

      final depositRects = [
        for (var index = 0; index < 4; index++)
          tester.getRect(find.byKey(ValueKey('ore-node-0:5:$index'))),
      ];
      for (var left = 0; left < depositRects.length; left++) {
        for (var right = left + 1; right < depositRects.length; right++) {
          expect(
            depositRects[left].overlaps(depositRects[right]),
            isFalse,
            reason: 'ore nodes overlap at ${size.width}x${size.height}',
          );
        }
      }

      final workerNodes = find.byWidgetPredicate(
        (widget) =>
            widget.key is ValueKey &&
            (widget.key as ValueKey).value.toString().startsWith(
              'mine-worker-4-',
            ),
      );
      expect(workerNodes, findsNWidgets(5));
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget.key is ValueKey &&
              (widget.key as ValueKey).value.toString().startsWith(
                'mine-worker-5-',
              ),
        ),
        findsNothing,
      );
      final drillRig = find.byKey(const ValueKey('deep-drill-rig-5'));
      expect(drillRig, findsOneWidget);
      final baseRigWidth = size.width < 690 ? 108.0 : 136.0;
      expect(tester.getSize(drillRig).width, closeTo(baseRigWidth * 1.3, .01));
      final workerRects = [
        for (var worker = 0; worker < 5; worker++)
          tester.getRect(find.byKey(ValueKey('mine-worker-4-0-$worker'))),
      ];
      for (var left = 0; left < workerRects.length; left++) {
        for (var right = left + 1; right < workerRects.length; right++) {
          expect(workerRects[left].overlaps(workerRects[right]), isFalse);
        }
      }
      for (final depositRect in depositRects) {
        for (final workerRect in workerRects) {
          expect(
            depositRect.overlaps(workerRect),
            isFalse,
            reason:
                'ore node overlaps a worker at ${size.width}x${size.height}',
          );
        }
      }
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    }
  });

  testWidgets('sahadaki yığın her vuruşta ödül verir ve bitince silinir', (
    tester,
  ) async {
    const size = Size(390, 844);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    final controller = _readyController();
    addTearDown(controller.dispose);
    final deposit = controller.state.oreDeposits['0:5:0']!;
    expect(controller.state.coins.toDouble(), 0);
    expect(controller.state.crewCount, 0);
    await tester.pumpWidget(
      MaterialApp(home: GameScreen(controller: controller)),
    );
    await tester.pump(const Duration(milliseconds: 250));

    final node = find.byKey(ValueKey('ore-node-${deposit.id}'));
    expect(node, findsOneWidget);
    for (var hit = 0; hit < deposit.hitPoints; hit++) {
      await tester.tap(node);
      await tester.pump(const Duration(milliseconds: 200));
      if (hit < deposit.hitPoints - 1) expect(node, findsOneWidget);
    }
    expect(node, findsNothing);
    expect(controller.state.amount('coal'), deposit.amount);
    expect(controller.state.oreDeposits[deposit.id]!.depleted, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('danışman ilk cevher görevini aldırıp ambarı açar', (
    tester,
  ) async {
    const size = Size(390, 844);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    final controller = _readyController(state: GameState.newGame(seed: 715));
    addTearDown(controller.dispose);
    final deposit = controller.state.oreDeposits['0:5:0']!;
    await tester.pumpWidget(
      MaterialApp(home: GameScreen(controller: controller)),
    );
    await tester.pump(const Duration(milliseconds: 250));

    await tester.tap(find.byKey(ValueKey('ore-node-${deposit.id}')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(controller.currentQuestReady, isTrue);
    expect(find.textContaining('1 / 5'), findsOneWidget);
    await tester.tap(find.text('AL'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(controller.currentQuest.id, 1);
    expect(find.textContaining('2 / 5'), findsOneWidget);
    await tester.tap(find.text('AÇ'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(BuildingDialog), findsOneWidget);
    expect(find.text('AMBAR'), findsWidgets);

    await tester.tap(find.text('KAPAT'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  for (final size in const [Size(390, 844), Size(800, 1180)]) {
    testWidgets('oyun ekranı ${size.width}x${size.height} düzenine sığar', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);

      final controller = _readyController();
      await tester.pumpWidget(
        MaterialApp(home: GameScreen(controller: controller)),
      );
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('KAZI'), findsNothing);
      expect(find.byKey(const ValueKey('goal-banner')), findsOneWidget);
      expect(find.textContaining('Matkap'), findsOneWidget);
      expect(find.textContaining('madenci'), findsOneWidget);
      expect(find.bySemanticsLabel('Maden katmanları'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.drag(
        find.bySemanticsLabel('Maden katmanları'),
        const Offset(0, -140),
      );
      await tester.pump();
      expect(find.byTooltip('Aktif derinliğe dön'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    });
  }
}

GameController _readyController({GameState? state}) {
  final controller = GameController();
  if (state != null) controller.state = state;
  controller.state
    ..musicEnabled = false
    ..soundEffectsEnabled = false;
  controller.isReady = true;
  return controller;
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
