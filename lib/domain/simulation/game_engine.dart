import 'dart:math';

import '../models/game_state.dart';
import '../models/achievement_definition.dart';
import '../models/resource_definition.dart';
import '../models/gem_definition.dart';
import '../models/cave_route_definition.dart';
import '../models/upgrade_definition.dart';
import '../models/daily_challenge_definition.dart';
import '../models/mine_event_definition.dart';
import '../models/cave_exploration_definition.dart';
import '../models/special_worker_definition.dart';
import '../models/scientist_definition.dart';
import '../models/ore_deposit.dart';
import '../models/drill_assembly_definition.dart';
import '../models/mr_mine_progression.dart';
import '../models/reactor_definition.dart';
import '../models/buff_lab_definition.dart';

class GameTickResult {
  const GameTickResult({this.events = const [], this.mined = 0});

  final List<String> events;
  final int mined;
}

class BossDefinition {
  const BossDefinition({
    required this.id,
    required this.name,
    required this.depthMeters,
    required this.health,
    required this.reward,
    required this.spriteIndex,
  });

  final int id;
  final String name;
  final double depthMeters;
  final double health;
  final int reward;
  final int spriteIndex;
}

abstract final class GameEngine {
  static const maxAdvanceDuration = Duration(hours: 48);
  static const resonanceDuration = Duration(minutes: 5);
  static const mineEventMinimumDelaySeconds = 150;
  static const mineEventMaximumDelaySeconds = 300;
  static const oilPumpMaximumLevel = 50;
  static const oilPumpBaseStorage = 100;
  static const oilPumpStoragePerUpgrade = 150;
  static const oilPumpSaleValuePerBarrel = 500;

  static const List<BossDefinition> bosses = [
    BossDefinition(
      id: 0,
      name: 'Bazalt Yüreği',
      depthMeters: 400000,
      health: 36,
      reward: 2200,
      spriteIndex: 0,
    ),
    BossDefinition(
      id: 1,
      name: 'Kor Boynuz',
      depthMeters: 500000,
      health: 52,
      reward: 3800,
      spriteIndex: 1,
    ),
    BossDefinition(
      id: 2,
      name: 'Bakır Oyukçu',
      depthMeters: 600000,
      health: 70,
      reward: 5600,
      spriteIndex: 2,
    ),
    BossDefinition(
      id: 3,
      name: 'Yitik Maden Bekçisi',
      depthMeters: 710000,
      health: 96,
      reward: 7600,
      spriteIndex: 3,
    ),
    BossDefinition(
      id: 4,
      name: 'Kurşun Kabuklu',
      depthMeters: 850000,
      health: 132,
      reward: 10400,
      spriteIndex: 4,
    ),
    BossDefinition(
      id: 5,
      name: 'Gece Yarası',
      depthMeters: 980000,
      health: 176,
      reward: 14800,
      spriteIndex: 5,
    ),
    BossDefinition(
      id: 6,
      name: 'Ay Nöbetçisi',
      depthMeters: 1032000,
      health: 220,
      reward: 19000,
      spriteIndex: 0,
    ),
    BossDefinition(
      id: 7,
      name: 'Regolit Yılanı',
      depthMeters: 1320000,
      health: 292,
      reward: 26000,
      spriteIndex: 1,
    ),
    BossDefinition(
      id: 8,
      name: 'Gümüş Hâkim',
      depthMeters: 1550000,
      health: 375,
      reward: 34000,
      spriteIndex: 2,
    ),
    BossDefinition(
      id: 9,
      name: 'Buz Leviathanı',
      depthMeters: 1814000,
      health: 490,
      reward: 46000,
      spriteIndex: 3,
    ),
    BossDefinition(
      id: 10,
      name: 'Metan Dikenlisi',
      depthMeters: 1950000,
      health: 625,
      reward: 62000,
      spriteIndex: 4,
    ),
    BossDefinition(
      id: 11,
      name: 'Halkalı Arşivci',
      depthMeters: 2100000,
      health: 820,
      reward: 90000,
      spriteIndex: 5,
    ),
  ];

  static const Map<String, String> milestoneBuildings = {
    '10000': 'super_miners',
    '15000': 'trader',
    '45000': 'caves',
    '50000': 'scientists',
    '100000': 'chest_collector',
    '225000': 'repair_robot',
    '300000': 'underground_city',
    '303000': 'gem_forge',
    '305000': 'armory',
    '501000': 'deep_core',
    '700000': 'chest_compressor',
    '1032000': 'moon_world',
    '1047000': 'lunar_trader',
    '1133000': 'reactor',
    '1135000': 'buff_lab',
    '1257000': 'robot_mk2',
    '1814000': 'titan_world',
    '1829000': 'titan_trader',
    '2039000': 'robot_mk3',
  };

  static const Map<String, (String, int, int)> hiddenEncounters = {
    '50000': ('Kayıp Madenci Frekansı', 800, 0),
    '225000': ('Uykudaki Sondaj Robotu', 1600, 1),
    '700000': ('Sandık Sıkıştırıcı Oyuğu', 3200, 1),
    '1032000': ('Ay Gölge Krateri', 5200, 2),
    '1782000': ('Kayıp Uzay Sinyali', 8000, 0),
    '1814000': ('Titan Kristal Arşivi', 9500, 3),
  };

  static int upgradeCost(GameState state, String track) {
    if (track == 'reactor') {
      return reactorUpgradeEnergyCost(state.upgradeLevel('reactor') + 1);
    }
    return UpgradeCatalog.next(track, state.upgradeLevel(track))?.cost ?? 0;
  }

  static Duration maxOfflineFor(GameState state) =>
      switch (state.managerLevel) {
        1 => const Duration(hours: 12),
        2 => const Duration(hours: 24),
        3 => const Duration(hours: 48),
        _ => Duration.zero,
      };

  static double offlineRateMultiplier(GameState state) =>
      switch (state.managerLevel) {
        1 => .25,
        2 => .5,
        3 => 1,
        _ => 0,
      };

  static int managerRequiredDepth(int nextLevel) => switch (nextLevel) {
    1 => 100000,
    2 => 150000,
    _ => 300000,
  };

  static Map<String, int> managerUpgradeRequirements(int nextLevel) =>
      switch (nextLevel) {
        1 => {'building_material': 2, 'red_diamond': 100},
        2 => {'building_material': 10, 'blue_obsidian': 10},
        3 => {'building_material': 50, 'californium': 25, 'oil': 50},
        _ => const {},
      };

  static Map<String, int> managerUpgradeDeficits(GameState state) {
    final requirements = managerUpgradeRequirements(state.managerLevel + 1);
    return {
      for (final entry in requirements.entries)
        if (_unreserved(state, entry.key) < entry.value)
          entry.key: entry.value - _unreserved(state, entry.key),
    };
  }

  static bool upgradeManager(GameState state) {
    final nextLevel = state.managerLevel + 1;
    if (nextLevel > 3 ||
        state.deepestMeters < managerRequiredDepth(nextLevel) ||
        managerUpgradeDeficits(state).isNotEmpty) {
      return false;
    }
    for (final entry in managerUpgradeRequirements(nextLevel).entries) {
      _consumeResource(state, entry.key, entry.value);
    }
    state.managerLevel = nextLevel;
    return true;
  }

  static int drillAssemblyLevel(GameState state, String componentId) =>
      switch (componentId) {
        'bit' => state.drillBitLevel,
        'fan' => state.drillFanLevel,
        'engine' => state.drillEngineLevel,
        _ => 0,
      };

  static int drillAssemblyUpgradeCost(GameState state, String componentId) {
    final component = DrillAssemblyCatalog.byId[componentId];
    final currentLevel = drillAssemblyLevel(state, componentId);
    if (component == null ||
        currentLevel < 1 ||
        currentLevel >= DrillAssemblyCatalog.maxLevel) {
      return 0;
    }
    return DrillAssemblyCatalog.cashCost(component, currentLevel);
  }

  static Map<String, int> drillAssemblyMaterialRequirements(
    GameState state,
    String componentId,
  ) {
    if (!DrillAssemblyCatalog.byId.containsKey(componentId)) return const {};
    return DrillAssemblyCatalog.materialCosts(
      componentId,
      drillAssemblyLevel(state, componentId) + 1,
    );
  }

  static Map<String, int> drillAssemblyMaterialDeficits(
    GameState state,
    String componentId,
  ) {
    final requirements = drillAssemblyMaterialRequirements(state, componentId);
    return {
      for (final entry in requirements.entries)
        if (_unreserved(state, entry.key) < entry.value)
          entry.key: entry.value - _unreserved(state, entry.key),
    };
  }

  static bool upgradeDrillAssembly(GameState state, String componentId) {
    final currentLevel = drillAssemblyLevel(state, componentId);
    final nextLevel = currentLevel + 1;
    final cost = drillAssemblyUpgradeCost(state, componentId);
    if (!DrillAssemblyCatalog.byId.containsKey(componentId) ||
        currentLevel < 1 ||
        currentLevel >= DrillAssemblyCatalog.maxLevel ||
        state.crewCount <= 0 ||
        state.coins < cost) {
      return false;
    }
    if (state.deepestMeters <
        DrillAssemblyCatalog.requiredDepthFor(nextLevel)) {
      return false;
    }
    final requiredBuilding = DrillAssemblyCatalog.requiredBuildingFor(
      nextLevel,
    );
    if (requiredBuilding != null &&
        !state.unlockedBuildings.contains(requiredBuilding)) {
      return false;
    }
    if (drillAssemblyMaterialDeficits(state, componentId).isNotEmpty) {
      return false;
    }
    state.coins -= cost;
    for (final entry in drillAssemblyMaterialRequirements(
      state,
      componentId,
    ).entries) {
      _consumeResource(state, entry.key, entry.value);
    }
    if (componentId == 'bit') {
      state.drillBitLevel++;
    } else if (componentId == 'fan') {
      state.drillFanLevel++;
    } else if (componentId == 'engine') {
      state.drillEngineLevel++;
    } else {
      return false;
    }
    return true;
  }

  static int reactorLevel(GameState state) =>
      ReactorCatalog.gridLevel(state.upgradeLevel('reactor'));

  static int reactorUpgradeEnergyCost(int nextLevel) => switch (nextLevel) {
    2 => 20000,
    3 => 200000,
    4 => 750000,
    5 => 1500000,
    _ => 0,
  };

  static int oilPumpStorageCapacity(GameState state) =>
      oilPumpBaseStorage + (state.oilPumpLevel - 1) * oilPumpStoragePerUpgrade;

  static double oilPumpProductionPerSecond(GameState state) =>
      0.2 * pow(1.6, state.oilPumpLevel - 1);

  static int oilPumpUpgradeCost(GameState state) => state.oilPumpLevel * 10000;

  static int oilPumpStored(GameState state) {
    final earthInventory = state.currentWorldIndex == 0
        ? state.inventory
        : state.worldInventories['0'];
    return earthInventory?['oil'] ?? 0;
  }

  static int unreservedOil(GameState state) {
    final reserved = state.currentWorldIndex == 0
        ? state.reserve('oil')
        : state.worldReserves['0']?['oil'] ?? 0;
    return max(0, oilPumpStored(state) - reserved);
  }

  static bool upgradeOilPump(GameState state) {
    if (!state.unlockedBuildings.contains('underground_city') ||
        state.oilPumpLevel >= oilPumpMaximumLevel ||
        state.coins < oilPumpUpgradeCost(state)) {
      return false;
    }
    state.coins -= oilPumpUpgradeCost(state);
    state.oilPumpLevel++;
    return true;
  }

  static bool sellOil(GameState state) {
    if (!state.unlockedBuildings.contains('underground_city')) return false;
    final quantity = unreservedOil(state);
    if (quantity <= 0) return false;
    final earthInventory = state.currentWorldIndex == 0
        ? state.inventory
        : state.worldInventories.putIfAbsent('0', () => <String, int>{});
    earthInventory['oil'] = oilPumpStored(state) - quantity;
    state.coins = min(1e18, state.coins + quantity * oilPumpSaleValuePerBarrel);
    recordDailyProgress(state, 'sell', quantity);
    return true;
  }

  static Map<String, int> reactorUpgradeMaterialRequirements(int nextLevel) =>
      switch (nextLevel) {
        2 => {'building_material': 25, 'e1': 10},
        3 => {'building_material': 50, 'e1': 100},
        4 => {'building_material': 100, 'e2': 50},
        5 => {'building_material': 500, 'e3': 30},
        _ => const {},
      };

  static Map<String, int> reactorUpgradeMaterialDeficits(GameState state) {
    final requirements = reactorUpgradeMaterialRequirements(
      state.upgradeLevel('reactor') + 1,
    );
    return {
      for (final entry in requirements.entries)
        if (_unreserved(state, entry.key) < entry.value)
          entry.key: entry.value - _unreserved(state, entry.key),
    };
  }

  static bool canUpgradeReactor(GameState state) =>
      state.unlockedBuildings.contains('reactor') &&
      state.upgradeLevel('reactor') < 5 &&
      state.energy >=
          reactorUpgradeEnergyCost(state.upgradeLevel('reactor') + 1) &&
      reactorUpgradeMaterialDeficits(state).isEmpty;

  static bool upgradeReactor(GameState state) {
    if (!canUpgradeReactor(state)) return false;
    final nextLevel = state.upgradeLevel('reactor') + 1;
    state.energy -= reactorUpgradeEnergyCost(nextLevel);
    for (final entry in reactorUpgradeMaterialRequirements(nextLevel).entries) {
      _consumeResource(state, entry.key, entry.value);
    }
    state.upgrades['reactor'] = nextLevel;
    return true;
  }

