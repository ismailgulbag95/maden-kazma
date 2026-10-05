class CaveDroneDefinition {
  const CaveDroneDefinition({
    required this.id,
    required this.name,
    required this.health,
    required this.speed,
    required this.vision,
    required this.fuel,
    required this.collectionRange,
    required this.description,
  });

  final String id;
  final String name;
  final int health;
  final double speed;
  final int vision;
  final int fuel;
  final int collectionRange;
  final String description;
}

abstract final class CaveDroneCatalog {
  static const List<CaveDroneDefinition> all = [
    CaveDroneDefinition(
      id: 'ground',
      name: 'Kaya Gezgini',
      health: 110,
      speed: 1,
      vision: 1,
      fuel: 4,
      collectionRange: 0,
      description: 'Zırhlı gövde, dar geçitlerde güvenli keşif.',
    ),
    CaveDroneDefinition(
      id: 'flying',
      name: 'Gök Feneri',
      health: 78,
      speed: 1.4,
      vision: 2,
      fuel: 4,
      collectionRange: 0,
      description: 'Uçar; önündeki iki sırayı erkenden görür.',
    ),
    CaveDroneDefinition(
      id: 'magnet',
      name: 'Demir Mıknatıs',
      health: 94,
      speed: 1,
      vision: 1,
      fuel: 4,
      collectionRange: 1,
      description: 'Yan tünellerdeki ganimeti de toplayabilir.',
    ),
    CaveDroneDefinition(
      id: 'healer',
      name: 'Can Desteği',
      health: 96,
      speed: .9,
      vision: 1,
      fuel: 4,
      collectionRange: 0,
      description: 'Her düğümde küçük bir onarım uygular.',
    ),
  ];

  static final Map<String, CaveDroneDefinition> byId = {
    for (final drone in all) drone.id: drone,
  };
}

class CaveNodeDefinition {
  const CaveNodeDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.risk,
  });

  final String id;
  final String name;
  final String description;
  final int risk;
}

abstract final class CaveNodeCatalog {
  static const List<CaveNodeDefinition> all = [
    CaveNodeDefinition(
      id: 'mineral',
      name: 'Cevher yığını',
      description: 'Bir avuç damar örneği.',
      risk: 0,
    ),
    CaveNodeDefinition(
      id: 'money',
      name: 'Eski kaset',
      description: 'Tüccar kasasında unutulmuş para.',
      risk: 0,
    ),
    CaveNodeDefinition(
      id: 'chest',
      name: 'Mühürlü sandık',
      description: 'Dünyaya özgü bir sandık.',
      risk: 1,
    ),
    CaveNodeDefinition(
      id: 'material',
      name: 'Yapı malzemesi',
      description: 'Taşınabilir onarım parçaları.',
      risk: 0,
    ),
    CaveNodeDefinition(
      id: 'buff',
      name: 'Rezonans kristali',
      description: 'Kısa süreli sondaj desteği.',
      risk: 1,
    ),
    CaveNodeDefinition(
      id: 'rare',
      name: 'Eski yazıt',
      description: 'Kalıntı ya da çekirdek parçası.',
      risk: 1,
    ),
    CaveNodeDefinition(
      id: 'health',
      name: 'İlk yardım sandığı',
      description: 'Keşif dronunu onarır.',
      risk: 0,
    ),
    CaveNodeDefinition(
      id: 'scientist',
      name: 'Kayıp araştırmacı',
      description: 'Güvenle kurtarılırsa araştırma ekibine katılır.',
      risk: 1,
    ),
    CaveNodeDefinition(
      id: 'hazard',
      name: 'Çöken tünel',
      description: 'Dron gövdesi hasar alabilir.',
      risk: 3,
    ),
    CaveNodeDefinition(
      id: 'boulder',
      name: 'Kaya bloğu',
      description: 'Geçmek için fazladan yakıtla delinir.',
      risk: 2,
    ),
    CaveNodeDefinition(
      id: 'mud',
      name: 'Çamur tabakası',
      description: 'Yer dronunun bu adımda yakıtını iki kat tüketir.',
      risk: 2,
    ),
    CaveNodeDefinition(
      id: 'radiation',
      name: 'Radyasyon cebi',
      description: 'Drona radyasyon hasarı verir; kalkan etkisizleştirir.',
      risk: 3,
    ),
    CaveNodeDefinition(
      id: 'lava',
      name: 'Lav akıntısı',
      description: 'Derin mağaralarda ağır ısı hasarı verir.',
      risk: 3,
    ),
  ];

  static final Map<String, CaveNodeDefinition> byId = {
    for (final node in all) node.id: node,
  };
}
