class MineEventDefinition {
  const MineEventDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.rewardDescription,
  });

  final String id;
  final String title;
  final String description;
  final String rewardDescription;
}

abstract final class MineEventCatalog {
  static const List<MineEventDefinition> all = [
    MineEventDefinition(
      id: 'gold_rush',
      title: 'Altına hücum',
      description: 'Eski bir damar kısa süreliğine altınla parlıyor.',
      rewardDescription: 'Derinliğe göre kasa kazan.',
    ),
    MineEventDefinition(
      id: 'collapsed_tunnel',
      title: 'Göçük tünel',
      description:
          'Yan tünel çöktü; ekip enkazın arkasında parlayan bir sandık buldu.',
      rewardDescription:
          'Basınç düşer ve bulunduğun dünyaya uygun sandık kazanırsın.',
    ),
    MineEventDefinition(
      id: 'rich_vein',
      title: 'Zengin cevher damarı',
      description: 'Sondaj ışığı yoğun bir cevher damarına vurdu.',
      rewardDescription:
          'Bulunduğun derinliğin cevherinden üç birime kadar al.',
    ),
    MineEventDefinition(
      id: 'lost_explorer',
      title: 'Kayıp kâşif',
      description: 'Eski bir keşif kapsülünden yardım sinyali geliyor.',
      rewardDescription:
          'Kâşifin bıraktığı yapı malzemelerini ve sondaj parçasını al.',
    ),
    MineEventDefinition(
      id: 'merchant',
      title: 'Gezgin tüccar',
      description:
          'Gezgin tüccar nadir maden parçalarını uygun fiyata bırakıyor.',
      rewardDescription: 'Ücretsiz kasa ve sondaj parçası kazan.',
    ),
    MineEventDefinition(
      id: 'ancient_chamber',
      title: 'Kadim oda',
      description: 'Kaya duvarının ardında mühürlü bir arşiv odası açıldı.',
      rewardDescription: 'Bulunduğun dünyaya uygun bir sandık kazan.',
    ),
    MineEventDefinition(
      id: 'monster_nest',
      title: 'Yaratık yuvası',
      description: 'Sondajın yanında bir cevher yaratığı yuvası bulundu.',
      rewardDescription:
          'Muhafız ekibi yuvayı temizleyip kasa ve parçaları getirir.',
    ),
  ];

  static final Map<String, MineEventDefinition> byId = {
    for (final event in all) event.id: event,
  };
}
