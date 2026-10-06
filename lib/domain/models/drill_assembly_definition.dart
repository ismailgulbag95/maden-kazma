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
      (baseWatts * math.pow(wattGrowth, (level - 1).clamp(0, 42))).toDouble();

  int upgradeCost(int currentLevel) =>
      (baseCost * math.pow(costGrowth, (currentLevel - 1).clamp(0, 42)))
          .round()
          .clamp(1, 1e18)
          .toInt();
}

abstract final class DrillAssemblyCatalog {
  static const int maxLevel = 43;
  static const int robotMk2Level = 24;
  static const int robotMk3Level = 37;

  /// Early Earth blueprint prices from Mr. Mine's published blueprint table.
  /// Later prices retain this project's economy curve where exact values are
  /// not available in its compact component-level save format.
  static const Map<String, Map<int, int>> _blueprintCashCosts = {
    'bit': {
      2: 250,
      3: 5500,
      4: 50000,
      5: 600000,
      6: 20000000,
      7: 200000000,
      8: 1750000000,
      9: 8000000000,
      10: 45000000000,
      11: 160000000000,
      12: 1200000000000,
      13: 5000000000000,
      14: 0,
      15: 0,
      16: 0,
      17: 0,
      21: 0,
      22: 0,
      23: 0,
    },
    'fan': {
      2: 700,
      3: 15000,
      4: 100000,
      5: 600000,
      6: 25000000,
      7: 300000000,
      8: 1350000000,
      9: 8000000000,
      10: 40000000000,
      11: 150000000000,
      12: 1000000000000,
      13: 4000000000000,
      14: 0,
      15: 0,
      16: 0,
      17: 0,
      21: 0,
      22: 0,
      23: 0,
    },
    'engine': {
      2: 150,
      3: 3500,
      4: 50000,
      5: 300000,
      6: 10000000,
      7: 150000000,
      8: 1500000000,
      9: 10000000000,
      10: 55000000000,
      11: 180000000000,
      12: 1200000000000,
      13: 5500000000000,
      14: 0,
      15: 0,
      16: 0,
      17: 0,
      21: 0,
      22: 0,
      23: 0,
    },
  };

