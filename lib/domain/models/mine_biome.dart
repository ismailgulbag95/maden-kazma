import 'game_state.dart';
import 'mr_mine_level_table.dart';
import 'resource_definition.dart';

/// The level table is the source of truth for both passive ore and deposits.
abstract final class MineBiome {
  static const metersPerFloor = 1000;

  static int floorAt(double depthMeters) => (depthMeters / metersPerFloor)
      .floor()
      .clamp(0, MrMineLevelTable.rows.length - 1);

  static int worldAt(double depthMeters) {
    if (depthMeters >= GameState.worldEntryDepths[2]) return 2;
    if (depthMeters >= GameState.worldEntryDepths[1]) return 1;
    return 0;
  }

  static bool containsMineral(double depthMeters, String resourceId) {
    if (depthMeters < 0 ||
        depthMeters >= MrMineLevelTable.rows.length * metersPerFloor) {
      return false;
    }
    final resource = ResourceCatalog.byId[resourceId];
    return resource?.kind == ResourceKind.mineral &&
        (MrMineLevelTable.rows[floorAt(depthMeters)][resourceId] ?? 0) > 0;
  }

  static ResourceDefinition? dominantMineral(double depthMeters) {
    if (depthMeters < 0 ||
        depthMeters >= MrMineLevelTable.rows.length * metersPerFloor) {
      return null;
    }
    ResourceDefinition? dominant;
    var highestWeight = 0.0;
    for (final entry in MrMineLevelTable.rows[floorAt(depthMeters)].entries) {
      final resource = ResourceCatalog.byId[entry.key];
      if (resource?.kind != ResourceKind.mineral ||
          entry.value <= highestWeight) {
        continue;
      }
      highestWeight = entry.value;
      dominant = resource;
    }
    return dominant;
  }
}