  static double buffLabEnergyDrainPerSecond(GameState state) => state
      .activeBuffIds
      .map((id) => BuffLabCatalog.byId[id]?.energyDrainPerSecond ?? 0)
      .fold<double>(0, (total, drain) => total + drain);

  static bool setBuffLabActive(GameState state, String buffId, bool active) {
    final definition = BuffLabCatalog.byId[buffId];
    if (!state.unlockedBuildings.contains('buff_lab') || definition == null) {
      return false;
    }
    if (active) {
      if (state.energy < definition.energyDrainPerSecond) return false;
      state.activeBuffIds.add(buffId);
    } else {
      state.activeBuffIds.remove(buffId);
    }
    return true;
  }

  static int reactorHeatGenerated(GameState state) => state
      .reactorComponents
      .values
      .map((id) => ReactorCatalog.componentById[id]?.heatGenerated ?? 0)
      .fold(0, (total, heat) => total + heat);

  static int reactorHeatCooled(GameState state) => state
      .reactorComponents
      .values
      .map((id) => ReactorCatalog.componentById[id]?.heatCooled ?? 0)
      .fold(0, (total, heat) => total + heat);

  static int reactorEnergyPerSecond(GameState state) => state
      .reactorComponents
      .values
      .map((id) => ReactorCatalog.componentById[id]?.energyPerSecond ?? 0)
      .fold(0, (total, energy) => total + energy);

  static bool reactorIsThermallyStable(GameState state) =>
      reactorHeatGenerated(state) <= reactorHeatCooled(state);

  static bool setReactorComponent(
    GameState state,
    int x,
    int y,
    String componentId,
  ) {
    if (!state.unlockedBuildings.contains('reactor')) return false;
    final level = reactorLevel(state);
    if (!ReactorCatalog.containsCell(level, x, y)) return false;
    if (componentId != 'empty') {
      final component = ReactorCatalog.componentById[componentId];
      if (component == null || component.minimumLevel > level) return false;
      state.reactorComponents['$x,$y'] = componentId;
    } else {
      state.reactorComponents.remove('$x,$y');
    }
    if (!reactorIsThermallyStable(state)) state.reactorShutdown = true;
    return true;
  }

  static bool restartReactor(GameState state) {
    if (!state.unlockedBuildings.contains('reactor') ||
        !state.reactorShutdown ||
        !reactorIsThermallyStable(state)) {
      return false;
    }
    state.reactorShutdown = false;
    return true;
  }

  static bool synthesizeReactorIsotope(GameState state, String isotopeId) {
    final recipe = ReactorCatalog.isotopeById[isotopeId];
    final isotope = ResourceCatalog.byId[isotopeId];
    if (!state.unlockedBuildings.contains('reactor') ||
        recipe == null ||
        isotope == null ||
        state.deepestMeters < recipe.minimumDepthMeters ||
        state.energy < recipe.energyCost ||
        _availableUnits(state, isotope) <= 0) {
      return false;
    }
    state.energy -= recipe.energyCost;
    return _addResource(state, isotope, 1) == 1;
  }

  static Map<String, int> upgradeMaterialRequirements(
    GameState state,
    String track,
  ) => track == 'reactor'
      ? reactorUpgradeMaterialRequirements(state.upgradeLevel('reactor') + 1)
      : Map<String, int>.from(
          UpgradeCatalog.next(
                track,
                state.upgradeLevel(track),
              )?.materialCosts ??
              const <String, int>{},
        );

  static Map<String, int> upgradeMaterialDeficits(
    GameState state,
    String track,
  ) {
    final requirements = upgradeMaterialRequirements(state, track);
    return {
      for (final entry in requirements.entries)
        if (_unreserved(state, entry.key) < entry.value)
          entry.key: entry.value - _unreserved(state, entry.key),
    };
  }

  static const List<int> _sourceMinerHireCosts = [
    50,
    500,
    2000,
    10000,
    25000,
    75000,
    150000,
    500000,
    3000000,
    10000000,
  ];

  static int minerCost(GameState state) {
    final currentCrew = state.crewCount.clamp(0, 80).toInt();
    if (currentCrew < _sourceMinerHireCosts.length) {
      return _sourceMinerHireCosts[currentCrew];
    }
    return min(1e18, 10000000 * pow(2, currentCrew - 9)).round();
  }

  static const int mineFloorMeters = 1000;
  static const int mineDepositSpawnDepth = 100;
  static const double mineDepositSpawnChancePerMeter = .00045;
  static const int maxLiveDepositsPerFloor = 4;

  /// Gives a fresh surface shift its guaranteed coal tutorial deposit.
  /// Other deposits spawn as the drill advances; open floors stay empty until
  /// a random spawn lands in them.
  static void ensureOpenMineDeposits(GameState state) {
    state.oreDeposits.removeWhere((_, deposit) {
      if (deposit.depleted) return false;
      final spawnDepth =
          deposit.spawnDepthMeters ??
          deposit.floorIndex * mineFloorMeters.toDouble();
      final band = MrMineProgression.bandByResourceId[deposit.resourceId];
      return band == null ||
          band.worldIndex != deposit.worldIndex ||
          spawnDepth < band.firstDepthMeters ||
          MrMineProgression.worldAtDepth(spawnDepth) != deposit.worldIndex;
    });

    if (state.activeWorldIndex != 0 || state.depthMeters >= mineFloorMeters) {
      return;
    }
    if (state.oreDeposits.keys.any((id) => id.startsWith('0:0:'))) return;

    final random = Random(state.seed);
    _createMineDeposit(
      state,
      worldIndex: 0,
      floorIndex: 0,
      spawnDepth: 0,
      resource: ResourceCatalog.byId['coal']!,
      valuePerClick: 2,
      hitPoints: 5,
      random: random,
    );
    state.seed = random.nextInt(0x7fffffff);
  }

  /// Probabilistically spawns a mineral deposit while the drill advances.
  /// Resource weights favor the newest mineral unlocked at this depth, with
  /// older eligible minerals retaining a decreasing chance to appear.
  static bool rollForMineralDepositSpawn(
    GameState state,
    Random random, {
    required double metersAdvanced,
    double chancePerMeter = mineDepositSpawnChancePerMeter,
  }) {
    if (state.cargoFull ||
        state.depthMeters <= mineDepositSpawnDepth ||
        metersAdvanced <= 0) {
      return false;
    }
    if (MrMineProgression.worldAtDepth(state.depthMeters) !=
        state.activeWorldIndex) {
      return false;
    }
    final chance = chancePerMeter.clamp(0, 1).toDouble();
    final rollChance = 1 - pow(1 - chance, metersAdvanced);
    if (random.nextDouble() >= rollChance) return false;

    final worldIndex = state.activeWorldIndex
        .clamp(0, GameState.worldEntryDepths.length - 1)
        .toInt();
    final worldStart = GameState.worldEntryDepths[worldIndex];
    final lowerBound = max(worldStart, state.depthMeters - 100);
    final possibleDepths = max(1, (state.depthMeters - lowerBound).floor() + 1);
    final spawnDepth = max(
      worldStart,
      state.depthMeters - random.nextInt(possibleDepths),
    );
    final floorIndex = ((spawnDepth - worldStart) / mineFloorMeters).floor();
    final activeInFloor = state.oreDeposits.values
        .where(
          (deposit) =>
              deposit.worldIndex == worldIndex &&
              deposit.floorIndex == floorIndex &&
              !deposit.depleted,
        )
        .length;
    if (activeInFloor >= maxLiveDepositsPerFloor) return false;

    final resource = _weightedMineralAtDepth(worldIndex, spawnDepth, random);
    if (resource == null) return false;
    final localDepth = max(0, spawnDepth - worldStart);
    final abundanceBand = (localDepth / 10000).floor().clamp(0, 10);
    final targetPileValue = 20 + abundanceBand * 2;
    final valuePerClick = max(
      1,
      (targetPileValue / (resource.baseValue * 5)).round(),
    );
    return _createMineDeposit(
          state,
          worldIndex: worldIndex,
          floorIndex: floorIndex,
          spawnDepth: spawnDepth,
          resource: resource,
          valuePerClick: valuePerClick,
          hitPoints: 5,
          random: random,
        ) !=
        null;
  }

  static ResourceDefinition? _weightedMineralAtDepth(
    int worldIndex,
    double depth,
    Random random,
  ) {
    final worldStart = GameState.worldEntryDepths[worldIndex];
    final worldEnd = worldIndex + 1 < GameState.worldEntryDepths.length
        ? GameState.worldEntryDepths[worldIndex + 1]
        : double.infinity;
    if (MrMineProgression.worldAtDepth(depth) != worldIndex) return null;
    final eligible = MrMineProgression.minerals
        .where((band) => band.worldIndex == worldIndex)
        .where((band) => band.firstDepthMeters <= depth)
        .where((band) => band.firstDepthMeters >= worldStart)
        .where((band) => band.firstDepthMeters < worldEnd)
        .map((band) => (band, ResourceCatalog.byId[band.resourceId]))
        .where((entry) => entry.$2 != null)
        .toList(growable: false);
    if (eligible.isEmpty) return null;

    final weights = [
      for (var index = 0; index < eligible.length; index++)
        pow(.58, eligible.length - index - 1).toDouble() *
            (eligible[index].$1.worldIndex < 2 &&
                    eligible[index].$1.isRichAt(depth)
                ? 4
                : 1),
    ];
    final totalWeight = weights.fold<double>(0, (sum, weight) => sum + weight);
    var choice = random.nextDouble() * totalWeight;
    for (var index = 0; index < eligible.length; index++) {
      choice -= weights[index];
      if (choice < 0) return eligible[index].$2;
    }
    return eligible.last.$2;
  }

  static OreDepositState? _createMineDeposit(
    GameState state, {
    required int worldIndex,
    required int floorIndex,
    required double spawnDepth,
    required ResourceDefinition resource,
    required int valuePerClick,
    required int hitPoints,
    required Random random,
  }) {
    final activePositions = state.oreDeposits.values
        .where(
          (deposit) =>
              deposit.worldIndex == worldIndex &&
              deposit.floorIndex == floorIndex &&
              !deposit.depleted,
        )
        .map((deposit) => deposit.side * 5 + deposit.pocket)
        .toSet();
    final availablePositions = [
      for (var position = 1; position <= 10; position++)
        if (!activePositions.contains(
          (position - 1) % 2 * 5 + (position - 1) ~/ 2,
        ))
          position,
    ];
    if (availablePositions.isEmpty) return null;
    final position =
        availablePositions[random.nextInt(availablePositions.length)];
    final slot = position - 1;
    final prefix = '$worldIndex:$floorIndex:';
    var nextIndex = 0;
    for (final id in state.oreDeposits.keys.where(
      (id) => id.startsWith(prefix),
    )) {
      final parsed = int.tryParse(id.substring(prefix.length));
      if (parsed != null) nextIndex = max(nextIndex, parsed + 1);
    }
    final id = '$prefix$nextIndex';
    final deposit = OreDepositState(
      id: id,
      worldIndex: worldIndex,
      floorIndex: floorIndex,
      resourceId: resource.id,
      amount: valuePerClick * hitPoints,
      hitPoints: hitPoints,
      side: slot % 2,
      pocket: slot ~/ 2,
      spawnDepthMeters: spawnDepth,
    );
    state.oreDeposits[id] = deposit;
    return deposit;
  }

  static int chestCollectorUpgradeCost(GameState state) =>
      (900 * pow(1.7, state.chestCollectorLevel)).round();

  static int chestCompressorUpgradeCost(GameState state) =>
      (1400 * pow(1.72, state.chestCompressionLevel)).round();

  static const List<int> chestCompressionBasicCosts = [
    15,
    14,
    12,
    10,
    9,
    8,
    7,
    6,
  ];
  static const List<int> chestCompressionGoldCosts = [6, 6, 5, 5, 4, 4, 3, 3];

  static int chestCompressionBasicCost(GameState state) =>
      chestCompressionBasicCosts[state.chestCompressionLevel.clamp(
        0,
        chestCompressionBasicCosts.length - 1,
      )];

  static int chestCompressionGoldCost(GameState state) =>
      chestCompressionGoldCosts[state.chestCompressionLevel.clamp(
        0,
        chestCompressionGoldCosts.length - 1,
      )];

  static String dailyChallengeKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static String weeklyChallengeKey(DateTime date) {
    final monday = DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(Duration(days: date.weekday - DateTime.monday));
    return dailyChallengeKey(monday);
  }

  static void prepareChallengeWindows(GameState state, DateTime now) {
    final dayKey = dailyChallengeKey(now);
    if (state.dailyChallengeDate != dayKey ||
        state.dailyChallengeIds.length != DailyChallengeCatalog.dailyCount) {
      state.dailyChallengeDate = dayKey;
      state.dailyChallengeIds
        ..clear()
        ..addAll(DailyChallengeCatalog.idsForDate(dayKey));
      state.dailyChallengeProgress
        ..clear()
        ..addEntries(state.dailyChallengeIds.map((id) => MapEntry(id, 0)));
      state.claimedDailyChallengeIds.clear();
    }
    final weekKey = weeklyChallengeKey(now);
    if (state.weeklyChallengeKey != weekKey) {
      state.weeklyChallengeKey = weekKey;
      state.weeklyChallengeProgress = 0;
      state.weeklyChallengeClaimed = false;
    }
  }

