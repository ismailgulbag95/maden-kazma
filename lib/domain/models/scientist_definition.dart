import 'dart:math';

class ScientistRarityDefinition {
  const ScientistRarityDefinition({
    required this.id,
    required this.name,
    required this.successBonus,
    required this.speedBonus,
  });

  final String id;
  final String name;
  final double successBonus;
  final double speedBonus;
}

abstract final class ScientistRarityCatalog {
  static const List<ScientistRarityDefinition> all = [
    ScientistRarityDefinition(
      id: 'common',
      name: 'Sıradan',
      successBonus: 0,
      speedBonus: 0,
    ),
    ScientistRarityDefinition(
      id: 'uncommon',
      name: 'Seçkin',
      successBonus: .04,
      speedBonus: .06,
    ),
    ScientistRarityDefinition(
      id: 'rare',
      name: 'Nadir',
      successBonus: .08,
      speedBonus: .12,
    ),
    ScientistRarityDefinition(
      id: 'legendary',
      name: 'Efsanevi',
      successBonus: .13,
      speedBonus: .19,
    ),
    ScientistRarityDefinition(
      id: 'mythic',
      name: 'Mitik',
      successBonus: .18,
      speedBonus: .26,
    ),
  ];

  static final Map<String, ScientistRarityDefinition> byId = {
    for (final rarity in all) rarity.id: rarity,
  };
}

class ScientistTraitDefinition {
  const ScientistTraitDefinition({
    required this.id,
    required this.name,
    required this.description,
    this.successBonus = 0,
    this.speedBonus = 0,
    this.mineralBonus = 0,
    this.relicBonus = 0,
  });

  final String id;
  final String name;
  final String description;
  final double successBonus;
  final double speedBonus;
  final double mineralBonus;
  final double relicBonus;
}

abstract final class ScientistTraitCatalog {
  static const List<ScientistTraitDefinition> all = [
    ScientistTraitDefinition(
      id: 'careful',
      name: 'Titiz arşivci',
      description: 'Görev başarısı +%5.',
      successBonus: .05,
    ),
    ScientistTraitDefinition(
      id: 'swift',
      name: 'Hızlı kazıcı',
      description: 'Kazı süresi -%18.',
      speedBonus: .18,
    ),
    ScientistTraitDefinition(
      id: 'geologist',
      name: 'Katman uzmanı',
      description: 'Cevher ganimeti +%30.',
      mineralBonus: .3,
    ),
    ScientistTraitDefinition(
      id: 'lucky',
      name: 'Şanslı gözlemci',
      description: 'Kalıntı bulma olasılığı +%12.',
      relicBonus: .12,
    ),
    ScientistTraitDefinition(
      id: 'methodical',
      name: 'Yöntemci',
      description: 'Görev başarısı +%3, kazı süresi -%5.',
      successBonus: .03,
      speedBonus: .05,
    ),
  ];

  static final Map<String, ScientistTraitDefinition> byId = {
    for (final trait in all) trait.id: trait,
  };
}

class ScientistState {
  ScientistState({
    required this.id,
    required this.name,
    required this.rarityId,
    required this.traitId,
    this.level = 1,
    this.experience = 0,
    this.injuredUntil,
    this.injuryCount = 0,
    this.dead = false,
  });

  final String id;
  final String name;
  String rarityId;
  String traitId;
  int level;
  int experience;
  DateTime? injuredUntil;
  int injuryCount;
  bool dead;

