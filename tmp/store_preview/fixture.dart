import 'dart:convert';
import 'dart:io';

import 'package:tasin_alti/domain/models/game_state.dart';

void main(List<String> args) {
  final now = DateTime.now();
  final outputDirectory = Directory('tmp/store_preview/fixtures')..createSync(recursive: true);
  for (final language in ['tr', 'en']) {
    for (final stage in ['start', 'crusher', 'midgame', 'advanced']) {
      final state = GameState.newGame(lastSavedAt: now, seed: 135790);
      state
        ..openingComicSeen = true
        ..languageCode = language;
      switch (stage) {
        case 'start':
          state.inventory['coal'] = 12;
        case 'crusher':
          state
            ..depthMeters = 8000
            ..deepestMeters = 8000
            ..questDepthBaselineMeters = 5000
            ..coins = 250000
            ..crewCount = 5
            ..guidedProgression = false
            ..crusherRepaired = true
            ..crusherLevel = 3
            ..totalOreCrushed = 548
            ..totalMined = 850
            ..cargoUsed = 345
            ..drillBitLevel = 4
            ..drillEngineLevel = 3;
          state.unlockedBuildings.addAll(['elevator', 'workshop', 'warehouse', 'trade', 'crusher', 'research', 'expedition']);
          state.inventory.addAll({'coal': 245, 'copper': 64, 'iron': 36});
          state.rawOreInventory.addAll({'coal': 48, 'copper': 17, 'iron': 11});
        case 'midgame':
          state
            ..depthMeters = 52000
            ..deepestMeters = 52000
            ..questDepthBaselineMeters = 5000
            ..coins = 1250000
            ..crewCount = 12
            ..guidedProgression = false
            ..cavesCompleted = 3
            ..relicsFound = 4
            ..scientists = 4
            ..caveDroneCount = 3
            ..drones = 7
            ..totalMined = 16200
            ..cargoUsed = 915
            ..drillBitLevel = 12
            ..drillEngineLevel = 10
            ..crusherRepaired = true;
          state.unlockedBuildings.addAll(['elevator', 'workshop', 'warehouse', 'trade', 'crusher', 'research', 'expedition', 'caves', 'scientists']);
          state.inventory.addAll({'coal': 1240, 'copper': 620, 'iron': 410, 'gold': 125, 'diamond': 24});
        case 'advanced':
          state
            ..depthMeters = 1900000
            ..deepestMeters = 1900000
            ..questDepthBaselineMeters = 5000
            ..coins = 987654321
            ..activeWorldIndex = 2
            ..crewCount = 38
            ..guidedProgression = false
            ..scientists = 11
            ..cavesCompleted = 24
            ..relicsFound = 31
            ..bossesDefeated = 6
            ..coreShards = 13
            ..drillParts = 280
            ..caveDroneCount = 12
            ..drones = 24
            ..totalMined = 845000
            ..cargoUsed = 6820
            ..drillBitLevel = 48
            ..drillFanLevel = 42
            ..drillEngineLevel = 46
            ..crusherRepaired = true;
          state
            ..worldDepths.addAll({'0': 1032000, '1': 1814000, '2': 1900000})
            ..worldMinerCounts.addAll({'0': 30, '1': 34, '2': 38})
            ..worldWorkerLevels.addAll({'0': 12, '1': 14, '2': 18});
          state.unlockedBuildings.addAll(['elevator', 'workshop', 'warehouse', 'trade', 'crusher', 'research', 'expedition', 'caves', 'scientists', 'boss', 'reactor']);
          state.inventory.addAll({'coal': 28000, 'copper': 15300, 'iron': 8600, 'gold': 5100, 'diamond': 920, 'moon_iron': 12400, 'lunar_titanium': 8600, 'titan_cobalt': 3400, 'promethium': 500});
      }
      final file = File('${outputDirectory.path}/${stage}_${language}.json');
      file.writeAsStringSync(jsonEncode(state.toJson()));
      stdout.writeln(file.path);
    }
  }
}