  static void recordDailyProgress(
    GameState state,
    String kind,
    int amount, {
    DateTime? now,
  }) {
    if (amount <= 0) return;
    prepareChallengeWindows(state, now ?? DateTime.now());
    for (final id in state.dailyChallengeIds) {
      final challenge = DailyChallengeCatalog.byId[id];
      if (challenge == null || challenge.kind != kind) continue;
      state.dailyChallengeProgress[id] =
          ((state.dailyChallengeProgress[id] ?? 0) + amount)
              .clamp(0, challenge.target)
              .toInt();
    }
  }

  static bool claimDailyChallenge(
    GameState state,
    String challengeId, {
    DateTime? now,
  }) {
    prepareChallengeWindows(state, now ?? DateTime.now());
    final challenge = DailyChallengeCatalog.byId[challengeId];
    if (challenge == null ||
        !state.dailyChallengeIds.contains(challengeId) ||
        state.claimedDailyChallengeIds.contains(challengeId) ||
        (state.dailyChallengeProgress[challengeId] ?? 0) < challenge.target) {
      return false;
    }
    state.claimedDailyChallengeIds.add(challengeId);
    state.coins += challenge.rewardCoins;
    state.weeklyChallengeProgress = (state.weeklyChallengeProgress + 1)
        .clamp(0, DailyChallengeCatalog.weeklyTarget)
        .toInt();
    return true;
  }

  static bool claimWeeklyChallenge(GameState state, {DateTime? now}) {
    prepareChallengeWindows(state, now ?? DateTime.now());
    if (state.weeklyChallengeClaimed ||
        state.weeklyChallengeProgress < DailyChallengeCatalog.weeklyTarget) {
      return false;
    }
    state.weeklyChallengeClaimed = true;
    state.coins += DailyChallengeCatalog.weeklyRewardCoins;
    state.coreShards += DailyChallengeCatalog.weeklyRewardCoreShards;
    return true;
  }

  static bool resolveMineEvent(GameState state) {
    final eventId = state.activeMineEventId;
    if (eventId == null || !MineEventCatalog.byId.containsKey(eventId)) {
      return false;
    }
    final stage = (state.depthMeters / 100000).floor().clamp(0, 49) + 1;
    switch (eventId) {
      case 'gold_rush':
        state.coins += 550 * stage;
        break;
      case 'collapsed_tunnel':
        state.pressure = (state.pressure - 14).clamp(0, 100).toDouble();
        _addWorldChest(state);
        state.inventory['building_material'] =
            state.amount('building_material') + 1;
        break;
      case 'rich_vein':
        final resource = ResourceCatalog.mineableAtDepth(state.depthMeters);
        if (resource == null) {
          state.coins += 500;
        } else {
          final added = _addResource(state, resource, 3);
          if (added <= 0) return false;
          state.totalMined += added;
          recordDailyProgress(state, 'mine', added);
        }
        break;
      case 'lost_explorer':
        state.inventory['building_material'] =
            state.amount('building_material') + 2;
        state.drillParts++;
        break;
      case 'merchant':
        state.coins += 260 * stage;
        state.drillParts++;
        break;
      case 'ancient_chamber':
        _addWorldChest(state);
        state.coreShards++;
        break;
      case 'monster_nest':
        state.coins += 240 * stage;
        state.drillParts += 2;
        break;
      default:
        return false;
    }
    state.activeMineEventId = null;
    final random = Random(state.seed ^ state.miningSeconds ^ eventId.hashCode);
    state.nextMineEventAtSeconds =
        state.miningSeconds +
        mineEventMinimumDelaySeconds +
        random.nextInt(
          mineEventMaximumDelaySeconds - mineEventMinimumDelaySeconds + 1,
        );
    state.seed = random.nextInt(0x7fffffff);
    recordDailyProgress(state, 'event', 1);
    return true;
  }

  static void _addWorldChest(GameState state) {
    switch (state.currentWorldIndex) {
      case 0:
        state.chestsFound++;
        break;
      case 1:
        state.goldChests++;
        break;
      case 2:
        state.deepChests++;
        break;
    }
  }

  static int specialistCost(GameState state, String role) =>
      (420 * pow(1.7, state.specialists[role] ?? 0)).round();

  static int scientistSacrificeReward(ScientistState scientist) {
    final rarityIndex = ScientistRarityCatalog.all.indexWhere(
      (rarity) => rarity.id == scientist.rarityId,
    );
    return 1 + max(0, rarityIndex).toInt() + (scientist.level - 1) ~/ 20;
  }

  static bool sacrificeScientistToCore(GameState state, String scientistId) {
    if (!state.unlockedBuildings.contains('deep_core') ||
        state.deepestMeters < 501000 ||
        state.activeScientistId == scientistId) {
      return false;
    }
    final index = state.scientistRoster.indexWhere(
      (scientist) => scientist.id == scientistId && !scientist.dead,
    );
    if (index < 0) return false;
    final scientist = state.scientistRoster.removeAt(index);
    state.coreShards += scientistSacrificeReward(scientist);
    state.scientistsSacrificedToCore++;
    state.scientists = state.livingScientistCount;
    return true;
  }

  static int scientistCost(GameState state) =>
      (420 * pow(1.55, state.scientistRoster.length)).round();

  static bool hireScientist(GameState state) {
    if (!state.unlockedBuildings.contains('scientists') ||
        state.scientistRoster.length >= 8 ||
        state.coins < scientistCost(state)) {
      return false;
    }
    state.coins -= scientistCost(state);
    addScientist(state);
    return true;
  }

  static bool addScientist(GameState state) {
    if (state.scientistRoster.length >= 8) return false;
    final random = Random(state.seed ^ state.scientistRoster.length ^ 0x5c13);
    var serial = state.scientistRoster.length + 1;
    while (state.scientistRoster.any(
      (scientist) => scientist.id == 'scientist_$serial',
    )) {
      serial++;
    }
    state.scientistRoster.add(ScientistState.create(serial, random));
    state.scientists = state.livingScientistCount;
    state.seed = random.nextInt(0x7fffffff);
    return true;
  }

  static bool reviveScientist(GameState state, String scientistId) {
    final scientist = state.scientistById(scientistId);
    if (scientist == null || !scientist.dead || state.revivalTokens <= 0) {
      return false;
    }
    state.revivalTokens--;
    scientist
      ..dead = false
      ..injuryCount = 0
      ..injuredUntil = null;
    state.scientists = state.livingScientistCount;
    return true;
  }

  static double scientistMissionSuccessChance(
    ScientistState scientist,
    ScientistExpeditionDefinition mission,
  ) => (mission.baseSuccessChance + scientist.successChanceBonus)
      .clamp(.25, .99)
      .toDouble();

  static Duration scientistMissionDuration(
    ScientistState scientist,
    ScientistExpeditionDefinition mission,
  ) => Duration(
    seconds: max(
      60,
      (mission.duration.inSeconds *
              (1 - scientist.excavationSpeed).clamp(.35, 1))
          .round(),
    ),
  );

  static bool startScientistExpedition(
    GameState state,
    String scientistId,
    String missionId,
    DateTime now,
  ) {
    final scientist = state.scientistById(scientistId);
    final mission = ScientistExpeditionCatalog.byId[missionId];
    if (scientist == null ||
        mission == null ||
        scientist.dead ||
        scientist.injured ||
        state.activeScientistId != null ||
        state.excavationReadyAt != null ||
        state.excavationCompletedPending ||
        state.deepestMeters < mission.minimumDepth) {
      return false;
    }
    final random = Random(
      state.seed ^
          scientist.id.hashCode ^
          mission.id.hashCode ^
          state.miningSeconds,
    );
    final roll = random.nextDouble();
    final chance = scientistMissionSuccessChance(scientist, mission);
    state.scientistExpeditionOutcome = roll < chance
        ? 'success'
        : roll < chance + .08
        ? 'partial'
        : 'injury';
    state.activeScientistId = scientist.id;
    state.activeScientistMissionId = mission.id;
    state.scientistExpeditionReadyAt = now.add(
      scientistMissionDuration(scientist, mission),
    );
    state.seed = random.nextInt(0x7fffffff);
    return true;
  }

  static bool claimScientistExpedition(GameState state, DateTime now) {
    final readyAt = state.scientistExpeditionReadyAt;
    final scientist = state.scientistById(state.activeScientistId);
    final mission =
        ScientistExpeditionCatalog.byId[state.activeScientistMissionId];
    final outcome = state.scientistExpeditionOutcome;
    if (readyAt == null ||
        readyAt.isAfter(now) ||
        scientist == null ||
        mission == null ||
        outcome == null) {
      return false;
    }

    final isSuccess = outcome == 'success';
    final isPartial = outcome == 'partial';
    final ore = ResourceCatalog.mineableAtDepth(
      max(state.depthMeters, mission.minimumDepth),
    );
    final resourceCount = ore == null
        ? 0
        : isSuccess
        ? (mission.resourceCount * (1 + scientist.trait.mineralBonus)).round()
        : isPartial
        ? max(1, mission.resourceCount ~/ 3)
        : 0;
    if (ore != null && resourceCount > _availableUnits(state, ore)) {
      return false;
    }

    if (isSuccess || isPartial) {
      final reward = isSuccess ? mission.coinReward : mission.coinReward ~/ 3;
      state.coins += reward;
      if (ore != null) _addResource(state, ore, resourceCount);
      if (isSuccess) {
        switch (mission.chestTier) {
          case 'gold':
            state.goldChests++;
            break;
          case 'deep':
            state.deepChests++;
            break;
          default:
            state.chestsFound++;
        }
        final random = Random(
          state.seed ^ state.chestsOpened ^ scientist.id.hashCode ^ 0xe71e,
        );
        final relicChance = (mission.relicChance + scientist.trait.relicBonus)
            .clamp(0, .95);
        if (random.nextDouble() < relicChance) {
          _awardRandomRelic(state, random);
        }
        if (mission.chestTier == 'deep' && random.nextInt(12) == 0) {
          state.revivalTokens++;
        }
        if (random.nextInt(4) == 0) state.workerScrap++;
        state.seed = random.nextInt(0x7fffffff);
      }
    } else {
      scientist.injuryCount++;
      if (scientist.injuryCount >= 2) {
        scientist
          ..dead = true
          ..injuredUntil = null;
      } else {
        final injuryDuration = switch (mission.id) {
          'titan_archive' => const Duration(hours: 1),
          'ancient_excavation' => const Duration(minutes: 30),
          _ => const Duration(minutes: 10),
        };
        scientist.injuredUntil = now.add(injuryDuration);
      }
      state.scientists = state.livingScientistCount;
    }
    scientist.experience += isSuccess
        ? 100
        : isPartial
        ? 55
        : 35;
    while (scientist.level < 50 &&
        scientist.experience >= scientist.level * 100) {
      scientist.experience -= scientist.level * 100;
      scientist.level++;
    }
    state.activeScientistId = null;
    state.activeScientistMissionId = null;
    state.scientistExpeditionReadyAt = null;
    state.scientistExpeditionOutcome = null;
    return true;
  }

  static int specialWorkerCost(GameState state) =>
      900 + state.specialWorkerRoster.length * 720;

  static SpecialWorkerState? specialWorkerById(GameState state, String id) {
    for (final worker in state.specialWorkerRoster) {
      if (worker.id == id) return worker;
    }
    return null;
  }

  static bool hireSpecialWorker(GameState state) {
    final cost = specialWorkerCost(state);
    if (!state.unlockedBuildings.contains('super_miners') ||
        state.specialWorkerRoster.length >= 12 ||
        state.coins < cost) {
      return false;
    }
    state.coins -= cost;
    final random = Random(
      state.seed ^ state.specialWorkerRoster.length ^ 0x5e11,
    );
    var serial = state.specialWorkerRoster.length + 1;
    while (state.specialWorkerRoster.any(
      (worker) => worker.id == 'super_worker_$serial',
    )) {
      serial++;
    }
    final worker = SpecialWorkerState.create(serial, random)
      ..assignedWorld = state.activeWorldIndex
      ..assignedFloor = state.activeDepthFloor;
    state.specialWorkerRoster.add(worker);
    state.seed = random.nextInt(0x7fffffff);
    return true;
  }

  static bool dismantleSpecialWorker(GameState state, String workerId) {
    final worker = specialWorkerById(state, workerId);
    if (worker == null) return false;
    state.specialWorkerRoster.remove(worker);
    state.workerScrap += worker.rarity.scrapValue;
    return true;
  }

  static int specialWorkerUpgradeCost(SpecialWorkerState worker) =>
      worker.level >= 20 ? 0 : worker.level + 2;

  static bool upgradeSpecialWorker(GameState state, String workerId) {
    final worker = specialWorkerById(state, workerId);
    if (worker == null) return false;
    final cost = specialWorkerUpgradeCost(worker);
    if (cost == 0 || state.workerScrap < cost) return false;
    state.workerScrap -= cost;
    worker.level++;
    worker.experience = 0;
    return true;
  }

  static bool moveSpecialWorker(
    GameState state,
    String workerId,
    int world,
    int floor,
  ) {
    if (world < 0 || world > 2 || floor < 0 || floor > 30) return false;
    final worker = specialWorkerById(state, workerId);
    if (worker == null) return false;
    final startFloor = (GameState.worldEntryDepths[world] / 100000).floor();
    final endDepth = world < 2
        ? min(state.deepestMeters, GameState.worldEntryDepths[world + 1] - 1)
        : state.deepestMeters;
    if (endDepth < GameState.worldEntryDepths[world] ||
        floor < startFloor ||
        floor > (endDepth / 100000).floor()) {
      return false;
    }
    worker.assignedWorld = world;
    worker.assignedFloor = floor;
    worker.autoMove = false;
    return true;
  }