  ScientistRarityDefinition get rarity =>
      ScientistRarityCatalog.byId[rarityId] ?? ScientistRarityCatalog.all.first;
  ScientistTraitDefinition get trait =>
      ScientistTraitCatalog.byId[traitId] ?? ScientistTraitCatalog.all.first;
  bool get injured => injuredUntil?.isAfter(DateTime.now()) == true;
  double get successChanceBonus =>
      rarity.successBonus + trait.successBonus + (level - 1) * .015;
  double get excavationSpeed =>
      rarity.speedBonus + trait.speedBonus + (level - 1) * .025;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'rarityId': rarityId,
    'traitId': traitId,
    'level': level,
    'experience': experience,
    'injuredUntil': injuredUntil?.toIso8601String(),
    'injuryCount': injuryCount,
    'dead': dead,
  };

  factory ScientistState.fromJson(Map<String, Object?> json) => ScientistState(
    id: json['id'] as String? ?? 'scientist-legacy',
    name: json['name'] as String? ?? 'Ada',
    rarityId: json['rarityId'] as String? ?? 'common',
    traitId: json['traitId'] as String? ?? 'careful',
    level: (json['level'] as num?)?.toInt() ?? 1,
    experience: (json['experience'] as num?)?.toInt() ?? 0,
    injuredUntil: DateTime.tryParse(json['injuredUntil'] as String? ?? ''),
    injuryCount: (json['injuryCount'] as num?)?.toInt() ?? 0,
    dead: json['dead'] as bool? ?? false,
  );

  static ScientistState create(int serial, Random random) {
    const names = [
      'Ada',
      'Lale',
      'Deniz',
      'Mira',
      'Ekin',
      'Aras',
      'Nehir',
      'Baran',
      'Selen',
      'Kaya',
      'Duru',
      'Tuna',
    ];
    final rarityRoll = random.nextInt(1000);
    final rarityId = rarityRoll < 10
        ? 'mythic'
        : rarityRoll < 55
        ? 'legendary'
        : rarityRoll < 170
        ? 'rare'
        : rarityRoll < 420
        ? 'uncommon'
        : 'common';
    final name = names[(serial + random.nextInt(names.length)) % names.length];
    final trait = ScientistTraitCatalog
        .all[random.nextInt(ScientistTraitCatalog.all.length)];
    return ScientistState(
      id: 'scientist_$serial',
      name: name,
      rarityId: rarityId,
      traitId: trait.id,
    );
  }
}

class ScientistExpeditionDefinition {
  const ScientistExpeditionDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.minimumDepth,
    required this.duration,
    required this.baseSuccessChance,
    required this.coinReward,
    required this.resourceCount,
    required this.chestTier,
    required this.relicChance,
  });

  final String id;
  final String name;
  final String description;
  final double minimumDepth;
  final Duration duration;
  final double baseSuccessChance;
  final int coinReward;
  final int resourceCount;
  final String chestTier;
  final double relicChance;
}

abstract final class ScientistExpeditionCatalog {
  static const List<ScientistExpeditionDefinition> all = [
    ScientistExpeditionDefinition(
      id: 'survey',
      name: 'Katman Ölçümü',
      description: 'Düşük risk • cevher, kasa ve deneyim.',
      minimumDepth: 50000,
      duration: Duration(minutes: 30),
      baseSuccessChance: .92,
      coinReward: 800,
      resourceCount: 8,
      chestTier: 'basic',
      relicChance: .08,
    ),
    ScientistExpeditionDefinition(
      id: 'ancient_excavation',
      name: 'Antik Kazı',
      description: 'Orta risk • altın sandık ve kalıntı olasılığı.',
      minimumDepth: 300000,
      duration: Duration(hours: 2),
      baseSuccessChance: .82,
      coinReward: 3800,
      resourceCount: 24,
      chestTier: 'gold',
      relicChance: .35,
    ),
    ScientistExpeditionDefinition(
      id: 'titan_archive',
      name: 'Titan Kristal Arşivi',
      description: 'Yüksek risk • derin sandık ve ender kalıntı.',
      minimumDepth: 1782000,
      duration: Duration(hours: 4),
      baseSuccessChance: .68,
      coinReward: 14500,
      resourceCount: 60,
      chestTier: 'deep',
      relicChance: .62,
    ),
  ];

  static final Map<String, ScientistExpeditionDefinition> byId = {
    for (final mission in all) mission.id: mission,
  };
}
