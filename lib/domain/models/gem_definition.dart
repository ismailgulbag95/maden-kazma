class GemDefinition {
  const GemDefinition({
    required this.id,
    required this.name,
    required this.recipe,
    required this.craftSeconds,
    required this.bonus,
    required this.colorHex,
  });

  final String id;
  final String name;
  final Map<String, int> recipe;
  final int craftSeconds;
  final String bonus;
  final int colorHex;
}

abstract final class GemCatalog {
  static const List<GemDefinition> all = [
    GemDefinition(
      id: 'ruby',
      name: 'Kor Yakutu',
      recipe: {'gold': 3, 'copper': 4},
      craftSeconds: 90,
      bonus: 'Satış geliri +%8',
      colorHex: 0xFFE64F69,
    ),
    GemDefinition(
      id: 'emerald',
      name: 'Derin Zümrüt',
      recipe: {'emerald': 3, 'iron': 6},
      craftSeconds: 120,
      bonus: 'Sondaj hızı +%8',
      colorHex: 0xFF31D6C5,
    ),
    GemDefinition(
      id: 'sapphire',
      name: 'Mavi Yıldız',
      recipe: {'sapphire': 2, 'gold': 6},
      craftSeconds: 150,
      bonus: 'Ambar kapasitesi +%10',
      colorHex: 0xFF389BFF,
    ),
    GemDefinition(
      id: 'amethyst',
      name: 'Boşluk Ametisti',
      recipe: {'amethyst': 2, 'titanium': 4},
      craftSeconds: 180,
      bonus: 'İzotop bulma olasılığı +%2,5',
      colorHex: 0xFFB64EFF,
    ),
    GemDefinition(
      id: 'diamond',
      name: 'Çekirdek Elması',
      recipe: {'star_crystal': 4, 'platinum': 8},
      craftSeconds: 240,
      bonus: 'Muhafız hasarı +%12',
      colorHex: 0xFFE7F6FF,
    ),
  ];

  static final Map<String, GemDefinition> byId = {
    for (final gem in all) gem.id: gem,
  };
}
