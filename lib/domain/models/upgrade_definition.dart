import 'dart:math' as math;

class UpgradeTrackDefinition {
  const UpgradeTrackDefinition({
    required this.id,
    required this.name,
    required this.baseCost,
    required this.costGrowth,
    required this.effect,
    this.costOverrides = const {},
    this.materialCostsByLevel = const {},
    this.maxLevel = 100,
  });

  final String id;
  final String name;
  final int baseCost;
  final double costGrowth;
  final String effect;
  final Map<int, int> costOverrides;
  final Map<int, Map<String, int>> materialCostsByLevel;
  final int maxLevel;

  UpgradeLevelDefinition level(int value) => UpgradeLevelDefinition(
    id: '${id}_$value',
    trackId: id,
    level: value,
    name: '$name • Şema ${value.toString().padLeft(2, '0')}',
    cost:
        costOverrides[value] ??
        (baseCost * math.pow(costGrowth, value - 1))
            .round()
            .clamp(1, 1e18)
            .toInt(),
    effect: effect,
    materialCosts: materialCostsByLevel[value] ?? const {},
  );
}

class UpgradeLevelDefinition {
  const UpgradeLevelDefinition({
    required this.id,
    required this.trackId,
    required this.level,
    required this.name,
    required this.cost,
    required this.effect,
    this.materialCosts = const {},
  });

  final String id;
  final String trackId;
  final int level;
  final String name;
  final int cost;
  final String effect;
  final Map<String, int> materialCosts;
}

abstract final class UpgradeCatalog {
  static const List<UpgradeTrackDefinition> tracks = [
    UpgradeTrackDefinition(
      id: 'drill',
      name: 'Sondaj ucu',
      baseCost: 52,
      costGrowth: 1.18,
      effect: 'Derinlik ilerleme hızını artırır.',
      costOverrides: {2: 150, 3: 3500},
      materialCostsByLevel: {
        3: {'coal': 20, 'copper': 3, 'silver': 1},
      },
    ),
    UpgradeTrackDefinition(
      id: 'workers',
      name: 'İşçi eğitimi',
      baseCost: 72,
      costGrowth: 1.19,
      effect: 'Kazı ekibinin cevher çıkarma hızını artırır.',
    ),
    UpgradeTrackDefinition(
      id: 'lift',
      name: 'Kuyu asansörü',
      baseCost: 45,
      costGrowth: 1.18,
      effect: 'Kargo kapasitesini ve tahliye hızını artırır.',
    ),
    UpgradeTrackDefinition(
      id: 'warehouse',
      name: 'Kargo ambarı',
      baseCost: 60,
      costGrowth: 1.18,
      effect: 'Kargo kapasitesini artırır.',
    ),
    UpgradeTrackDefinition(
      id: 'scanner',
      name: 'Mineral tarayıcı',
      baseCost: 95,
      costGrowth: 1.19,
      effect: 'İzotop ve sandık bulma şansını artırır.',
    ),
    UpgradeTrackDefinition(
      id: 'foundry',
      name: 'Dökümhane',
      baseCost: 180,
      costGrowth: 1.2,
      effect: 'Cevher işleme tariflerini ve üretim hızını açar.',
    ),
    UpgradeTrackDefinition(
      id: 'weapon',
      name: 'Muhafız silahı',
      baseCost: 260,
      costGrowth: 1.2,
      effect: 'Muhafızlara verilen hasarı artırır.',
    ),
    UpgradeTrackDefinition(
      id: 'reactor',
      name: 'Çekirdek reaktörü',
      baseCost: 900,
      costGrowth: 1.22,
      effect: 'Reaktör ızgarasını büyütür, modül yuvaları açar.',
      costOverrides: {2: 20000, 3: 200000, 4: 750000, 5: 1500000},
      materialCostsByLevel: {
        2: {'building_material': 25, 'e1': 10},
        3: {'building_material': 50, 'e1': 100},
        4: {'building_material': 100, 'e2': 50},
        5: {'building_material': 500, 'e3': 30},
      },
    ),
  ];

  static final Map<String, UpgradeTrackDefinition> byId = {
    for (final track in tracks) track.id: track,
  };

  /// Eight upgrade families with 100 individually addressable level records.
  static final List<UpgradeLevelDefinition> levels = [
    for (final track in tracks)
      for (var level = 1; level <= track.maxLevel; level++) track.level(level),
  ];

  static final Map<String, List<UpgradeLevelDefinition>> levelsByTrack = {
    for (final track in tracks)
      track.id: levels.where((level) => level.trackId == track.id).toList(),
  };

  static UpgradeLevelDefinition? next(String trackId, int currentLevel) {
    final family = levelsByTrack[trackId];
    final familyLimit = trackId == 'reactor' ? 5 : family?.length ?? 0;
    if (family == null || currentLevel < 0 || currentLevel >= familyLimit) {
      return null;
    }
    return family[currentLevel];
  }
}
