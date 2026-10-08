import 'game_state.dart';

class AdvisorGuideDefinition {
  const AdvisorGuideDefinition({
    required this.id,
    required this.title,
    required this.message,
    required this.target,
    required this.targetLabel,
    this.targetPanel,
    this.requiredDepthMeters = 0,
    this.requiredMinerCount = 0,
    this.unlockBuildingId,
    this.unlockWorkerRole,
  });

  final String id;
  final String title;
  final String message;
  final String target;
  final String targetLabel;
  final String? targetPanel;
  final int requiredDepthMeters;
  final int requiredMinerCount;
  final String? unlockBuildingId;
  final String? unlockWorkerRole;
  bool get isTutorial => id.startsWith('tutorial_');
}

abstract final class AdvisorGuideCatalog {
  static const List<AdvisorGuideDefinition> _tutorial = [
    AdvisorGuideDefinition(
      id: 'tutorial_mine',
      title: 'İlk cevherini çıkar',
      message: 'Kömür damarına art arda dokun; taş örnekleri ambara düşecek.',
      target: 'ore',
      targetLabel: 'KÖMÜR DAMARI',
    ),
    AdvisorGuideDefinition(
      id: 'tutorial_sell',
      title: 'Kömürü kasaya çevir',
      message: 'İlk damara dokundun. Ambarı açıp kömürünü satarak kasa kazan.',
      target: 'warehouse',
      targetLabel: 'AMBAR',
      targetPanel: 'warehouse',
    ),
    AdvisorGuideDefinition(
      id: 'tutorial_hire',
      title: 'Vardiyana madenci kat',
      message: 'Satıştan gelen kasayla atölyeyi aç ve ilk madencini işe al.',
      target: 'workshop',
      targetLabel: 'ATÖLYE',
      targetPanel: 'workshop',
    ),
    AdvisorGuideDefinition(
      id: 'tutorial_upgrade',
      title: 'Sondaj ucunu güçlendir',
      message: 'Madencin hazır. Atölyede sondaj ucuna bir kademe yatırım yap.',
      target: 'workshop',
      targetLabel: 'SONDAJ YÜKSELTMESİ',
      targetPanel: 'workshop',
    ),
    AdvisorGuideDefinition(
      id: 'tutorial_drill',
      title: 'Matkabın ilerlemesini izle',
      message: 'Sondaj otomatik sürer. 10 km derinliğe ulaştığında bu görev tamamlanır.',
      target: 'drill',
      targetLabel: 'OTOMATİK MATKAP',
    ),
  ];

  static const AdvisorGuideDefinition _questLine = AdvisorGuideDefinition(
    id: 'ongoing_quests',
    title: 'Görev hattı devam ediyor',
    message: 'İlk beş vardiya görevi tamamlandı. Yeni hedefler derinlik, ekip ve keşif sistemlerini sırayla tanıtacak.',
    target: 'quests',
    targetLabel: 'GÖREV DEFTERİ',
    targetPanel: 'quests',
  );

  static const AdvisorGuideDefinition _achievements = AdvisorGuideDefinition(
    id: 'achievement_book',
    title: 'Başarı kayıtları açıldı',
    message: 'Kilometre taşları ve kalıcı ödüller burada izlenir. Yeni bir başarı kazandığında bu deftere dön.',
    target: 'achievements',
    targetLabel: 'BAŞARIMLAR',
    targetPanel: 'achievements',
  );

  static const AdvisorGuideDefinition _finalDescent = AdvisorGuideDefinition(
    id: 'final_descent',
    title: 'Titan kuyusunun son katı',
    message: 'Son sondaj derinliğine ulaştın. Son katın kaynaklarını ve açılan kayıtları gözden geçir.',
    target: 'depth',
    targetLabel: 'SON KATMAN',
    requiredDepthMeters: 2566000,
  );

