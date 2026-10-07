import 'mr_mine_drill_blueprint_table.dart';

class DrillAssemblyDefinition {
  const DrillAssemblyDefinition({required this.id, required this.name});

  final String id;
  final String name;

  double wattsAt(int level) => DrillAssemblyCatalog.baseWattsAt(id, level);
}

abstract final class DrillAssemblyCatalog {
  static const int maxLevel = 43;
  static const int robotMk2Level = 24;
  static const int robotMk3Level = 37;
  static const Map<String, int> blueprintSlots = {
    'engine': 0,
    'bit': 1,
    'fan': 2,
    'cargo': 3,
  };

  /// The source game's drill blueprint order is engine, bit, fan, cargo for
  /// each equipment level, starting with level 2 at blueprint ID 0.
  static int? blueprintIdFor(String componentId, int targetLevel) {
    final slot = blueprintSlots[componentId];
    if (slot == null || targetLevel < 2) return null;
    final id = (targetLevel - 2) * 4 + slot;
    return id <= 158 ? id : null;
  }


  static const List<DrillAssemblyDefinition> all = [
    DrillAssemblyDefinition(id: 'bit', name: 'Sondaj ucu'),
    DrillAssemblyDefinition(id: 'fan', name: 'Soğutma fanı'),
    DrillAssemblyDefinition(id: 'engine', name: 'Sondaj motoru'),
  ];

  static final Map<String, DrillAssemblyDefinition> byId = {
    for (final component in all) component.id: component,
  };

  static double baseWattsAt(String componentId, int level) {
    final values = MrMineDrillBlueprintTable.baseWatts[componentId];
    if (values == null || values.isEmpty) return 0;
    return values[(level - 1).clamp(0, values.length - 1).toInt()];
  }

  static double wattMultiplierAt(String componentId, int level) {
    final values = MrMineDrillBlueprintTable.wattMultipliers[componentId];
    if (values == null || values.isEmpty) return 1;
    return values[(level - 1).clamp(0, values.length - 1).toInt()];
  }

  static double power({
    required int bitLevel,
    required int fanLevel,
    required int engineLevel,
  }) {
    final basePower =
        baseWattsAt('bit', bitLevel) +
        baseWattsAt('fan', fanLevel) +
        baseWattsAt('engine', engineLevel);
    final multiplier =
        wattMultiplierAt('bit', bitLevel) *
        wattMultiplierAt('fan', fanLevel) *
        wattMultiplierAt('engine', engineLevel);
    return basePower * multiplier;
  }

  /// Relative to the starter 5 W assembly. Kept for compact HUD presentation.
  static double speedMultiplier({
    required int bitLevel,
    required int fanLevel,
    required int engineLevel,
  }) =>
      power(bitLevel: bitLevel, fanLevel: fanLevel, engineLevel: engineLevel) /
      5;

  static Map<String, int> materialCosts(String componentId, int nextLevel) =>
      MrMineDrillBlueprintTable.materialCosts[componentId]?[nextLevel] ??
      const {};

  static double cashCost(DrillAssemblyDefinition component, int currentLevel) =>
      MrMineDrillBlueprintTable.cashCosts[component.id]?[currentLevel + 1] ?? 0;

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