  static bool setSpecialWorkerAutoMove(
    GameState state,
    String workerId,
    bool autoMove,
  ) {
    final worker = specialWorkerById(state, workerId);
    if (worker == null) return false;
    worker.autoMove = autoMove;
    return true;
  }

  static void _moveRoamingSpecialWorkers(GameState state, Random random) {
    final openPositions = <(int, int)>[];
    for (var world = 0; world < GameState.worldEntryDepths.length; world++) {
      final entryDepth = GameState.worldEntryDepths[world];
      if (state.deepestMeters < entryDepth) continue;
      final lastDepth = world < 2
          ? min(state.deepestMeters, GameState.worldEntryDepths[world + 1] - 1)
          : state.deepestMeters;
      final firstFloor = (entryDepth / 100000).floor();
      final lastFloor = (lastDepth / 100000).floor();
      for (var floor = firstFloor; floor <= lastFloor; floor++) {
        openPositions.add((world, floor));
      }
    }
    if (openPositions.isEmpty) return;
    for (final worker in state.specialWorkerRoster.where(
      (item) => item.autoMove,
    )) {
      final position = openPositions[random.nextInt(openPositions.length)];
      worker
        ..assignedWorld = position.$1
        ..assignedFloor = position.$2;
    }
  }

  static int _specialWorkerAutoSell(GameState state) {
    final sellers = state.specialWorkerRoster
        .where(
          (worker) =>
              worker.abilityId == 'auto_seller' &&
              worker.assignedWorld == state.activeWorldIndex &&
              worker.assignedFloor == state.activeDepthFloor,
        )
        .toList();
    if (sellers.isEmpty) return 0;
    final resources = <ResourceDefinition>[
      ...ResourceCatalog.minerals,
      ...ResourceCatalog.isotopes,
    ]..sort((a, b) => a.baseValue.compareTo(b.baseValue));
    var total = 0;
    for (final worker in sellers) {
      for (final resource in resources) {
        final available = _unreserved(state, resource.id);
        if (available <= 0 || state.lockedResources.contains(resource.id)) {
          continue;
        }
        total += sellResource(
          state,
          resource.id,
          requested: min(available, max(1, worker.power.ceil())),
        );
        break;
      }
    }
    return total;
  }

  static bool hireSpecialist(GameState state, String role) {
    const roles = {'geologist', 'engineer', 'scout', 'guardian'};
    if (!roles.contains(role) ||
        !state.unlockedBuildings.contains('super_miners') ||
        (state.specialists[role] ?? 0) >= 3) {
      return false;
    }
    final cost = specialistCost(state, role);
    if (state.coins < cost) return false;
    state.coins -= cost;
    state.specialists[role] = (state.specialists[role] ?? 0) + 1;
    return true;
  }

  static List<AchievementDefinition> checkAchievements(GameState state) {
    final earned = <AchievementDefinition>[];
    for (final achievement in AchievementCatalog.all) {
      if (state.unlockedAchievements.contains(achievement.id)) continue;
      final progress = switch (achievement.kind) {
        'mine' => state.totalMined,
        'depth' || 'world' => state.deepestMeters.floor(),
        'crew' => state.crewCount,
        'sale' => state.totalSold.floor(),
        'chest' => state.chestsOpened,
        'cave' => state.cavesCompleted,
        'relic' => state.relicsFound,
        'boss' => state.bossesDefeated,
        'resonance' => state.resonanceChains,
        'prestige' => state.prestigeCount,
        _ => 0,
      };
      if (progress >= achievement.target) {
        state.unlockedAchievements.add(achievement.id);
        state.coins += achievement.reward;
        earned.add(achievement);
      }
    }
    return earned;
  }

  static GameTickResult advance(
    GameState state,
    Duration elapsed, {
    DateTime? now,
    bool allowRandomEvents = true,
  }) {
    final currentTime = now ?? DateTime.now();
    prepareChallengeWindows(state, currentTime);
    final requestedSeconds = elapsed.inSeconds.clamp(
      0,
      maxAdvanceDuration.inSeconds,
    );
    if (requestedSeconds <= 0) return const GameTickResult();

    final events = <String>[];
    var mined = 0;
    var lastNoticeDepth = state.deepestMeters;
    final random = Random(state.seed);
    for (var second = 0; second < requestedSeconds; second++) {
      state.miningSeconds++;
      if (state.miningSeconds % 300 == 0) {
        _moveRoamingSpecialWorkers(state, random);
      }
      if (state.miningSeconds % 60 == 0) {
        _specialWorkerAutoSell(state);
      }
      if (state.miningSeconds % 300 == 0) {
        if (state.activeSpecialWorkerPower('buff_generator') > 0) {
          final buffUntil = currentTime.add(const Duration(seconds: 75));
          if (state.resonanceBuffUntil == null ||
              state.resonanceBuffUntil!.isBefore(buffUntil)) {
            state.resonanceBuffUntil = buffUntil;
            events.add('Kristal şamanı kısa süreli sondaj rezonansı başlattı.');
          }
        }
      }
      if (!state.cargoFull) {
        final previousDepth = state.depthMeters;
        final drillDistance = state.drillRateMetersPerSecond;
        state.depthMeters += drillDistance;
        rollForMineralDepositSpawn(
          state,
          random,
          metersAdvanced: drillDistance,
        );
        final metersAdvanced = (state.depthMeters - previousDepth).floor();
        if (metersAdvanced > 0) {
          recordDailyProgress(state, 'depth', metersAdvanced, now: currentTime);
        }
        state.deepestMeters = max(state.deepestMeters, state.depthMeters);
        final relicPressureResistance = state.equippedRelics.contains('relic_6')
            ? 1 - (0.4 + state.relicLevel('relic_6') * 0.1)
            : 1.0;
        final workerPressureResistance = max(
          .55,
          1 - state.activeSpecialWorkerPower('support') * .07,
        );
        state.pressure =
            (state.pressure +
                    state.drillRateMetersPerSecond *
                        0.00045 *
                        relicPressureResistance *
                        workerPressureResistance)
                .clamp(0, 100)
                .toDouble();
        final diggingWorkers = state.diggingWorkers;
        final workerEfficiency = 1 + state.upgradeLevel('workers') * 0.03;
        final specialMiningSpeed =
            1 + state.activeSpecialWorkerPower('miner_booster') * .22;
        final miningInterval = max(
          1,
          (4 / (workerEfficiency * specialMiningSpeed)).ceil(),
        );
        if (diggingWorkers > 0 && state.miningSeconds % miningInterval == 0) {
          final worldIndex = state.activeWorldIndex;
          final worldStart = GameState.worldEntryDepths[worldIndex];
          final localDeepest = max(0.0, state.depthMeters - worldStart);
          final openFloorCount = (localDeepest / mineFloorMeters).floor() + 1;
          final isotopeBonus =
              (state.equippedRelics.contains('relic_5')
                  ? 12 * state.relicLevel('relic_5')
                  : 0) +
              (state.equippedGems.contains('amethyst') ? 25 : 0) +
              (state.specialists['geologist'] ?? 0) * 8 +
              state.scannerWorkers * 4 +
              (state.activeSpecialWorkerPower('rare_drop_booster') * 18)
                  .round();
          final resourceWorkerPower = state.activeSpecialWorkerPower(
            'resource_booster',
          );
          final chestOdds = max(
            200,
            1700 -
                state.scannerWorkers * 90 -
                (state.activeSpecialWorkerPower('chest_hunter') * 210).round() -
                (state.equippedRelics.contains('relic_9')
                    ? state.relicLevel('relic_9') * 120
                    : 0),
          );

          // Each open kilometer has its own hired-worker slots and yields its
          // depth-eligible minerals into the same cargo hold.
          for (
            var floorIndex = 0;
            floorIndex < openFloorCount && !state.cargoFull;
            floorIndex++
          ) {
            final floorDepth = worldStart + floorIndex * mineFloorMeters;
            if (MrMineProgression.worldAtDepth(floorDepth) != worldIndex) {
              continue;
            }
            final minerals = MrMineProgression.minerals
                .where((band) => band.worldIndex == worldIndex)
                .where((band) => band.firstDepthMeters <= floorDepth)
                .map((band) => ResourceCatalog.byId[band.resourceId])
                .whereType<ResourceDefinition>()
                .toList(growable: false);
            if (minerals.isEmpty) continue;
            final ore = minerals[random.nextInt(minerals.length)];
            final oreYieldMultiplier =
                state.activeBuffIds.contains('buff_resonance')
                ? BuffLabCatalog.oreYieldMultiplier.round()
                : 1;
            final oreAdded = _addResource(
              state,
              ore,
              diggingWorkers * oreYieldMultiplier,
            );
            state.totalMined += oreAdded;
            mined += oreAdded;
            if (oreAdded > 0) {
              recordDailyProgress(state, 'mine', oreAdded, now: currentTime);
            }
            if (oreAdded > 0 &&
                resourceWorkerPower > 0 &&
                random.nextInt(100) <
                    min(75, (resourceWorkerPower * 28).round())) {
              final extraOre = _addResource(state, ore, 1);
              state.totalMined += extraOre;
              mined += extraOre;
              recordDailyProgress(state, 'mine', extraOre, now: currentTime);
            }

            final isotopes = ResourceCatalog.isotopes
                .where(
                  (resource) => MrMineProgression.isotopeAvailableAtDepth(
                    resource.id,
                    worldIndex,
                    floorDepth,
                  ),
                )
                .where(
                  (resource) =>
                      !ReactorCatalog.isotopeById.containsKey(resource.id),
                )
                .toList(growable: false);
            if (oreAdded > 0 &&
                isotopes.isNotEmpty &&
                random.nextInt(1000) <
                    min(
                      150,
                      6 + state.upgradeLevel('scanner') * 3 + isotopeBonus,
                    )) {
              final isotope = isotopes[random.nextInt(isotopes.length)];
              _addResource(state, isotope, 1);
            }
            if (oreAdded > 0 && random.nextInt(chestOdds) == 0) {
              state.chestsFound++;
              events.add(
                'Eski sandık bulundu! Tüccar binasından ganimetini al.',
              );
            }
          }
        }
      }

      _advanceReactor(state, events);
      _advanceBuffLab(state, events);
      _advanceOilPump(state);
      if (state.unlockedBuildings.contains('chest_collector') &&
          state.miningSeconds % 1800 == 0) {
        if (state.collectorStoredChests < state.chestCollectorCapacity) {
          state.collectorStoredChests++;
          events.add(
            'Otomatik toplayıcı sandık buldu (${state.collectorStoredChests}/${state.chestCollectorCapacity}).',
          );
        } else {
          events.add('Sandık toplayıcının deposu dolu. Sandıkları teslim al.');
        }
      }
      _completeTimedActivities(state, currentTime, events, random);
      _advanceGemCrafting(state, events);
      _unlockMilestones(state, events);
      _autoSellToThreshold(state);

      if (allowRandomEvents &&
          state.activeMineEventId == null &&
          state.miningSeconds >= state.nextMineEventAtSeconds) {
        final event =
            MineEventCatalog.all[random.nextInt(MineEventCatalog.all.length)];
        state.activeMineEventId = event.id;
        events.add('Maden olayı: ${event.title} kuyuda belirdi.');
      }

      if (state.deepestMeters - lastNoticeDepth >= 1000) {
        lastNoticeDepth = state.deepestMeters;
      }
    }
    if (!allowRandomEvents &&
        state.activeMineEventId == null &&
        state.nextMineEventAtSeconds <= state.miningSeconds) {
      state.nextMineEventAtSeconds =
          state.miningSeconds +
          mineEventMinimumDelaySeconds +
          random.nextInt(
            mineEventMaximumDelaySeconds - mineEventMinimumDelaySeconds + 1,
          );
    }
    state.seed = random.nextInt(0x7fffffff);
    ensureOpenMineDeposits(state);
    return GameTickResult(events: events, mined: mined);
  }

  static bool switchWorld(GameState state, int worldIndex) {
    if (worldIndex < 0 || worldIndex >= GameState.worldEntryDepths.length) {
      return false;
    }
    if (worldIndex == state.currentWorldIndex) return true;
    final entryDepth = GameState.worldEntryDepths[worldIndex];
    if (state.deepestMeters < entryDepth) return false;

    state.storeActiveWorldSnapshot();
    final key = worldIndex.toString();
    state.worldDepths.putIfAbsent(key, () => entryDepth);
    state.worldPressures.putIfAbsent(key, () => 14);
    state.worldCargoUsed.putIfAbsent(key, () => 0);
    state.worldInventories.putIfAbsent(key, () => {'coal': 0, 'copper': 0});
    state.worldReserves.putIfAbsent(key, () => <String, int>{});

    state.activeWorldIndex = worldIndex;
    state.depthMeters = state.worldDepths[key]!
        .clamp(entryDepth, state.deepestMeters)
        .toDouble();
    state.pressure = state.worldPressures[key]!.clamp(0, 100).toDouble();
    state.inventory
      ..clear()
      ..addAll(state.worldInventories[key]!);
    state.reserves
      ..clear()
      ..addAll(state.worldReserves[key]!);
    state.cargoUsed = state.worldCargoUsed[key]!
        .clamp(0, state.effectiveCargoCapacity)
        .toDouble();
    ensureOpenMineDeposits(state);
    return true;
  }

