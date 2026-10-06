import 'dart:math';

import 'quest_definition.dart';
import 'resource_definition.dart';
import 'gem_definition.dart';
import 'cave_route_definition.dart';
import 'cave_exploration_definition.dart';
import 'upgrade_definition.dart';
import 'daily_challenge_definition.dart';
import 'mine_event_definition.dart';
import 'scientist_definition.dart';
import 'special_worker_definition.dart';
import 'ore_deposit.dart';
import 'reactor_definition.dart';
import 'drill_assembly_definition.dart';
import 'buff_lab_definition.dart';

class GameState {
  static const int currentSchemaVersion = 19;
  static const List<double> worldEntryDepths = [0, 1032000, 1814000];
  static const List<double> autoSellThresholdChoices = [.6, .75, .85, .95];

  GameState({
    this.coins = 240,
    this.depthMeters = 0,
    this.deepestMeters = 0,
    this.pressure = 14,
    this.energy = 0,
    this.cargoCapacity = 24,
    this.cargoUsed = 0,
    this.crewCount = 1,
    this.totalMined = 0,
    this.totalSold = 0,
    this.chestsFound = 0,
    this.goldChests = 0,
    this.deepChests = 0,
    this.chestsOpened = 0,
    this.collectorStoredChests = 0,
    this.chestCollectorLevel = 0,
    this.chestCompressionLevel = 0,
    this.cavesCompleted = 0,
    this.relicsFound = 0,
    this.bossesDefeated = 0,
    this.resonanceChains = 0,
    this.miningSeconds = 0,
    this.tutorialStep = 0,
    this.coreShards = 0,
    this.prestigeCount = 0,
    this.drillParts = 0,
    this.scientists = 0,
    this.revivalTokens = 0,
    this.workerScrap = 0,
    this.drones = 1,
    this.caveDroneCount = 1,
    this.caveTripsStarted = 0,
    this.caveExploring = false,
    this.caveStep = 0,
    this.cavePreviousLane = 1,
    this.caveDroneType = 'ground',
    this.caveDroneHealth = 100,
    this.caveDroneFuel = 4,
    this.caveRoute = 'survey',
    this.expeditionLevel = 0,
    this.activeScientistId,
    this.activeScientistMissionId,
    this.scientistExpeditionReadyAt,
    this.scientistExpeditionOutcome,
    this.bossDamage = 0,
    this.bossWeakPointUntil,
    this.lastSavedAt,
    this.caveReadyAt,
    this.caveCompletedPending = false,
    this.excavationReadyAt,
    this.excavationCompletedPending = false,
    this.resonanceBuffUntil,
    this.merchantReadyAt,
    this.chestCompressionReadyAt,
    this.activeWorldIndex = 0,
    this.autoSellEnabled = false,
    this.autoSellThreshold = .85,
    this.managerLevel = 0,
    this.oilPumpLevel = 1,
    this.oilPumpProgress = 0,
    this.drillBitLevel = 1,
    this.drillFanLevel = 1,
    this.drillEngineLevel = 1,
    this.reactorShutdown = false,
    this.scientistsSacrificedToCore = 0,
    Map<String, int>? inventory,
    Map<String, int>? reserves,
    Map<String, int>? upgrades,
    Map<String, String>? reactorComponents,
    Map<String, double>? worldDepths,
    Map<String, double>? worldPressures,
    Map<String, double>? worldCargoUsed,
    Map<String, Map<String, int>>? worldInventories,
    Map<String, Map<String, int>>? worldReserves,
    Set<int>? claimedQuestIds,
    Set<String>? unlockedRelics,
    Set<String>? equippedRelics,
    Set<String>? equippedGems,
    Set<String>? lockedResources,
    Set<String>? activeBuffIds,
    Set<String>? unlockedBuildings,
    Set<String>? discoveredEncounters,
    Set<int>? defeatedBossIds,
    Set<String>? unlockedAchievements,
    List<String>? resonancePattern,
    Map<String, int>? pendingCaveLoot,
    Map<String, int>? specialists,
    List<String>? chestCompressionQueue,
    Map<String, int>? gems,
    List<ScientistState>? scientistRoster,
    List<SpecialWorkerState>? specialWorkerRoster,
    List<List<String>>? caveNodeMap,
    List<int>? cavePathLanes,
    Map<String, int>? relicDuplicates,
    Map<String, int>? relicLevels,
    this.relicScrap = 0,
    Map<String, int>? gemWorkload,
    Map<String, double>? gemCraftRemainingSeconds,
    Map<String, int>? workerAssignments,
    Map<String, int>? oreVeinDamage,
    Map<String, OreDepositState>? oreDeposits,
    List<String>? workerRolePriority,
    String? dailyChallengeDate,
    List<String>? dailyChallengeIds,
    Map<String, int>? dailyChallengeProgress,
    Set<String>? claimedDailyChallengeIds,
    String? weeklyChallengeKey,
    this.weeklyChallengeProgress = 0,
    this.weeklyChallengeClaimed = false,
    this.activeMineEventId,
    this.nextMineEventAtSeconds = 120,
  }) : inventory = inventory ?? {'coal': 0, 'copper': 0},
       reserves = reserves ?? {},
       upgrades =
           upgrades ??
           {
             'drill': 1,
             'workers': 0,
             'lift': 1,
             'warehouse': 1,
             'scanner': 0,
             'foundry': 0,
             'weapon': 0,
             'reactor': 0,
           },
       reactorComponents = reactorComponents ?? ReactorCatalog.starterLayout(),
       claimedQuestIds = claimedQuestIds ?? <int>{},
       unlockedRelics = unlockedRelics ?? <String>{},
       equippedRelics = equippedRelics ?? <String>{},
       equippedGems = equippedGems ?? <String>{},
       lockedResources = lockedResources ?? <String>{},
       activeBuffIds = activeBuffIds ?? <String>{},
       unlockedBuildings =
           unlockedBuildings ??
           <String>{
             'elevator',
             'workshop',
             'warehouse',
             'trade',
             'research',
             'expedition',
           },
       discoveredEncounters = discoveredEncounters ?? <String>{},
       defeatedBossIds = defeatedBossIds ?? <int>{},
       unlockedAchievements = unlockedAchievements ?? <String>{},
       resonancePattern = resonancePattern ?? ['coal', 'copper', 'iron'],
       pendingCaveLoot = pendingCaveLoot ?? {},
       chestCompressionQueue = chestCompressionQueue ?? <String>[],
       workerAssignments =
           workerAssignments ?? {'transport': 0, 'scanner': 0, 'sorting': 0},
       oreVeinDamage = oreVeinDamage ?? {},
       oreDeposits = oreDeposits ?? {},
       workerRolePriority =
           workerRolePriority ?? ['digging', 'transport', 'scanner', 'sorting'],
       gems =
           gems ??
           {
             'ruby': 0,
             'emerald': 0,
             'sapphire': 0,
             'amethyst': 0,
             'diamond': 0,
           },
       caveNodeMap = caveNodeMap ?? <List<String>>[],
       cavePathLanes = cavePathLanes ?? <int>[],
       scientistRoster = scientistRoster ?? <ScientistState>[],
       specialWorkerRoster = specialWorkerRoster ?? <SpecialWorkerState>[],
       relicDuplicates = relicDuplicates ?? {},
       relicLevels = relicLevels ?? {},
       gemWorkload =
           gemWorkload ??
           {
             'ruby': 20,
             'emerald': 20,
             'sapphire': 20,
             'amethyst': 20,
             'diamond': 20,
           },
       dailyChallengeDate = dailyChallengeDate ?? '',
       dailyChallengeIds = dailyChallengeIds ?? <String>[],
       dailyChallengeProgress = dailyChallengeProgress ?? {},
       claimedDailyChallengeIds = claimedDailyChallengeIds ?? <String>{},
       weeklyChallengeKey = weeklyChallengeKey ?? '',
       gemCraftRemainingSeconds = gemCraftRemainingSeconds ?? {},
       worldDepths = worldDepths ?? {},
       worldPressures = worldPressures ?? {},
       worldCargoUsed = worldCargoUsed ?? {},
       worldInventories = worldInventories ?? {},
       worldReserves = worldReserves ?? {},
       specialists =
           specialists ??
           {'geologist': 0, 'engineer': 0, 'scout': 0, 'guardian': 0};

