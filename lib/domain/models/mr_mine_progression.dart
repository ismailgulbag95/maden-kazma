/// Mineral discovery and rich-depth gates adapted from Mr. Mine's materials
/// tables. The active shaft rarity table is copied separately from the live
/// browser source. Values are in meters; artwork remains project-made.
class MrMineMineralBand {
  const MrMineMineralBand({
    required this.resourceId,
    required this.worldIndex,
    required this.firstDepthMeters,
    required this.richFromMeters,
    required this.richUntilMeters,
  });

  final String resourceId;
  final int worldIndex;
  final int firstDepthMeters;
  final int richFromMeters;
  final int richUntilMeters;

  bool isRichAt(double depthMeters) =>
      depthMeters >= richFromMeters && depthMeters <= richUntilMeters;
}

abstract final class MrMineProgression {
  static const earthEndMeters = 1000000;
  static const moonStartMeters = 1032000;
  static const moonEndMeters = 1782000;
  static const titanStartMeters = 1814000;
  static const titanEndMeters = 2567000;

  /// Wiki-listed shafts that produce helium-3 on the Moon.
  static const Set<int> moonHelium3DepthKm = {
    1133,
    1148,
    1156,
    1181,
    1182,
    1216,
    1217,
    1268,
    1301,
    1316,
    1332,
    1354,
    1371,
    1390,
    1414,
    1434,
    1452,
    1477,
    1506,
    1542,
    1562,
    1587,
    1611,
    1630,
    1642,
    1672,
    1691,
    1705,
    1735,
    1762,
    1782,
  };

  /// The Wiki lists discrete mineshafts for the Titan isotope families.
  static const Set<int> titanHydrogenDepthKm = {
    1849,
    1885,
    1915,
    1961,
    1993,
    2026,
    2065,
    2106,
    2153,
  };
  static const Set<int> titanOxygenDepthKm = {
    1914,
    1960,
    1992,
    2025,
    2064,
    2105,
    2152,
  };

  /// Wiki `Materials` table, with world-absolute depths converted to meters.
  static const List<MrMineMineralBand> minerals = [
    MrMineMineralBand(
      resourceId: 'coal',
      worldIndex: 0,
      firstDepthMeters: 0,
      richFromMeters: 0,
      richUntilMeters: 14000,
    ),
    MrMineMineralBand(
      resourceId: 'copper',
      worldIndex: 0,
      firstDepthMeters: 4000,
      richFromMeters: 7000,
      richUntilMeters: 19000,
    ),
    MrMineMineralBand(
      resourceId: 'silver',
      worldIndex: 0,
      firstDepthMeters: 13000,
      richFromMeters: 18000,
      richUntilMeters: 24000,
    ),
    MrMineMineralBand(
      resourceId: 'gold',
      worldIndex: 0,
      firstDepthMeters: 17000,
      richFromMeters: 24000,
      richUntilMeters: 41000,
    ),
    MrMineMineralBand(
      resourceId: 'platinum',
      worldIndex: 0,
      firstDepthMeters: 21000,
      richFromMeters: 41000,
      richUntilMeters: 55000,
    ),
    MrMineMineralBand(
      resourceId: 'diamond',
      worldIndex: 0,
      firstDepthMeters: 30000,
      richFromMeters: 48000,
      richUntilMeters: 71000,
    ),
    MrMineMineralBand(
      resourceId: 'coltan',
      worldIndex: 0,
      firstDepthMeters: 45000,
      richFromMeters: 72000,
      richUntilMeters: 80000,
    ),
    MrMineMineralBand(
      resourceId: 'painite',
      worldIndex: 0,
      firstDepthMeters: 60000,
      richFromMeters: 81000,
      richUntilMeters: 102000,
    ),
    MrMineMineralBand(
      resourceId: 'black_opal',
      worldIndex: 0,
      firstDepthMeters: 79000,
      richFromMeters: 103000,
      richUntilMeters: 199000,
    ),
    MrMineMineralBand(
      resourceId: 'red_diamond',
      worldIndex: 0,
      firstDepthMeters: 80000,
      richFromMeters: 200000,
      richUntilMeters: 300000,
    ),
    MrMineMineralBand(
      resourceId: 'blue_obsidian',
      worldIndex: 0,
      firstDepthMeters: 93000,
      richFromMeters: 301000,
      richUntilMeters: 400000,
    ),
    MrMineMineralBand(
      resourceId: 'californium',
      worldIndex: 0,
      firstDepthMeters: 305000,
      richFromMeters: 401000,
      richUntilMeters: 1000000,
    ),
    MrMineMineralBand(
      resourceId: 'carbon',
      worldIndex: 1,
      firstDepthMeters: 1032000,
      richFromMeters: 1032000,
      richUntilMeters: 1782000,
    ),
    MrMineMineralBand(
      resourceId: 'moon_iron',
      worldIndex: 1,
      firstDepthMeters: 1041000,
      richFromMeters: 1131000,
      richUntilMeters: 1782000,
    ),
    MrMineMineralBand(
      resourceId: 'aluminum',
      worldIndex: 1,
      firstDepthMeters: 1042000,
      richFromMeters: 1196000,
      richUntilMeters: 1782000,
    ),
    MrMineMineralBand(
      resourceId: 'magnesium',
      worldIndex: 1,
      firstDepthMeters: 1125000,
      richFromMeters: 1233000,
      richUntilMeters: 1782000,
    ),
    MrMineMineralBand(
      resourceId: 'lunar_titanium',
      worldIndex: 1,
      firstDepthMeters: 1211000,
      richFromMeters: 1315000,
      richUntilMeters: 1782000,
    ),
    MrMineMineralBand(
      resourceId: 'silicon',
      worldIndex: 1,
      firstDepthMeters: 1333000,
      richFromMeters: 1417000,
      richUntilMeters: 1782000,
    ),
    MrMineMineralBand(
      resourceId: 'promethium',
      worldIndex: 1,
      firstDepthMeters: 1462000,
      richFromMeters: 1507000,
      richUntilMeters: 1782000,
    ),
    MrMineMineralBand(
      resourceId: 'neodymium',
      worldIndex: 1,
      firstDepthMeters: 1562000,
      richFromMeters: 1615000,
      richUntilMeters: 1782000,
    ),
    MrMineMineralBand(
      resourceId: 'ytterbium',
      worldIndex: 1,
      firstDepthMeters: 1605000,
      richFromMeters: 1725000,
      richUntilMeters: 1782000,
    ),
    MrMineMineralBand(
      resourceId: 'tin',
      worldIndex: 2,
      firstDepthMeters: 1814000,
      richFromMeters: 0,
      richUntilMeters: 0,
    ),
    MrMineMineralBand(
      resourceId: 'sulfur',
      worldIndex: 2,
      firstDepthMeters: 1854000,
      richFromMeters: 0,
      richUntilMeters: 0,
    ),
    MrMineMineralBand(
      resourceId: 'lithium',
      worldIndex: 2,
      firstDepthMeters: 1878000,
      richFromMeters: 0,
      richUntilMeters: 0,
    ),
    MrMineMineralBand(
      resourceId: 'manganese',
      worldIndex: 2,
      firstDepthMeters: 2015000,
      richFromMeters: 0,
      richUntilMeters: 0,
    ),
    MrMineMineralBand(
      resourceId: 'mercury',
      worldIndex: 2,
      firstDepthMeters: 2142000,
      richFromMeters: 0,
      richUntilMeters: 0,
    ),
    MrMineMineralBand(
      resourceId: 'nickel',
      worldIndex: 2,
      firstDepthMeters: 2242000,
      richFromMeters: 0,
      richUntilMeters: 0,
    ),
    MrMineMineralBand(
      resourceId: 'alexandrite',
      worldIndex: 2,
      firstDepthMeters: 2317000,
      richFromMeters: 0,
      richUntilMeters: 0,
    ),
    MrMineMineralBand(
      resourceId: 'benitoite',
      worldIndex: 2,
      firstDepthMeters: 2414000,
      richFromMeters: 0,
      richUntilMeters: 0,
    ),
    MrMineMineralBand(
      resourceId: 'titan_cobalt',
      worldIndex: 2,
      firstDepthMeters: 2500000,
      richFromMeters: 0,
      richUntilMeters: 0,
    ),
  ];