  static bool tapOre(GameState state, String resourceId, {DateTime? now}) {
    ensureOpenMineDeposits(state);
    final worldIndex = state.activeWorldIndex;
    final worldStart = GameState.worldEntryDepths[worldIndex];
    final activeFloor =
        ((state.depthMeters - worldStart).clamp(0, double.infinity) /
                mineFloorMeters)
            .floor();
    var deposit = state.oreDeposits.values
        .where(
          (item) =>
              item.worldIndex == worldIndex &&
              item.floorIndex == activeFloor &&
              item.resourceId == resourceId &&
              !item.depleted,
        )
        .firstOrNull;
    return deposit != null && tapMineDeposit(state, deposit.id, now: now);
  }

  static bool tapMineDeposit(
    GameState state,
    String depositId, {
    DateTime? now,
  }) {
    if (state.cargoFull) return false;
    final deposit = state.oreDeposits[depositId];
    if (deposit == null || deposit.depleted) return false;
    final resource = ResourceCatalog.byId[deposit.resourceId];
    if (resource == null || resource.kind != ResourceKind.mineral) return false;
    final worldStart = GameState.worldEntryDepths[deposit.worldIndex];
    final floorDepth = worldStart + deposit.floorIndex * mineFloorMeters;
    if (floorDepth > state.depthMeters ||
        (deposit.spawnDepthMeters != null &&
            resource.minDepthMeters > deposit.spawnDepthMeters!) ||
        resource.minDepthMeters > state.depthMeters) {
      return false;
    }
    final yield = nextMineDepositYield(state, deposit);
    if (yield <= 0 || _availableUnits(state, resource) < yield) {
      return false;
    }

    deposit.damage = min(
      deposit.hitPoints,
      deposit.damage + 1 + state.upgradeLevel('drill') ~/ 12,
    ).toInt();
    recordDailyProgress(state, 'tap', 1, now: now);
    tapResonance(state, resource.id, now: now ?? DateTime.now());
    final added = _addResource(state, resource, yield);
    state.totalMined += added;
    recordDailyProgress(state, 'mine', added, now: now);
    state.tutorialStep = max(state.tutorialStep, 1);
    _unlockMilestones(state, []);
    return true;
  }

  /// Resource granted by the next successful hit on a saved ore deposit.
  static int nextMineDepositYield(GameState state, OreDepositState deposit) {
    if (deposit.depleted) return 0;
    final damagePerTap = 1 + state.upgradeLevel('drill') ~/ 12;
    final nextDamage = min(deposit.hitPoints, deposit.damage + damagePerTap);
    final alreadyCollected =
        deposit.amount * deposit.damage ~/ deposit.hitPoints;
    final collectedAfterHit = deposit.amount * nextDamage ~/ deposit.hitPoints;
    return collectedAfterHit - alreadyCollected;
  }

  /// The KAZI button advances the active drill without awarding ore.
  static bool manualDig(GameState state, {DateTime? now}) {
    if (state.cargoFull) return false;
    final drillLevel = state.upgradeLevel('drill');
    final distance = 1 + drillLevel ~/ 5;
    state.depthMeters += distance;
    state.deepestMeters = max(state.deepestMeters, state.depthMeters);
    final random = Random(state.seed);
    rollForMineralDepositSpawn(
      state,
      random,
      metersAdvanced: distance.toDouble(),
    );
    state.seed = random.nextInt(0x7fffffff);
    recordDailyProgress(state, 'depth', distance, now: now);
    if (state.tutorialStep == 4) state.tutorialStep = 5;
    _unlockMilestones(state, []);
    ensureOpenMineDeposits(state);
    return true;
  }

  static bool buyUpgrade(GameState state, String track) {
    if (track == 'reactor') return upgradeReactor(state);
    final nextLevel = UpgradeCatalog.next(track, state.upgradeLevel(track));
    if (nextLevel == null) return false;
    if (track == 'drill' && state.crewCount <= 0) return false;
    if (track == 'reactor' && !state.unlockedBuildings.contains('reactor')) {
      return false;
    }
    final cost = nextLevel.cost;
    if (state.coins < cost) return false;
    if (upgradeMaterialDeficits(state, track).isNotEmpty) return false;
    state.coins -= cost;
    for (final entry in nextLevel.materialCosts.entries) {
      _consumeResource(state, entry.key, entry.value);
    }
    state.upgrades[track] = nextLevel.level;
    if (track == 'warehouse') {
      final added = 10 + nextLevel.level * 5;
      state.cargoCapacity += added;
    }
    if (track == 'lift') state.cargoCapacity += 2 + nextLevel.level;
    if (track == 'weapon') state.drillParts += 1;
    state.tutorialStep = max(state.tutorialStep, 4);
    recordDailyProgress(state, 'upgrade', 1);
    return true;
  }

  static bool assignWorkerRole(GameState state, String role, int delta) {
    if (!const {'transport', 'scanner', 'sorting'}.contains(role) ||
        (delta != -1 && delta != 1)) {
      return false;
    }
    final current = state.workerAssignments[role] ?? 0;
    if (delta > 0) {
      final targetIndex = state.workerRolePriority.indexOf(role);
      final lowerPriorityRoles = state.workerRolePriority
          .take(targetIndex)
          .toList();
      String? donor;
      for (final candidate in lowerPriorityRoles) {
        final available = candidate == 'digging'
            ? state.diggingWorkers
            : state.workerAssignments[candidate] ?? 0;
        if (available > 0) {
          donor = candidate;
          break;
        }
      }
      if (donor == null) return false;
      if (donor != 'digging') {
        state.workerAssignments[donor] =
            (state.workerAssignments[donor] ?? 0) - 1;
      }
      state.workerAssignments[role] = current + 1;
    } else {
      if (current <= 0) return false;
      state.workerAssignments[role] = current - 1;
    }
    return true;
  }

  static bool setWorkerRolePriority(
    GameState state,
    String role,
    int position,
  ) {
    final current = state.workerRolePriority.indexOf(role);
    if (current < 0 ||
        position < 0 ||
        position >= state.workerRolePriority.length) {
      return false;
    }
    state.workerRolePriority.removeAt(current);
    state.workerRolePriority.insert(position, role);
    return true;
  }

  static bool hireMiner(GameState state) {
    final cost = minerCost(state);
    if (state.coins < cost ||
        state.crewCount >= 80 ||
        (state.crewCount == 0 && state.totalSold <= 0)) {
      return false;
    }
    state.coins -= cost;
    state.crewCount++;
    state.tutorialStep = max(state.tutorialStep, 3);
    recordDailyProgress(state, 'hire', 1);
    return true;
  }

  static bool refineBuildingMaterial(GameState state) {
    if (state.upgradeLevel('foundry') < 1 ||
        _unreserved(state, 'copper') < 5 ||
        _unreserved(state, 'coal') < 10) {
      return false;
    }
    _consumeResource(state, 'copper', 5);
    _consumeResource(state, 'coal', 10);
    state.inventory['building_material'] =
        state.amount('building_material') + 2;
    return true;
  }

  static bool refineOil(GameState state) {
    if (!state.unlockedBuildings.contains('underground_city') ||
        state.currentWorldIndex != 0 ||
        state.amount('oil') < 5) {
      return false;
    }
    state.inventory['oil'] = state.amount('oil') - 5;
    state.inventory['building_material'] =
        state.amount('building_material') + 2;
    return true;
  }

  static bool startGemCraft(GameState state, String gemId) {
    final gem = GemCatalog.byId[gemId];
    if (gem == null ||
        !state.unlockedBuildings.contains('gem_forge') ||
        state.gemCraftRemainingSeconds.containsKey(gemId) ||
        (state.gemWorkload[gemId] ?? 0) <= 0) {
      return false;
    }
    for (final entry in gem.recipe.entries) {
      if (_unreserved(state, entry.key) < entry.value) return false;
    }
    for (final entry in gem.recipe.entries) {
      _consumeResource(state, entry.key, entry.value);
    }
    state.gemCraftRemainingSeconds[gemId] = gem.craftSeconds.toDouble();
    return true;
  }

  static void adjustGemWorkload(GameState state, String gemId, int delta) {
    if (!GemCatalog.byId.containsKey(gemId) || delta == 0) return;
    final current = state.gemWorkload[gemId] ?? 0;
    final target = (current + delta).clamp(0, 100).toInt();
    final amountToMove = (target - current).abs();
    if (amountToMove == 0) return;
    state.gemWorkload[gemId] = target;
    var remaining = amountToMove;
    final others = GemCatalog.all
        .where((gem) => gem.id != gemId)
        .map((gem) => gem.id)
        .toList();
    if (delta > 0) {
      for (final otherId in others.reversed) {
        final available = state.gemWorkload[otherId] ?? 0;
        final moved = min(available, remaining);
        state.gemWorkload[otherId] = available - moved;
        remaining -= moved;
        if (remaining == 0) break;
      }
      if (remaining > 0) state.gemWorkload[gemId] = target - remaining;
    } else {
      final recipient = others.first;
      state.gemWorkload[recipient] =
          (state.gemWorkload[recipient] ?? 0) + remaining;
    }
  }

  static bool toggleGemEquipment(GameState state, String gemId) {
    if ((state.gems[gemId] ?? 0) <= 0 || !GemCatalog.byId.containsKey(gemId)) {
      return false;
    }
    if (!state.equippedGems.add(gemId)) {
      state.equippedGems.remove(gemId);
      return true;
    }
    if (state.equippedGems.length > 3) {
      state.equippedGems.remove(gemId);
      return false;
    }
    return true;
  }

  static void _advanceGemCrafting(GameState state, List<String> events) {
    for (final entry in state.gemCraftRemainingSeconds.entries.toList()) {
      final workload = (state.gemWorkload[entry.key] ?? 0) / 100;
      final remaining = entry.value - workload;
      if (remaining > 0) {
        state.gemCraftRemainingSeconds[entry.key] = remaining;
      } else {
        state.gemCraftRemainingSeconds.remove(entry.key);
        state.gems[entry.key] = (state.gems[entry.key] ?? 0) + 1;
        events.add('${GemCatalog.byId[entry.key]!.name} dövüldü.');
      }
    }
  }

  static bool forgeDrillPart(GameState state) {
    if (state.upgradeLevel('foundry') < 2 ||
        _unreserved(state, 'iron') < 4 ||
        _unreserved(state, 'copper') < 3 ||
        state.amount('building_material') < 1) {
      return false;
    }
    _consumeResource(state, 'iron', 4);
    _consumeResource(state, 'copper', 3);
    state.inventory['building_material'] =
        state.amount('building_material') - 1;
    state.drillParts++;
    return true;
  }

  static int _unreserved(GameState state, String id) =>
      max(0, state.amount(id) - state.reserve(id));

  static void _consumeResource(GameState state, String id, int amount) {
    final resource = ResourceCatalog.byId[id];
    if (resource == null) return;
    state.inventory[id] = max(0, state.amount(id) - amount);
    state.cargoUsed = max(
      0,
      state.cargoUsed - amount * resource.weight,
    ).toDouble();
  }

  static int sellResource(
    GameState state,
    String resourceId, {
    int? requested,
  }) {
    final resource = ResourceCatalog.byId[resourceId];
    if (resource == null ||
        state.lockedResources.contains(resourceId) ||
        (resource.kind != ResourceKind.mineral &&
            resource.kind != ResourceKind.isotope)) {
      return 0;
    }
    final available = max(
      0,
      state.amount(resourceId) - state.reserve(resourceId),
    );
    final quantity = min(available, requested ?? available);
    if (quantity <= 0) return 0;
    state.inventory[resourceId] = state.amount(resourceId) - quantity;
    state.cargoUsed = max(
      0,
      state.cargoUsed - quantity * resource.weight,
    ).toDouble();
    final relicSaleBonus = state.equippedRelics.contains('relic_2')
        ? 1 + .15 * state.relicLevel('relic_2')
        : 1.0;
    final gemSaleBonus = state.equippedGems.contains('ruby') ? 1.08 : 1.0;
    final sortingBonus = 1 + min(1, state.sortingWorkers * 0.02);
    final saleBonus = relicSaleBonus * gemSaleBonus * sortingBonus;
    final value = (quantity * resource.baseValue * saleBonus).round();
    state.coins += value;
    state.totalSold += value;
    state.tutorialStep = max(state.tutorialStep, 2);
    recordDailyProgress(state, 'sell', value);
    return value;
  }

  static int sellAll(GameState state) {
    var total = 0;
    for (final id in state.inventory.keys.toList()) {
      total += sellResource(state, id);
    }
    return total;
  }

  static int sellFraction(GameState state, double fraction) {
    if (fraction <= 0 || fraction > 1) return 0;
    var total = 0;
    for (final id in state.inventory.keys.toList()) {
      final resource = ResourceCatalog.byId[id];
      if (resource == null ||
          (resource.kind != ResourceKind.mineral &&
              resource.kind != ResourceKind.isotope)) {
        continue;
      }
      final available = _unreserved(state, id);
      if (available <= 0 || state.lockedResources.contains(id)) continue;
      final quantity = (available * fraction)
          .round()
          .clamp(1, available)
          .toInt();
      total += sellResource(state, id, requested: quantity);
    }
    return total;
  }

  static void toggleReserve(GameState state, String resourceId) {
    final old = state.reserve(resourceId);
    state.reserves[resourceId] = old > 0
        ? 0
        : min(10, state.amount(resourceId));
  }

  static void toggleResourceLock(GameState state, String resourceId) {
    if (!ResourceCatalog.byId.containsKey(resourceId)) return;
    if (!state.lockedResources.add(resourceId)) {
      state.lockedResources.remove(resourceId);
    }
  }

