import 'dart:math';

class SpecialWorkerRarityDefinition {
  const SpecialWorkerRarityDefinition({
    required this.id,
    required this.name,
    required this.power,
    required this.sellerUnitsPerLevel,
    required this.scrapValue,
    required this.colorHex,
  });

  final String id;
  final String name;
  final double power;
  final int sellerUnitsPerLevel;
  final int scrapValue;
  final int colorHex;
}

abstract final class SpecialWorkerRarityCatalog {
  static const List<SpecialWorkerRarityDefinition> all = [
    SpecialWorkerRarityDefinition(
      id: 'common',
      name: 'Yaygın',
      power: 1,
      sellerUnitsPerLevel: 10,
      scrapValue: 1,
      colorHex: 0xFFB9C7C6,
    ),
    SpecialWorkerRarityDefinition(
      id: 'uncommon',
      name: 'Az bulunan',
      power: 1.15,
      sellerUnitsPerLevel: 13,
      scrapValue: 2,
      colorHex: 0xFF63D4A4,
    ),
    SpecialWorkerRarityDefinition(
      id: 'rare',
      name: 'Nadir',
      power: 1.35,
      sellerUnitsPerLevel: 18,
      scrapValue: 4,
      colorHex: 0xFF68AFFF,
    ),
    SpecialWorkerRarityDefinition(
      id: 'legendary',
      name: 'Efsanevi',
      power: 1.7,
      sellerUnitsPerLevel: 25,
      scrapValue: 7,
      colorHex: 0xFFCA8DFF,
    ),
    SpecialWorkerRarityDefinition(
      id: 'mythic',
      name: 'Mitik',
      power: 2.1,
      sellerUnitsPerLevel: 25,
      scrapValue: 12,
      colorHex: 0xFFFFCE67,
    ),
  ];

  static final Map<String, SpecialWorkerRarityDefinition> byId = {
    for (final rarity in all) rarity.id: rarity,
  };
}

class SpecialWorkerAbilityDefinition {
  const SpecialWorkerAbilityDefinition({
    required this.id,
    required this.name,
    required this.description,
  });

  final String id;
  final String name;
  final String description;
}

abstract final class SpecialWorkerAbilityCatalog {
  static const List<SpecialWorkerAbilityDefinition> all = [
    SpecialWorkerAbilityDefinition(
      id: 'auto_seller',
      name: 'Otomatik Satıcı',
      description: 'Seçilen madeni her saniye satar; satış kilitlerine uyar.',
    ),
    SpecialWorkerAbilityDefinition(
      id: 'miner_booster',
      name: 'Sürat Madenci',
      description: 'Bulunduğu katta ekibin cevher çıkarma hızını artırır.',
    ),
    SpecialWorkerAbilityDefinition(
      id: 'drill_booster',
      name: 'Uç Ustası',
      description: 'Bulunduğu katta sondajı hızlandırır.',
    ),
    SpecialWorkerAbilityDefinition(
      id: 'chest_hunter',
      name: 'Sandık Avcısı',
      description: 'Bulunduğu katta eski sandık izlerini daha sık bulur.',
    ),
    SpecialWorkerAbilityDefinition(
      id: 'resource_booster',
      name: 'Damar Yöneticisi',
      description: 'Bulunduğu katta ek cevher çıkarır.',
    ),
    SpecialWorkerAbilityDefinition(
      id: 'rare_drop_booster',
      name: 'İzotop İz Sürücü',
      description: 'Bulunduğu katta nadir kaynak olasılığını yükseltir.',
    ),
    SpecialWorkerAbilityDefinition(
      id: 'buff_generator',
      name: 'Kristal Şamanı',
      description: 'Düzenli aralıklarla kısa sondaj buffı üretir.',
    ),
    SpecialWorkerAbilityDefinition(
      id: 'support',
      name: 'İskele Ustası',
      description: 'Bulunduğu katta depoyu ve basınç direncini destekler.',
    ),
  ];

  static final Map<String, SpecialWorkerAbilityDefinition> byId = {
    for (final ability in all) ability.id: ability,
  };
}

class SpecialWorkerState {
  SpecialWorkerState({
    required this.id,
    required this.name,
    required this.rarityId,
    required this.abilityId,
    this.level = 1,
    this.experience = 0,
    this.assignedWorld = 0,
    this.assignedFloor = 0,
    this.autoMove = true,
    this.selectedResourceId,
  });

  final String id;
  final String name;
  String rarityId;
  String abilityId;
  int level;
  int experience;
  int assignedWorld;
  int assignedFloor;
  bool autoMove;
  String? selectedResourceId;

  SpecialWorkerRarityDefinition get rarity =>
      SpecialWorkerRarityCatalog.byId[rarityId] ??
      SpecialWorkerRarityCatalog.all.first;

  double get power => rarity.power * (1 + (level - 1) * .12);

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'rarityId': rarityId,
    'abilityId': abilityId,
    'level': level,
    'experience': experience,
    'assignedWorld': assignedWorld,
    'assignedFloor': assignedFloor,
    'autoMove': autoMove,
    'selectedResourceId': selectedResourceId,
  };

  factory SpecialWorkerState.fromJson(Map<String, Object?> json) =>
      SpecialWorkerState(
        id: json['id'] as String? ?? 'worker-legacy',
        name: json['name'] as String? ?? 'Madenci Ustası',
        rarityId: json['rarityId'] as String? ?? 'common',
        abilityId: json['abilityId'] as String? ?? 'miner_booster',
        level: (json['level'] as num?)?.toInt() ?? 1,
        experience: (json['experience'] as num?)?.toInt() ?? 0,
        assignedWorld: (json['assignedWorld'] as num?)?.toInt() ?? 0,
        assignedFloor: (json['assignedFloor'] as num?)?.toInt() ?? 0,
        autoMove: json['autoMove'] as bool? ?? true,
        selectedResourceId:
            json['selectedResourceId'] as String? ??
            ((json['abilityId'] as String?) == 'auto_seller' ? 'coal' : null),
      );

  static SpecialWorkerState create(int serial, Random random) {
    const names = [
      'Lodos',
      'Kıvılcım',
      'Mandal',
      'Çekiç',
      'Çınar',
      'Fener',
      'Kanca',
      'Poyraz',
    ];
    final roll = random.nextInt(1000);
    final rarityId = roll < 10
        ? 'mythic'
        : roll < 55
        ? 'legendary'
        : roll < 170
        ? 'rare'
        : roll < 420
        ? 'uncommon'
        : 'common';
    final ability = SpecialWorkerAbilityCatalog
        .all[random.nextInt(SpecialWorkerAbilityCatalog.all.length)];
    return SpecialWorkerState(
      id: 'super_worker_$serial',
      name: names[(serial + random.nextInt(names.length)) % names.length],
      rarityId: rarityId,
      abilityId: ability.id,
      selectedResourceId: ability.id == 'auto_seller' ? 'coal' : null,
    );
  }
}
