import 'dart:math' as math;

class DrillAssemblyDefinition {
  const DrillAssemblyDefinition({
    required this.id,
    required this.name,
    required this.baseWatts,
    required this.wattGrowth,
    required this.baseCost,
    required this.costGrowth,
  });

  final String id;
  final String name;
  final double baseWatts;
  final double wattGrowth;
  final int baseCost;
  final double costGrowth;

  double wattsAt(int level) =>
      (baseWatts * math.pow(wattGrowth, (level - 1).clamp(0, 25))).toDouble();

  int upgradeCost(int currentLevel) =>
      (baseCost * math.pow(costGrowth, (currentLevel - 1).clamp(0, 25)))
          .round()
          .clamp(1, 1e18)
          .toInt();
}

abstract final class DrillAssemblyCatalog {
  static const int maxLevel = 26;
  static const int robotMk2Level = 24;

  static const List<DrillAssemblyDefinition> all = [
    DrillAssemblyDefinition(
      id: 'bit',
      name: 'Sondaj ucu',
      baseWatts: 100,
      wattGrowth: 2.2,
      baseCost: 250,
      costGrowth: 3.0,
    ),
    DrillAssemblyDefinition(
      id: 'fan',
      name: 'Soğutma fanı',
      baseWatts: 50,
      wattGrowth: 2.0,
      baseCost: 150,
      costGrowth: 2.8,
    ),
    DrillAssemblyDefinition(
      id: 'engine',
      name: 'Sondaj motoru',
      baseWatts: 5,
      wattGrowth: 2.0,
      baseCost: 500,
      costGrowth: 3.5,
    ),
  ];

  static final Map<String, DrillAssemblyDefinition> byId = {
    for (final component in all) component.id: component,
  };

  static double power({
    required int bitLevel,
    required int fanLevel,
    required int engineLevel,
  }) {
    final bit = byId['bit']!.wattsAt(bitLevel);
    final fan = byId['fan']!.wattsAt(fanLevel);
    final engineBase = byId['engine']!.wattsAt(engineLevel);
    final engineMultiplier = math.pow(1.5, engineLevel - 1);
    return (fan + bit) * engineMultiplier + engineBase * engineMultiplier;
  }

  static double speedMultiplier({
    required int bitLevel,
    required int fanLevel,
    required int engineLevel,
  }) {
    const starterPower = 155.0;
    final ratio =
        power(
          bitLevel: bitLevel,
          fanLevel: fanLevel,
          engineLevel: engineLevel,
        ) /
        starterPower;
    // Preserve the source game's component-power curve while keeping it in
    // balance with Taşın Altı's metre-based idle progression.
    return (1 + math.log(math.max(1, ratio)) * .30).clamp(1, 6).toDouble();
  }

  static Map<String, int> materialCosts(int nextLevel) {
    if (nextLevel < robotMk2Level) return const {};
    return switch (nextLevel) {
      24 => {'helium_ore': 4, 'building_material': 8},
      25 => {'selenite': 8, 'building_material': 15},
      _ => {'helium_ore': 12, 'building_material': 25},
    };
  }
}
