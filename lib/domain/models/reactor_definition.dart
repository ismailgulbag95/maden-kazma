class ReactorComponentDefinition {
  const ReactorComponentDefinition({
    required this.id,
    required this.name,
    required this.shortName,
    this.heatGenerated = 0,
    this.heatCooled = 0,
    this.energyPerSecond = 0,
    this.minimumLevel = 1,
  });

  final String id;
  final String name;
  final String shortName;
  final int heatGenerated;
  final int heatCooled;
  final int energyPerSecond;
  final int minimumLevel;
}

class ReactorIsotopeRecipe {
  const ReactorIsotopeRecipe({
    required this.id,
    required this.name,
    required this.energyCost,
    required this.minimumDepthMeters,
  });

  final String id;
  final String name;
  final int energyCost;
  final double minimumDepthMeters;
}

abstract final class ReactorCatalog {
  static const List<ReactorComponentDefinition> components = [
    ReactorComponentDefinition(
      id: 'fuel_rod',
      name: 'Uranyum yakıt çubuğu',
      shortName: 'YAKIT',
      heatGenerated: 20,
      energyPerSecond: 15,
    ),
    ReactorComponentDefinition(
      id: 'cooling_fan',
      name: 'Soğutma fanı',
      shortName: 'FAN',
      heatCooled: 12,
    ),
    ReactorComponentDefinition(
      id: 'cryo_fan',
      name: 'Kriyojenik ısı dağıtıcı',
      shortName: 'KRİYO',
      heatCooled: 24,
      minimumLevel: 2,
    ),
    ReactorComponentDefinition(
      id: 'battery',
      name: 'Güç bataryası',
      shortName: 'PİL',
      energyPerSecond: 5,
    ),
    ReactorComponentDefinition(
      id: 'neutron_bombardment',
      name: 'Nötron bombardımanı',
      shortName: 'NÖTRON',
      heatGenerated: 45,
      energyPerSecond: 40,
      minimumLevel: 3,
    ),
  ];

  static final Map<String, ReactorComponentDefinition> componentById = {
    for (final component in components) component.id: component,
  };

  static const List<ReactorIsotopeRecipe> isotopeRecipes = [
    ReactorIsotopeRecipe(
      id: 'e1',
      name: 'Einsteinyum I',
      energyCost: 25,
      minimumDepthMeters: 1133000,
    ),
    ReactorIsotopeRecipe(
      id: 'e2',
      name: 'Einsteinyum II',
      energyCost: 75,
      minimumDepthMeters: 1200000,
    ),
    ReactorIsotopeRecipe(
      id: 'e3',
      name: 'Einsteinyum III',
      energyCost: 180,
      minimumDepthMeters: 1250000,
    ),
    ReactorIsotopeRecipe(
      id: 'f1',
      name: 'Fermiyum I',
      energyCost: 150,
      minimumDepthMeters: 1150000,
    ),
    ReactorIsotopeRecipe(
      id: 'f2',
      name: 'Fermiyum II',
      energyCost: 140,
      minimumDepthMeters: 1200000,
    ),
    ReactorIsotopeRecipe(
      id: 'f3',
      name: 'Fermiyum III',
      energyCost: 320,
      minimumDepthMeters: 1250000,
    ),
  ];

  static final Map<String, ReactorIsotopeRecipe> isotopeById = {
    for (final recipe in isotopeRecipes) recipe.id: recipe,
  };

  static int gridLevel(int upgradeLevel) => upgradeLevel.clamp(1, 5).toInt();

  static int gridDimension(int upgradeLevel) =>
      switch (gridLevel(upgradeLevel)) {
        1 => 3,
        2 => 4,
        3 => 5,
        4 => 7,
        _ => 9,
      };

  static int slotCount(int upgradeLevel) => switch (gridLevel(upgradeLevel)) {
    1 => 9,
    2 => 15,
    3 => 25,
    4 => 45,
    _ => 81,
  };

  static List<(int, int)> cells(int upgradeLevel) {
    final dimension = gridDimension(upgradeLevel);
    return [
      for (var index = 0; index < slotCount(upgradeLevel); index++)
        (index % dimension, index ~/ dimension),
    ];
  }

  static bool containsCell(int upgradeLevel, int x, int y) =>
      cells(upgradeLevel).contains((x, y));

  static Map<String, String> starterLayout() => {
    '1,1': 'fuel_rod',
    '0,1': 'cooling_fan',
    '2,1': 'cooling_fan',
  };
}
