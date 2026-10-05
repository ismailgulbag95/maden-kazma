class BuffLabDefinition {
  const BuffLabDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.energyDrainPerSecond,
  });

  final String id;
  final String name;
  final String description;
  final double energyDrainPerSecond;
}

abstract final class BuffLabCatalog {
  static const List<BuffLabDefinition> all = [
    BuffLabDefinition(
      id: 'buff_overdrive',
      name: 'Hiper Aşırı Yük',
      description: 'Sondaj ilerlemesini 2 katına çıkarır.',
      energyDrainPerSecond: 10,
    ),
    BuffLabDefinition(
      id: 'buff_resonance',
      name: 'Kuantum Rezonansı',
      description: 'Kazı ekibinin cevher verimini 3 katına çıkarır.',
      energyDrainPerSecond: 15,
    ),
    BuffLabDefinition(
      id: 'buff_shield',
      name: 'Dron Kalkanı',
      description: 'Mağara keşiflerinde tehlike hasarını engeller.',
      energyDrainPerSecond: 8,
    ),
  ];

  static final Map<String, BuffLabDefinition> byId = {
    for (final buff in all) buff.id: buff,
  };

  static const double overdriveMultiplier = 2;
  static const double oreYieldMultiplier = 3;
}
