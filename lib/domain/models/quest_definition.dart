enum QuestKind {
  mine,
  depth,
  hire,
  sell,
  upgrade,
  chest,
  cave,
  relic,
  boss,
  resonance,
}

class QuestDefinition {
  const QuestDefinition({
    required this.id,
    required this.chapter,
    required this.title,
    required this.description,
    required this.kind,
    required this.target,
    required this.reward,
  });

  final int id;
  final int chapter;
  final String title;
  final String description;
  final QuestKind kind;
  final int target;
  final int reward;
}

abstract final class QuestCatalog {
  static const _chapters = [
    'Bakır Kervanı',
    'Kırık Pusula',
    'Mavi Katman',
    'Yankı Kuyusu',
    'Kayıp İstasyon',
    'Sessiz Galeri',
    'Yeraltı Pazarı',
    'Kızıl Damar',
    'Derin Arşiv',
    'Ay Ufku',
    'Buz Feneri',
    'Titan Günlüğü',
    'Eski Rezonans',
    'Son Harita',
  ];

  static const _chapterBriefs = [
    'Vardiya defterindeki bakır lekeleri, ekibin unutulmuş bir sevkiyat yolunu bulduğunu gösteriyor.',
    'Pusula her titreştiğinde kuyu duvarında yeni bir işaret beliriyor; ölçümü doğrula.',
    'Mavi kaya kuşağında cevher yüzeyi ışığı yutuyor; taşı dikkatle tara.',
    'Kuyunun yankısı bir adım önden geliyor. Eski sondaj izlerini karşılaştır.',
    'Terk edilmiş istasyonun notları, depoda bırakılan malzemelerin yerini tarif ediyor.',
    'Sessiz galeride makineler durdu; ekibin küçük ilerlemeleri yeniden başlatması gerek.',
    'Yeraltı pazarında herkes aynı cevheri arıyor; adil bir takas için yükünü hazırla.',
    'Kızıl damarın çevresinde ısı artıyor. Kaynağı topla ve basıncı izle.',
    'Derin arşivdeki yazıtlar eski bir çekirdek düzenini anlatıyor; bulguları sıraya koy.',
    'Ay yüzeyinden gelen yeni örnekler Dünya kayıtlarıyla eşleşmiyor; ayrı bir karşılaştırma yap.',
    'Buz fenerleri sönmeden önce ekipmanını ve sefer yükünü kontrol et.',
    'Titan günlüğü, sis altında kalan cevher izlerinin yalnızca kısa süre göründüğünü söylüyor.',
    'Eski rezonans çizgileri, doğru damar sırasına dokununca tekrar canlanıyor.',
    'Son haritanın boş bıraktığı bölgeyi kendi vardiya kayıtlarınla tamamla.',
  ];

  static const _tutorial = [
    (
      QuestKind.mine,
      'İlk kıvılcım',
      'Görünen cevher damarına dokun ve ilk taş örneğini çıkar',
      'cevher',
      1,
    ),
    (
      QuestKind.sell,
      'Yüzeye ilk sevkiyat',
      'Ambarından kaynak satarak kasaya gelir aktar',
      'kasa değeri',
      40,
    ),
    (
      QuestKind.hire,
      'Vardiyaya bir kişi daha',
      'Satıştan gelen kasayla ilk madenciyi işe alıp kazıyı otomatikleştir',
      'yeni madenci',
      1,
    ),
    (
      QuestKind.upgrade,
      'Sondaj ucunu keskinleştir',
      'Atölyeden bir ekipman yükseltmesi al',
      'toplam ekipman seviyesi',
      4,
    ),
    (
      QuestKind.depth,
      'İlk katman ölçümü',
      'Daha güçlü sondajla kuyu ölçümünü ilerlet',
      'metre derinlik',
      80,
    ),
  ];

  static const _objectives = [
    (QuestKind.mine, 'Damar kaydı', 'yeni örnek çıkar', 'kazılan cevher', 18),
    (QuestKind.depth, 'Katman ölçümü', 'kuyu işaretini ilerlet', 'metre', 500),
    (
      QuestKind.hire,
      'Ekip genişlemesi',
      'madenciyi vardiyaya kat',
      'işe alım',
      2,
    ),
    (
      QuestKind.sell,
      'Kasa sevkiyatı',
      'satış değerini tamamla',
      'kasa değeri',
      100,
    ),
    (
      QuestKind.upgrade,
      'Takım bakımı',
      'ekipman seviyelerini geliştir',
      'toplam ekipman seviyesi',
      6,
    ),
    (
      QuestKind.chest,
      'Gömülü emanet',
      'sandığın içindekini teslim al',
      'açılan sandık',
      1,
    ),
    (
      QuestKind.cave,
      'Yan galeri keşfi',
      'dronu güvenle geri getir',
      'tamamlanan sefer',
      1,
    ),
    (
      QuestKind.relic,
      'Yazıt parçası',
      'bilimsel kazıda kalıcı buluntu edin',
      'kalıntı',
      1,
    ),
    (
      QuestKind.boss,
      'Kuyu nöbeti',
      'muhafızın zayıf noktasını bul ve yen',
      'zafer',
      1,
    ),
    (
      QuestKind.resonance,
      'Damar akordu',
      'işaretli damarları doğru sırayla seç',
      'rezonans dizisi',
      1,
    ),
  ];

  static final List<QuestDefinition> all = List.generate(112, (index) {
    if (index < _tutorial.length) {
      final objective = _tutorial[index];
      return QuestDefinition(
        id: index,
        chapter: 0,
        title: 'İlk Vardiya • ${objective.$2}',
        description: objective.$3,
        kind: objective.$1,
        target: objective.$5,
        reward: 35 + index * 15,
      );
    }

    final stageIndex = index - _tutorial.length;
    final chapter = (stageIndex * _chapters.length) ~/ (112 - _tutorial.length);
    final objective = _objectives[stageIndex % _objectives.length];
    final target = switch (objective.$1) {
      QuestKind.mine => 18 + (chapter * 24),
      QuestKind.depth => 500 + (chapter * 40000),
      QuestKind.hire => 2 + (chapter * 3),
      QuestKind.sell => 100 + (chapter * 900),
      QuestKind.upgrade => 6 + (chapter * 5),
      QuestKind.chest => 1 + (chapter ~/ 3),
      QuestKind.cave => 1 + (chapter ~/ 3),
      QuestKind.relic => 1 + (chapter ~/ 4),
      QuestKind.boss => 1 + (chapter ~/ 5),
      QuestKind.resonance => 1 + (chapter ~/ 2),
    };
    final story = _chapterBriefs[chapter];
    return QuestDefinition(
      id: index,
      chapter: chapter,
      title: '${_chapters[chapter]} • ${objective.$2}',
      description: '$story ${objective.$3}: $target ${objective.$4}.',
      kind: objective.$1,
      target: target,
      reward: 60 + (chapter * 75) + (stageIndex % 8 * 13),
    );
  });
}