  static void setAutoSellThreshold(GameState state, double threshold) {
    state.autoSellThreshold = GameState.autoSellThresholdChoices.reduce(
      (closest, choice) =>
          (choice - threshold).abs() < (closest - threshold).abs()
          ? choice
          : closest,
    );
  }

  static int _autoSellToThreshold(GameState state) {
    if (!state.autoSellEnabled ||
        state.cargoUsed <=
            state.effectiveCargoCapacity * state.autoSellThreshold) {
      return 0;
    }
    final target = state.effectiveCargoCapacity * state.autoSellThreshold;
    final candidates = [
      ...ResourceCatalog.minerals,
      ...ResourceCatalog.isotopes,
    ]..sort((a, b) => a.baseValue.compareTo(b.baseValue));
    var total = 0;
    for (final resource in candidates) {
      if (state.cargoUsed <= target) break;
      if (state.lockedResources.contains(resource.id)) continue;
      final available = _unreserved(state, resource.id);
      if (available <= 0) continue;
      final weight = resource.weight < 1 ? 1 : resource.weight;
      final unitsNeeded = ((state.cargoUsed - target) / weight)
          .ceil()
          .clamp(1, available)
          .toInt();
      total += sellResource(state, resource.id, requested: unitsNeeded);
    }
    return total;
  }

  static int openChest(GameState state) => openChestTier(state, 'basic');

  static int openChestTier(GameState state, String tier) {
    final count = switch (tier) {
      'basic' => state.chestsFound,
      'gold' => state.goldChests,
      'deep' => state.deepChests,
      _ => 0,
    };
    if (count <= 0) return 0;
    final ore = ResourceCatalog.mineableAtDepth(state.depthMeters);
    final freeUnits = ore == null ? 0 : _availableUnits(state, ore);
    final unitsRequired = tier == 'deep'
        ? 6
        : tier == 'gold'
        ? 4
        : 1;
    if (ore != null && freeUnits < unitsRequired) return 0;
    final tierSeed = switch (tier) {
      'gold' => 0x601d,
      'deep' => 0xdee9,
      _ => 0xba51c,
    };
    final random = Random(state.seed ^ (state.chestsOpened + 1) ^ tierSeed);
    final oreBase = switch (tier) {
      'gold' => 6,
      'deep' => 12,
      _ => 2,
    };
    final oreAmount = ore == null
        ? 0
        : min(oreBase + random.nextInt(4), freeUnits);
    switch (tier) {
      case 'basic':
        state.chestsFound--;
        break;
      case 'gold':
        state.goldChests--;
        break;
      case 'deep':
        state.deepChests--;
        break;
    }
    state.chestsOpened++;
    state.seed = random.nextInt(0x7fffffff);
    final reward = switch (tier) {
      'gold' => 400 + random.nextInt(400) + state.chestsOpened * 12,
      'deep' => 1500 + random.nextInt(1500) + state.chestsOpened * 20,
      _ => 90 + random.nextInt(240) + state.chestsOpened * 8,
    };
    state.coins += reward;
    if (ore != null && oreAmount > 0) _addResource(state, ore, oreAmount);
    if (random.nextInt(
          tier == 'deep'
              ? 2
              : tier == 'gold'
              ? 3
              : 5,
        ) ==
        0) {
      state.drillParts += tier == 'deep'
          ? 3
          : tier == 'gold'
          ? 2
          : 1;
    }
    if (tier != 'basic' && random.nextInt(tier == 'deep' ? 2 : 4) == 0) {
      state.relicScrap++;
    }
    if (tier != 'basic' && random.nextInt(tier == 'deep' ? 3 : 9) == 0) {
      state.workerScrap++;
    }
    final revivalOdds = switch (tier) {
      'deep' => 10,
      'gold' => 48,
      _ => 0,
    };
    if (revivalOdds > 0 && random.nextInt(revivalOdds) == 0) {
      state.revivalTokens++;
    }
    final relicChance = switch (tier) {
      'deep' => 2,
      'gold' => 3,
      _ => 9,
    };
    if (random.nextInt(relicChance) == 0) _awardRandomRelic(state, random);
    return reward;
  }

  static void _awardRandomRelic(GameState state, Random random) {
    final relicId = 'relic_${random.nextInt(12) + 1}';
    recordRelicFound(state, relicId);
  }

  static void recordRelicFound(GameState state, String relicId) {
    if (!RegExp(r'^relic_(?:[1-9]|1[0-2])$').hasMatch(relicId)) return;
    state.relicsFound++;
    if (state.unlockedRelics.add(relicId)) {
      state.relicLevels.putIfAbsent(relicId, () => 1);
    } else {
      state.relicDuplicates[relicId] =
          (state.relicDuplicates[relicId] ?? 0) + 1;
    }
  }

  static int relicUpgradeCost(GameState state, String relicId) =>
      state.unlockedRelics.contains(relicId) && state.relicLevel(relicId) < 5
      ? state.relicLevel(relicId) * 3
      : 0;

  static bool dismantleRelicDuplicate(GameState state, String relicId) {
    final duplicateCount = state.relicDuplicates[relicId] ?? 0;
    if (duplicateCount <= 0 || !state.unlockedRelics.contains(relicId)) {
      return false;
    }
    state.relicDuplicates[relicId] = duplicateCount - 1;
    state.relicScrap++;
    return true;
  }

  static bool upgradeRelic(GameState state, String relicId) {
    final cost = relicUpgradeCost(state, relicId);
    if (cost <= 0 || state.relicScrap < cost) return false;
    state.relicScrap -= cost;
    state.relicLevels[relicId] = state.relicLevel(relicId) + 1;
    return true;
  }

  static bool claimCollectedChests(GameState state) {
    if (!state.unlockedBuildings.contains('chest_collector') ||
        state.collectorStoredChests <= 0) {
      return false;
    }
    state.chestsFound += state.collectorStoredChests;
    state.collectorStoredChests = 0;
    return true;
  }

  static bool upgradeChestCollector(GameState state) {
    if (!state.unlockedBuildings.contains('chest_collector') ||
        state.chestCollectorLevel >= 10) {
      return false;
    }
    final cost = chestCollectorUpgradeCost(state);
    if (state.coins < cost) return false;
    state.coins -= cost;
    state.chestCollectorLevel++;
    return true;
  }

  static bool startChestCompression(
    GameState state,
    String outputTier, {
    DateTime? now,
  }) {
    if (!state.unlockedBuildings.contains('chest_compressor') ||
        (outputTier != 'gold' && outputTier != 'deep') ||
        state.chestCompressionQueue.length >= state.chestCompressionSlots) {
      return false;
    }
    if (outputTier == 'gold') {
      final cost = chestCompressionBasicCost(state);
      if (state.chestsFound < cost) return false;
      state.chestsFound -= cost;
    } else {
      final cost = chestCompressionGoldCost(state);
      if (state.goldChests < cost) return false;
      state.goldChests -= cost;
    }
    state.chestCompressionQueue.add(outputTier);
    if (state.chestCompressionReadyAt == null) {
      _startNextChestCompression(state, now ?? DateTime.now());
    }
    return true;
  }

  static bool upgradeChestCompressor(GameState state) {
    if (!state.unlockedBuildings.contains('chest_compressor') ||
        state.chestCompressionLevel >= 9) {
      return false;
    }
    final cost = chestCompressorUpgradeCost(state);
    if (state.coins < cost) return false;
    state.coins -= cost;
    state.chestCompressionLevel++;
    return true;
  }

  static int chestCompressionSecondsLeft(GameState state, DateTime now) {
    final readyAt = state.chestCompressionReadyAt;
    if (readyAt == null || !readyAt.isAfter(now)) return 0;
    return readyAt.difference(now).inSeconds;
  }

  static void _startNextChestCompression(GameState state, DateTime startedAt) {
    if (state.chestCompressionQueue.isEmpty) {
      state.chestCompressionReadyAt = null;
      return;
    }
    final outputTier = state.chestCompressionQueue.first;
    final baseSeconds = outputTier == 'gold' ? 5 * 60 : 20 * 60;
    final speedMultiplier = 1 + state.chestCompressionLevel * 0.18;
    final duration = max(60, (baseSeconds / speedMultiplier).round());
    state.chestCompressionReadyAt = startedAt.add(Duration(seconds: duration));
  }

  static void _completeChestCompression(
    GameState state,
    DateTime now,
    List<String> events,
  ) {
    final readyAt = state.chestCompressionReadyAt;
    if (readyAt == null || readyAt.isAfter(now)) return;
    if (state.chestCompressionQueue.isEmpty) {
      state.chestCompressionReadyAt = null;
      return;
    }
    final result = state.chestCompressionQueue.removeAt(0);
    if (result == 'gold') {
      state.goldChests++;
      events.add('Sandık sıkıştırıcı bir altın sandık üretti.');
    } else {
      state.deepChests++;
      events.add('Sandık sıkıştırıcı bir derin sandık üretti.');
    }
    state.chestCompressionReadyAt = null;
    if (state.chestCompressionQueue.isNotEmpty) {
      _startNextChestCompression(state, readyAt);
    }
  }

  static bool startCaveExpedition(GameState state, DateTime now) {
    if (state.deepestMeters < 45000 ||
        state.caveReadyAt?.isAfter(now) == true) {
      return false;
    }
    if (state.caveReadyAt != null ||
        state.caveCompletedPending ||
        state.caveExploring) {
      return false;
    }
    if (state.drones <= 0) return false;
    final drone = CaveDroneCatalog.byId[state.caveDroneType]!;
    state.caveDroneCount = state.caveDroneCount.clamp(1, state.drones).toInt();
    state.caveTripsStarted++;
    state.pendingCaveLoot.clear();
    state.caveNodeMap
      ..clear()
      ..addAll(
        _generateCaveMap(state, Random(state.seed ^ state.caveTripsStarted)),
      );
    state.cavePathLanes.clear();
    state.caveExploring = true;
    state.caveStep = 0;
    state.cavePreviousLane = 1;
    state.caveDroneHealth = drone.health + (state.caveDroneCount - 1) * 14;
    state.caveDroneFuel = drone.fuel + (drone.speed >= 1.3 ? 1 : 0);
    state.caveCompletedPending = false;
    return true;
  }

  static List<List<String>> _generateCaveMap(GameState state, Random random) {
    final route = state.caveRoute;
    final rows = <List<String>>[];
    const common = [
      'mineral',
      'money',
      'material',
      'health',
      'chest',
      'buff',
      'rare',
      'scientist',
    ];
    for (var row = 0; row < 4; row++) {
      final rowNodes = <String>[];
      for (var lane = 0; lane < 3; lane++) {
        final pool = <String>[...common];
        final hazardRolls = route == 'deep'
            ? 3
            : route == 'safe'
            ? 1
            : 2;
        final hazards = [
          'boulder',
          'mud',
          'radiation',
          if (state.deepestMeters >= 300000) 'lava',
        ];
        for (var i = 0; i < hazardRolls; i++) {
          pool.add(hazards[random.nextInt(hazards.length)]);
        }
        if (row == 3 && lane == 1) pool.add('rare');
        rowNodes.add(pool[random.nextInt(pool.length)]);
      }
      rows.add(rowNodes);
    }
    return rows;
  }

  static bool selectCaveDrone(GameState state, String droneId) {
    if (state.caveExploring ||
        state.caveCompletedPending ||
        !CaveDroneCatalog.byId.containsKey(droneId)) {
      return false;
    }
    state.caveDroneType = droneId;
    return true;
  }

  static bool chooseCaveNode(GameState state, int lane, {DateTime? now}) {
    if (!state.caveExploring ||
        lane < 0 ||
        lane > 2 ||
        state.caveStep >= state.caveNodeMap.length) {
      return false;
    }
    final drone = CaveDroneCatalog.byId[state.caveDroneType]!;
    if ((lane - state.cavePreviousLane).abs() > (1 + drone.collectionRange)) {
      return false;
    }
    final nodeId = state.caveNodeMap[state.caveStep][lane];
    final random = Random(
      state.seed ^ state.caveTripsStarted ^ (state.caveStep << 8) ^ lane,
    );
    _resolveCaveNode(state, nodeId, random, now ?? DateTime.now());
    state.cavePreviousLane = lane;
    state.cavePathLanes.add(lane);
    state.caveStep++;
    final nodeFuelCost = switch (nodeId) {
      'boulder' => 1,
      'mud' when state.caveDroneType == 'ground' => 1,
      _ => 0,
    };
    state.caveDroneFuel = max(0, state.caveDroneFuel - 1 - nodeFuelCost);
    if (state.caveDroneType == 'healer') {
      state.caveDroneHealth = min(
        drone.health + (state.caveDroneCount - 1) * 14,
        state.caveDroneHealth + 7,
      );
    }
    state.seed = random.nextInt(0x7fffffff);
    if (state.caveStep >= state.caveNodeMap.length ||
        state.caveDroneHealth <= 0 ||
        state.caveDroneFuel <= 0) {
      state.caveExploring = false;
      state.caveCompletedPending = true;
    }
    return true;
  }

  static bool retreatCave(GameState state) {
    if (!state.caveExploring || state.caveStep <= 0) return false;
    state.caveExploring = false;
    state.caveCompletedPending = true;
    return true;
  }

