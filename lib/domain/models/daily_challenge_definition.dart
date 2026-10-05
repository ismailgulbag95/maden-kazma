class DailyChallengeDefinition {
  const DailyChallengeDefinition({
    required this.id,
    required this.kind,
    required this.title,
    required this.description,
    required this.target,
    required this.rewardCoins,
  });

  final String id;
  final String kind;
  final String title;
  final String description;
  final int target;
  final int rewardCoins;
}

abstract final class DailyChallengeCatalog {
  static const dailyCount = 3;
  static const weeklyTarget = 12;
  static const weeklyRewardCoins = 3500;
  static const weeklyRewardCoreShards = 1;

  static const List<DailyChallengeDefinition> all = [
    DailyChallengeDefinition(
      id: 'ore_25',
      kind: 'mine',
      title: 'Vardiya cevheri',
      description: '25 cevher birimi çıkar.',
      target: 25,
      rewardCoins: 300,
    ),
    DailyChallengeDefinition(
      id: 'depth_2000',
      kind: 'depth',
      title: 'Bir kat daha derin',
      description: 'Bugün 2.000 metre ilerle.',
      target: 2000,
      rewardCoins: 350,
    ),
    DailyChallengeDefinition(
      id: 'sell_1000',
      kind: 'sell',
      title: 'Vardiya hasılatı',
      description: '1.000 kasa değerinde kaynak sat.',
      target: 1000,
      rewardCoins: 320,
    ),
    DailyChallengeDefinition(
      id: 'upgrade_1',
      kind: 'upgrade',
      title: 'Takımı geliştir',
      description: 'Bir ekipman yükseltmesi satın al.',
      target: 1,
      rewardCoins: 260,
    ),
    DailyChallengeDefinition(
      id: 'hire_1',
      kind: 'hire',
      title: 'Yeni vardiya arkadaşı',
      description: 'Ekibe bir madenci kat.',
      target: 1,
      rewardCoins: 300,
    ),
    DailyChallengeDefinition(
      id: 'tap_10',
      kind: 'tap',
      title: 'Damara dokun',
      description: '10 kez cevher damarını elle çıkar.',
      target: 10,
      rewardCoins: 220,
    ),
    DailyChallengeDefinition(
      id: 'event_1',
      kind: 'event',
      title: 'Kuyudaki fırsat',
      description: 'Bir maden olayını çöz.',
      target: 1,
      rewardCoins: 320,
    ),
  ];

  static final Map<String, DailyChallengeDefinition> byId = {
    for (final challenge in all) challenge.id: challenge,
  };

  static List<String> idsForDate(String dateKey) {
    final pool = all.map((challenge) => challenge.id).toList();
    var seed = 17;
    for (final codeUnit in dateKey.codeUnits) {
      seed = (seed * 31 + codeUnit) & 0x7fffffff;
    }
    for (var index = pool.length - 1; index > 0; index--) {
      seed = (1103515245 * seed + 12345) & 0x7fffffff;
      final swapIndex = seed % (index + 1);
      final value = pool[index];
      pool[index] = pool[swapIndex];
      pool[swapIndex] = value;
    }
    return pool.take(dailyCount).toList(growable: false);
  }
}
