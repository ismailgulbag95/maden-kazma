class CaveRouteDefinition {
  const CaveRouteDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.durationMultiplier,
    required this.lootMultiplier,
    required this.relicChance,
    required this.ticketChance,
  });

  final String id;
  final String name;
  final String description;
  final double durationMultiplier;
  final double lootMultiplier;
  final int relicChance;
  final int ticketChance;
}

abstract final class CaveRouteCatalog {
  static const List<CaveRouteDefinition> all = [
    CaveRouteDefinition(
      id: 'survey',
      name: 'Haritalı Galeri',
      description:
          'Dengeli süre ve ganimet; yeni seferler için güvenilir rota.',
      durationMultiplier: 1,
      lootMultiplier: 1,
      relicChance: 4,
      ticketChance: 3,
    ),
    CaveRouteDefinition(
      id: 'safe',
      name: 'Güvenli Şaft',
      description: 'Daha uzun sürer; düşük miktarlı, düzenli ganimet getirir.',
      durationMultiplier: 1.35,
      lootMultiplier: .72,
      relicChance: 7,
      ticketChance: 5,
    ),
    CaveRouteDefinition(
      id: 'deep',
      name: 'Derin Yarık',
      description:
          'Daha uzun ve belirsiz; yüksek cevher ve kalıntı şansı taşır.',
      durationMultiplier: 1.65,
      lootMultiplier: 1.55,
      relicChance: 3,
      ticketChance: 3,
    ),
  ];

  static final Map<String, CaveRouteDefinition> byId = {
    for (final route in all) route.id: route,
  };
}