  static void _resolveCaveNode(
    GameState state,
    String nodeId,
    Random random,
    DateTime now,
  ) {
    void addLoot(String id, int count) {
      state.pendingCaveLoot[id] = (state.pendingCaveLoot[id] ?? 0) + count;
    }

    final routeMultiplier =
        CaveRouteCatalog.byId[state.caveRoute]!.lootMultiplier *
        (1 +
            (state.equippedRelics.contains('relic_3')
                ? .25 * state.relicLevel('relic_3')
                : 0) +
            (state.specialists['scout'] ?? 0) * .1) *
        (1 + (state.caveDroneCount - 1) * .35 + state.expeditionLevel * .025);
    switch (nodeId) {
      case 'mineral':
        final ore = ResourceCatalog.mineableAtDepth(state.depthMeters);
        if (ore == null) {
          addLoot('cave_coins', max(1, (120 * routeMultiplier).round()));
        } else {
          addLoot(
            ore.id,
            max(1, ((2 + random.nextInt(3)) * routeMultiplier).round()),
          );
        }
        break;
      case 'money':
        addLoot(
          'cave_coins',
          max(1, ((90 + random.nextInt(211)) * routeMultiplier).round()),
        );
        break;
      case 'chest':
        addLoot('cave_chest', 1);
        break;
      case 'material':
        addLoot(
          'building_material',
          max(1, ((1 + random.nextInt(2)) * routeMultiplier).round()),
        );
        break;
      case 'buff':
        addLoot('cave_buff', 1);
        break;
      case 'rare':
        if (random.nextInt(4) == 0) {
          state.coreShards++;
        } else {
          addLoot('relic_${random.nextInt(12) + 1}', 1);
        }
        break;
      case 'health':
        state.caveDroneHealth = min(
          CaveDroneCatalog.byId[state.caveDroneType]!.health +
              (state.caveDroneCount - 1) * 14,
          state.caveDroneHealth + 28,
        );
        break;
      case 'scientist':
        if (state.scientistRoster.length < 8) {
          addLoot('cave_scientist', 1);
        } else {
          addLoot('cave_coins', 450);
        }
        break;
      case 'hazard':
      case 'radiation':
      case 'lava':
        if (!state.activeBuffIds.contains('buff_shield') &&
            !(nodeId == 'lava' && state.caveDroneType != 'ground')) {
          final drone = CaveDroneCatalog.byId[state.caveDroneType]!;
          final baseDamage = switch (nodeId) {
            'radiation' => 10,
            'lava' => 15,
            _ =>
              state.caveRoute == 'safe'
                  ? 10 + random.nextInt(11)
                  : 19 + random.nextInt(18),
          };
          final damage = (baseDamage / drone.speed).round();
          state.caveDroneHealth = max(0, state.caveDroneHealth - damage);
        }
        break;
      case 'boulder':
      case 'mud':
        break;
    }
    if (state.caveDroneType == 'healer' &&
        nodeId == 'hazard' &&
        !state.activeBuffIds.contains('buff_shield')) {
      state.caveDroneHealth = max(0, state.caveDroneHealth - 6);
    }
    if (nodeId == 'buff') {
      final until = now.add(const Duration(seconds: 90));
      if (state.resonanceBuffUntil == null ||
          state.resonanceBuffUntil!.isBefore(until)) {
        state.resonanceBuffUntil = until;
      }
    }
  }

  static bool selectCaveRoute(GameState state, String routeId) {
    if (state.caveReadyAt != null ||
        state.caveCompletedPending ||
        state.caveExploring ||
        !CaveRouteCatalog.byId.containsKey(routeId)) {
      return false;
    }
    state.caveRoute = routeId;
    return true;
  }

  static bool setCaveDroneCount(GameState state, int count) {
    if (state.caveReadyAt != null ||
        state.caveCompletedPending ||
        state.caveExploring ||
        count < 1 ||
        count > state.drones) {
      return false;
    }
    state.caveDroneCount = count;
    return true;
  }

  static bool claimCaveExpedition(GameState state, DateTime now) {
    final exploringClaim =
        state.caveNodeMap.isNotEmpty &&
        state.caveCompletedPending &&
        !state.caveExploring;
    final legacyClaim =
        state.caveReadyAt != null &&
        !state.caveReadyAt!.isAfter(now) &&
        state.caveCompletedPending;
    if (!exploringClaim && !legacyClaim) {
      return false;
    }
    if (state.pendingCaveLoot.isEmpty && legacyClaim) {
      _generateCaveLoot(state, Random(state.seed ^ state.caveTripsStarted));
    }
    if (!_fitsLoot(state, state.pendingCaveLoot)) return false;
    state.caveReadyAt = null;
    state.caveCompletedPending = false;
    for (final entry in state.pendingCaveLoot.entries) {
      final definition = ResourceCatalog.byId[entry.key];
      if (definition != null) {
        _addResource(state, definition, entry.value);
      } else if (entry.key == 'cave_coins') {
        state.coins += entry.value;
      } else if (entry.key == 'cave_chest') {
        for (var count = 0; count < entry.value; count++) {
          _addWorldChest(state);
        }
      } else if (entry.key == 'cave_scientist') {
        if (!addScientist(state)) state.coins += entry.value * 450;
      } else if (entry.key == 'cave_buff') {
        final until = now.add(const Duration(seconds: 90));
        if (state.resonanceBuffUntil == null ||
            state.resonanceBuffUntil!.isBefore(until)) {
          state.resonanceBuffUntil = until;
        }
      } else if (entry.key.startsWith('relic_') &&
          RegExp(r'^relic_(?:[1-9]|1[0-2])$').hasMatch(entry.key)) {
        recordRelicFound(state, entry.key);
      }
    }
    state.coins += 80 + state.expeditionLevel * 25;
    state.cavesCompleted++;
    state.pendingCaveLoot.clear();
    state.caveNodeMap.clear();
    state.cavePathLanes.clear();
    state.caveStep = 0;
    state.caveDroneHealth = 0;
    state.caveDroneFuel = 0;
    return true;
  }

  static bool startExcavation(GameState state, DateTime now) {
    final hasAvailableScientist = state.scientistRoster.any(
      (scientist) => !scientist.dead && !scientist.injured,
    );
    if (state.deepestMeters < 50000 ||
        !hasAvailableScientist ||
        state.activeScientistId != null) {
      return false;
    }
    if (state.excavationReadyAt != null || state.excavationCompletedPending) {
      return false;
    }
    state.excavationReadyAt = now.add(const Duration(seconds: 70));
    return true;
  }

  static bool claimExcavation(GameState state, DateTime now) {
    if (state.excavationReadyAt == null ||
        state.excavationReadyAt!.isAfter(now) ||
        !state.excavationCompletedPending) {
      return false;
    }
    state.excavationReadyAt = null;
    state.excavationCompletedPending = false;
    final relicId = 'relic_${(state.relicsFound % 12) + 1}';
    recordRelicFound(state, relicId);
    state.drillParts += 1;
    state.coins += 360;
    return true;
  }

  static int? availableBossIndex(GameState state) {
    for (final boss in bosses) {
      if (state.currentWorldIndex == bossWorldIndex(boss) &&
          state.depthMeters >= boss.depthMeters &&
          !state.defeatedBossIds.contains(boss.id)) {
        return boss.id;
      }
    }
    return null;
  }

  static int bossWorldIndex(BossDefinition boss) =>
      boss.depthMeters >= GameState.worldEntryDepths[2]
      ? 2
      : boss.depthMeters >= GameState.worldEntryDepths[1]
      ? 1
      : 0;

  static double bossHealth(GameState state, int id) =>
      max(0, (bosses[id].health - state.bossDamage));

  static bool focusBossWeakPoint(GameState state, DateTime now) {
    if (availableBossIndex(state) == null) return false;
    state.bossWeakPointUntil = now.add(const Duration(seconds: 4));
    return true;
  }

  static double bossAttackDamage(GameState state, {bool critical = false}) {
    final relicDamage =
        (state.equippedRelics.contains('relic_10')
            ? 1.2 + (state.relicLevel('relic_10') - 1) * 0.1
            : 1.0) +
        (state.specialists['guardian'] ?? 0) * 0.15;
    return (1 + state.upgradeLevel('weapon') * 0.7 + state.crewCount * 0.18) *
        relicDamage *
        (state.equippedGems.contains('diamond') ? 1.12 : 1.0) *
        (critical ? 3 : 1);
  }

  static int attackBoss(GameState state) {
    final bossId = availableBossIndex(state);
    if (bossId == null) return 0;
    final boss = bosses[bossId];
    final weakPoint = state.bossWeakPointUntil?.isAfter(DateTime.now()) == true;
    state.bossWeakPointUntil = null;
    final damage = bossAttackDamage(state, critical: weakPoint);
    state.bossDamage += damage;
    if (state.bossDamage >= boss.health) {
      state.defeatedBossIds.add(boss.id);
      state.bossesDefeated++;
      state.bossDamage = 0;
      state.coins += boss.reward;
      state.drillParts += 3 + boss.id;
      switch (bossWorldIndex(boss)) {
        case 0:
          state.chestsFound++;
          break;
        case 1:
          state.goldChests++;
          break;
        case 2:
          state.deepChests++;
          break;
      }
      return boss.reward;
    }
    return weakPoint ? -2 : -1;
  }

  static bool ventPressure(GameState state) {
    if (state.pressure < 25) return false;
    if (state.amount('building_material') > 0) {
      state.inventory['building_material'] =
          state.amount('building_material') - 1;
    } else if (state.coins >= 90) {
      state.coins -= 90;
    } else {
      return false;
    }
    state.pressure = 8;
    state.energy += 12;
    return true;
  }

  static bool activateReactorBuff(GameState state, DateTime now) {
    if (state.upgradeLevel('reactor') <= 0 || state.energy < 25) return false;
    state.energy -= 25;
    final duration = state.equippedRelics.contains('relic_11')
        ? Duration(seconds: 120 + 30 * state.relicLevel('relic_11'))
        : const Duration(minutes: 2);
    final nextBuffUntil = now.add(duration);
    final activeBuffUntil = state.resonanceBuffUntil;
    state.resonanceBuffUntil =
        activeBuffUntil != null && activeBuffUntil.isAfter(nextBuffUntil)
        ? activeBuffUntil
        : nextBuffUntil;
    return true;
  }

  static bool acceptMerchantDeal(GameState state) {
    final offer = merchantOffer(state);
    if (state.amount(offer.giveId) < offer.giveAmount ||
        state.reserve(offer.giveId) >
            state.amount(offer.giveId) - offer.giveAmount) {
      return false;
    }
    final giveDefinition = ResourceCatalog.byId[offer.giveId];
    final getDefinition = ResourceCatalog.byId[offer.getId];
    if (giveDefinition == null || getDefinition == null) return false;
    final cargoAfterTrade =
        state.cargoUsed -
        offer.giveAmount * giveDefinition.weight +
        offer.getAmount * getDefinition.weight;
    if (cargoAfterTrade > state.effectiveCargoCapacity) return false;
    state.inventory[offer.giveId] =
        state.amount(offer.giveId) - offer.giveAmount;
    state.cargoUsed = max(
      0,
      state.cargoUsed - offer.giveAmount * giveDefinition.weight,
    ).toDouble();
    _addResource(state, getDefinition, offer.getAmount);
    state.merchantReadyAt = DateTime.now().add(const Duration(minutes: 2));
    return true;
  }

  static TradeOffer merchantOffer(GameState state) {
    final eligible = MrMineProgression.minerals
        .where((band) => band.worldIndex == state.activeWorldIndex)
        .where((band) => band.firstDepthMeters <= state.depthMeters)
        .map((band) => ResourceCatalog.byId[band.resourceId])
        .whereType<ResourceDefinition>()
        .toList();
    final index = max(0, eligible.length - 1);
    final give = eligible[max(0, index - 1)];
    final get = eligible[index];
    final giveAmount = 4 + (state.crewCount % 5);
    final localTradeBonus = switch (state.activeWorldIndex) {
      1 when state.unlockedBuildings.contains('lunar_trader') => 1.25,
      2 when state.unlockedBuildings.contains('titan_trader') => 1.25,
      _ => 1.0,
    };
    return TradeOffer(
      giveId: give.id,
      giveAmount: giveAmount,
      getId: get.id,
      getAmount: max(
        1,
        (giveAmount *
                give.baseValue /
                max(1, get.baseValue) *
                1.15 *
                localTradeBonus)
            .floor(),
      ),
    );
  }

  static int merchantSecondsLeft(GameState state, DateTime now) {
    final readyAt = state.merchantReadyAt;
    if (readyAt == null || !readyAt.isAfter(now)) return 0;
    return readyAt.difference(now).inSeconds;
  }

  static String currentResonanceTarget(GameState state) {
    if (state.resonancePattern.isEmpty) return 'coal';
    return state.resonancePattern[state.resonanceProgress %
        state.resonancePattern.length];
  }

  static bool scanResonance(GameState state) {
    if (state.upgradeLevel('scanner') <= 0 && state.coins < 80) return false;
    if (state.upgradeLevel('scanner') <= 0) state.coins -= 80;
    final available = ResourceCatalog.minerals
        .where(
          (resource) => resource.minDepthMeters <= state.depthMeters + 1200,
        )
        .toList();
    final random = Random(
      state.seed ^ state.totalMined ^ state.resonanceChains,
    );
    final patternLength = min(5, 3 + state.upgradeLevel('scanner') ~/ 4);
    state.resonancePattern = List.generate(
      patternLength,
      (_) => available[random.nextInt(available.length)].id,
    );
    state.resonanceProgress = 0;
    state.seed = random.nextInt(0x7fffffff);
    return true;
  }