  double coins;
  double depthMeters;
  double deepestMeters;
  double pressure;
  double energy;
  double cargoCapacity;
  double cargoUsed;
  int crewCount;
  int totalMined;
  double totalSold;
  int chestsFound;
  int goldChests;
  int deepChests;
  int chestsOpened;
  int collectorStoredChests;
  int chestCollectorLevel;
  int chestCompressionLevel;
  int cavesCompleted;
  int relicsFound;
  int bossesDefeated;
  int resonanceChains;
  int miningSeconds;
  int tutorialStep;
  int coreShards;
  int prestigeCount;
  int drillParts;
  int scientists;
  int revivalTokens;
  int workerScrap;
  int drones;
  int caveDroneCount;
  int caveTripsStarted;
  bool caveExploring;
  int caveStep;
  int cavePreviousLane;
  String caveDroneType;
  int caveDroneHealth;
  int caveDroneFuel;
  String caveRoute;
  int expeditionLevel;
  String? activeScientistId;
  String? activeScientistMissionId;
  DateTime? scientistExpeditionReadyAt;
  String? scientistExpeditionOutcome;
  double bossDamage;
  DateTime? bossWeakPointUntil;
  DateTime? lastSavedAt;
  DateTime? caveReadyAt;
  bool caveCompletedPending;
  DateTime? excavationReadyAt;
  bool excavationCompletedPending;
  DateTime? resonanceBuffUntil;
  DateTime? merchantReadyAt;
  DateTime? chestCompressionReadyAt;
  int activeWorldIndex;
  bool autoSellEnabled;
  double autoSellThreshold;
  int managerLevel;
  int oilPumpLevel;
  double oilPumpProgress;
  int drillBitLevel;
  int drillFanLevel;
  int drillEngineLevel;
  bool reactorShutdown;
  int scientistsSacrificedToCore;
  final Map<String, int> inventory;
  final Map<String, int> reserves;
  final Map<String, int> upgrades;
  final Map<String, String> reactorComponents;
  final Set<int> claimedQuestIds;
  final Set<String> unlockedRelics;
  final Set<String> equippedRelics;
  final Set<String> equippedGems;
  final Set<String> lockedResources;
  final Set<String> activeBuffIds;
  final Set<String> unlockedBuildings;
  final Set<String> discoveredEncounters;
  final Set<int> defeatedBossIds;
  final Set<String> unlockedAchievements;
  List<String> resonancePattern;
  int resonanceProgress = 0;
  final Map<String, int> pendingCaveLoot;
  final List<String> chestCompressionQueue;
  final Map<String, int> workerAssignments;
  final Map<String, int> oreVeinDamage;
  final Map<String, OreDepositState> oreDeposits;
  final List<String> workerRolePriority;
  final Map<String, int> gems;
  final List<List<String>> caveNodeMap;
  final List<int> cavePathLanes;
  final List<ScientistState> scientistRoster;
  final List<SpecialWorkerState> specialWorkerRoster;
  final Map<String, int> relicDuplicates;
  final Map<String, int> relicLevels;
  int relicScrap;
  final Map<String, int> gemWorkload;
  final Map<String, double> gemCraftRemainingSeconds;
  String dailyChallengeDate;
  final List<String> dailyChallengeIds;
  final Map<String, int> dailyChallengeProgress;
  final Set<String> claimedDailyChallengeIds;
  String weeklyChallengeKey;
  int weeklyChallengeProgress;
  bool weeklyChallengeClaimed;
  String? activeMineEventId;
  int nextMineEventAtSeconds;
  final Map<String, double> worldDepths;
  final Map<String, double> worldPressures;
  final Map<String, double> worldCargoUsed;
  final Map<String, Map<String, int>> worldInventories;
  final Map<String, Map<String, int>> worldReserves;
  final Map<String, int> specialists;
  int seed = 91827;

  /// Creates the actual first-shift state without changing fixture defaults.
  /// `GameState()` remains useful for tests and restored legacy data.
  factory GameState.newGame({DateTime? lastSavedAt, int? seed}) {
    final state = GameState(
      coins: 0,
      crewCount: 0,
      lastSavedAt: lastSavedAt,
      inventory: {'coal': 0, 'copper': 0},
    );
    state.seed = seed ?? Random.secure().nextInt(0x7fffffff);
    return state;
  }

  int get totalChestsFound => chestsFound + goldChests + deepChests;

  int get chestCollectorCapacity => 5 + chestCollectorLevel * 2;

  int get chestCompressionSlots =>
      (1 + chestCompressionLevel ~/ 3).clamp(1, 4).toInt();

  int get equippedGemCount => equippedGems.length;

  int get livingScientistCount =>
      scientistRoster.where((item) => !item.dead).length;

  int get activeDepthFloor => (depthMeters / 100000).floor();

  double activeSpecialWorkerPower(String abilityId) => specialWorkerRoster
      .where(
        (worker) =>
            worker.abilityId == abilityId &&
            worker.assignedWorld == activeWorldIndex &&
            worker.assignedFloor == activeDepthFloor,
      )
      .fold(0, (total, worker) => total + worker.power);

  ScientistState? scientistById(String? id) {
    if (id == null) return null;
    for (final scientist in scientistRoster) {
      if (scientist.id == id) return scientist;
    }
    return null;
  }

  int relicLevel(String relicId) =>
      (relicLevels[relicId] ?? 1).clamp(1, 5).toInt();

  int get currentWorldIndex => activeWorldIndex;

  String get currentWorldName =>
      const ['Dünya', 'Ay', 'Titan'][currentWorldIndex];

  double get effectiveCargoCapacity =>
      cargoCapacity *
      (1 + transportWorkers * 0.04) *
      (1 + activeSpecialWorkerPower('support') * 0.035) *
      (equippedRelics.contains('relic_4')
          ? 1 + .05 * relicLevel('relic_4')
          : 1) *
      (equippedGems.contains('sapphire') ? 1.1 : 1);

