class CargoEquipmentDefinition {
  const CargoEquipmentDefinition({
    required this.level,
    required this.name,
    required this.capacity,
    required this.cashCost,
    this.materialCosts = const {},
  });

  final int level;
  final String name;
  final double capacity;
  final double cashCost;
  final Map<String, int> materialCosts;
}

abstract final class CargoEquipmentCatalog {
  static const List<CargoEquipmentDefinition> all = [
    CargoEquipmentDefinition(
      level: 1,
      name: 'Hurda Kargo',
      capacity: 1500,
      cashCost: 0,
    ),
    CargoEquipmentDefinition(
      level: 2,
      name: 'Nano Kargo',
      capacity: 7500,
      cashCost: 1400,
      materialCosts: {'copper': 200, 'silver': 1},
    ),
    CargoEquipmentDefinition(
      level: 3,
      name: 'Mikro Kargo',
      capacity: 15000,
      cashCost: 15000,
      materialCosts: {'gold': 125, 'platinum': 15},
    ),
    CargoEquipmentDefinition(
      level: 4,
      name: 'Küçük Kargo',
      capacity: 50000,
      cashCost: 150000,
      materialCosts: {'gold': 500, 'platinum': 200, 'diamond': 50},
    ),
    CargoEquipmentDefinition(
      level: 5,
      name: 'Orta Kargo',
      capacity: 150000,
      cashCost: 1000000,
      materialCosts: {'platinum': 2000, 'diamond': 1000, 'coltan': 25},
    ),
    CargoEquipmentDefinition(
      level: 6,
      name: 'Büyük Kargo',
      capacity: 500000,
      cashCost: 20000000,
      materialCosts: {'diamond': 50000},
    ),
    CargoEquipmentDefinition(
      level: 7,
      name: 'Dev Kargo',
      capacity: 1000000,
      cashCost: 300000000,
      materialCosts: {'u1': 600, 'painite': 500},
    ),
    CargoEquipmentDefinition(
      level: 8,
      name: 'Devin Kargosu',
      capacity: 2000000,
      cashCost: 3500000000,
      materialCosts: {'black_opal': 10000, 'po1': 250},
    ),
    CargoEquipmentDefinition(
      level: 9,
      name: 'Muazzam Kargo',
      capacity: 3500000,
      cashCost: 6000000000,
      materialCosts: {'red_diamond': 30000, 'po1': 500},
    ),
    CargoEquipmentDefinition(
      level: 10,
      name: 'Endüstriyel Kargo',
      capacity: 5000000,
      cashCost: 50000000000,
      materialCosts: {'pu1': 5000, 'pu3': 100},
    ),
    CargoEquipmentDefinition(
      level: 11,
      name: 'Altın Kral Kargosu',
      capacity: 10000000,
      cashCost: 200000000000,
      materialCosts: {
        'black_opal': 500000,
        'pu2': 1000,
        'po1': 2000,
        'californium': 150000,
      },
    ),
    CargoEquipmentDefinition(
      level: 12,
      name: 'Şehir Kapasitesi',
      capacity: 25000000,
      cashCost: 1000000000000,
      materialCosts: {'oil': 32, 'u1': 40000},
    ),
    CargoEquipmentDefinition(
      level: 13,
      name: 'Ülke Kapasitesi',
      capacity: 100000000,
      cashCost: 3000000000000,
      materialCosts: {'oil': 150, 'pu1': 20000},
    ),
    CargoEquipmentDefinition(
      level: 14,
      name: 'Gezegen Kapasitesi',
      capacity: 200000000,
      cashCost: 20000000000000,
      materialCosts: {'oil': 2000},
    ),
    CargoEquipmentDefinition(
      level: 15,
      name: 'Vakum Paketli Kargo',
      capacity: 500000000,
      cashCost: 150000000000000000,
      materialCosts: {'n1': 1000000, 'e1': 300, 'e2': 50},
    ),
    CargoEquipmentDefinition(
      level: 16,
      name: 'Çift Vakum Paketli Kargo',
      capacity: 1000000000,
      cashCost: 750000000000000000000,
      materialCosts: {'sulfur': 1000000, 'f2': 15, 'f3': 5},
    ),
  ];

  static CargoEquipmentDefinition? next(int currentLevel) =>
      currentLevel < 1 || currentLevel >= all.length ? null : all[currentLevel];
}
