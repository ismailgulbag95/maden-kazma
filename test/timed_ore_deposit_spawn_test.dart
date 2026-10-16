import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tasin_alti/domain/models/game_state.dart';
import 'package:tasin_alti/domain/models/mine_biome.dart';
import 'package:tasin_alti/domain/models/mr_mine_level_table.dart';
import 'package:tasin_alti/domain/models/ore_deposit.dart';
import 'package:tasin_alti/domain/models/resource_definition.dart';
import 'package:tasin_alti/domain/simulation/game_engine.dart';

void main() {
  GameState newMineState() => GameState(
    depthMeters: GameState.startingDepthMeters,
    deepestMeters: GameState.startingDepthMeters,
    crewCount: 0,
    worldDepths: {'0': GameState.startingDepthMeters},
    worldMinerCounts: {'0': 0},
  )..seed = 3471;

  test('three active minutes create one deposit, and a second interval adds one', () {
    final state = newMineState();

    GameEngine.advance(state, const Duration(seconds: 179));
    expect(state.oreDeposits, isEmpty);
    expect(state.oreDepositSpawnProgressSeconds, 179);

    GameEngine.advance(state, const Duration(seconds: 1));
    expect(
      state.oreDeposits,
      hasLength(1),
      reason:
          'progress=${state.oreDepositSpawnProgressSeconds}, depth=${state.depthMeters}, deepest=${state.deepestMeters}, world=${state.activeWorldIndex}',
    );
    expect(state.oreDepositSpawnProgressSeconds, 0);

    GameEngine.advance(state, const Duration(minutes: 3));
    expect(state.oreDeposits, hasLength(2));
    expect(state.oreDepositSpawnProgressSeconds, 0);
  });

  test('deposit resource and floor always match an already opened floor', () {
    final state = newMineState();

    GameEngine.advance(state, const Duration(minutes: 3));

    final deposit = state.oreDeposits.values.single;
    final worldStart = GameState.worldEntryDepths[deposit.worldIndex];
    final floorDepth =
        worldStart + deposit.floorIndex * GameEngine.mineFloorMeters;
    expect(floorDepth, lessThanOrEqualTo(state.deepestMeters));
    expect(deposit.side, inInclusiveRange(0, 1));
    expect(deposit.pocket, inInclusiveRange(0, 4));
    expect(
      MineBiome.containsMineral(deposit.spawnDepthMeters!, deposit.resourceId),
      isTrue,
    );
    expect(
      deposit.floorIndex,
      lessThanOrEqualTo(
        ((state.deepestMeters - worldStart) / GameEngine.mineFloorMeters)
            .floor(),
      ),
    );
  });

  test('a capped floor is skipped and an occupied slot is never reused', () {
    const maxDepth = 40000.0;
    const firstAllowedFloor = 26;
    const excludedUpperFloor = firstAllowedFloor - 1;
    final state = GameState(
      depthMeters: maxDepth,
      deepestMeters: maxDepth,
      crewCount: 0,
      cargoCapacity: 1,
      cargoUsed: 1,
      worldDepths: {'0': maxDepth},
      worldMinerCounts: {'0': 0},
    )..seed = 847;

    for (var floor = 0; floor <= 40; floor++) {
      final mineralId = MrMineLevelTable.rows[floor].keys.firstWhere(
        (id) => ResourceCatalog.byId[id]?.kind == ResourceKind.mineral,
      );
      final depositCount =
          floor == firstAllowedFloor || floor == excludedUpperFloor ? 3 : 4;
      for (var slot = 0; slot < depositCount; slot++) {
        final id = '0:$floor:$slot';
        state.oreDeposits[id] = OreDepositState(
          id: id,
          worldIndex: 0,
          floorIndex: floor,
          resourceId: mineralId,
          amount: 5,
          hitPoints: 5,
          side: slot % 2,
          pocket: slot ~/ 2,
          spawnDepthMeters: floor * GameEngine.mineFloorMeters.toDouble(),
        );
      }
    }

    GameEngine.advance(state, const Duration(minutes: 3));

    final depositsOnIncludedBoundary = state.oreDeposits.values
        .where((deposit) => deposit.floorIndex == firstAllowedFloor)
        .toList();
    expect(depositsOnIncludedBoundary, hasLength(4));
    expect(
      depositsOnIncludedBoundary
          .map((deposit) => '${deposit.side}:${deposit.pocket}')
          .toSet(),
      hasLength(4),
    );
    expect(
      state.oreDeposits.values
          .where((deposit) => deposit.worldIndex == 0 && !deposit.depleted)
          .where((deposit) => deposit.floorIndex == firstAllowedFloor)
          .length,
      GameEngine.maxLiveDepositsPerFloor,
    );
    expect(
      state.oreDeposits.values
          .where((deposit) => deposit.worldIndex == 0)
          .where((deposit) => deposit.floorIndex == excludedUpperFloor)
          .length,
      3,
      reason: 'The floor immediately above the bottom-15 window is excluded.',
    );
  });

  test('drill-roll deposits stay within the bottom 15 opened floors', () {
    const depth = 120000.0;
    const firstAllowedFloor = 106; // Floors 0 through 120 are open.
    final state = GameState(
      depthMeters: depth,
      deepestMeters: depth,
      crewCount: 0,
      worldDepths: {'0': depth},
      worldMinerCounts: {'0': 0},
    );
    final random = Random(611);

    for (var attempt = 0; attempt < 2000; attempt++) {
      GameEngine.rollForMineralDepositSpawn(
        state,
        random,
        metersAdvanced: 1,
        chancePerMeter: 1,
      );
    }

    final spawnedFloors = state.oreDeposits.values
        .map((deposit) => deposit.floorIndex)
        .toSet();
    expect(spawnedFloors, isNotEmpty);
    expect(
      spawnedFloors,
      everyElement(inInclusiveRange(firstAllowedFloor, 120)),
    );
    expect(spawnedFloors, contains(firstAllowedFloor));
    expect(spawnedFloors, contains(120));
  });

  test(
    'early tutorial starter veins remain when fewer than 15 floors are open',
    () {
      final state = GameState.newGame(seed: 71);

      GameEngine.ensureOpenMineDeposits(state);

      final starterVeins = state.oreDeposits.values.toList();
      expect(starterVeins, hasLength(4));
      expect(
        starterVeins.map((deposit) => deposit.resourceId),
        everyElement('coal'),
      );
      expect(
        starterVeins.map((deposit) => deposit.floorIndex),
        everyElement(inInclusiveRange(1, 5)),
      );
    },
  );

  test(
    'timer survives save/load and offline simulation does not advance it',
    () {
      final state = newMineState();
      GameEngine.advance(state, const Duration(seconds: 179));
      final saved = state.toJson();
      final offlineBranch = GameState.fromJson(saved);
      final saveLoadBranch = GameState.fromJson(saved);
      final uninterrupted = GameState.fromJson(saved);

      expect(saveLoadBranch.oreDepositSpawnProgressSeconds, 179);
      GameEngine.advance(
        offlineBranch,
        const Duration(hours: 1),
        allowRandomEvents: false,
      );
      expect(offlineBranch.oreDeposits, isEmpty);
      expect(offlineBranch.oreDepositSpawnProgressSeconds, 179);

      GameEngine.advance(saveLoadBranch, const Duration(seconds: 1));
      GameEngine.advance(uninterrupted, const Duration(seconds: 1));

      expect(saveLoadBranch.oreDeposits.keys, uninterrupted.oreDeposits.keys);
      final restoredDeposit = saveLoadBranch.oreDeposits.values.single;
      final uninterruptedDeposit = uninterrupted.oreDeposits.values.single;
      expect(restoredDeposit.toJson(), uninterruptedDeposit.toJson());
      expect(saveLoadBranch.seed, uninterrupted.seed);
      expect(saveLoadBranch.oreDepositSpawnProgressSeconds, 0);
      expect(uninterrupted.oreDepositSpawnProgressSeconds, 0);
    },
  );
}