  /// Blueprint recipes are scaled to the smaller inventories in this game.
  /// Resource ratios and unlock order follow the published Earth blueprints.
  static const Map<String, Map<int, Map<String, int>>> _blueprintMaterials = {
    'bit': {
      3: {'coal': 10, 'silver': 3, 'gold': 1},
      4: {'gold': 10, 'platinum': 2},
      5: {'gold': 60, 'platinum': 20, 'diamond': 2},
      6: {'platinum': 500, 'diamond': 100},
      7: {'platinum': 1500, 'coltan': 1000},
      8: {'diamond': 1000, 'pu1': 1},
      9: {'diamond': 15000, 'painite': 1500},
      10: {'coltan': 5000, 'blue_obsidian': 1},
      11: {'black_opal': 2500, 'po2': 1, 'californium': 600},
      12: {'oil': 1, 'coal': 50000},
      13: {'oil': 3, 'copper': 150000},
      14: {'oil': 10},
      15: {'oil': 10, 'gold': 2000, 'u2': 1, 'po1': 1},
      16: {'oil': 10, 'copper': 7500},
      17: {'oil': 40},
      18: {'carbon': 5, 'coal': 5000, 'n1': 5},
      19: {'carbon': 100, 'n1': 10},
      20: {'carbon': 1000, 'n3': 5, 'gold': 2000},
      21: {'carbon': 2000, 'n2': 4, 'painite': 10000, 'magnesium': 3},
      22: {'lunar_titanium': 10, 'n2': 4, 'painite': 20000, 'magnesium': 3},
      23: {'lunar_titanium': 150, 'n3': 10, 'magnesium': 5, 'oil': 80},
      24: {'moon_iron': 10000, 'lunar_titanium': 100, 'he3': 1},
      25: {'carbon': 35000, 'moon_iron': 10000, 'oil': 80, 'n3': 500},
      26: {'silicon': 50000, 'n1': 2000, 'e1': 1},
      27: {'silver': 1000, 'silicon': 100, 'e2': 1},
      28: {'promethium': 50, 'e3': 1},
      29: {'lunar_titanium': 100, 'promethium': 100, 'e1': 5, 'e2': 1},
      30: {'neodymium': 40, 'ytterbium': 1, 'f1': 1},
      31: {'lunar_titanium': 200, 'ytterbium': 8, 'f2': 1},
      32: {'lunar_titanium': 300, 'ytterbium': 1000, 'f3': 1},
      33: {'neodymium': 100, 'tin': 10},
      34: {'sulfur': 200, 'e1': 5, 'h2': 20},
      35: {'tin': 500, 'o1': 1},
      36: {'lunar_titanium': 500, 'o3': 1},
      37: {'manganese': 750, 'f1': 1},
      38: {'sulfur': 2000, 'lithium': 2000, 'manganese': 20},
      39: {'lunar_titanium': 3000, 'o3': 100},
      40: {'mercury': 3000, 'h3': 800, 'o3': 200},
      41: {'nickel': 5000},
      42: {'alexandrite': 800, 'benitoite': 50},
      43: {'sulfur': 10000, 'lithium': 10000, 'titan_cobalt': 500},
    },
    'fan': {
      3: {'copper': 9, 'silver': 2},
      4: {'silver': 50},
      5: {'silver': 80, 'gold': 30, 'platinum': 10},
      6: {'silver': 1000, 'gold': 1000},
      7: {'gold': 2500, 'diamond': 500},
      8: {'platinum': 1500, 'coltan': 100, 'painite': 10},
      9: {'coltan': 1000, 'black_opal': 1000, 'red_diamond': 300},
      10: {'coltan': 3000, 'painite': 1000},
      11: {'black_opal': 1500, 'blue_obsidian': 150},
      12: {'oil': 1, 'californium': 40000},
      13: {'oil': 10, 'californium': 100000},
      14: {'oil': 5},
      15: {'oil': 5, 'blue_obsidian': 1250, 'red_diamond': 750},
      16: {'oil': 10, 'pu1': 300},
      17: {'oil': 20},
      18: {'moon_iron': 10},
      19: {'moon_iron': 1000, 'pu1': 1000, 'u1': 1000},
      20: {'moon_iron': 1000, 'aluminum': 5},
      21: {'moon_iron': 3500, 'aluminum': 50, 'magnesium': 5},
      22: {'lunar_titanium': 1, 'aluminum': 500, 'magnesium': 4},
      23: {'lunar_titanium': 200, 'he2': 40, 'he3': 1},
      24: {'aluminum': 10000, 'lunar_titanium': 100, 'he3': 1},
      25: {'aluminum': 35000, 'silicon': 5, 'oil': 80, 'n3': 350},
      26: {'silicon': 30000, 'lunar_titanium': 10000, 'e1': 1},
      27: {'silicon': 1000, 'e2': 1},
      28: {'promethium': 50, 'e3': 1},
      29: {'californium': 10000, 'e1': 5, 'e2': 1},
      30: {'neodymium': 30, 'f1': 1},
      31: {'neodymium': 400, 'f2': 1},
      32: {'neodymium': 10000, 'f3': 1},
      33: {'tin': 100, 'e1': 1},
      34: {'sulfur': 500, 'h3': 10},
      35: {'sulfur': 10000, 'o2': 1},
      36: {'e2': 2, 'o3': 1},
      37: {'manganese': 500, 'e3': 1},
      38: {'tin': 2000, 'manganese': 50},
      39: {'manganese': 2000, 'e2': 1, 'f2': 1},
      40: {'mercury': 1000, 'o3': 100},
      41: {'nickel': 50},
      42: {'nickel': 5, 'alexandrite': 500},
      43: {'benitoite': 500, 'titan_cobalt': 50, 'n3': 5},
    },
    'engine': {
      3: {'coal': 20, 'copper': 3, 'silver': 1},
      4: {'coal': 40, 'copper': 20, 'silver': 15},
      5: {'coal': 50, 'silver': 50, 'gold': 30, 'platinum': 10},
      6: {'coal': 500, 'u1': 3},
      7: {'coal': 1000, 'copper': 1000, 'u1': 2},
      8: {'coal': 5000, 'u1': 5, 'u2': 1, 'u3': 1},
      9: {'u1': 30, 'pu1': 15, 'po1': 5},
      10: {'coltan': 1000, 'po1': 10},
      11: {'red_diamond': 5000, 'po1': 30, 'po3': 1},
      12: {'oil': 1, 'californium': 5000, 'po3': 1},
      13: {'oil': 2, 'californium': 15000, 'po3': 1},
      14: {'oil': 10, 'po3': 2},
      15: {'oil': 10, 'californium': 10000, 'u3': 1},
      16: {'oil': 20, 'californium': 3000, 'pu3': 1},
      17: {'oil': 40, 'coal': 100000, 'u1': 50, 'u2': 3},
      18: {'carbon': 5, 'oil': 1},
      19: {'carbon': 200, 'oil': 40, 'moon_iron': 40},
      20: {'aluminum': 5, 'n2': 1},
      21: {'aluminum': 50, 'magnesium': 1, 'painite': 10000, 'n3': 1},
      22: {'aluminum': 500, 'magnesium': 10, 'n3': 1},
      23: {'lunar_titanium': 150, 'oil': 80},
      24: {'carbon': 10000, 'lunar_titanium': 100, 'he3': 1},
      25: {'magnesium': 35000, 'oil': 50, 'n3': 50},
      26: {'lunar_titanium': 1500},
      27: {'lunar_titanium': 1000, 'silicon': 100, 'e2': 1},
      28: {'promethium': 500, 'e3': 1},
      29: {'californium': 10000, 'e1': 5, 'e2': 1},
      30: {'neodymium': 400, 'ytterbium': 1, 'f1': 1},
      31: {'lunar_titanium': 20000, 'ytterbium': 80, 'f2': 1},
      32: {'lunar_titanium': 30000, 'ytterbium': 1000, 'f3': 1},
      33: {'neodymium': 100, 'tin': 1},
      34: {'sulfur': 2, 'e1': 5, 'h2': 20},
      35: {'tin': 50, 'o1': 1},
      36: {'lunar_titanium': 500, 'o3': 1},
      37: {'h1': 5, 'h2': 1, 'o3': 1},
      38: {'manganese': 250, 'o1': 100, 'o2': 10},
      39: {'manganese': 7500, 'h2': 1, 'o3': 1},
      40: {'lunar_titanium': 5000, 'nickel': 3000, 'o3': 1},
      41: {'nickel': 4000, 'alexandrite': 50},
      42: {'alexandrite': 1000, 'benitoite': 50},
      43: {'manganese': 5000, 'mercury': 2500, 'titan_cobalt': 2000},
    },
  };

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

  static Map<String, int> materialCosts(String componentId, int nextLevel) {
    return _blueprintMaterials[componentId]?[nextLevel] ?? const {};
  }

  static int cashCost(DrillAssemblyDefinition component, int currentLevel) =>
      _blueprintCashCosts[component.id]?[currentLevel + 1] ??
      component.upgradeCost(currentLevel);

  static int requiredDepthFor(int nextLevel) => switch (nextLevel) {
    <= 5 => 0,
    <= 9 => 50000,
    <= 13 => 225000,
    <= 17 => 100000,
    <= 23 => 1032000,
    <= 26 => 1257000,
    <= 32 => 1032000,
    <= 36 => 1814000,
    <= 43 => 2039000,
    _ => 1 << 30,
  };

  static String? requiredBuildingFor(int nextLevel) => switch (nextLevel) {
    >= robotMk2Level && <= 26 => 'robot_mk2',
    >= robotMk3Level && <= 40 => 'robot_mk3',
    _ => null,
  };
}