  int get transportWorkers => workerAssignments['transport'] ?? 0;
  int get scannerWorkers => workerAssignments['scanner'] ?? 0;
  int get sortingWorkers => workerAssignments['sorting'] ?? 0;
  int get diggingWorkers =>
      (crewCount - transportWorkers - scannerWorkers - sortingWorkers)
          .clamp(0, crewCount)
          .toInt();

  double oreVeinProgress(String resourceId) =>
      ((oreVeinDamage[resourceId] ?? 0) / 100).clamp(0, 1).toDouble();

  double get cargoRatio => effectiveCargoCapacity <= 0
      ? 1
      : (cargoUsed / effectiveCargoCapacity).clamp(0, 1);

  bool get cargoFull => cargoUsed >= effectiveCargoCapacity;

  bool get resonanceActive =>
      resonanceBuffUntil != null && resonanceBuffUntil!.isAfter(DateTime.now());

  double get drillRateMetersPerSecond {
    final drill = upgrades['drill'] ?? 1;
    final scanner = upgrades['scanner'] ?? 0;
    final resonanceBonus = resonanceActive ? 1.25 : 1.0;
    final relicBonus =
        (equippedRelics.contains('relic_1')
            ? 0.12 * relicLevel('relic_1')
            : 0) +
        (equippedRelics.contains('relic_7') ? 0.05 * relicLevel('relic_7') : 0);
    final engineerBonus = (specialists['engineer'] ?? 0) * 0.08;
    final specialDrillBonus = activeSpecialWorkerPower('drill_booster') * .06;
    final repairRobotBonus = unlockedBuildings.contains('repair_robot')
        ? 1.1
        : 1.0;
    final gemDrillBonus = equippedGems.contains('emerald') ? 1.08 : 1.0;
    final pressurePenalty = pressure >= 88
        ? 0.68
        : pressure >= 70
        ? 0.86
        : 1.0;
    final achievementMultiplier = 1 + unlockedAchievements.length * 0.005;
    final assemblyMultiplier = DrillAssemblyCatalog.speedMultiplier(
      bitLevel: drillBitLevel,
      fanLevel: drillFanLevel,
      engineLevel: drillEngineLevel,
    );
    final buffMultiplier = activeBuffIds.contains('buff_overdrive')
        ? BuffLabCatalog.overdriveMultiplier
        : 1.0;
    return (1.8 + drill * 0.75 + scanner * 0.12) *
        assemblyMultiplier *
        buffMultiplier *
        (1 + relicBonus + engineerBonus) *
        (1 + specialDrillBonus) *
        resonanceBonus *
        repairRobotBonus *
        gemDrillBonus *
        achievementMultiplier *
        pressurePenalty;
  }

  int upgradeLevel(String id) => upgrades[id] ?? 0;

  int amount(String id) => inventory[id] ?? 0;

  int reserve(String id) => reserves[id] ?? 0;

  int progressFor(QuestDefinition quest) => switch (quest.kind) {
    QuestKind.mine => totalMined,
    QuestKind.depth => deepestMeters.floor(),
    QuestKind.hire => crewCount - 1,
    QuestKind.sell => totalSold.floor(),
    QuestKind.upgrade => upgrades.values.fold(0, (sum, level) => sum + level),
    QuestKind.chest => chestsOpened,
    QuestKind.cave => cavesCompleted,
    QuestKind.relic => relicsFound,
    QuestKind.boss => bossesDefeated,
    QuestKind.resonance => resonanceChains,
  };

  void storeActiveWorldSnapshot() {
    final key = activeWorldIndex.toString();
    worldDepths[key] = depthMeters;
    worldPressures[key] = pressure;
    worldCargoUsed[key] = cargoUsed;
    worldInventories[key] = Map<String, int>.from(inventory);
    worldReserves[key] = Map<String, int>.from(reserves);
  }

  Map<String, Object?> toJson() {
    storeActiveWorldSnapshot();
    return {
      'schema': currentSchemaVersion,
      'coins': coins,
      'depthMeters': depthMeters,
      'deepestMeters': deepestMeters,
      'pressure': pressure,
      'energy': energy,
      'cargoCapacity': cargoCapacity,
      'cargoUsed': cargoUsed,
      'crewCount': crewCount,
      'totalMined': totalMined,
      'totalSold': totalSold,
      'chestsFound': chestsFound,
      'goldChests': goldChests,
      'deepChests': deepChests,
      'chestsOpened': chestsOpened,
      'collectorStoredChests': collectorStoredChests,
      'chestCollectorLevel': chestCollectorLevel,
      'chestCompressionLevel': chestCompressionLevel,
      'cavesCompleted': cavesCompleted,
      'relicsFound': relicsFound,
      'bossesDefeated': bossesDefeated,
      'resonanceChains': resonanceChains,
      'miningSeconds': miningSeconds,
      'tutorialStep': tutorialStep,
      'coreShards': coreShards,
      'prestigeCount': prestigeCount,
      'drillParts': drillParts,
      'scientists': scientists,
      'scientistRoster': scientistRoster
          .map((scientist) => scientist.toJson())
          .toList(),
      'revivalTokens': revivalTokens,
      'workerScrap': workerScrap,
      'specialWorkerRoster': specialWorkerRoster
          .map((worker) => worker.toJson())
          .toList(),
      'drones': drones,
      'caveDroneCount': caveDroneCount,
      'caveRoute': caveRoute,
      'caveTripsStarted': caveTripsStarted,
      'caveExploring': caveExploring,
      'caveStep': caveStep,
      'cavePreviousLane': cavePreviousLane,
      'caveDroneType': caveDroneType,
      'caveDroneHealth': caveDroneHealth,
      'caveDroneFuel': caveDroneFuel,
      'caveNodeMap': caveNodeMap,
      'cavePathLanes': cavePathLanes,
      'expeditionLevel': expeditionLevel,
      'activeScientistId': activeScientistId,
      'activeScientistMissionId': activeScientistMissionId,
      'scientistExpeditionReadyAt': scientistExpeditionReadyAt
          ?.toIso8601String(),
      'scientistExpeditionOutcome': scientistExpeditionOutcome,
      'bossDamage': bossDamage,
      'bossWeakPointUntil': bossWeakPointUntil?.toIso8601String(),
      'lastSavedAt': lastSavedAt?.toIso8601String(),
      'caveReadyAt': caveReadyAt?.toIso8601String(),
      'caveCompletedPending': caveCompletedPending,
      'excavationReadyAt': excavationReadyAt?.toIso8601String(),
      'excavationCompletedPending': excavationCompletedPending,
      'resonanceBuffUntil': resonanceBuffUntil?.toIso8601String(),
      'merchantReadyAt': merchantReadyAt?.toIso8601String(),
      'chestCompressionReadyAt': chestCompressionReadyAt?.toIso8601String(),
      'chestCompressionQueue': chestCompressionQueue,
      'gems': gems,
      'relicDuplicates': relicDuplicates,
      'relicLevels': relicLevels,
      'relicScrap': relicScrap,
      'gemWorkload': gemWorkload,
      'gemCraftRemainingSeconds': gemCraftRemainingSeconds,
      'dailyChallengeDate': dailyChallengeDate,
      'dailyChallengeIds': dailyChallengeIds,
      'dailyChallengeProgress': dailyChallengeProgress,
      'claimedDailyChallengeIds': claimedDailyChallengeIds.toList(),
      'weeklyChallengeKey': weeklyChallengeKey,
      'weeklyChallengeProgress': weeklyChallengeProgress,
      'weeklyChallengeClaimed': weeklyChallengeClaimed,
      'activeMineEventId': activeMineEventId,
      'nextMineEventAtSeconds': nextMineEventAtSeconds,
      'activeWorldIndex': activeWorldIndex,
      'autoSellEnabled': autoSellEnabled,
      'autoSellThreshold': autoSellThreshold,
      'managerLevel': managerLevel,
      'oilPumpLevel': oilPumpLevel,
      'oilPumpProgress': oilPumpProgress,
      'drillBitLevel': drillBitLevel,
      'drillFanLevel': drillFanLevel,
      'drillEngineLevel': drillEngineLevel,
      'reactorShutdown': reactorShutdown,
      'scientistsSacrificedToCore': scientistsSacrificedToCore,
      'reactorComponents': reactorComponents,
      'worldDepths': worldDepths,
      'worldPressures': worldPressures,
      'worldCargoUsed': worldCargoUsed,
      'worldInventories': worldInventories,
      'worldReserves': worldReserves,
      'inventory': inventory,
      'reserves': reserves,
      'upgrades': upgrades,
      'claimedQuestIds': claimedQuestIds.toList(),
      'unlockedRelics': unlockedRelics.toList(),
      'equippedRelics': equippedRelics.toList(),
      'equippedGems': equippedGems.toList(),
      'lockedResources': lockedResources.toList(),
      'activeBuffIds': activeBuffIds.toList(),
      'unlockedBuildings': unlockedBuildings.toList(),
      'discoveredEncounters': discoveredEncounters.toList(),
      'defeatedBossIds': defeatedBossIds.toList(),
      'unlockedAchievements': unlockedAchievements.toList(),
      'resonancePattern': resonancePattern,
      'resonanceProgress': resonanceProgress,
      'pendingCaveLoot': pendingCaveLoot,
      'specialists': specialists,
      'workerAssignments': workerAssignments,
      'oreVeinDamage': oreVeinDamage,
      'oreDeposits': {
        for (final entry in oreDeposits.entries)
          entry.key: entry.value.toJson(),
      },
      'workerRolePriority': workerRolePriority,
      'seed': seed,
    };
  }