  static const List<AdvisorGuideDefinition> _progression = [
    AdvisorGuideDefinition(
      id: 'elevator',
      title: 'Kuyu asansörü açıldı',
      message: 'Atölyedeki asansör modülü yükü dipten yüzeye taşır. Taşıma kapasitesini ve kuyu basıncını bu binadan yönet.',
      target: 'workshop',
      targetLabel: 'ATÖLYE',
      targetPanel: 'workshop',
      unlockBuildingId: 'elevator',
    ),
    AdvisorGuideDefinition(
      id: 'first_depth_chest',
      title: 'İlk katman sandığı',
      message: 'Derinlikte bulunan sandıkları ambar ve sandık düğmesinden aç; içinden kasa ve malzeme çıkar.',
      target: 'trade',
      targetLabel: 'İLK SANDIK',
      targetPanel: 'trade',
      requiredDepthMeters: 1000,
    ),
    AdvisorGuideDefinition(
      id: 'mine_events',
      title: 'Kuyu olayları',
      message: 'Zaman zaman kuyuda özel fırsatlar belirir. Süre dolmadan olayı inceleyip ödülünü al.',
      target: 'mine_event',
      targetLabel: 'KUYU OLAYI',
      targetPanel: 'mine_event',
      requiredDepthMeters: 1000,
    ),
    AdvisorGuideDefinition(
      id: 'worker_transport',
      title: 'Taşıma ekibini kur',
      message: 'Taşıma ekibini açmak için iki madencin olmalı. Gerekirse birini daha işe al; sonra bir kazıcıyı taşıyıcı yap. Her taşıyıcı ambar kapasitesini %4 artırır ama kazı yapmaz.',
      target: 'workshop',
      targetLabel: 'TAŞIMA EKİBİ',
      targetPanel: 'workshop',
      requiredDepthMeters: 5000,
      requiredMinerCount: 2,
      unlockWorkerRole: 'transport',
    ),
    AdvisorGuideDefinition(
      id: 'super_miners',
      title: 'Uzman madenciler',
      message: 'Uzman rolleri farklı kaynaklara ve kuyu görevlerine bonus verir. Atölyeden ekibini seç.',
      target: 'workshop',
      targetLabel: 'UZMAN EKİBİ',
      targetPanel: 'workshop',
      requiredDepthMeters: 10000,
      unlockBuildingId: 'super_miners',
    ),
    AdvisorGuideDefinition(
      id: 'worker_scanner',
      title: 'Tarama ekibini kur',
      message: 'İki madencin olduğunda birini tarayıcı yap. Tarayıcılar üretim sırasında sandık bulma olasılığını artırır ama kazı yapmaz.',
      target: 'workshop',
      targetLabel: 'TARAMA EKİBİ',
      targetPanel: 'workshop',
      requiredDepthMeters: 10000,
      requiredMinerCount: 2,
      unlockWorkerRole: 'scanner',
    ),
    AdvisorGuideDefinition(
      id: 'trader',
      title: 'Tüccar açıldı',
      message: 'Tüccar tekliflerinde bir kaynağı diğerine çevirebilirsin. Ambarını ve rezervlerini kontrol ederek takas yap.',
      target: 'trade',
      targetLabel: 'TİCARET',
      targetPanel: 'trade',
      requiredDepthMeters: 15000,
      unlockBuildingId: 'trader',
    ),
    AdvisorGuideDefinition(
      id: 'worker_sorting',
      title: 'Ayıklama ekibini kur',
      message: 'İki madencin olduğunda birini ayıklayıcı yap. Her ayıklayıcı satış değerini %2 artırır ama kazı yapmaz.',
      target: 'workshop',
      targetLabel: 'AYIKLAMA EKİBİ',
      targetPanel: 'workshop',
      requiredDepthMeters: 15000,
      requiredMinerCount: 2,
      unlockWorkerRole: 'sorting',
    ),
    AdvisorGuideDefinition(
      id: 'caves',
      title: 'Mağara keşifleri',
      message: 'Keşif dronunu bir mağaraya gönder. Rota ve dron sayısı süreyi, tehlikeyi ve ganimeti değiştirir.',
      target: 'expedition',
      targetLabel: 'SEFER GARAJI',
      targetPanel: 'expedition',
      requiredDepthMeters: 45000,
      unlockBuildingId: 'caves',
    ),
    AdvisorGuideDefinition(
      id: 'scientists',
      title: 'Bilim ekibi',
      message: 'Bilim insanlarını kalıntı kazısına ata; buluntular kalıcı geliştirmeler ve yazıtlar sağlar.',
      target: 'research',
      targetLabel: 'ARAŞTIRMA',
      targetPanel: 'research',
      requiredDepthMeters: 50000,
      unlockBuildingId: 'scientists',
    ),
    AdvisorGuideDefinition(
      id: 'chest_collector',
      title: 'Otomatik sandık toplayıcı',
      message: 'Toplayıcı, vardiya sürerken belirli aralıklarla yeni sandık bulur. Depolama kapasitesini yükselt.',
      target: 'warehouse',
      targetLabel: 'SANDIK TOPLAYICI',
      targetPanel: 'warehouse',
      requiredDepthMeters: 100000,
      unlockBuildingId: 'chest_collector',
    ),
    AdvisorGuideDefinition(
      id: 'repair_robot',
      title: 'Sondaj robotu',
      message: 'Bulduğun robotu parça ve yapı malzemesiyle onar; daha derin kuyularda ek üretim sağlar.',
      target: 'workshop',
      targetLabel: 'SONDAJ ROBOTU',
      targetPanel: 'workshop',
      requiredDepthMeters: 225000,
      unlockBuildingId: 'repair_robot',
    ),
    AdvisorGuideDefinition(
      id: 'underground_city',
      title: 'Yeraltı yerleşkesi',
      message: 'Petrol pompası kasa üretir. Petrolü satabilir ya da yapı malzemesine dönüştürebilirsin.',
      target: 'workshop',
      targetLabel: 'YERALTI YERLEŞKESİ',
      targetPanel: 'workshop',
      requiredDepthMeters: 300000,
      unlockBuildingId: 'underground_city',
    ),
    AdvisorGuideDefinition(
      id: 'gem_forge',
      title: 'Mücevher ocağı',
      message: 'Tarif için gereken madenleri ayır, iş yükünü seç ve mücevher üretimini başlat.',
      target: 'workshop',
      targetLabel: 'MÜCEVHER OCAĞI',
      targetPanel: 'workshop',
      requiredDepthMeters: 303000,
      unlockBuildingId: 'gem_forge',
    ),
    AdvisorGuideDefinition(
      id: 'armory',
      title: 'Yeraltı cephaneliği',
      message: 'Muhafızlar derinlik kapılarını korur. Silahını geliştir ve zayıf noktayı açıp saldır.',
      target: 'workshop',
      targetLabel: 'CEPHANELİK',
      targetPanel: 'workshop',
      requiredDepthMeters: 305000,
      unlockBuildingId: 'armory',
    ),
    AdvisorGuideDefinition(
      id: 'deep_core',
      title: 'Derin çekirdek',
      message: 'Bilim insanı veya kaynak fedasıyla kalıcı çekirdek parçası kazan ve sonraki vardiyaları güçlendir.',
      target: 'research',
      targetLabel: 'DERİN ÇEKİRDEK',
      targetPanel: 'research',
      requiredDepthMeters: 501000,
      unlockBuildingId: 'deep_core',
    ),
    AdvisorGuideDefinition(
      id: 'chest_compressor',
      title: 'Sandık sıkıştırıcı',
      message: 'Düşük kaliteli sandıkları birleştirerek daha değerli ganimet ve daha fazla kapasite elde et.',
      target: 'warehouse',
      targetLabel: 'SANDIK SIKIŞTIRICI',
      targetPanel: 'warehouse',
      requiredDepthMeters: 700000,
      unlockBuildingId: 'chest_compressor',
    ),
    AdvisorGuideDefinition(
      id: 'moon_world',
      title: 'Ay kuyusu',
      message: 'Ay katmanında farklı kaynaklar ve ayrı bir derinlik kaydı bulunur. Sefer garajındaki dünya kartlarından geçiş yap.',
      target: 'expedition',
      targetLabel: 'AY DÜNYASI',
      targetPanel: 'expedition',
      requiredDepthMeters: 1032000,
      unlockBuildingId: 'moon_world',
    ),
    AdvisorGuideDefinition(
      id: 'lunar_trader',
      title: 'Ay ticaret istasyonu',
      message: 'Ay cevherleri burada daha yüksek karşılık bulur. Dünya kartı ve ticaret panelini kullan.',
      target: 'trade',
      targetLabel: 'AY TİCARETİ',
      targetPanel: 'trade',
      requiredDepthMeters: 1047000,
      unlockBuildingId: 'lunar_trader',
    ),
    AdvisorGuideDefinition(
      id: 'reactor',
      title: 'Çekirdek reaktörü',
      message: 'Yakıt ve soğutma modüllerini dengele; üretilen enerji izotop sentezi ve güç darbelerinde kullanılır.',
      target: 'workshop',
      targetLabel: 'REAKTÖR',
      targetPanel: 'workshop',
      requiredDepthMeters: 1133000,
      unlockBuildingId: 'reactor',
    ),
    AdvisorGuideDefinition(
      id: 'buff_lab',
      title: 'Buff laboratuvarı',
      message: 'Reaktör enerjisiyle süreli güçlendirmeler hazırla ve uygun vardiyada etkinleştir.',
      target: 'workshop',
      targetLabel: 'BUFF LABORATUVARI',
      targetPanel: 'workshop',
      requiredDepthMeters: 1135000,
      unlockBuildingId: 'buff_lab',
    ),
    AdvisorGuideDefinition(
      id: 'robot_mk2',
      title: 'Sondaj robotu Mk II',
      message: 'Robot Mk II ile yeni montaj şemaları açılır. Uç, fan ve motor parçalarını birlikte geliştir.',
      target: 'workshop',
      targetLabel: 'ROBOT MK II',
      targetPanel: 'workshop',
      requiredDepthMeters: 1257000,
      unlockBuildingId: 'robot_mk2',
    ),
    AdvisorGuideDefinition(
      id: 'titan_world',
      title: 'Titan kuyusu',
      message: 'Titan kendi katmanlarını ve madenlerini kullanır. Sefer garajından dünyalar arasında geçiş yap.',
      target: 'expedition',
      targetLabel: 'TİTAN DÜNYASI',
      targetPanel: 'expedition',
      requiredDepthMeters: 1814000,
      unlockBuildingId: 'titan_world',
    ),
    AdvisorGuideDefinition(
      id: 'titan_trader',
      title: 'Titan ticaret istasyonu',
      message: 'Titan kaynaklarının takas değeri burada yükselir; rezervlerini koruyarak teklifleri kullan.',
      target: 'trade',
      targetLabel: 'TİTAN TİCARETİ',
      targetPanel: 'trade',
      requiredDepthMeters: 1829000,
      unlockBuildingId: 'titan_trader',
    ),
    AdvisorGuideDefinition(
      id: 'robot_mk3',
      title: 'Sondaj robotu Mk III',
      message: 'Son montaj şemaları Titan derinliklerinde açılır. Üç parçanın gücünü birlikte yükselt.',
      target: 'workshop',
      targetLabel: 'ROBOT MK III',
      targetPanel: 'workshop',
      requiredDepthMeters: 2039000,
      unlockBuildingId: 'robot_mk3',
    ),
  ];

  static final Map<String, AdvisorGuideDefinition> byId = {
    for (final guide in [
      ..._progression,
      _questLine,
      _achievements,
      _finalDescent,
    ])
      guide.id: guide,
  };

  static AdvisorGuideDefinition? currentFor(GameState state) {
    if (!state.guidedProgression || state.debugModeEnabled) return null;
    if (!state.initialTutorialComplete) {
      final index = List<int>.generate(_tutorial.length, (id) => id).firstWhere(
        (id) => !state.claimedQuestIds.contains(id),
        orElse: () => _tutorial.length - 1,
      );
      return _tutorial[index];
    }
    if (!state.completedAdvisorGuideIds.contains(_questLine.id)) {
      return _questLine;
    }
    if (!state.completedAdvisorGuideIds.contains(_achievements.id)) {
      return _achievements;
    }
    for (final guide in _progression) {
      if (state.deepestMeters >= guide.requiredDepthMeters &&
          !state.completedAdvisorGuideIds.contains(guide.id)) {
        return guide;
      }
    }
    if (state.deepestMeters >= _finalDescent.requiredDepthMeters &&
        !state.completedAdvisorGuideIds.contains(_finalDescent.id)) {
      return _finalDescent;
    }
    return null;
  }
}