  static final Map<String, MrMineMineralBand> bandByResourceId = {
    for (final band in minerals) band.resourceId: band,
  };

  static bool isotopeAvailableAtDepth(
    String resourceId,
    int worldIndex,
    double depthMeters,
  ) {
    // A listed mineshaft unlocks its isotope for that entire 1 km floor.
    final depthKm = (depthMeters / 1000).floor();
    if (worldIndex == 1 && resourceId == 'he3') {
      return depthMeters >= moonStartMeters &&
          depthMeters < moonEndMeters &&
          moonHelium3DepthKm.contains(depthKm);
    }
    if (worldIndex == 2 && const {'h1', 'h2', 'h3'}.contains(resourceId)) {
      return depthMeters >= titanStartMeters &&
          depthMeters < titanEndMeters &&
          titanHydrogenDepthKm.contains(depthKm);
    }
    if (worldIndex == 2 && const {'o1', 'o2', 'o3'}.contains(resourceId)) {
      return depthMeters >= titanStartMeters &&
          depthMeters < titanEndMeters &&
          titanOxygenDepthKm.contains(depthKm);
    }
    final firstDepth = switch (resourceId) {
      'u1' || 'u2' || 'u3' => 24000,
      'pu1' || 'pu2' || 'pu3' => 34000,
      'po1' || 'po2' || 'po3' => 54000,
      'n1' || 'n2' || 'n3' => 1067000,
      'he1' || 'he2' || 'he3' => 1132000,
      'h1' || 'h2' || 'h3' => 1849000,
      'o1' || 'o2' || 'o3' => 1914000,
      _ => null,
    };
    if (firstDepth == null || depthMeters < firstDepth) return false;
    return switch (worldIndex) {
      0 => depthMeters < earthEndMeters && firstDepth < earthEndMeters,
      1 => depthMeters >= moonStartMeters && depthMeters < moonEndMeters,
      2 => depthMeters >= titanStartMeters && depthMeters < titanEndMeters,
      _ => false,
    };
  }

  static int? worldAtDepth(double depthMeters) {
    if (depthMeters < earthEndMeters) return 0;
    if (depthMeters >= moonStartMeters && depthMeters < moonEndMeters) {
      return 1;
    }
    if (depthMeters >= titanStartMeters && depthMeters < titanEndMeters) {
      return 2;
    }
    return null;
  }
}