  factory GameState.fromJson(Map<String, Object?> json) {
    final schema = (json['schema'] as num?)?.toInt() ?? 0;
    if (schema < 0 || schema > currentSchemaVersion) {
      throw FormatException('Kayıt şeması desteklenmiyor: $schema');
    }

    int readInt(String key, [int fallback = 0]) =>
        (json[key] as num?)?.toInt() ?? fallback;
    double readDouble(String key, [double fallback = 0]) =>
        (json[key] as num?)?.toDouble() ?? fallback;
    DateTime? readDate(String key) =>
        DateTime.tryParse(json[key] as String? ?? '');
    Map<String, int> readIntMap(String key) =>
        (json[key] as Map?)?.map(
          (k, v) => MapEntry(k.toString(), (v as num).toInt()),
        ) ??
        {};
    Map<String, String> readStringMap(String key) =>
        (json[key] as Map?)?.map(
          (k, v) => MapEntry(k.toString(), v.toString()),
        ) ??
        {};
    Map<String, OreDepositState> readOreDeposits() {
      final raw = json['oreDeposits'];
      if (raw is! Map) return {};
      final deposits = <String, OreDepositState>{};
      for (final entry in raw.entries.take(50000)) {
        if (entry.value is! Map) continue;
        final id = entry.key.toString();
        deposits[id] = OreDepositState.fromJson(
          id,
          Map<String, Object?>.from(entry.value as Map),
        );
      }
      return deposits;
    }

    Map<String, double> readDoubleMap(String key) =>
        (json[key] as Map?)?.map(
          (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
        ) ??
        {};
    Map<String, Map<String, int>> readNestedIntMap(String key) =>
        (json[key] as Map?)?.map((world, values) {
          final resources = values is Map
              ? values.map(
                  (resource, amount) =>
                      MapEntry(resource.toString(), (amount as num).toInt()),
                )
              : <String, int>{};
          return MapEntry(world.toString(), resources);
        }) ??
        {};
    Set<String> readStringSet(String key) => ((json[key] as List?) ?? const [])
        .map((item) => item.toString())
        .toSet();
    Set<int> readIntSet(String key) => ((json[key] as List?) ?? const [])
        .map((item) => (item as num).toInt())
        .toSet();
    List<String> readStringList(String key) =>
        ((json[key] as List?) ?? const [])
            .map((item) => item.toString())
            .toList();
    List<List<String>> readStringGrid(String key) =>
        ((json[key] as List?) ?? const [])
            .whereType<List>()
            .map((row) => row.map((item) => item.toString()).toList())
            .toList();
    List<ScientistState> readScientists() =>
        ((json['scientistRoster'] as List?) ?? const [])
            .whereType<Map>()
            .map(
              (record) =>
                  ScientistState.fromJson(Map<String, Object?>.from(record)),
            )
            .toList();
    List<SpecialWorkerState> readSpecialWorkers() =>
        ((json['specialWorkerRoster'] as List?) ?? const [])
            .whereType<Map>()
            .map(
              (record) => SpecialWorkerState.fromJson(
                Map<String, Object?>.from(record),
              ),
            )
            .toList();

    final state = GameState(
      coins: readDouble('coins', 240),
      depthMeters: readDouble('depthMeters'),
      deepestMeters: readDouble('deepestMeters'),
      pressure: readDouble('pressure', 14),
      energy: readDouble('energy'),
      cargoCapacity: readDouble('cargoCapacity', 24),
      cargoUsed: readDouble('cargoUsed'),
      crewCount: readInt('crewCount', 1),
      totalMined: readInt('totalMined'),
      totalSold: readDouble('totalSold'),
      chestsFound: readInt('chestsFound'),
      goldChests: readInt('goldChests'),
      deepChests: readInt('deepChests'),
      chestsOpened: readInt('chestsOpened'),
      collectorStoredChests: readInt('collectorStoredChests'),
      chestCollectorLevel: readInt('chestCollectorLevel'),
      chestCompressionLevel: readInt('chestCompressionLevel'),
      cavesCompleted: readInt('cavesCompleted'),
      relicsFound: readInt('relicsFound'),
      bossesDefeated: readInt('bossesDefeated'),
      resonanceChains: readInt('resonanceChains'),
      miningSeconds: readInt('miningSeconds'),
      tutorialStep: readInt('tutorialStep'),
      coreShards: readInt('coreShards'),
      prestigeCount: readInt('prestigeCount'),
      drillParts: readInt('drillParts'),
      scientists: readInt('scientists'),
      revivalTokens: readInt('revivalTokens'),
      workerScrap: readInt('workerScrap'),
      drones: readInt('drones', 1),
      caveDroneCount: readInt('caveDroneCount', 1),
      caveTripsStarted: readInt('caveTripsStarted'),
      caveExploring: json['caveExploring'] as bool? ?? false,
      caveStep: readInt('caveStep'),
      cavePreviousLane: readInt('cavePreviousLane', 1),
      caveDroneType: json['caveDroneType'] as String? ?? 'ground',
      caveDroneHealth: readInt('caveDroneHealth', 100),
      caveDroneFuel: readInt('caveDroneFuel', 4),
      caveNodeMap: readStringGrid('caveNodeMap'),
      cavePathLanes: ((json['cavePathLanes'] as List?) ?? const [])
          .whereType<num>()
          .map((value) => value.toInt())
          .toList(),
      expeditionLevel: readInt('expeditionLevel'),
      activeScientistId: json['activeScientistId'] as String?,
      activeScientistMissionId: json['activeScientistMissionId'] as String?,
      scientistExpeditionReadyAt: readDate('scientistExpeditionReadyAt'),
      scientistExpeditionOutcome: json['scientistExpeditionOutcome'] as String?,
      scientistRoster: readScientists(),
      specialWorkerRoster: readSpecialWorkers(),
      bossDamage: readDouble('bossDamage'),
      bossWeakPointUntil: readDate('bossWeakPointUntil'),
      lastSavedAt: readDate('lastSavedAt'),
      caveReadyAt: readDate('caveReadyAt'),
      caveRoute: json['caveRoute'] as String? ?? 'survey',
      caveCompletedPending: json['caveCompletedPending'] as bool? ?? false,
      excavationReadyAt: readDate('excavationReadyAt'),
      excavationCompletedPending:
          json['excavationCompletedPending'] as bool? ?? false,
      resonanceBuffUntil: readDate('resonanceBuffUntil'),
      merchantReadyAt: readDate('merchantReadyAt'),
      chestCompressionReadyAt: readDate('chestCompressionReadyAt'),
      gems: readIntMap('gems'),
      relicDuplicates: readIntMap('relicDuplicates'),
      relicLevels: readIntMap('relicLevels'),
      relicScrap: readInt('relicScrap'),
      gemWorkload: readIntMap('gemWorkload'),
      gemCraftRemainingSeconds: readDoubleMap('gemCraftRemainingSeconds'),
      dailyChallengeDate: json['dailyChallengeDate'] as String? ?? '',
      dailyChallengeIds: readStringList('dailyChallengeIds'),
      dailyChallengeProgress: readIntMap('dailyChallengeProgress'),
      claimedDailyChallengeIds: readStringSet('claimedDailyChallengeIds'),
      weeklyChallengeKey: json['weeklyChallengeKey'] as String? ?? '',
      weeklyChallengeProgress: readInt('weeklyChallengeProgress'),
      weeklyChallengeClaimed: json['weeklyChallengeClaimed'] as bool? ?? false,
      activeMineEventId: json['activeMineEventId'] as String?,
      nextMineEventAtSeconds: readInt(
        'nextMineEventAtSeconds',
        readInt('miningSeconds') + 120,
      ),
      activeWorldIndex: readInt('activeWorldIndex', -1),
      autoSellEnabled: json['autoSellEnabled'] as bool? ?? false,
      autoSellThreshold: readDouble('autoSellThreshold', .85),
      managerLevel: readInt('managerLevel'),
      oilPumpLevel: readInt('oilPumpLevel', 1),
      oilPumpProgress: readDouble('oilPumpProgress'),
      drillBitLevel: readInt('drillBitLevel', 1),
      drillFanLevel: readInt('drillFanLevel', 1),
      drillEngineLevel: readInt('drillEngineLevel', 1),
      reactorShutdown: json['reactorShutdown'] as bool? ?? false,
      scientistsSacrificedToCore: readInt('scientistsSacrificedToCore'),
      reactorComponents: json.containsKey('reactorComponents')
          ? readStringMap('reactorComponents')
          : ReactorCatalog.starterLayout(),
      inventory: readIntMap('inventory'),
      reserves: readIntMap('reserves'),
      upgrades: readIntMap('upgrades'),
      worldDepths: readDoubleMap('worldDepths'),
      worldPressures: readDoubleMap('worldPressures'),
      worldCargoUsed: readDoubleMap('worldCargoUsed'),
      worldInventories: readNestedIntMap('worldInventories'),
      worldReserves: readNestedIntMap('worldReserves'),
      claimedQuestIds: readIntSet('claimedQuestIds'),
      unlockedRelics: readStringSet('unlockedRelics'),
      equippedRelics: readStringSet('equippedRelics'),
      equippedGems: readStringSet('equippedGems'),
      lockedResources: readStringSet('lockedResources'),
      activeBuffIds: readStringSet('activeBuffIds'),
      unlockedBuildings: readStringSet('unlockedBuildings'),
      discoveredEncounters: readStringSet('discoveredEncounters'),
      defeatedBossIds: readIntSet('defeatedBossIds'),
      unlockedAchievements: readStringSet('unlockedAchievements'),
      resonancePattern:
          ((json['resonancePattern'] as List?) ??
                  const ['coal', 'copper', 'iron'])
              .map((item) => item.toString())
              .toList(),
      pendingCaveLoot: readIntMap('pendingCaveLoot'),
      chestCompressionQueue: readStringList('chestCompressionQueue'),
      specialists: readIntMap('specialists'),
      workerAssignments: readIntMap('workerAssignments'),
      oreVeinDamage: readIntMap('oreVeinDamage'),
      oreDeposits: readOreDeposits(),
      workerRolePriority: readStringList('workerRolePriority'),
    );
    state.resonanceProgress = readInt('resonanceProgress');
    state.seed = readInt('seed', 91827);
    state.relicScrap = state.relicScrap.clamp(0, 1000000000).toInt();
    if (state.inventory.isEmpty) state.inventory['coal'] = 0;
    if (state.upgrades.isEmpty) {
      state.upgrades.addAll({
        'drill': 1,
        'workers': 0,
        'lift': 1,
        'warehouse': 1,
        'scanner': 0,
      });
    }
    state.coins = state.coins.clamp(0, 1e18).toDouble();
    if (!state.autoSellThreshold.isFinite) state.autoSellThreshold = .85;
    state.autoSellThreshold = GameState.autoSellThresholdChoices.reduce(
      (closest, choice) =>
          (choice - state.autoSellThreshold).abs() <
              (closest - state.autoSellThreshold).abs()
          ? choice
          : closest,
    );
    state.cargoCapacity = state.cargoCapacity.clamp(1, 1e12).toDouble();
    state.crewCount = state.crewCount.clamp(schema >= 14 ? 0 : 1, 80).toInt();
    state.workerAssignments.removeWhere(
      (role, _) => !const {'transport', 'scanner', 'sorting'}.contains(role),
    );
    for (final role in const ['transport', 'scanner', 'sorting']) {
      state.workerAssignments[role] = (state.workerAssignments[role] ?? 0)
          .clamp(0, state.crewCount)
          .toInt();
    }
    final cleanedPriority = <String>[];
    for (final role in state.workerRolePriority) {
      if (const {'digging', 'transport', 'scanner', 'sorting'}.contains(role) &&
          !cleanedPriority.contains(role)) {
        cleanedPriority.add(role);
      }
    }
    state.workerRolePriority
      ..clear()
      ..addAll(cleanedPriority);
    for (final role in const ['digging', 'transport', 'scanner', 'sorting']) {
      if (!state.workerRolePriority.contains(role)) {
        state.workerRolePriority.add(role);
      }
    }
    var assignedWorkers =
        state.transportWorkers + state.scannerWorkers + state.sortingWorkers;
    for (final role in state.workerRolePriority) {
      if (role == 'digging') continue;
      if (assignedWorkers <= state.crewCount) break;
      final excess = assignedWorkers - state.crewCount;
      final current = state.workerAssignments[role] ?? 0;
      final removed = excess < current ? excess : current;
      state.workerAssignments[role] = current - removed;
      assignedWorkers -= removed;
    }
    state.oreVeinDamage.removeWhere(
      (resource, _) => !ResourceCatalog.byId.containsKey(resource),
    );
    for (final resource in state.oreVeinDamage.keys.toList()) {
      state.oreVeinDamage[resource] = state.oreVeinDamage[resource]!
          .clamp(0, 100)
          .toInt();
    }
    state.oreDeposits.removeWhere(
      (id, deposit) =>
          deposit.id != id ||
          !ResourceCatalog.byId.containsKey(deposit.resourceId) ||
          ResourceCatalog.byId[deposit.resourceId]!.kind !=
              ResourceKind.mineral,
    );
    for (final deposit in state.oreDeposits.values) {
      deposit.damage = deposit.damage.clamp(0, deposit.hitPoints).toInt();
    }
    final cleanedDailyIds = <String>[];
    for (final id in state.dailyChallengeIds) {
      if (DailyChallengeCatalog.byId.containsKey(id) &&
          !cleanedDailyIds.contains(id)) {
        cleanedDailyIds.add(id);
      }
    }
    state.dailyChallengeIds
      ..clear()
      ..addAll(cleanedDailyIds);
    if (state.dailyChallengeIds.length > DailyChallengeCatalog.dailyCount) {
      state.dailyChallengeIds.removeRange(
        DailyChallengeCatalog.dailyCount,
        state.dailyChallengeIds.length,
      );
    }
    state.dailyChallengeProgress.removeWhere(
      (id, _) => !state.dailyChallengeIds.contains(id),
    );
    for (final id in state.dailyChallengeIds) {
      state.dailyChallengeProgress[id] = (state.dailyChallengeProgress[id] ?? 0)
          .clamp(0, DailyChallengeCatalog.byId[id]!.target)
          .toInt();
    }
    state.claimedDailyChallengeIds.removeWhere(
      (id) => !state.dailyChallengeIds.contains(id),
    );
    state.weeklyChallengeProgress = state.weeklyChallengeProgress
        .clamp(0, DailyChallengeCatalog.weeklyTarget)
        .toInt();
    if (state.weeklyChallengeProgress < DailyChallengeCatalog.weeklyTarget) {
      state.weeklyChallengeClaimed = false;
    }
    if (!MineEventCatalog.byId.containsKey(state.activeMineEventId)) {
      state.activeMineEventId = null;
    }
    state.nextMineEventAtSeconds = state.nextMineEventAtSeconds.clamp(
      state.miningSeconds + 1,
      0x7fffffff,
    );
    state.scientists = state.scientists.clamp(0, 8).toInt();
    state.revivalTokens = state.revivalTokens.clamp(0, 999).toInt();
    final uniqueScientists = <String>{};
    state.scientistRoster.removeWhere(
      (scientist) => !uniqueScientists.add(scientist.id),
    );
    if (state.scientistRoster.length > 8) {
      state.scientistRoster.removeRange(8, state.scientistRoster.length);
    }
    if (state.scientistRoster.isEmpty && state.scientists > 0) {
      for (var index = 0; index < state.scientists; index++) {
        state.scientistRoster.add(
          ScientistState.create(index + 1, Random(9217 + index)),
        );
      }
    }
    for (final scientist in state.scientistRoster) {
      if (!ScientistRarityCatalog.byId.containsKey(scientist.rarityId)) {
        scientist.rarityId = 'common';
      }
      if (!ScientistTraitCatalog.byId.containsKey(scientist.traitId)) {
        scientist.traitId = 'careful';
      }
      scientist.level = scientist.level.clamp(1, 100).toInt();
      scientist.experience = scientist.experience.clamp(0, 1000000).toInt();
      scientist.injuryCount = scientist.injuryCount.clamp(0, 2).toInt();
      if (scientist.dead) scientist.injuredUntil = null;
    }
    state.scientists = state.livingScientistCount.clamp(0, 8).toInt();
    state.workerScrap = state.workerScrap.clamp(0, 1000000000).toInt();
    final uniqueSpecialWorkers = <String>{};
    state.specialWorkerRoster.removeWhere(
      (worker) => !uniqueSpecialWorkers.add(worker.id),
    );
    if (state.specialWorkerRoster.length > 12) {
      state.specialWorkerRoster.removeRange(
        12,
        state.specialWorkerRoster.length,
      );
    }
    for (final worker in state.specialWorkerRoster) {
      if (!SpecialWorkerRarityCatalog.byId.containsKey(worker.rarityId)) {
        worker.rarityId = 'common';
      }
      if (!SpecialWorkerAbilityCatalog.byId.containsKey(worker.abilityId)) {
        worker.abilityId = 'miner_booster';
      }
      worker.level = worker.level.clamp(1, 20).toInt();
      worker.experience = worker.experience.clamp(0, 1000000).toInt();
      worker.assignedWorld = worker.assignedWorld.clamp(0, 2).toInt();
      worker.assignedFloor = worker.assignedFloor.clamp(0, 30).toInt();
    }
    final missionValid = ScientistExpeditionCatalog.byId.containsKey(
      state.activeScientistMissionId,
    );
    final scientistValid = state.scientistById(state.activeScientistId) != null;
    const validOutcomes = {'success', 'partial', 'injury', 'death', 'failure'};
    if (!missionValid ||
        !scientistValid ||
        state.scientistExpeditionReadyAt == null ||
        !validOutcomes.contains(state.scientistExpeditionOutcome)) {
      state.activeScientistId = null;
      state.activeScientistMissionId = null;
      state.scientistExpeditionReadyAt = null;
      state.scientistExpeditionOutcome = null;
    }
    state.drones = state.drones.clamp(0, 50).toInt();
    state.caveDroneCount = state.caveDroneCount
        .clamp(1, state.drones < 1 ? 1 : state.drones)
        .toInt();
    if (!CaveDroneCatalog.byId.containsKey(state.caveDroneType)) {
      state.caveDroneType = 'ground';
    }
    state.caveStep = state.caveStep.clamp(0, 4).toInt();
    state.cavePreviousLane = state.cavePreviousLane.clamp(0, 2).toInt();
    state.caveDroneHealth = state.caveDroneHealth.clamp(0, 1000).toInt();
    state.caveDroneFuel = state.caveDroneFuel.clamp(0, 10).toInt();
    final caveNodeIds = CaveNodeCatalog.all.map((node) => node.id).toSet();
    final caveMapValid =
        state.caveNodeMap.length == 4 &&
        state.caveNodeMap.every(
          (row) => row.length == 3 && row.every(caveNodeIds.contains),
        );
    if (!caveMapValid) {
      state.caveNodeMap.clear();
      state.cavePathLanes.clear();
      state.caveExploring = false;
      state.caveStep = 0;
      if (state.caveReadyAt == null) state.caveCompletedPending = false;
    } else if (state.caveStep >= 4 && state.caveExploring) {
      state.caveExploring = false;
      state.caveCompletedPending = true;
    }
    state.cavePathLanes.removeWhere((lane) => lane < 0 || lane > 2);
    if (state.cavePathLanes.length > state.caveStep) {
      state.cavePathLanes.removeRange(
        state.caveStep,
        state.cavePathLanes.length,
      );
    }
    if (!CaveRouteCatalog.byId.containsKey(state.caveRoute)) {
      state.caveRoute = 'survey';
    }
    state.chestsFound = state.chestsFound.clamp(0, 1e9).toInt();
    state.goldChests = state.goldChests.clamp(0, 1e9).toInt();
    state.deepChests = state.deepChests.clamp(0, 1e9).toInt();
    state.chestsOpened = state.chestsOpened.clamp(0, 1e12).toInt();
    state.chestCollectorLevel = state.chestCollectorLevel.clamp(0, 10).toInt();
    state.collectorStoredChests = state.collectorStoredChests
        .clamp(0, state.chestCollectorCapacity)
        .toInt();
    state.chestCompressionLevel = state.chestCompressionLevel
        .clamp(0, 9)
        .toInt();
    state.chestCompressionQueue.removeWhere(
      (tier) => tier != 'gold' && tier != 'deep',
    );
    if (state.chestCompressionQueue.length > state.chestCompressionSlots) {
      state.chestCompressionQueue.removeRange(
        state.chestCompressionSlots,
        state.chestCompressionQueue.length,
      );
    }
    if (state.chestCompressionQueue.isEmpty ||
        state.chestCompressionReadyAt == null) {
      state.chestCompressionQueue.clear();
      state.chestCompressionReadyAt = null;
    }
    state.totalMined = state.totalMined.clamp(0, 1e12).toInt();
    state.totalSold = state.totalSold.clamp(0, 1e18).toDouble();
    state.energy = state.energy.clamp(0, 1e9).toDouble();
    state.pressure = state.pressure.clamp(0, 100).toDouble();
    for (final entry in state.inventory.entries.toList()) {
      if (entry.value < 0) state.inventory[entry.key] = 0;
    }
    for (final entry in state.reserves.entries.toList()) {
      state.reserves[entry.key] = entry.value
          .clamp(0, state.amount(entry.key))
          .toInt();
    }
    for (final entry in state.upgrades.entries.toList()) {
      final maxLevel = UpgradeCatalog.byId[entry.key]?.maxLevel ?? 100;
      state.upgrades[entry.key] = entry.value.clamp(0, maxLevel).toInt();
    }
    state.managerLevel = state.managerLevel.clamp(0, 3).toInt();
    state.oilPumpLevel = state.oilPumpLevel.clamp(1, 50).toInt();
    if (!state.oilPumpProgress.isFinite) state.oilPumpProgress = 0;
    state.oilPumpProgress = state.oilPumpProgress.clamp(0, 1000000).toDouble();
    state.drillBitLevel = state.drillBitLevel
        .clamp(1, DrillAssemblyCatalog.maxLevel)
        .toInt();
    state.drillFanLevel = state.drillFanLevel
        .clamp(1, DrillAssemblyCatalog.maxLevel)
        .toInt();
    state.drillEngineLevel = state.drillEngineLevel
        .clamp(1, DrillAssemblyCatalog.maxLevel)
        .toInt();
    state.scientistsSacrificedToCore = state.scientistsSacrificedToCore
        .clamp(0, 1000000)
        .toInt();
    if (state.unlockedBuildings.contains('reactor') &&
        state.upgradeLevel('reactor') == 0) {
      state.upgrades['reactor'] = 1;
    }
    final reactorLevel = ReactorCatalog.gridLevel(
      state.upgradeLevel('reactor'),
    );
    state.reactorComponents.removeWhere((cell, componentId) {
      final coordinates = cell.split(',');
      if (coordinates.length != 2) return true;
      final x = int.tryParse(coordinates[0]);
      final y = int.tryParse(coordinates[1]);
      final component = ReactorCatalog.componentById[componentId];
      return x == null ||
          y == null ||
          !ReactorCatalog.containsCell(reactorLevel, x, y) ||
          component == null ||
          component.minimumLevel > reactorLevel;
    });
    if (state.energy.isFinite) {
      state.energy = state.energy.clamp(0, 1e9).toDouble();
    } else {
      state.energy = 0;
    }
    state.lockedResources.removeWhere(
      (resourceId) => !ResourceCatalog.byId.containsKey(resourceId),
    );
    state.activeBuffIds.removeWhere(
      (buffId) => !BuffLabCatalog.byId.containsKey(buffId),
    );
    if (!state.unlockedBuildings.contains('buff_lab')) {
      state.activeBuffIds.clear();
    }
    if (state.gems.isEmpty) {
      state.gems.addAll({for (final gem in GemCatalog.all) gem.id: 0});
    }
    state.gems.removeWhere((id, _) => !GemCatalog.byId.containsKey(id));
    for (final gem in GemCatalog.all) {
      state.gems[gem.id] = (state.gems[gem.id] ?? 0).clamp(0, 1e9).toInt();
      state.gemWorkload[gem.id] = (state.gemWorkload[gem.id] ?? 0)
          .clamp(0, 100)
          .toInt();
    }
    state.gemWorkload.removeWhere((id, _) => !GemCatalog.byId.containsKey(id));
    final workloadTotal = state.gemWorkload.values.fold<int>(
      0,
      (sum, value) => sum + value,
    );
    if (workloadTotal == 0) {
      for (final gem in GemCatalog.all) {
        state.gemWorkload[gem.id] = 100 ~/ GemCatalog.all.length;
      }
    } else if (workloadTotal != 100) {
      var assigned = 0;
      for (var index = 0; index < GemCatalog.all.length; index++) {
        final gem = GemCatalog.all[index];
        final value = index == GemCatalog.all.length - 1
            ? 100 - assigned
            : (state.gemWorkload[gem.id]! * 100 / workloadTotal).floor();
        state.gemWorkload[gem.id] = value;
        assigned += value;
      }
    }
    state.gemCraftRemainingSeconds.removeWhere(
      (id, seconds) =>
          !GemCatalog.byId.containsKey(id) || !seconds.isFinite || seconds <= 0,
    );
    for (final entry in state.gemCraftRemainingSeconds.entries.toList()) {
      state.gemCraftRemainingSeconds[entry.key] = entry.value.clamp(0, 1e9);
    }
    state.equippedGems.removeWhere(
      (id) => !GemCatalog.byId.containsKey(id) || (state.gems[id] ?? 0) <= 0,
    );
    while (state.equippedGems.length > 3) {
      state.equippedGems.remove(state.equippedGems.first);
    }
    state.unlockedRelics.removeWhere(
      (id) => !RegExp(r'^relic_(?:[1-9]|1[0-2])$').hasMatch(id),
    );
    state.equippedRelics.removeWhere(
      (id) => !state.unlockedRelics.contains(id),
    );
    while (state.equippedRelics.length > 3) {
      state.equippedRelics.remove(state.equippedRelics.first);
    }
    state.relicDuplicates.removeWhere(
      (id, _) => !state.unlockedRelics.contains(id),
    );
    for (final entry in state.relicDuplicates.entries.toList()) {
      state.relicDuplicates[entry.key] = entry.value
          .clamp(0, 1000000000)
          .toInt();
    }
    state.relicLevels.removeWhere(
      (id, _) => !state.unlockedRelics.contains(id),
    );
    for (final relicId in state.unlockedRelics) {
      state.relicLevels[relicId] = (state.relicLevels[relicId] ?? 1)
          .clamp(1, 5)
          .toInt();
    }
    for (final entry in state.specialists.entries.toList()) {
      state.specialists[entry.key] = entry.value.clamp(0, 3).toInt();
    }
    for (final entry in state.pendingCaveLoot.entries.toList()) {
      if (entry.value < 0) state.pendingCaveLoot[entry.key] = 0;
    }
    state.depthMeters = state.depthMeters.clamp(0, 1e12).toDouble();
    state.deepestMeters = state.deepestMeters
        .clamp(state.depthMeters, 1e12)
        .toDouble();

    var reconstructedCargo = 0.0;
    for (final entry in state.inventory.entries.toList()) {
      final resource = ResourceCatalog.byId[entry.key];
      if (resource == null ||
          (resource.kind != ResourceKind.mineral &&
              resource.kind != ResourceKind.isotope)) {
        continue;
      }
      final weight = resource.weight < 1 ? 1 : resource.weight;
      final remainingUnits =
          ((state.effectiveCargoCapacity - reconstructedCargo) / weight)
              .floor()
              .clamp(0, entry.value)
              .toInt();
      state.inventory[entry.key] = remainingUnits;
      reconstructedCargo += remainingUnits * weight;
    }
    state.cargoUsed = reconstructedCargo;

    final hasWorldSnapshots =
        state.worldDepths.isNotEmpty || state.worldInventories.isNotEmpty;
    if (state.activeWorldIndex < 0 || state.activeWorldIndex > 2) {
      state.activeWorldIndex = state.depthMeters >= worldEntryDepths[2]
          ? 2
          : state.depthMeters >= worldEntryDepths[1]
          ? 1
          : 0;
    }
    state.worldDepths
      ..removeWhere(
        (key, value) =>
            int.tryParse(key) == null ||
            int.parse(key) < 0 ||
            int.parse(key) > 2 ||
            !value.isFinite ||
            value < 0,
      )
      ..putIfAbsent('0', () => worldEntryDepths[0])
      ..putIfAbsent('1', () => worldEntryDepths[1])
      ..putIfAbsent('2', () => worldEntryDepths[2]);
    state.worldPressures
      ..removeWhere(
        (key, value) =>
            int.tryParse(key) == null ||
            int.parse(key) < 0 ||
            int.parse(key) > 2 ||
            !value.isFinite,
      )
      ..putIfAbsent('0', () => 14)
      ..putIfAbsent('1', () => 14)
      ..putIfAbsent('2', () => 14);
    state.worldCargoUsed.removeWhere(
      (key, value) =>
          int.tryParse(key) == null ||
          int.parse(key) < 0 ||
          int.parse(key) > 2 ||
          !value.isFinite ||
          value < 0,
    );
    state.worldInventories.removeWhere(
      (key, _) =>
          int.tryParse(key) == null || int.parse(key) < 0 || int.parse(key) > 2,
    );
    state.worldReserves.removeWhere(
      (key, _) =>
          int.tryParse(key) == null || int.parse(key) < 0 || int.parse(key) > 2,
    );

    for (var world = 0; world < worldEntryDepths.length; world++) {
      final key = world.toString();
      final worldInventory = state.worldInventories.putIfAbsent(
        key,
        () => world == state.activeWorldIndex
            ? Map<String, int>.from(state.inventory)
            : {'coal': 0, 'copper': 0},
      );
      worldInventory.removeWhere((_, amount) => amount < 0);
      var used = 0.0;
      for (final entry in worldInventory.entries.toList()) {
        final resource = ResourceCatalog.byId[entry.key];
        if (resource == null ||
            (resource.kind != ResourceKind.mineral &&
                resource.kind != ResourceKind.isotope)) {
          continue;
        }
        final weight = resource.weight < 1 ? 1 : resource.weight;
        final remaining = ((state.effectiveCargoCapacity - used) / weight)
            .floor()
            .clamp(0, entry.value)
            .toInt();
        worldInventory[entry.key] = remaining;
        used += remaining * weight;
      }
      state.worldCargoUsed[key] = used;
      state.worldDepths[key] = state.worldDepths[key]!
          .clamp(worldEntryDepths[world], 1e12)
          .toDouble();
      final worldReserves = state.worldReserves.putIfAbsent(
        key,
        () => world == state.activeWorldIndex
            ? Map<String, int>.from(state.reserves)
            : <String, int>{},
      );
      worldReserves.removeWhere((_, amount) => amount < 0);
      for (final entry in worldReserves.entries.toList()) {
        worldReserves[entry.key] = entry.value
            .clamp(0, worldInventory[entry.key] ?? 0)
            .toInt();
      }
      state.worldPressures[key] = state.worldPressures[key]!
          .clamp(0, 100)
          .toDouble();
    }

    final activeKey = state.activeWorldIndex.toString();
    if (hasWorldSnapshots) {
      state.depthMeters = state.worldDepths[activeKey]!
          .clamp(worldEntryDepths[state.activeWorldIndex], 1e12)
          .toDouble();
      state.pressure = state.worldPressures[activeKey]!;
      state.inventory
        ..clear()
        ..addAll(state.worldInventories[activeKey]!);
      state.reserves
        ..clear()
        ..addAll(state.worldReserves[activeKey]!);
      state.cargoUsed = state.worldCargoUsed[activeKey]!;
      state.deepestMeters = state.deepestMeters.clamp(state.depthMeters, 1e12);
    } else {
      state.worldDepths[activeKey] = state.depthMeters;
      state.worldPressures[activeKey] = state.pressure;
      state.worldCargoUsed[activeKey] = state.cargoUsed;
      state.worldInventories[activeKey] = Map<String, int>.from(
        state.inventory,
      );
      state.worldReserves[activeKey] = Map<String, int>.from(state.reserves);
    }
    return state;
  }
}