  static bool tapResonance(
    GameState state,
    String resourceId, {
    DateTime? now,
  }) {
    final time = now ?? DateTime.now();
    if (resourceId != currentResonanceTarget(state)) {
      state.resonanceProgress = 0;
      return false;
    }
    state.resonanceProgress++;
    if (state.resonanceProgress < state.resonancePattern.length) return false;
    state.resonanceProgress = 0;
    state.resonanceChains++;
    final duration = state.equippedRelics.contains('relic_7')
        ? resonanceDuration + Duration(minutes: state.relicLevel('relic_7'))
        : resonanceDuration;
    final nextBuffUntil = time.add(duration);
    final activeBuffUntil = state.resonanceBuffUntil;
    state.resonanceBuffUntil =
        activeBuffUntil != null && activeBuffUntil.isAfter(nextBuffUntil)
        ? activeBuffUntil
        : nextBuffUntil;
    final random = Random(state.seed ^ state.resonanceChains);
    state.seed = random.nextInt(0x7fffffff);
    state.coins += 50 + random.nextInt(60);
    return true;
  }

  static void applyPrestige(GameState state) {
    final relicBonus = state.equippedRelics.contains('relic_12')
        ? state.relicLevel('relic_12')
        : 0;
    final reward = max(1, (state.deepestMeters / 500000).floor() + relicBonus);
    state.coreShards += reward;
    state.prestigeCount++;
    state.depthMeters = 0;
    state.deepestMeters = 0;
    state.activeWorldIndex = 0;
    state.coins = 240 + state.coreShards * 45;
    state.energy = 0;
    state.cargoUsed = 0;
    state.managerLevel = 0;
    state.oilPumpLevel = 1;
    state.oilPumpProgress = 0;
    state.drillBitLevel = 1;
    state.drillFanLevel = 1;
    state.drillEngineLevel = 1;
    state.reactorShutdown = false;
    state.reactorComponents
      ..clear()
      ..addAll(ReactorCatalog.starterLayout());
    state.inventory
      ..clear()
      ..addAll({'coal': 0, 'copper': 0});
    state.reserves.clear();
    state.worldDepths
      ..clear()
      ..addAll({
        '0': 0,
        '1': GameState.worldEntryDepths[1],
        '2': GameState.worldEntryDepths[2],
      });
    state.worldPressures
      ..clear()
      ..addAll({'0': 14, '1': 14, '2': 14});
    state.worldCargoUsed
      ..clear()
      ..addAll({'0': 0, '1': 0, '2': 0});
    state.worldInventories
      ..clear()
      ..addAll({
        '0': {'coal': 0, 'copper': 0},
        '1': {'coal': 0, 'copper': 0},
        '2': {'coal': 0, 'copper': 0},
      });
    state.worldReserves
      ..clear()
      ..addAll({
        '0': <String, int>{},
        '1': <String, int>{},
        '2': <String, int>{},
      });
    state.upgrades
      ..clear()
      ..addAll({
        'drill': (1 + state.coreShards).clamp(1, 100).toInt(),
        'workers': 0,
        'lift': 1,
        'warehouse': 1,
        'scanner': 0,
        'foundry': 0,
        'weapon': 0,
        'reactor': 0,
      });
    state.crewCount = 1;
    state.workerAssignments
      ..clear()
      ..addAll({'transport': 0, 'scanner': 0, 'sorting': 0});
    state.oreVeinDamage.clear();
    state.oreDeposits.clear();
    ensureOpenMineDeposits(state);
    state.chestsFound = 0;
    state.goldChests = 0;
    state.deepChests = 0;
    state.collectorStoredChests = 0;
    state.chestCollectorLevel = 0;
    state.chestCompressionLevel = 0;
    state.activeBuffIds.clear();
    state.chestCompressionQueue.clear();
    state.chestCompressionReadyAt = null;
    state.bossDamage = 0;
    state.defeatedBossIds.clear();
    state.unlockedBuildings
      ..clear()
      ..addAll({
        'elevator',
        'workshop',
        'warehouse',
        'trade',
        'research',
        'expedition',
      });
  }

  static int _addResource(
    GameState state,
    ResourceDefinition resource,
    int quantity,
  ) {
    if (quantity <= 0) return 0;
    final carriesWeight =
        resource.kind == ResourceKind.mineral ||
        resource.kind == ResourceKind.isotope;
    final added = carriesWeight
        ? min(quantity, _availableUnits(state, resource))
        : quantity;
    if (added <= 0) return 0;
    state.inventory[resource.id] = state.amount(resource.id) + added;
    if (carriesWeight) state.cargoUsed += added * resource.weight;
    return added;
  }

  static int _availableUnits(GameState state, ResourceDefinition resource) {
    final weight = max(1, resource.weight);
    final remaining = state.effectiveCargoCapacity - state.cargoUsed;
    if (remaining < weight) return 0;
    return (remaining / weight).floor();
  }

  static bool _fitsLoot(GameState state, Map<String, int> loot) {
    var incomingWeight = 0.0;
    for (final entry in loot.entries) {
      final resource = ResourceCatalog.byId[entry.key];
      if (resource == null || entry.value <= 0) continue;
      if (resource.kind == ResourceKind.mineral ||
          resource.kind == ResourceKind.isotope) {
        incomingWeight += entry.value * resource.weight;
      }
    }
    return state.cargoUsed + incomingWeight <= state.effectiveCargoCapacity;
  }

  static void _generateCaveLoot(GameState state, Random random) {
    final ore = ResourceCatalog.mineableAtDepth(state.depthMeters);
    final route = CaveRouteCatalog.byId[state.caveRoute]!;
    final caveBonus =
        1 +
        (state.equippedRelics.contains('relic_3')
            ? 0.25 * state.relicLevel('relic_3')
            : 0) +
        (state.specialists['scout'] ?? 0) * 0.1;
    final droneMultiplier = 1 + (state.caveDroneCount - 1) * .35;
    if (ore != null) {
      state.pendingCaveLoot[ore.id] = max(
        1,
        ((6 + state.expeditionLevel * 3 + random.nextInt(8)) *
                caveBonus *
                route.lootMultiplier *
                droneMultiplier)
            .round(),
      );
    }
    state.pendingCaveLoot['building_material'] =
        1 + random.nextInt(4) + max(0, state.caveDroneCount - 1);
    if (random.nextInt(route.ticketChance) == 0) {
      state.pendingCaveLoot['ticket'] = 1;
    }
    if (random.nextInt(route.relicChance) == 0) {
      final relicId = 'relic_${random.nextInt(12) + 1}';
      state.pendingCaveLoot[relicId] = 1;
    }
  }

  static void _unlockMilestones(GameState state, List<String> events) {
    if (state.deepestMeters >= 1000 &&
        state.discoveredEncounters.add('first_depth_chest')) {
      state.chestsFound++;
      events.add('İlk katman sandığı bulundu! Açmak için ambarında yer bırak.');
    }
    for (final entry in milestoneBuildings.entries) {
      final depth = double.parse(entry.key);
      if (state.deepestMeters >= depth &&
          state.unlockedBuildings.add(entry.value)) {
        events.add(_milestoneMessage(entry.value));
        state.coins += 100 + (depth / 1000).floor();
        if (entry.value == 'scientists' && state.scientistRoster.isEmpty) {
          addScientist(state);
        }
        if (entry.value == 'caves') state.drones = max(1, state.drones);
        if (entry.value == 'reactor') {
          state.upgrades['reactor'] = max(1, state.upgradeLevel('reactor'));
        }
      }
    }
    for (final entry in hiddenEncounters.entries) {
      final depth = double.parse(entry.key);
      if (state.deepestMeters >= depth &&
          state.discoveredEncounters.add(entry.value.$1)) {
        state.coins += entry.value.$2;
        state.drillParts += entry.value.$3;
        state.chestsFound++;
        events.add(
          'Gizli keşif: ${entry.value.$1}! +${entry.value.$2} kasa ve bir sandık.',
        );
      }
    }
  }

  static String _milestoneMessage(String id) => switch (id) {
    'super_miners' => 'Özel madenciler keşfedildi!',
    'trader' => 'Tüccar hattı açıldı!',
    'caves' => 'Mağara dronları hazır!',
    'scientists' => 'Araştırma ekibi bulundu!',
    'chest_collector' => 'Otomatik sandık toplayıcı açıldı! Beş sandığa kadar depolar; her 30 dakikada bir yenisini bulur.',
    'repair_robot' => 'Eski sondaj robotu devreye girdi! Sondaj hızı +%10.',
    'underground_city' => 'Yeraltı yerleşkesi açıldı! Pompa dakikada 12 varil petrol üretir; stoğu satabilir ya da yapı malzemesine çevirebilirsin.',
    'gem_forge' => 'Mücevher Ocağı açıldı! Kaynakları mücevhere işleyip üç yuvaya takabilirsin.',
    'armory' =>
      'Cephanelik açıldı! Derinlik muhafızlarına karşı savaşabilirsin.',
    'deep_core' => 'Derin çekirdek erişilebilir!',
    'chest_compressor' => 'Sandık sıkıştırıcı açıldı! 10 temel sandığı altına, 5 altın sandığı derin sandığa dönüştür.',
    'moon_world' => 'Ay bölgesine geçiş açıldı!',
    'reactor' => 'Reaktör üretimi açıldı!',
    'buff_lab' => 'Üretim laboratuvarı açıldı! Reaktör güç darbeleri uzadı.',
    'titan_world' => 'Titan bölgesine geçiş açıldı!',
    'lunar_trader' =>
      'Ay Ticaret İstasyonu açıldı! Ay kaynaklarında takas getirisi arttı.',
    'robot_mk2' =>
      'Sondaj Robotu Mk II bulundu! 24–26. parça şemaları erişilebilir.',
    'titan_domain' =>
      'Titan etki alanı açıldı! Derin metan ve hidrojen damarları belirdi.',
    'titan_trader' => 'Titan Ticaret İstasyonu açıldı! Titan kaynakları için yeni takaslar kullanılabilir.',
    'robot_mk3' => 'Sondaj Robotu Mk III bulundu! İleri Titan parça şemalarına erişim açıldı.',
    _ => 'Yeni bir derinlik sistemi açıldı!',
  };

  static void _advanceOilPump(GameState state) {
    if (!state.unlockedBuildings.contains('underground_city') ||
        state.miningSeconds % 60 != 0) {
      return;
    }
    final oil = ResourceCatalog.byId['oil'];
    if (oil == null) return;

    final earthInventory = state.currentWorldIndex == 0
        ? state.inventory
        : state.worldInventories.putIfAbsent('0', () => <String, int>{});
    final capacity = oilPumpStorageCapacity(state);
    final currentOil = earthInventory['oil'] ?? 0;
    if (currentOil >= capacity) {
      state.oilPumpProgress = 0;
      return;
    }

    // The source pump produces 0.2 barrels per second; this game records
    // fractional output and adds whole barrels to its shared inventory.
    state.oilPumpProgress += oilPumpProductionPerSecond(state) * 60;
    final due = (state.oilPumpProgress + 1e-9).floor();
    if (due <= 0) return;

    final quantity = min(due, capacity - currentOil);
    // Oil is a city material with no cargo weight. Keep the pump's stock in
    // Earth's saved inventory even while the player is mining another world.
    final added = min(quantity, max(0, capacity - currentOil));
    earthInventory['oil'] = currentOil + added;
    state.oilPumpProgress -= added;
    if (state.amount('oil') >= capacity || added < quantity) {
      state.oilPumpProgress = 0;
    }
  }

  static void _advanceReactor(GameState state, List<String> events) {
    if (!state.unlockedBuildings.contains('reactor') ||
        state.upgradeLevel('reactor') <= 0 ||
        state.currentWorldIndex != 1) {
      return;
    }
    if (!reactorIsThermallyStable(state)) {
      if (!state.reactorShutdown) {
        events.add('Reaktör ısındı ve güvenlik nedeniyle kapandı.');
      }
      state.reactorShutdown = true;
      return;
    }
    if (state.reactorShutdown) return;
    state.energy = min(
      1e9,
      state.energy + reactorEnergyPerSecond(state),
    ).toDouble();
  }

  static void _advanceBuffLab(GameState state, List<String> events) {
    if (!state.unlockedBuildings.contains('buff_lab') ||
        state.activeBuffIds.isEmpty) {
      return;
    }
    final drain = buffLabEnergyDrainPerSecond(state);
    if (state.energy < drain) {
      state.activeBuffIds.clear();
      events.add('Buff laboratuvarında enerji bitti; tüm etkiler kapandı.');
      return;
    }
    state.energy -= drain;
  }

  static void _completeTimedActivities(
    GameState state,
    DateTime now,
    List<String> events,
    Random random,
  ) {
    _completeChestCompression(state, now, events);
    final caveReadyAt = state.caveReadyAt;
    if (caveReadyAt != null &&
        !caveReadyAt.isAfter(now) &&
        !state.caveCompletedPending) {
      _generateCaveLoot(state, random);
      state.caveCompletedPending = true;
      events.add('Keşif dronu mağaradan döndü. Ödülünü Sefer Garajı’ndan al.');
    }
    final excavationReadyAt = state.excavationReadyAt;
    if (excavationReadyAt != null &&
        !excavationReadyAt.isAfter(now) &&
        !state.excavationCompletedPending) {
      state.excavationCompletedPending = true;
      events.add(
        'Bilim insanlarının kazısı tamamlandı. Araştırma binasından ödülünü al.',
      );
    }
  }
}

class TradeOffer {
  const TradeOffer({
    required this.giveId,
    required this.giveAmount,
    required this.getId,
    required this.getAmount,
  });

  final String giveId;
  final int giveAmount;
  final String getId;
  final int getAmount;
}
