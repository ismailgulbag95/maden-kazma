import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/game_controller.dart';
import '../../core/design/palette.dart';
import '../../domain/models/achievement_definition.dart';
import '../../domain/models/advisor_guide.dart';
import '../../domain/models/cave_route_definition.dart';
import '../../domain/models/cave_exploration_definition.dart';
import '../../domain/models/daily_challenge_definition.dart';
import '../../domain/models/gem_definition.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/mr_mine_level_table.dart';
import '../../domain/models/quest_definition.dart';
import '../../domain/models/resource_definition.dart';
import '../../domain/models/mine_event_definition.dart';
import '../../domain/models/scientist_definition.dart';
import '../../domain/models/special_worker_definition.dart';
import '../../domain/models/drill_assembly_definition.dart';
import '../../domain/models/reactor_definition.dart';
import '../../domain/models/buff_lab_definition.dart';
import '../../domain/simulation/game_engine.dart';
import 'atlas_sprite.dart';
import 'game_primitives.dart';
import 'warehouse_panel.dart';

String _compactCash(num value) {
  if (value >= 1e12) return '${(value / 1e12).toStringAsFixed(2)}T';
  if (value >= 1e9) return '${(value / 1e9).toStringAsFixed(2)}B';
  if (value >= 1e6) return '${(value / 1e6).toStringAsFixed(2)}M';
  if (value >= 1e3) return '${(value / 1e3).toStringAsFixed(2)}K';
  return value.toStringAsFixed(0);
}

class BuildingDialog extends StatelessWidget {
  const BuildingDialog({
    super.key,
    required this.controller,
    required this.buildingId,
  });

  final GameController controller;
  final String buildingId;

  bool _shouldHighlightUpgrade(String track, GameState state) {
    final guideId = AdvisorGuideCatalog.currentFor(state)?.id;
    if (guideId == 'tutorial_upgrade') {
      return track == 'drill';
    }
    if (guideId == 'elevator') return track == 'lift';
    return controller.currentQuest.kind == QuestKind.upgrade &&
        const {'drill', 'foundry', 'weapon'}.contains(track);
  }

  @override
  Widget build(BuildContext context) {
    final data = _buildingData(buildingId);
    final width = math.min(620.0, MediaQuery.sizeOf(context).width - 36);
    final height = math.min(850.0, MediaQuery.sizeOf(context).height * .86);
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: MinePalette.ink,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(13),
        side: const BorderSide(color: MinePalette.border, width: 1.4),
      ),
      child: SizedBox(
        width: width,
        height: height,
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) => Column(
            children: [
              _DialogHeader(data: data),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                  child: _contents(context),
                ),
              ),
              Container(
                height: 54,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: const BoxDecoration(
                  color: Color(0xFF0B222C),
                  border: Border(top: BorderSide(color: MinePalette.border)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.circle,
                      color: controller.saveError == null
                          ? MinePalette.teal
                          : MinePalette.danger,
                      size: 10,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        controller.saveError == null
                            ? 'Vardiya kaydı etkin'
                            : 'Kayıt uyarısı: ${controller.saveError}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: MinePalette.muted,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('KAPAT'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _contents(BuildContext context) {
    final state = controller.state;
    if (buildingId == 'warehouse') {
      return WarehousePanel(controller: controller);
    }
    switch (buildingId) {
      case 'workshop':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionIntro(
              'VARDİYA EKİBİ',
              'Madenciler otomatik kazı yapar. Sondaj ucunu güçlendir, takımını büyüt ve derinlik silahını hazırla.',
            ),
            ActionTile(
              icon: Icons.engineering_rounded,
              title: 'Madenci işe al',
              description:
                  'Bu dünyada ${state.activeMinerCount}/10 madenci var. İşçiler tüm açık katlarda cevher arar.',
              buttonLabel: state.activeMinerCount >= 10
                  ? 'EKİP TAMAM'
                  : '${_compactCash(GameEngine.minerCost(state))} kasa',
              enabled:
                  state.canAfford(GameEngine.minerCost(state)) &&
                  state.activeMinerCount < 10 &&
                  (!state.guidedProgression ||
                      state.debugModeEnabled ||
                      state.initialTutorialComplete ||
                      state.tutorialStep == 2),
              onPressed: controller.hireMiner,
              accent: MinePalette.amber,
            ),
            ActionTile(
              icon: Icons.model_training_rounded,
              title: 'Madenci eğitimi • Lv ${state.activeWorkerLevel}/10',
              description: state.activeMinerCount < 10
                  ? 'Bu dünyanın 10 işçisi tamamlanınca eğitim açılır.'
                  : 'Eğitim, her kattaki cevher bulma olasılığını artırır. Sonraki seviye ${_compactCash(GameEngine.workerLevelCost(state))} kasa.',
              buttonLabel: state.activeWorkerLevel >= 10
                  ? 'MAKSİMUM'
                  : '${_compactCash(GameEngine.workerLevelCost(state))} kasa',
              enabled:
                  state.activeMinerCount >= 10 &&
                  state.activeWorkerLevel < 10 &&
                  state.canAfford(GameEngine.workerLevelCost(state)),
              onPressed: controller.upgradeWorkerLevel,
              accent: MinePalette.cyan,
            ),
            _workerAssignmentsSection(state),
            for (final track in ['drill', 'foundry', 'weapon'])
              UpgradeRow(
                controller: controller,
                track: track,
                highlighted: _shouldHighlightUpgrade(track, state),
              ),
            _drillAssemblySection(state),
            if (state.unlockedBuildings.contains('elevator')) ...[
              const SizedBox(height: 8),
              _subheading('KUYU ASANSÖRÜ'),
              _meter(
                'Kuyu basıncı',
                state.pressure / 100,
                '${state.pressure.toStringAsFixed(1)}%',
              ),
              const SizedBox(height: 8),
              _meter(
                'Enerji',
                (state.energy / 100).clamp(0, 1).toDouble(),
                '${state.energy.toStringAsFixed(0)} / 100',
              ),
              const SizedBox(height: 12),
              UpgradeRow(
                controller: controller,
                track: 'lift',
                highlighted: _shouldHighlightUpgrade('lift', state),
              ),
              ActionTile(
                icon: Icons.air_rounded,
                title: 'Basıncı boşalt',
                description: 'Basıncı güvenli düzeye indirir ve 12 enerji üretir. En az %25 basınç gerekir.',
                buttonLabel: state.amount('building_material') > 0
                    ? '1 MALZ.'
                    : '90 KASA',
                enabled:
                    state.pressure >= 25 &&
                    (state.amount('building_material') > 0 ||
                        state.canAfford(90)),
                onPressed: controller.ventPressure,
                accent: MinePalette.cyan,
              ),
              ActionTile(
                icon: Icons.bolt_rounded,
                title: 'Reaktör güç darbesi',
                description: state.unlockedBuildings.contains('reactor')
                    ? '25 enerji tüketerek iki dakikalığına sondaj hızını artırır.'
                    : 'Reaktör 1.132 km kilometre taşında açılır. Şimdiki derinlik: ${state.deepestMeters.floor()} m.',
                buttonLabel: 'ETKİNLEŞTİR',
                enabled:
                    state.unlockedBuildings.contains('reactor') &&
                    state.energy >= 25,
                onPressed: controller.activateReactorBuff,
                accent: MinePalette.teal,
              ),
            ],
            if (state.unlockedBuildings.contains('reactor'))
              ActionTile(
                icon: Icons.bolt_rounded,
                title: 'Çekirdek reaktörü',
                description:
                    'Izgara ${GameEngine.reactorLevel(state)} • ${GameEngine.reactorHeatGenerated(state)} ısı / ${GameEngine.reactorHeatCooled(state)} soğutma • ${GameEngine.reactorEnergyPerSecond(state)} enerji/sn.',
                buttonLabel: 'IZGARAYI YÖNET',
                enabled: true,
                onPressed: () => _openNested(context, 'reactor'),
                accent: MinePalette.teal,
              )
            else
              const _EmptyHint(
                'Reaktör 1.132 km’de açılır; yakıt, soğutma ve enerji modüllerini yerleştir.',
              ),
            ActionTile(
              icon: Icons.local_fire_department_rounded,
              title: 'Yapı malzemesi erit',
              description:
                  'Dökümhane Lv 1 • 5 bakır + 10 kömür karşılığında iki yapı malzemesi üret. Ambar: ${state.amount('building_material')}.',
              buttonLabel: '2 MALZEME',
              enabled:
                  state.upgradeLevel('foundry') >= 1 &&
                  state.amount('copper') - state.reserve('copper') >= 5 &&
                  state.amount('coal') - state.reserve('coal') >= 10,
              onPressed: controller.refineMaterials,
              accent: MinePalette.amber,
            ),
            _oilPumpSection(state),
            ActionTile(
              icon: Icons.local_fire_department_rounded,
              title: 'Petrolü yapı malzemesine işle',
              description: state.currentWorldIndex == 0
                  ? '5 petrol → 2 yapı malzemesi. Dünya pompa stoğu: ${GameEngine.oilPumpStored(state)}.'
                  : 'Petrol Dünya ambarında tutulur. İşlemek için Dünya’ya geç.',
              buttonLabel: state.currentWorldIndex == 0
                  ? '5 PETROL → 2 MALZ.'
                  : 'DÜNYA’YA GEÇ',
              enabled:
                  state.currentWorldIndex == 0 &&
                  state.unlockedBuildings.contains('underground_city') &&
                  state.amount('oil') >= 5,
              onPressed: controller.refineOil,
              accent: MinePalette.amber,
            ),
            ActionTile(
              icon: Icons.hardware_rounded,
              title: 'Sondaj parçası döv',
              description: 'Dökümhane Lv 2 • 4 demir + 3 bakır + 1 yapı malzemesi. Parçalar derinlik silahını üretir.',
              buttonLabel: '+1 PARÇA',
              enabled:
                  state.upgradeLevel('foundry') >= 2 &&
                  state.amount('iron') - state.reserve('iron') >= 4 &&
                  state.amount('copper') - state.reserve('copper') >= 3 &&
                  state.amount('building_material') >= 1,
              onPressed: controller.forgeDrillPart,
              accent: MinePalette.cyan,
            ),
            _gemForgeSection(state),
            _subheading('UZMAN MADENCİLER'),
            if (!state.unlockedBuildings.contains('super_miners'))
              const _EmptyHint(
                'Jeolog, mühendis, kâşif ve muhafız uzmanı 10 km derinlikte keşfedilir.',
              )
            else
              for (final specialist in const [
                (
                  'geologist',
                  'Jeolog',
                  'İzotop bulma olasılığını artırır.',
                  Icons.science_rounded,
                ),
                (
                  'engineer',
                  'Sondaj mühendisi',
                  'Her uzman sondaj hızına %8 katkı verir.',
                  Icons.engineering_rounded,
                ),
                (
                  'scout',
                  'Mağara kâşifi',
                  'Dron seferi cevher ganimetini artırır.',
                  Icons.travel_explore_rounded,
                ),
                (
                  'guardian',
                  'Muhafız avcısı',
                  'Boss saldırıları her uzmanla %15 güçlenir.',
                  Icons.shield_rounded,
                ),
              ])
                _specialistAction(
                  specialist.$1,
                  specialist.$2,
                  specialist.$3,
                  specialist.$4,
                ),
            const SizedBox(height: 6),
            _specialWorkerRosterSection(state),
            ActionTile(
              icon: Icons.shield_rounded,
              title: 'Muhafız karşılaşması',
              description: GameEngine.availableBossIndex(state) == null
                  ? 'İlk kaya muhafızı 400.000 m derinlikte uyuyor.'
                  : '${GameEngine.bosses[GameEngine.availableBossIndex(state)!].name} kuyuda belirdi. Muhafızları yenerek parça ve sandık kazan.',
              buttonLabel: 'ARENA',
              enabled: GameEngine.availableBossIndex(state) != null,
              onPressed: () => _openNested(context, 'boss'),
              accent: MinePalette.danger,
            ),
          ],
        );
      case 'warehouse':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionIntro(
              'KARGO VE SATIŞ',
              'Dolu kargo otomatik kazıyı durdurur. Kaynakları kasaya çevir veya bir kısmını rezervde tut.',
            ),
            _meter(
              'Ambar doluluğu',
              state.cargoRatio,
              '${state.cargoUsed.toStringAsFixed(0)} / ${state.effectiveCargoCapacity.toStringAsFixed(0)}',
            ),
            const SizedBox(height: 8),
            _statTile(
              'İşleme stoku',
              '${state.amount('oil')} petrol • ${state.amount('building_material')} yapı malzemesi',
            ),
            const SizedBox(height: 9),
            UpgradeRow(controller: controller, track: 'warehouse'),
            _managerUpgradeTile(state),
            Container(
              margin: const EdgeInsets.only(top: 4, bottom: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0B222C),
                border: Border.all(color: MinePalette.border),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.autorenew_rounded,
                        color: MinePalette.cyan,
                        size: 18,
                      ),
                      const SizedBox(width: 7),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Otomatik satış',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              'Ucuz cevherden başlayarak eşiğe kadar satar. Kilit ve rezerv korunur.',
                              style: TextStyle(
                                color: MinePalette.muted,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: state.autoSellEnabled,
                        onChanged: controller.setAutoSellEnabled,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  SegmentedButton<double>(
                    showSelectedIcon: false,
                    segments: [
                      for (final threshold
                          in GameState.autoSellThresholdChoices)
                        ButtonSegment<double>(
                          value: threshold,
                          label: Text('${(threshold * 100).round()}%'),
                        ),
                    ],
                    selected: {state.autoSellThreshold},
                    onSelectionChanged: (selected) =>
                        controller.setAutoSellThreshold(selected.first),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                for (final (fraction, label) in const [
                  (.1, '%10 SAT'),
                  (.25, '%25 SAT'),
                  (.5, '%50 SAT'),
                ])
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: OutlinedButton(
                        onPressed: _canSellResources(state)
                            ? () => controller.sellFraction(fraction)
                            : null,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          minimumSize: const Size(0, 48),
                          textStyle: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        child: Text(label),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 46,
              child: ElevatedButton.icon(
                onPressed: _canSellResources(state) ? controller.sellAll : null,
                icon: const Icon(Icons.point_of_sale_rounded),
                label: const Text('REZERV DIŞI HER ŞEYİ SAT'),
              ),
            ),
            const SizedBox(height: 10),
            _subheading('KAYNAK ENVANTERİ'),
            const SizedBox(height: 5),
            ..._visibleInventory().map(
              (resource) =>
                  _InventoryRow(controller: controller, resource: resource),
            ),
            if (_visibleInventory().isEmpty)
              const _EmptyHint(
                'Henüz ambarında kaynak yok. Maden yüzeyindeki cevher düğümlerine dokun.',
              ),
          ],
        );
      case 'trade':
        final offer = GameEngine.merchantOffer(state);
        final wait = GameEngine.merchantSecondsLeft(state, DateTime.now());
        if (offer.blueprintId != null && offer.blueprintCashCost != null) {
          final blueprintId = offer.blueprintId!;
          final cashCost = offer.blueprintCashCost!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sectionIntro(
                'TİCARET NOKTASI',
                'Gezgin tüccar bazen montaj planlarını kasa karşılığında sunar. Her teklif süre bitene kadar değişmez.',
              ),
              ActionTile(
                icon: Icons.description_rounded,
                title:
                    'Montaj şeması • ${GameEngine.blueprintName(blueprintId)}',
                description: wait > 0
                    ? 'Tüccar yeni yük hazırlıyor. ${_duration(wait)} sonra dönecek.'
                    : 'Bu planı ${_compactCash(cashCost.toDouble())} kasa karşılığında arşive ekle.',
                buttonLabel: wait > 0
                    ? 'BEKLE'
                    : '${_compactCash(cashCost.toDouble())} KASA • AL',
                enabled: wait == 0 && state.canAfford(cashCost),
                onPressed: controller.acceptTrade,
                accent: MinePalette.amber,
              ),
              _statTile(
                'Bilinen montaj şeması',
                '${state.knownBlueprintIds.length}',
              ),
            ],
          );
        }
        final give = ResourceCatalog.byId[offer.giveId]!;
        final get = ResourceCatalog.byId[offer.getId]!;
        final canTrade =
            wait == 0 &&
            state.amount(offer.giveId) - state.reserve(offer.giveId) >=
                offer.giveAmount;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionIntro(
              'TİCARET NOKTASI',
              'Gezgin tüccar, kasaya alternatif olarak nadir kaynak takası sunar. Teklif derinliğe göre değişir.',
            ),
            ActionTile(
              icon: Icons.swap_horiz_rounded,
              title: 'Gezgin tüccar teklifi',
              description: wait > 0
                  ? 'Tüccar yeni yük hazırlıyor. ${_duration(wait)} sonra dönecek.'
                  : '${offer.giveAmount} ${give.name} ver → ${offer.getAmount} ${get.name} al. Rezervdeki cevher kullanılamaz.',
              buttonLabel: wait > 0 ? 'BEKLE' : 'TAKAS ET',
              enabled: canTrade,
              onPressed: controller.acceptTrade,
              accent: MinePalette.teal,
            ),
            _statTile(
              'Sandık koleksiyonu',
              '${state.totalChestsFound} bekliyor • ${state.chestsOpened} açıldı',
            ),
            for (final (tier, title, icon, count) in [
              (
                'basic',
                'Temel sandık',
                Icons.inventory_2_rounded,
                state.chestsFound,
              ),
              ('gold', 'Altın sandık', Icons.star_rounded, state.goldChests),
              ('deep', 'Derin sandık', Icons.diamond_rounded, state.deepChests),
            ])
              if (count > 0)
                ActionTile(
                  icon: icon,
                  title: '$title • $count',
                  description: 'Kasa, derinlik cevheri ve sondaj parçası içerir; ganimet kargo kapasitesini aşabilir.',
                  buttonLabel: 'SANDIĞI AÇ',
                  enabled: true,
                  onPressed: () => controller.openChest(tier: tier),
                  accent: tier == 'deep'
                      ? MinePalette.violet
                      : tier == 'gold'
                      ? MinePalette.amber
                      : MinePalette.teal,
                ),
            if (state.unlockedBuildings.contains('chest_collector')) ...[
              ActionTile(
                icon: Icons.archive_rounded,
                title: 'Otomatik sandık toplayıcı',
                description:
                    '${state.collectorStoredChests}/${state.chestCollectorCapacity} sandık depoda • her 30 dakikada bir sandık bulur.',
                buttonLabel: state.collectorStoredChests > 0
                    ? 'DEPOLANANLARI AL'
                    : 'DEPO BOŞ',
                enabled: state.collectorStoredChests > 0,
                onPressed: controller.claimCollectedChests,
                accent: MinePalette.cyan,
              ),
              ActionTile(
                icon: Icons.expand_rounded,
                title: 'Toplayıcı deposu • Lv ${state.chestCollectorLevel}',
                description:
                    'Kapasiteyi iki sandık artırır. Sonraki geliştirme ${GameEngine.chestCollectorUpgradeCost(state)} kasa.',
                buttonLabel: state.chestCollectorLevel >= 10
                    ? 'MAKSİMUM'
                    : '${GameEngine.chestCollectorUpgradeCost(state)} KASA',
                enabled:
                    state.chestCollectorLevel < 10 &&
                    state.canAfford(
                      GameEngine.chestCollectorUpgradeCost(state).toDouble(),
                    ),
                onPressed: controller.upgradeChestCollector,
                accent: MinePalette.cyan,
              ),
            ],
            if (state.unlockedBuildings.contains('chest_compressor')) ...[
              _statTile(
                'Sıkıştırma kuyruğu',
                '${state.chestCompressionQueue.length}/${state.chestCompressionSlots} yuva • ${_duration(GameEngine.chestCompressionSecondsLeft(state, DateTime.now()))} kaldı',
              ),
              ActionTile(
                icon: Icons.all_inbox_rounded,
                title:
                    '${GameEngine.chestCompressionBasicCost(state)} temel → 1 altın sandık',
                description:
                    'Süre: 5 dakika. Kuyruk seviyesi ${state.chestCompressionLevel}; maliyet ödenen temel sandıklardır.',
                buttonLabel: 'SIRAYA KOY',
                enabled:
                    state.chestsFound >=
                        GameEngine.chestCompressionBasicCost(state) &&
                    state.chestCompressionQueue.length <
                        state.chestCompressionSlots,
                onPressed: () => controller.startChestCompression('gold'),
                accent: MinePalette.amber,
              ),
              ActionTile(
                icon: Icons.diamond_rounded,
                title:
                    '${GameEngine.chestCompressionGoldCost(state)} altın → 1 derin sandık',
                description: 'Süre: 20 dakika. Derin sandık en yüksek ganimet havuzudur.',
                buttonLabel: 'SIRAYA KOY',
                enabled:
                    state.goldChests >=
                        GameEngine.chestCompressionGoldCost(state) &&
                    state.chestCompressionQueue.length <
                        state.chestCompressionSlots,
                onPressed: () => controller.startChestCompression('deep'),
                accent: MinePalette.violet,
              ),
              ActionTile(
                icon: Icons.upgrade_rounded,
                title: 'Sandık sıkıştırıcı • Lv ${state.chestCompressionLevel}',
                description: 'Seviye süreyi kısaltır; her 3 seviye bir kuyruk yuvası açar.',
                buttonLabel: state.chestCompressionLevel >= 9
                    ? 'MAKSİMUM'
                    : '${GameEngine.chestCompressorUpgradeCost(state)} KASA',
                enabled:
                    state.chestCompressionLevel < 9 &&
                    state.canAfford(
                      GameEngine.chestCompressorUpgradeCost(state).toDouble(),
                    ),
                onPressed: controller.upgradeChestCompressor,
                accent: MinePalette.violet,
              ),
            ],
            _statTile(
              'Toplam satış',
              '${state.totalSold.exponent >= 15 ? state.totalSold.toScientificString() : state.totalSold} kasa değeri',
            ),
            _statTile(
              'Sandık koleksiyonu',
              '${state.chestsOpened} açıldı • ${state.chestsFound} bekliyor',
            ),
            if (state.unlockedBuildings.contains('chest_collector'))
              _statTile('Otomatik toplayıcı', 'Her 30 dakikada bir sandık'),
            if (state.unlockedBuildings.contains('chest_compressor'))
              _statTile('Sandık sıkıştırıcı', 'Daha çok cevher ve +%50 kasa'),
            if (state.amount('ticket') > 0)
              _statTile('Sefer bileti', '${state.amount('ticket')} adet'),
          ],
        );
      case 'research':
        return _researchContents(context);
      case 'reactor':
        return _reactorContents(context);
      case 'buff_lab':
        return _buffLabContents();
      case 'armory':
        return _bossContents();
      case 'expedition':
        return _expeditionContents(context);
      case 'boss':
        return _bossContents();
      case 'mine_event':
        return _mineEventContents();
      case 'quests':
        return _questContents();
      case 'achievements':
        return _achievementContents();
      default:
        return _researchContents(context);
    }
  }

  Widget _oilPumpSection(GameState state) {
    if (!state.unlockedBuildings.contains('underground_city')) {
      return const ActionTile(
        icon: Icons.oil_barrel_rounded,
        title: 'Yeraltı şehri petrol pompası',
        description: 'Pompa 300 km derinlikte açılır.',
        buttonLabel: '300 KM AÇILIR',
        enabled: false,
        onPressed: null,
        accent: MinePalette.amber,
      );
    }

    final capacity = GameEngine.oilPumpStorageCapacity(state);
    final storedOil = GameEngine.oilPumpStored(state);
    final availableOil = GameEngine.unreservedOil(state);
    final upgradeCost = GameEngine.oilPumpUpgradeCost(state);
    final productionPerMinute =
        GameEngine.oilPumpProductionPerSecond(state) * 60;
    final atMaximum = state.oilPumpLevel >= GameEngine.oilPumpMaximumLevel;
    final saleValue = availableOil * GameEngine.oilPumpSaleValuePerBarrel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ActionTile(
          icon: Icons.oil_barrel_rounded,
          title: 'Yeraltı şehri petrol pompası',
          description:
              'Kademe ${state.oilPumpLevel} • ${productionPerMinute.toStringAsFixed(1)} petrol/dk • Dünya deposu $storedOil/$capacity varil. Her kademe üretimi ×1,6 artırır ve depoya 150 varil ekler.',
          buttonLabel: atMaximum
              ? 'EN YÜKSEK KADEME'
              : '$upgradeCost KASA • GELİŞTİR',
          enabled: !atMaximum && state.canAfford(upgradeCost.toDouble()),
          onPressed: controller.upgradeOilPump,
          accent: MinePalette.amber,
        ),
        ActionTile(
          icon: Icons.point_of_sale_rounded,
          title: 'Pompadaki petrolü sat',
          description: 'Rezerve edilmeyen her varil 500 kasa getirir. İşleyerek yapı malzemesi üretmek için bir bölümünü saklayabilirsin.',
          buttonLabel: availableOil > 0 ? '+$saleValue KASA' : 'PETROL YOK',
          enabled: availableOil > 0,
          onPressed: controller.sellOil,
          accent: MinePalette.teal,
        ),
      ],
    );
  }

  Widget _drillAssemblySection(GameState state) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: 7),
      _subheading('SONDAJ MONTAJI'),
      _sectionIntro(
        'UÇ • FAN • MOTOR',
        'Toplam güç, üç parçanın watt değerleri ve çarpanlarıyla hesaplanır. Kazı süresi bulunduğun derinliğin zorluğuna göre değişir; şemalar kasa ve maden ister.',
      ),
      for (final encounter in GameEngine.blueprintEncounters.entries)
        if (GameEngine.canClaimBlueprintEncounter(state, encounter.key))
          ActionTile(
            icon: Icons.description_rounded,
            title: '${encounter.value.$1} montaj şemaları',
            description:
                '${encounter.value.$2 ~/ 1000} km derinlikte bulunan donanım planlarını arşive ekle.',
            buttonLabel: 'ŞEMALARI AL',
            enabled: true,
            onPressed: () => controller.claimBlueprintEncounter(encounter.key),
            accent: MinePalette.cyan,
          ),
      _statTile('Bilinen montaj şeması', '${state.knownBlueprintIds.length}'),
      _statTile(
        'Toplam montaj gücü',
        '${DrillAssemblyCatalog.power(bitLevel: state.drillBitLevel, fanLevel: state.drillFanLevel, engineLevel: state.drillEngineLevel).toStringAsFixed(0)} W • derinliğe göre hesaplanır',
      ),
      for (final component in DrillAssemblyCatalog.all)
        _drillAssemblyUpgradeTile(state, component),
    ],
  );

  Widget _drillAssemblyUpgradeTile(
    GameState state,
    DrillAssemblyDefinition component,
  ) {
    final level = GameEngine.drillAssemblyLevel(state, component.id);
    final nextLevel = level + 1;
    final cost = GameEngine.drillAssemblyUpgradeCost(state, component.id);
    final requirements = GameEngine.drillAssemblyMaterialRequirements(
      state,
      component.id,
    );
    final deficits = GameEngine.drillAssemblyMaterialDeficits(
      state,
      component.id,
    );
    final requiredDepth = DrillAssemblyCatalog.requiredDepthFor(nextLevel);
    final depthLocked =
        nextLevel <= DrillAssemblyCatalog.maxLevel &&
        state.deepestMeters < requiredDepth;
    final requiredBuilding = DrillAssemblyCatalog.requiredBuildingFor(
      nextLevel,
    );
    final blueprintId = DrillAssemblyCatalog.blueprintIdFor(
      component.id,
      nextLevel,
    );
    final blueprintLocked =
        blueprintId != null && !state.knownBlueprintIds.contains(blueprintId);
    final buildingLocked =
        requiredBuilding != null &&
        !state.unlockedBuildings.contains(requiredBuilding);
    final requiredBuildingName = switch (requiredBuilding) {
      'robot_mk2' => 'Robot Mk II',
      'robot_mk3' => 'Robot Mk III',
      _ => '',
    };
    final recipeText = requirements.entries
        .map(
          (entry) =>
              '${entry.value} ${ResourceCatalog.byId[entry.key]?.name ?? entry.key}',
        )
        .join(' + ');
    final currentWatts = component.wattsAt(level);
    final nextWatts = level >= DrillAssemblyCatalog.maxLevel
        ? currentWatts
        : component.wattsAt(nextLevel);
    final currentMultiplier = DrillAssemblyCatalog.wattMultiplierAt(
      component.id,
      level,
    );
    final nextMultiplier = level >= DrillAssemblyCatalog.maxLevel
        ? currentMultiplier
        : DrillAssemblyCatalog.wattMultiplierAt(component.id, nextLevel);
    return ActionTile(
      icon: switch (component.id) {
        'bit' => Icons.hardware_rounded,
        'fan' => Icons.toys_rounded,
        _ => Icons.settings_rounded,
      },
      title: '${component.name} • Lv $level/${DrillAssemblyCatalog.maxLevel}',
      description: level >= DrillAssemblyCatalog.maxLevel
          ? 'Son şema tamamlandı • ${currentWatts.toStringAsFixed(0)} W.'
          : blueprintLocked
          ? 'Bu seviyenin montaj şeması henüz arşivde yok.'
          : depthLocked
          ? 'Sonraki şema ${requiredDepth ~/ 1000} km derinlikte açılır.'
          : buildingLocked
          ? 'Bu şema için $requiredBuildingName bulunmalı.'
          : '${currentWatts.toStringAsFixed(0)} W ×${_compactCash(currentMultiplier)} → ${nextWatts.toStringAsFixed(0)} W ×${_compactCash(nextMultiplier)}${recipeText.isEmpty ? '' : ' • Tarif: $recipeText'}.',
      buttonLabel: level >= DrillAssemblyCatalog.maxLevel
          ? 'MAKSİMUM'
          : blueprintLocked
          ? 'ŞEMA GEREKİYOR'
          : depthLocked
          ? '${requiredDepth ~/ 1000} KM'
          : buildingLocked
          ? requiredBuildingName.toUpperCase()
          : cost == 0
          ? 'TARİFİ ÜRET'
          : '${_compactCash(cost)} KASA',
      enabled:
          level < DrillAssemblyCatalog.maxLevel &&
          !blueprintLocked &&
          !depthLocked &&
          !buildingLocked &&
          state.crewCount > 0 &&
          state.canAfford(cost.toDouble()) &&
          deficits.isEmpty,
      onPressed: () => controller.upgradeDrillAssembly(component.id),
      accent: component.id == 'engine' ? MinePalette.amber : MinePalette.cyan,
    );
  }

  Widget _managerUpgradeTile(GameState state) {
    final nextLevel = state.managerLevel + 1;
    final requirements = GameEngine.managerUpgradeRequirements(nextLevel);
    final deficits = GameEngine.managerUpgradeDeficits(state);
    final requiredDepth = nextLevel <= 3
        ? GameEngine.managerRequiredDepth(nextLevel)
        : 0;
    final depthLocked = nextLevel <= 3 && state.deepestMeters < requiredDepth;
    final hours = GameEngine.maxOfflineFor(state).inHours;
    final currentRate = (GameEngine.offlineRateMultiplier(state) * 100).round();
    final nextOfflineHours = switch (nextLevel) {
      1 => 12,
      2 => 24,
      3 => 48,
      _ => hours,
    };
    final nextRate = switch (nextLevel) {
      1 => 25,
      2 => 50,
      3 => 100,
      _ => currentRate,
    };
    final costText = requirements.entries
        .map(
          (entry) =>
              '${entry.value} ${ResourceCatalog.byId[entry.key]?.name ?? entry.key}',
        )
        .join(' + ');
    final missingText = deficits.entries
        .map(
          (entry) =>
              '${entry.value} ${ResourceCatalog.byId[entry.key]?.name ?? entry.key}',
        )
        .join(', ');
    return ActionTile(
      icon: Icons.manage_accounts_rounded,
      title: 'Vardiya yöneticisi • Kademe ${state.managerLevel}/3',
      description: nextLevel > 3
          ? 'Maksimum kademe • çevrimdışı üretim %$currentRate hızda, en fazla $hours saat.'
          : depthLocked
          ? 'Çevrimdışı üretimi %$nextRate hıza ve $nextOfflineHours saate çıkarır. $requiredDepth m’de açılır.'
          : 'Şimdi çevrimdışı üretim %$currentRate hızda, en fazla $hours saat. Sonraki kademe: %$nextRate hız ve $nextOfflineHours saat • $costText${missingText.isEmpty ? '' : ' • Eksik: $missingText'}. Kaynak kilitleri ve rezervler korunur.',
      buttonLabel: nextLevel > 3
          ? 'MAKSİMUM'
          : depthLocked
          ? '${(requiredDepth / 1000).round()} KM AÇILIR'
          : 'YÖNETİCİYİ GELİŞTİR',
      enabled: nextLevel <= 3 && !depthLocked && deficits.isEmpty,
      onPressed: controller.upgradeManager,
      accent: MinePalette.teal,
    );
  }

  Widget _reactorUpgradeTile(GameState state) {
    final currentLevel = state.upgradeLevel('reactor');
    final nextLevel = currentLevel + 1;
    if (nextLevel > 5) {
      return ActionTile(
        icon: Icons.upgrade_rounded,
        title: 'Reaktör ızgarası • Maksimum',
        description: '81 hücreli son ızgara kademesi açıldı.',
        buttonLabel: 'MAKSİMUM',
        enabled: false,
        onPressed: () {},
        accent: MinePalette.teal,
      );
    }
    final energyCost = GameEngine.reactorUpgradeEnergyCost(nextLevel);
    final requirements = GameEngine.reactorUpgradeMaterialRequirements(
      nextLevel,
    );
    final deficits = GameEngine.reactorUpgradeMaterialDeficits(state);
    final costText = requirements.entries
        .map(
          (entry) =>
              '${entry.value} ${ResourceCatalog.byId[entry.key]?.name ?? entry.key}',
        )
        .join(' + ');
    final missingText = deficits.entries
        .map(
          (entry) =>
              '${entry.value} ${ResourceCatalog.byId[entry.key]?.name ?? entry.key}',
        )
        .join(', ');
    return ActionTile(
      icon: Icons.upgrade_rounded,
      title: 'Izgara kademesi $nextLevel/5',
      description:
          '$costText + $energyCost enerji. Depoda ${state.energy.toStringAsFixed(0)} enerji var${missingText.isEmpty ? '' : ' • Eksik: $missingText'}.',
      buttonLabel: GameEngine.canUpgradeReactor(state)
          ? '$energyCost ENERJİYLE YÜKSELT'
          : 'GEREKSİNİMLERİ TOPLA',
      enabled: GameEngine.canUpgradeReactor(state),
      onPressed: () => controller.upgrade('reactor'),
      accent: MinePalette.teal,
    );
  }

  Widget _buffLabContents() {
    final state = controller.state;
    final totalDrain = GameEngine.buffLabEnergyDrainPerSecond(state);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionIntro(
          'BUFF LABORATUVARI',
          'Sürekli etkiler reaktör enerjisi tüketir. Enerji biterse çalışan tüm etkiler kapanır.',
        ),
        _statTile('Enerji deposu', '${state.energy.toStringAsFixed(0)} birim'),
        _statTile('Anlık tüketim', '$totalDrain enerji/sn'),
        const SizedBox(height: 6),
        for (final buff in BuffLabCatalog.all)
          Container(
            margin: const EdgeInsets.only(bottom: 7),
            decoration: BoxDecoration(
              color: state.activeBuffIds.contains(buff.id)
                  ? const Color(0xFF102F2B)
                  : const Color(0xFF0B222C),
              border: Border.all(
                color: state.activeBuffIds.contains(buff.id)
                    ? MinePalette.teal
                    : MinePalette.border,
              ),
              borderRadius: BorderRadius.circular(7),
            ),
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              title: Text(
                buff.name,
                style: const TextStyle(
                  color: MinePalette.cream,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
              subtitle: Text(
                '${buff.description} • ${buff.energyDrainPerSecond.toStringAsFixed(0)} enerji/sn',
                style: const TextStyle(color: MinePalette.muted, fontSize: 10),
              ),
              value: state.activeBuffIds.contains(buff.id),
              activeThumbColor: MinePalette.teal,
              onChanged:
                  state.activeBuffIds.contains(buff.id) ||
                      state.energy >= buff.energyDrainPerSecond
                  ? (active) => controller.toggleBuffLabEffect(buff.id, active)
                  : null,
            ),
          ),
      ],
    );
  }

  Widget _reactorContents(BuildContext context) {
    final state = controller.state;
    final level = GameEngine.reactorLevel(state);
    final dimension = ReactorCatalog.gridDimension(level);
    final validCells = ReactorCatalog.cells(level).toSet();
    final stable = GameEngine.reactorIsThermallyStable(state);
    final heat = GameEngine.reactorHeatGenerated(state);
    final cooling = GameEngine.reactorHeatCooled(state);
    final cellWidth = (dimension * 44).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionIntro(
          'REAKTÖR • KADEME $level',
          'Yakıt üretim sağlar; fanlar ısıyı düşürür. Isı soğutmayı geçerse güvenlik sistemi reaktörü kapatır.',
        ),
        _reactorUpgradeTile(state),
        Container(
          margin: const EdgeInsets.only(bottom: 9),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: state.reactorShutdown || !stable
                ? const Color(0xFF351C20)
                : const Color(0xFF102F2B),
            border: Border.all(
              color: state.reactorShutdown || !stable
                  ? MinePalette.danger
                  : MinePalette.teal,
            ),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                state.reactorShutdown
                    ? 'GÜVENLİK KAPATMASI'
                    : stable
                    ? 'ISI DENGESİ STABİL'
                    : 'ISI DENGESİ AŞILDI',
                style: TextStyle(
                  color: state.reactorShutdown || !stable
                      ? MinePalette.danger
                      : MinePalette.teal,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Isı $heat / Soğutma $cooling • Üretim ${GameEngine.reactorEnergyPerSecond(state)} enerji/sn • Depo ${state.energy.toStringAsFixed(0)}',
                style: const TextStyle(color: MinePalette.cream, fontSize: 10),
              ),
              if (state.reactorShutdown)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: OutlinedButton.icon(
                    onPressed: stable ? controller.restartReactor : null,
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: const Text('DENGEYİ KUR VE YENİDEN BAŞLAT'),
                  ),
                ),
            ],
          ),
        ),
        _subheading(
          'REAKTÖR IZGARASI • ${ReactorCatalog.slotCount(level)} YUVA',
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: cellWidth,
            height: cellWidth,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: dimension * dimension,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: dimension,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
              ),
              itemBuilder: (context, index) {
                final x = index % dimension;
                final y = index ~/ dimension;
                final valid = validCells.contains((x, y));
                final componentId = state.reactorComponents['$x,$y'];
                final component = ReactorCatalog.componentById[componentId];
                final color = component == null
                    ? MinePalette.border
                    : component.heatGenerated > 0
                    ? MinePalette.danger
                    : component.heatCooled > 0
                    ? MinePalette.cyan
                    : MinePalette.amber;
                return Semantics(
                  button: valid,
                  label: valid
                      ? 'Yuva $x, $y • ${component?.name ?? 'boş'}'
                      : 'Kilitli yuva',
                  child: InkWell(
                    onTap: valid
                        ? () => _showReactorComponentSelector(context, x, y)
                        : null,
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: valid
                            ? const Color(0xFF10252C)
                            : const Color(0xFF07141A),
                        border: Border.all(
                          color: valid
                              ? color.withValues(alpha: .75)
                              : MinePalette.border,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        component?.shortName ?? (valid ? '·' : '×'),
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        style: TextStyle(
                          color: color,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        _subheading('İZOTOP ÜRETİMİ'),
        for (final recipe in ReactorCatalog.isotopeRecipes)
          Builder(
            builder: (context) {
              final owned = state.amount(recipe.id);
              final depthReady =
                  state.deepestMeters >= recipe.minimumDepthMeters;
              return ActionTile(
                icon: Icons.science_rounded,
                title: '${recipe.name} • $owned ambarda',
                description: depthReady
                    ? '${recipe.energyCost} enerji kullanır. Reaktör deposunda ${state.energy.toStringAsFixed(0)} enerji var.'
                    : '${(recipe.minimumDepthMeters / 1000).round()} km derinlikte şeması açılır.',
                buttonLabel: depthReady
                    ? '${recipe.energyCost} ENERJİ ÜRET'
                    : '${(recipe.minimumDepthMeters / 1000).round()} KM',
                enabled: depthReady && state.energy >= recipe.energyCost,
                onPressed: () => controller.synthesizeReactorIsotope(recipe.id),
                accent: MinePalette.cyan,
              );
            },
          ),
        ActionTile(
          icon: Icons.bolt_rounded,
          title: 'Kısa güç darbesi',
          description: '25 enerji harca; sondaj rezonansı için iki dakikalık güç desteği başlat.',
          buttonLabel: 'GÜÇ VER',
          enabled: state.energy >= 25,
          onPressed: controller.activateReactorBuff,
          accent: MinePalette.amber,
        ),
      ],
    );
  }

  void _showReactorComponentSelector(BuildContext context, int x, int y) {
    final level = GameEngine.reactorLevel(controller.state);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: MinePalette.ink,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(
              title: Text(
                'REAKTÖR MODÜLÜ SEÇ',
                style: TextStyle(
                  color: MinePalette.amber,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.crop_square_rounded,
                color: MinePalette.muted,
              ),
              title: const Text('Yuvayı boşalt'),
              onTap: () {
                controller.setReactorComponent(x, y, 'empty');
                Navigator.pop(sheetContext);
              },
            ),
            for (final component in ReactorCatalog.components)
              if (component.minimumLevel <= level)
                ListTile(
                  leading: Icon(
                    _reactorModuleIcon(component.id),
                    color: component.heatGenerated > 0
                        ? MinePalette.danger
                        : component.heatCooled > 0
                        ? MinePalette.cyan
                        : MinePalette.amber,
                  ),
                  title: Text(component.name),
                  subtitle: Text(
                    '+${component.energyPerSecond} enerji/sn • +${component.heatGenerated} ısı • -${component.heatCooled} soğutma',
                    style: const TextStyle(color: MinePalette.muted),
                  ),
                  onTap: () {
                    controller.setReactorComponent(x, y, component.id);
                    Navigator.pop(sheetContext);
                  },
                ),
          ],
        ),
      ),
    );
  }

  IconData _reactorModuleIcon(String id) => switch (id) {
    'fuel_rod' => Icons.local_fire_department_rounded,
    'cooling_fan' || 'cryo_fan' => Icons.toys_rounded,
    'battery' => Icons.battery_charging_full_rounded,
    'neutron_bombardment' => Icons.bolt_rounded,
    _ => Icons.crop_square_rounded,
  };

  Future<void> _confirmScientistSacrifice(
    BuildContext context,
    ScientistState scientist,
  ) async {
    final reward = GameEngine.scientistSacrificeReward(scientist);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: MinePalette.ink,
        title: const Text('Bilim insanını çekirdeğe ada?'),
        content: Text(
          '${scientist.name} kadrodan kalıcı olarak ayrılır. Karşılığında $reward kalıcı çekirdek parçası alırsın.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('VAZGEÇ'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('ADA'),
          ),
        ],
      ),
    );
    if (confirmed == true) controller.sacrificeScientistToCore(scientist.id);
  }

  Widget _researchContents(BuildContext context) {
    final state = controller.state;
    final resonanceQuestActive =
        controller.currentQuest.kind == QuestKind.resonance;
    final targetName =
        ResourceCatalog.byId[GameEngine.currentResonanceTarget(state)]?.name ??
        'Kömür';
    final resonanceSequence = state.resonancePattern
        .map((id) => ResourceCatalog.byId[id]?.name ?? id)
        .join(' → ');
    final resonanceSequenceLength = math.max(1, state.resonancePattern.length);
    final relicNames = {
      'relic_1': 'Yankı Aynası',
      'relic_2': 'Cevher Kalbi',
      'relic_3': 'Derinlik Pusulası',
      'relic_4': 'Kırık Sondaj',
      'relic_5': 'Ay Yazıtı',
      'relic_6': 'Isı Mührü',
      'relic_7': 'Kristal Tohum',
      'relic_8': 'Boşluk Madalyonu',
      'relic_9': 'Eski Kask',
      'relic_10': 'Titan Dişi',
      'relic_11': 'Saat Taşı',
      'relic_12': 'Çekirdek Mührü',
      'relic_150': 'Atom Kargısı',
      'relic_151': 'Atom Kargısı+',
      'relic_152': 'Atom Kargısı++',
      'relic_153': 'Tüy Parçası',
      'relic_154': 'Nükleer Kargı+',
      'relic_155': 'Nükleer Kargı++',
    };
    final relics = state.unlockedRelics.toList()
      ..sort((a, b) {
        final aNum = int.tryParse(a.replaceAll(RegExp(r'\D'), '')) ?? 0;
        final bNum = int.tryParse(b.replaceAll(RegExp(r'\D'), '')) ?? 0;
        return aNum.compareTo(bNum);
      });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionIntro(
          'ARAŞTIRMA GÖZLEMEVİ',
          'Bilim insanları damar dizilerini izler, kalıntıları inceler ve çekirdek teknolojilerini geliştirir.',
        ),
        ActionTile(
          icon: Icons.radar_rounded,
          title: 'Katman Rezonansı • Damar Akordu',
          description:
              '${resonanceQuestActive ? 'Görevi buradan başlat: ' : ''}${state.upgradeLevel('scanner') > 0 ? 'Tarama ücretsiz.' : 'Diziyi taramak 80 kasa.'} Sonra kuyuya dön ve sırayı uygula: $resonanceSequence. Sıradaki damar: $targetName (${state.resonanceProgress + 1}/$resonanceSequenceLength). Doğru cevher taşlarına sırayla dokun; dizi tamamlanınca üretim 5 dakika hızlanır.',
          buttonLabel: state.upgradeLevel('scanner') > 0
              ? 'DİZİYİ TARA'
              : 'TARA • 80 KASA',
          enabled: state.upgradeLevel('scanner') > 0 || state.canAfford(80),
          onPressed: controller.scanResonance,
          accent: resonanceQuestActive ? MinePalette.amber : MinePalette.cyan,
          highlighted: resonanceQuestActive,
        ),
        UpgradeRow(controller: controller, track: 'scanner'),
        ActionTile(
          icon: Icons.science_rounded,
          title: 'Bilim insanı işe al',
          description: state.deepestMeters < 50000
              ? 'Araştırma ekibi 50.000 m kilometre taşında bulunur.'
              : '${state.scientists} bilim insanı görevde. Kazı ekibi yeni kalıntılar ve sondaj parçaları arar.',
          buttonLabel: state.deepestMeters < 50000
              ? '50 km AÇILIR'
              : '420 KASA',
          enabled:
              state.deepestMeters >= 50000 &&
              state.scientists < 8 &&
              state.canAfford(420),
          onPressed: controller.hireScientist,
          accent: MinePalette.teal,
        ),
        _scientistRosterSection(state),
        if (state.unlockedBuildings.contains('deep_core')) ...[
          _subheading('DERİN ÇEKİRDEK • BİLİM İNSANI ADAMA'),
          for (final scientist in state.scientistRoster)
            if (!scientist.dead && state.activeScientistId != scientist.id)
              ActionTile(
                icon: Icons.auto_awesome_rounded,
                title: '${scientist.name}’i çekirdeğe ada',
                description:
                    'Bilim insanı kalıcı olarak kadrodan çıkar. ${GameEngine.scientistSacrificeReward(scientist)} çekirdek parçası kazanırsın.',
                buttonLabel: 'ÇEKİRDEĞE ADA',
                enabled: true,
                onPressed: () => _confirmScientistSacrifice(context, scientist),
                accent: MinePalette.violet,
              ),
          if (state.scientistRoster.every(
            (scientist) =>
                scientist.dead || state.activeScientistId == scientist.id,
          ))
            const _EmptyHint(
              'Çekirdeğe adanabilecek, görev dışında yaşayan bilim insanı yok.',
            ),
        ],
        ActionTile(
          icon: Icons.search_rounded,
          title: state.excavationCompletedPending
              ? 'Araştırma buluntusu hazır'
              : 'Bilimsel kazı başlat',
          description:
              state.excavationReadyAt != null &&
                  !state.excavationCompletedPending
              ? 'Kazı sürüyor • ${_duration(state.excavationReadyAt!.difference(DateTime.now()).inSeconds)} kaldı. Uygulama kapalıyken de süre işler.'
              : '70 saniyelik otomatik kazı, 50 km sonrasında bir kalıntı, sondaj parçası ve kasa ödülü verir.',
          buttonLabel: state.excavationCompletedPending
              ? 'BULUNTUYU AL'
              : state.excavationReadyAt != null
              ? 'SÜRÜYOR'
              : 'KAZI BAŞLAT',
          enabled:
              state.excavationCompletedPending ||
              (state.excavationReadyAt == null &&
                  state.deepestMeters >= 50000 &&
                  state.scientists > 0),
          onPressed: state.excavationCompletedPending
              ? controller.claimExcavation
              : controller.startExcavation,
          accent: MinePalette.violet,
        ),
        if (state.unlockedBuildings.contains('reactor')) ...[
          ActionTile(
            icon: Icons.bolt_rounded,
            title: 'Reaktör ızgarası',
            description:
                'Izgara ${GameEngine.reactorLevel(state)}. kademe • Enerji ${state.energy.toStringAsFixed(0)} • Isı ${GameEngine.reactorHeatGenerated(state)}/${GameEngine.reactorHeatCooled(state)}.',
            buttonLabel: 'REAKTÖRÜ AÇ',
            enabled: true,
            onPressed: () => _openNested(context, 'reactor'),
            accent: MinePalette.teal,
          ),
        ] else
          _EmptyHint(
            'Reaktör 1.132 km’de, kalıcı çekirdek 500 km’de açılır. Bu sistemler keşif kilometre taşlarıyla gelir.',
          ),
        if (state.unlockedBuildings.contains('buff_lab'))
          ActionTile(
            icon: Icons.speed_rounded,
            title: 'Buff laboratuvarı',
            description: 'Üç sürekli etkiyi reaktör enerjisiyle çalıştır: sondaj, cevher verimi veya dron kalkanı.',
            buttonLabel: 'ETKİLERİ YÖNET',
            enabled: true,
            onPressed: () => _openNested(context, 'buff_lab'),
            accent: MinePalette.cyan,
          )
        else
          const _EmptyHint('Buff laboratuvarı 1.135 km’de açılır.'),
        if (state.unlockedBuildings.contains('armory'))
          ActionTile(
            icon: Icons.shield_rounded,
            title: 'Yeraltı cephaneliği',
            description:
                'Muhafızları yenerek sondaj parçaları ve bölge ödülleri kazan.',
            buttonLabel: 'MUHAFIZLARI YÖNET',
            enabled: true,
            onPressed: () => _openNested(context, 'armory'),
            accent: MinePalette.amber,
          )
        else
          const _EmptyHint('Yeraltı cephaneliği 305 km’de açılır.'),
        const SizedBox(height: 5),
        _subheading(
          'GİZLİ KEŞİFLER • ${state.discoveredEncounters.length} / ${GameEngine.hiddenEncounters.length}',
        ),
        if (state.discoveredEncounters.isEmpty)
          const _EmptyHint(
            'Kuyudaki eski frekansları ve kayıp yapıları aramaya devam et.',
          )
        else
          for (final discovery in state.discoveredEncounters)
            _statTile(discovery, 'ARŞİVE KAYDEDİLDİ'),
        const SizedBox(height: 5),
        _subheading('KALINTI ARŞİVİ • ${relics.length} / ${relicNames.length}'),
        _statTile('Yazıt hurdası', '${state.relicScrap} adet'),
        const SizedBox(height: 5),
        if (relics.isEmpty)
          const _EmptyHint(
            'İlk kalıntılar sandıklardan veya bilimsel kazılardan çıkar.',
          ),
        for (final relic in relics)
          _RelicRow(
            name: _relicDisplayName(
              relic,
              state.relicLevel(relic),
              relicNames[relic] ?? 'Bilinmeyen yazıt',
            ),
            id: relic,
            level: state.relicLevel(relic),
            equipped: state.equippedRelics.contains(relic),
            duplicateCount: state.relicDuplicates[relic] ?? 0,
            upgradeCost: GameEngine.relicUpgradeCost(state, relic),
            onToggle: () => controller.toggleRelic(relic),
            onDismantle: () => controller.dismantleRelicDuplicate(relic),
            onUpgrade: () => controller.upgradeRelic(relic),
          ),
      ],
    );
  }

  Widget _scientistRosterSection(GameState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        _subheading(
          'BİLİM KADROSU • ${state.livingScientistCount}/${state.scientistRoster.length} CANLI • MÜHÜR ${state.revivalTokens}',
        ),
        if (state.scientistRoster.isEmpty)
          const _EmptyHint(
            'İlk bilim insanı 50 km’de araştırma ekibine katılır.',
          ),
        for (final scientist in state.scientistRoster)
          _scientistCard(scientist, state),
      ],
    );
  }

  Widget _scientistCard(ScientistState scientist, GameState state) {
    final active = state.activeScientistId == scientist.id;
    final readyAt = active ? state.scientistExpeditionReadyAt : null;
    final rarityColor = switch (scientist.rarityId) {
      'uncommon' => const Color(0xFF63D4A4),
      'rare' => const Color(0xFF68AFFF),
      'legendary' => const Color(0xFFCA8DFF),
      'mythic' => const Color(0xFFFFCE67),
      _ => const Color(0xFFB9C7C6),
    };
    final canStart =
        !scientist.dead &&
        !scientist.injured &&
        !active &&
        state.activeScientistId == null;
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFF10252C),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: rarityColor.withValues(alpha: .48)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _AnimatedPortraitSprite(
                asset: 'scientist-portraits-atlas.png',
                index: state.scientistRoster.indexOf(scientist) % 8,
                width: 34,
                height: 34,
                haloColor: rarityColor,
                dimmed: scientist.dead,
                badge: scientist.dead
                    ? Icons.person_off_rounded
                    : scientist.injured
                    ? Icons.personal_injury_rounded
                    : null,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  '${scientist.name} • ${scientist.rarity.name} • Lv ${scientist.level}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: rarityColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${scientist.experience}/${scientist.level * 100} xp',
                style: const TextStyle(color: MinePalette.muted, fontSize: 8),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              '${scientist.trait.name} • ${scientist.trait.description} • Başarı +%${(scientist.successChanceBonus * 100).round()} • Süre −%${(scientist.excavationSpeed * 100).round()} • Yaralanma ${scientist.injuryCount}/2',
              style: const TextStyle(color: MinePalette.muted, fontSize: 8),
            ),
          ),
          if (scientist.dead)
            Padding(
              padding: const EdgeInsets.only(top: 7),
              child: OutlinedButton.icon(
                onPressed: state.revivalTokens > 0
                    ? () => controller.reviveScientist(scientist.id)
                    : null,
                icon: const Icon(Icons.favorite_rounded, size: 15),
                label: Text(
                  state.revivalTokens > 0
                      ? 'NADİR MÜHÜRLE CANLANDIR'
                      : 'CANLANDIRMA MÜHRÜ GEREKİR',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            )
          else if (scientist.injured)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                'Yaralı • iyileşmesine ${_duration(scientist.injuredUntil!.difference(DateTime.now()).inSeconds)} kaldı. Sonraki yaralanma ölümcül olur.',
                style: const TextStyle(color: MinePalette.danger, fontSize: 8),
              ),
            )
          else if (active)
            Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      readyAt!.isAfter(DateTime.now())
                          ? '${ScientistExpeditionCatalog.byId[state.activeScientistMissionId]!.name} sürüyor • ${_duration(readyAt.difference(DateTime.now()).inSeconds)} kaldı.'
                          : 'Sefer tamamlandı; ganimeti teslim al.',
                      style: const TextStyle(
                        color: MinePalette.amber,
                        fontSize: 9,
                      ),
                    ),
                  ),
                  if (!readyAt.isAfter(DateTime.now()))
                    TextButton.icon(
                      onPressed: controller.claimScientistExpedition,
                      icon: const Icon(Icons.inventory_2_rounded, size: 15),
                      label: const Text('AL', style: TextStyle(fontSize: 9)),
                    ),
                ],
              ),
            )
          else if (state.activeScientistId == null)
            Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Wrap(
                spacing: 5,
                runSpacing: 5,
                children: [
                  for (final mission in ScientistExpeditionCatalog.all)
                    Tooltip(
                      message:
                          '${mission.description}\n${(GameEngine.scientistMissionSuccessChance(scientist, mission) * 100).round()}% başarı • ${_duration(GameEngine.scientistMissionDuration(scientist, mission).inSeconds)} • Başarısızlık yaralanma riski taşır.',
                      child: OutlinedButton(
                        onPressed:
                            canStart &&
                                state.deepestMeters >= mission.minimumDepth
                            ? () => controller.startScientistExpedition(
                                scientist.id,
                                mission.id,
                              )
                            : null,
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          side: const BorderSide(color: MinePalette.border),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          '${mission.name} • ${(GameEngine.scientistMissionSuccessChance(scientist, mission) * 100).round()}%',
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _expeditionContents(BuildContext context) {
    final state = controller.state;
    final readyAt = state.caveReadyAt;
    final exploring = state.caveExploring;
    final secondsLeft = readyAt == null
        ? 0
        : math.max(0, readyAt.difference(DateTime.now()).inSeconds);
    final canClaim = state.caveCompletedPending;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionIntro(
          'SEFER GARAJI',
          'Keşif dronları mağaraları haritalar. Ekipman yükseltmeleri dönüş süresini kısaltır ve ganimeti büyütür.',
        ),
        Container(
          height: 112,
          margin: const EdgeInsets.only(bottom: 9),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF123944), Color(0xFF0B222D)],
            ),
            border: Border.all(color: MinePalette.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              AtlasSprite(
                asset: 'cave-creatures-guardians.png',
                index: 0,
                columns: 3,
                rows: 2,
                width: 100,
                height: 100,
              ),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  'Haritası çıkarılmamış mağaralarda cevher, yapı malzemesi, sefer bileti ve eski kalıntılar bulunabilir.',
                  style: TextStyle(
                    color: MinePalette.cream,
                    fontSize: 10,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        _statTile('Keşif dronları', '${state.drones} hazır'),
        _statTile('Tamamlanan mağaralar', '${state.cavesCompleted}'),
        _detailTile(
          'Mağara tehlikeleri',
          'Kaya bloğu: +1 yakıt • çamur: yer dronuna +1 yakıt • radyasyon: tüm dronlara hasar • lav (300 km+): yer dronuna hasar. Buff Lab kalkanı hasarı engeller.',
        ),
        ActionTile(
          icon: Icons.flight_rounded,
          title: 'Yeni keşif dronu',
          description: 'Mağara kilometre taşı açıldıktan sonra ek dron alabilirsin. Seferler sırayla yürütülür.',
          buttonLabel: '${260 + state.drones * 240} KASA',
          enabled:
              state.unlockedBuildings.contains('caves') &&
              state.drones < 12 &&
              state.canAfford((260 + state.drones * 240).toDouble()),
          onPressed: controller.buyDrone,
          accent: MinePalette.cyan,
        ),
        if (readyAt == null && !canClaim && !exploring) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0B222C),
              border: Border.all(color: MinePalette.border),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'SEFER ROTASI',
                  style: TextStyle(
                    color: MinePalette.cyan,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 'survey', label: Text('HARİTALI')),
                    ButtonSegment(value: 'safe', label: Text('GÜVENLİ')),
                    ButtonSegment(value: 'deep', label: Text('DERİN')),
                  ],
                  selected: {state.caveRoute},
                  onSelectionChanged: (selected) =>
                      controller.selectCaveRoute(selected.first),
                ),
                const SizedBox(height: 4),
                Text(
                  CaveRouteCatalog.byId[state.caveRoute]!.description,
                  style: const TextStyle(color: MinePalette.muted, fontSize: 9),
                ),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'GÖNDERİLECEK DRON',
                        style: TextStyle(
                          color: MinePalette.muted,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Bir dron çıkar',
                      constraints: const BoxConstraints.tightFor(
                        width: 48,
                        height: 48,
                      ),
                      onPressed: state.caveDroneCount > 1
                          ? () => controller.setCaveDroneCount(
                              state.caveDroneCount - 1,
                            )
                          : null,
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                    ),
                    Text(
                      '${state.caveDroneCount} / ${state.drones}',
                      style: const TextStyle(
                        color: MinePalette.cream,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Bir dron ekle',
                      constraints: const BoxConstraints.tightFor(
                        width: 48,
                        height: 48,
                      ),
                      onPressed: state.caveDroneCount < state.drones
                          ? () => controller.setCaveDroneCount(
                              state.caveDroneCount + 1,
                            )
                          : null,
                      icon: const Icon(Icons.add_circle_outline_rounded),
                    ),
                  ],
                ),
                Text(
                  '4 düğümlü keşif • Ganimet çarpanı ${((1 + (state.caveDroneCount - 1) * .35) * CaveRouteCatalog.byId[state.caveRoute]!.lootMultiplier).toStringAsFixed(1)}×',
                  style: const TextStyle(
                    color: MinePalette.amber,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'KEŞİF DRONU',
            style: TextStyle(
              color: MinePalette.cyan,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 5,
            runSpacing: 3,
            children: [
              for (final drone in CaveDroneCatalog.all)
                ChoiceChip(
                  avatar: AtlasSprite(
                    asset: 'support-drones-atlas.png',
                    index: _droneSpriteIndex(drone.id),
                    columns: 4,
                    rows: 2,
                    width: 30,
                    height: 23,
                  ),
                  label: Text(drone.name),
                  selected: state.caveDroneType == drone.id,
                  onSelected: (_) => controller.selectCaveDrone(drone.id),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${CaveDroneCatalog.byId[state.caveDroneType]!.description} • '
            'Can ${CaveDroneCatalog.byId[state.caveDroneType]!.health} • '
            'Görüş ${CaveDroneCatalog.byId[state.caveDroneType]!.vision} • '
            'Yakıt ${CaveDroneCatalog.byId[state.caveDroneType]!.fuel} • '
            'Toplama menzili ${CaveDroneCatalog.byId[state.caveDroneType]!.collectionRange}',
            style: const TextStyle(color: MinePalette.muted, fontSize: 9),
          ),
        ],
        if (state.caveNodeMap.isNotEmpty)
          _caveExplorationMap(state, controller),
        ActionTile(
          icon: Icons.route_rounded,
          title: canClaim
              ? 'Dron mağaradan döndü'
              : exploring
              ? 'Mağara haritası açık'
              : readyAt != null
              ? 'Keşif seferi sürüyor'
              : 'Mağara seferi başlat',
          description: canClaim
              ? 'Bulunan ganimet: ${_caveLootSummary(state)}'
              : exploring
              ? 'Düğüm ${state.caveStep + 1}/4 • Can ${state.caveDroneHealth} • Yakıt ${state.caveDroneFuel}. Bir yol seç; tehlike büyümeden ganimeti alabilirsin.'
              : readyAt != null
              ? '${CaveRouteCatalog.byId[state.caveRoute]!.name} • ${state.caveDroneCount} dron • ${_duration(secondsLeft)} kaldı. Oyunu kapatsan da keşif sürer.'
              : '45 km’den sonra açılır. ${CaveRouteCatalog.byId[state.caveRoute]!.name} rotasında ${state.caveDroneCount} dron cevher, yapı malzemesi ve bazen bilet veya kalıntı arar.',
          buttonLabel: canClaim
              ? 'GANİMETİ AL'
              : exploring
              ? 'KEŞİFTE'
              : readyAt != null
              ? 'SEFERDE'
              : 'SEFER GÖNDER',
          enabled:
              canClaim ||
              (!exploring &&
                  readyAt == null &&
                  state.deepestMeters >= 45000 &&
                  state.drones > 0),
          onPressed: canClaim
              ? controller.claimCaveExpedition
              : controller.startCaveExpedition,
          accent: canClaim ? MinePalette.amber : MinePalette.teal,
        ),
        if (exploring && state.caveStep > 0)
          ActionTile(
            icon: Icons.keyboard_return_rounded,
            title: 'Ganimetle geri dön',
            description: 'Şimdi dönersen bulunan ganimet güvende kalır.',
            buttonLabel: 'GERİ ÇAĞIR',
            enabled: true,
            onPressed: controller.retreatCave,
            accent: MinePalette.amber,
          ),
        ActionTile(
          icon: Icons.upgrade_rounded,
          title: 'Dron haritalama modülü • Lv ${state.expeditionLevel}',
          description: 'Her seviye mağara ganimetini %2,5 artırır ve keşif rotalarında yeni buluntu olasılığını yükseltir.',
          buttonLabel: '${380 + state.expeditionLevel * 520} KASA',
          enabled:
              state.expeditionLevel < 15 &&
              state.canAfford((380 + state.expeditionLevel * 520).toDouble()),
          onPressed: controller.upgradeExpedition,
          accent: MinePalette.amber,
        ),
        if (state.deepestMeters >= 500000)
          ActionTile(
            icon: Icons.restart_alt_rounded,
            title: 'Çekirdek sıfırlaması',
            description:
                'Bu kuyu vardiyasını yeniden kurar ve en derin ilerlemeden kalıcı çekirdek parçaları verir. Şimdiye kadarki derinlik: ${state.deepestMeters.floor()} m.',
            buttonLabel: 'YENİDEN DOĞ',
            enabled: true,
            onPressed: () => _confirmPrestige(context),
            accent: MinePalette.violet,
          )
        else
          _EmptyHint(
            'Çekirdek sıfırlaması 500 km’de açılır. Kalıcı parçalar, yeni vardiyanın sondajını güçlendirir.',
          ),
        const SizedBox(height: 7),
        _subheading('BÖLGELER'),
        _worldCard(0, 'Dünya', 'Başlangıç katmanları', Icons.terrain_rounded),
        _worldCard(
          1,
          'Ay',
          'Ay istasyonu • 1.032 km’de açılır',
          Icons.nights_stay_rounded,
        ),
        _worldCard(
          2,
          'Titan',
          'Buz ve metan • 1.782 km’de açılır',
          Icons.ac_unit_rounded,
        ),
        _EmptyHint(
          'Her dünyanın derinliği, basıncı ve ambarı ayrı kaydedilir. Ekipman yükseltmeleri ve kasa ortak kalır.',
        ),
      ],
    );
  }

  Widget _caveExplorationMap(GameState state, GameController controller) {
    final drone = CaveDroneCatalog.byId[state.caveDroneType]!;
    final maxHealth = drone.health + (state.caveDroneCount - 1) * 14;
    final visibleThrough = state.caveStep + drone.vision;
    final maxLaneJump = 1 + drone.collectionRange;
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF17353C), Color(0xFF091C25)],
        ),
        border: Border.all(color: const Color(0xFF31717A)),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _AnimatedDroneSprite(
                droneId: state.caveDroneType,
                damaged: state.caveDroneHealth <= maxHealth * .35,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${drone.name} • DÜĞÜM ${state.caveStep.clamp(0, 4)}/4',
                  style: const TextStyle(
                    color: MinePalette.cream,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .4,
                  ),
                ),
              ),
              Text(
                'YAKIT ${state.caveDroneFuel}',
                style: const TextStyle(
                  color: MinePalette.amber,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: maxHealth <= 0
                  ? 0
                  : (state.caveDroneHealth / maxHealth).clamp(0, 1),
              minHeight: 6,
              backgroundColor: const Color(0xFF422D2C),
              color: state.caveDroneHealth <= maxHealth * .3
                  ? MinePalette.danger
                  : MinePalette.teal,
            ),
          ),
          const SizedBox(height: 8),
          for (var row = 0; row < state.caveNodeMap.length; row++) ...[
            Row(
              children: [
                SizedBox(
                  width: 22,
                  child: Text(
                    '${row + 1}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: row == state.caveStep
                          ? MinePalette.amber
                          : MinePalette.muted,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                for (var lane = 0; lane < 3; lane++) ...[
                  if (lane > 0) const SizedBox(width: 5),
                  Expanded(
                    child: _caveNodeButton(
                      state: state,
                      controller: controller,
                      row: row,
                      lane: lane,
                      visible: row < visibleThrough,
                      active: state.caveExploring && row == state.caveStep,
                      reachable:
                          (lane - state.cavePreviousLane).abs() <= maxLaneJump,
                    ),
                  ),
                ],
              ],
            ),
            if (row < state.caveNodeMap.length - 1)
              const Padding(
                padding: EdgeInsets.only(left: 21),
                child: SizedBox(
                  height: 5,
                  child: Align(
                    alignment: Alignment.center,
                    child: VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: Color(0xFF38757B),
                    ),
                  ),
                ),
              ),
          ],
          const SizedBox(height: 5),
          Text(
            state.caveExploring
                ? 'Seçili yoldaki düğüme dokun. Dron görüşü sisi deler; mıknatıs yan kola erişir.'
                : state.caveDroneHealth <= 0
                ? 'Dronun canı tükendi. Kısmi ganimeti güvenceye al.'
                : 'Rota tamamlandı. Buluntuları ambara ve arşive aktar.',
            style: const TextStyle(color: MinePalette.muted, fontSize: 8),
          ),
        ],
      ),
    );
  }

  String _caveLootSummary(GameState state) => state.pendingCaveLoot.entries
      .map((entry) {
        final name =
            ResourceCatalog.byId[entry.key]?.name ??
            switch (entry.key) {
              'cave_coins' => 'kasa',
              'cave_chest' => 'sandık',
              'cave_buff' => 'rezonans buffı',
              'cave_scientist' => 'araştırmacı',
              _ => entry.key,
            };
        return '$name ×${entry.value}';
      })
      .join(', ');

  Widget _caveNodeButton({
    required GameState state,
    required GameController controller,
    required int row,
    required int lane,
    required bool visible,
    required bool active,
    required bool reachable,
  }) {
    final nodeId = state.caveNodeMap[row][lane];
    final node = CaveNodeCatalog.byId[nodeId]!;
    final visited = row < state.cavePathLanes.length;
    final selectedPath = visited && state.cavePathLanes[row] == lane;
    final canChoose = active && reachable;
    final tint = visible ? _caveNodeColor(nodeId) : MinePalette.muted;
    return Semantics(
      button: canChoose,
      label: visible ? node.name : 'Keşfedilmemiş galeri',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 42,
        decoration: BoxDecoration(
          color: visible
              ? tint.withValues(alpha: canChoose ? .22 : .09)
              : const Color(0xFF102129),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: canChoose
                ? MinePalette.amber
                : selectedPath
                ? MinePalette.teal
                : MinePalette.border,
            width: canChoose || selectedPath ? 1.5 : 1,
          ),
          boxShadow: canChoose
              ? [BoxShadow(color: tint.withValues(alpha: .18), blurRadius: 7)]
              : null,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: canChoose ? () => controller.chooseCaveNode(lane) : null,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: !visible
                ? const Center(
                    key: ValueKey('fog'),
                    child: Icon(
                      Icons.question_mark_rounded,
                      color: MinePalette.muted,
                      size: 15,
                    ),
                  )
                : Center(
                    key: ValueKey('$nodeId-$selectedPath-$canChoose'),
                    child: selectedPath
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: MinePalette.teal,
                            size: 17,
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _caveNodeIcon(nodeId),
                                color: tint,
                                size: 16,
                              ),
                              Text(
                                node.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: MinePalette.cream,
                                  fontSize: 6.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                  ),
          ),
        ),
      ),
    );
  }

  int _droneSpriteIndex(String id) => switch (id) {
    'flying' => 1,
    'magnet' => 2,
    'healer' => 3,
    _ => 0,
  };

  IconData _caveNodeIcon(String id) => switch (id) {
    'mineral' => Icons.diamond_rounded,
    'money' => Icons.payments_rounded,
    'chest' => Icons.inventory_2_rounded,
    'material' => Icons.construction_rounded,
    'buff' => Icons.auto_awesome_rounded,
    'rare' => Icons.token_rounded,
    'health' => Icons.medical_services_rounded,
    'scientist' => Icons.science_rounded,
    'boulder' => Icons.terrain_rounded,
    'mud' => Icons.water_rounded,
    'radiation' => Icons.warning_amber_rounded,
    'lava' => Icons.local_fire_department_rounded,
    _ => Icons.warning_amber_rounded,
  };

  Color _caveNodeColor(String id) => switch (id) {
    'mineral' => MinePalette.cyan,
    'money' => MinePalette.amber,
    'chest' => MinePalette.amber,
    'material' => MinePalette.teal,
    'buff' => MinePalette.violet,
    'rare' => const Color(0xFFDDA9FF),
    'health' => MinePalette.teal,
    'scientist' => const Color(0xFF9FDFC1),
    'boulder' => const Color(0xFFB7A28D),
    'mud' => const Color(0xFF9B7950),
    'radiation' => MinePalette.violet,
    'lava' => const Color(0xFFFF654A),
    _ => MinePalette.danger,
  };

  Widget _bossContents() {
    final state = controller.state;
    final bossIndex = GameEngine.availableBossIndex(state);
    if (bossIndex == null) {
      final nextBosses = GameEngine.bosses
          .where(
            (boss) =>
                GameEngine.bossWorldIndex(boss) == state.currentWorldIndex &&
                !state.defeatedBossIds.contains(boss.id),
          )
          .toList();
      final next = nextBosses.isEmpty ? null : nextBosses.first;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionIntro(
            'DERİNLİK MUHAFIZLARI',
            'Muhafız karşılaşmaları, yeni katmanlara geçiş için sondaj silahı ve takım gücü sınar.',
          ),
          _EmptyHint(
            next == null
                ? 'Bu bölgede kalan muhafız yok.'
                : 'Sıradaki muhafız: ${next.name} • ${next.depthMeters.floor()} m. Şu an: ${state.depthMeters.floor()} m.',
          ),
          const SizedBox(height: 8),
          for (final boss in GameEngine.bosses)
            _statTile(
              '${state.defeatedBossIds.contains(boss.id) ? '✓' : '○'} ${boss.name}',
              '${boss.depthMeters.floor()} m • ${boss.health.floor()} dayanıklılık',
            ),
        ],
      );
    }
    final boss = GameEngine.bosses[bossIndex];
    final health = GameEngine.bossHealth(state, bossIndex);
    final weakPointUntil = state.bossWeakPointUntil;
    final weakPointOpen = weakPointUntil?.isAfter(DateTime.now()) == true;
    final chestRewardName = switch (GameEngine.bossWorldIndex(boss)) {
      0 => 'temel sandık',
      1 => 'altın sandık',
      _ => 'derin sandık',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionIntro(
          'KATMAN MUHAFIZI',
          'Hedefli vuruşlar muhafızı zayıflatır. Silahı yükseltip ekiple saldır; zafer kasa, sondaj parçası ve sandık verir.',
        ),
        Container(
          height: 190,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: MinePalette.border),
            gradient: const RadialGradient(
              colors: [Color(0xFF63362B), Color(0xFF251C25), Color(0xFF0B2029)],
            ),
          ),
          child: Center(
            child: AtlasSprite(
              asset: GameEngine.bossWorldIndex(boss) == 0
                  ? 'guardian-bosses-sheet.png'
                  : 'guardian-bosses-worlds-sheet.png',
              index: boss.spriteIndex,
              columns: 3,
              rows: 2,
              width: 240,
              height: 178,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          boss.name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: MinePalette.cream,
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '${health.toStringAsFixed(0)} / ${boss.health.toStringAsFixed(0)} dayanıklılık',
          textAlign: TextAlign.center,
          style: const TextStyle(color: MinePalette.muted, fontSize: 11),
        ),
        const SizedBox(height: 7),
        LinearProgressIndicator(
          value: (health / boss.health).clamp(0, 1).toDouble(),
          minHeight: 12,
          backgroundColor: MinePalette.ink,
          color: MinePalette.danger,
          borderRadius: BorderRadius.circular(8),
        ),
        const SizedBox(height: 10),
        UpgradeRow(controller: controller, track: 'weapon'),
        ActionTile(
          icon: Icons.center_focus_strong_rounded,
          title: weakPointOpen ? 'Zayıf nokta açık' : 'Zayıf noktayı kilitle',
          description: weakPointOpen
              ? 'Kritik vuruş için ${weakPointUntil!.difference(DateTime.now()).inSeconds} saniyen var.'
              : 'Hedef işaretini dört saniyeliğine aç. Süre bitmeden saldırırsan üç kat hasar verirsin.',
          buttonLabel: weakPointOpen ? 'HEDEF AÇIK' : 'HEDEFLE',
          enabled: !weakPointOpen,
          onPressed: controller.focusBossWeakPoint,
          accent: MinePalette.danger,
        ),
        SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            onPressed: controller.attackBoss,
            icon: const Icon(Icons.flash_on_rounded),
            label: Text(
              'SALDIR • ${GameEngine.bossAttackDamage(state, critical: weakPointOpen).toStringAsFixed(1)} GÜÇ',
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Zafer ödülü: ${boss.reward} kasa + ${3 + boss.id} sondaj parçası + $chestRewardName',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: MinePalette.amber,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _questContents() {
    final state = controller.state;
    final dailyChallenges = state.dailyChallengeIds
        .map((id) => DailyChallengeCatalog.byId[id])
        .whereType<DailyChallengeDefinition>()
        .toList(growable: false);
    final remaining = QuestCatalog.all
        .where(
          (quest) =>
              !state.claimedQuestIds.contains(quest.id) &&
              controller.isQuestAvailable(quest),
        )
        .take(20)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionIntro(
          'GÖREV DEFTERİ',
          'Her gün üç hedef ve haftada bir kilometre taşı kasa kazandırır. Uzun vadeli 112 aşamalı görev hattı da burada.',
        ),
        _subheading('BUGÜN • ${state.dailyChallengeDate}'),
        for (final challenge in dailyChallenges)
          ActionTile(
            icon: Icons.task_alt_rounded,
            title: challenge.title,
            description:
                '${challenge.description} İlerleme: ${state.dailyChallengeProgress[challenge.id] ?? 0}/${challenge.target}. Ödül: ${challenge.rewardCoins} kasa.',
            buttonLabel: state.claimedDailyChallengeIds.contains(challenge.id)
                ? 'ALINDI'
                : (state.dailyChallengeProgress[challenge.id] ?? 0) >=
                      challenge.target
                ? 'ÖDÜLÜ AL'
                : 'SÜRÜYOR',
            enabled:
                !state.claimedDailyChallengeIds.contains(challenge.id) &&
                (state.dailyChallengeProgress[challenge.id] ?? 0) >=
                    challenge.target,
            onPressed: () => controller.claimDailyChallenge(challenge.id),
            accent: MinePalette.teal,
          ),
        ActionTile(
          icon: Icons.calendar_view_week_rounded,
          title: 'Haftalık kilometre taşı',
          description:
              '${state.weeklyChallengeProgress}/${DailyChallengeCatalog.weeklyTarget} günlük hedefi ödüllendir. Ödül: ${DailyChallengeCatalog.weeklyRewardCoins} kasa ve ${DailyChallengeCatalog.weeklyRewardCoreShards} çekirdek parçası.',
          buttonLabel: state.weeklyChallengeClaimed
              ? 'ALINDI'
              : state.weeklyChallengeProgress >=
                    DailyChallengeCatalog.weeklyTarget
              ? 'ÖDÜLÜ AL'
              : 'HAFTALIK',
          enabled:
              !state.weeklyChallengeClaimed &&
              state.weeklyChallengeProgress >=
                  DailyChallengeCatalog.weeklyTarget,
          onPressed: controller.claimWeeklyChallenge,
          accent: MinePalette.violet,
        ),
        const SizedBox(height: 8),
        _subheading('VARDİYA GÖREVLERİ'),
        if (controller.currentQuestReady)
          ActionTile(
            icon: Icons.workspace_premium_rounded,
            title: controller.currentQuest.title,
            description: controller.currentQuest.description,
            buttonLabel: '+${controller.currentQuest.reward}',
            onPressed: controller.claimCurrentQuest,
            accent: MinePalette.amber,
          )
        else
          _QuestProgressCard(controller: controller),
        const SizedBox(height: 8),
        _subheading('SONRAKİ HEDEFLER'),
        for (final quest in remaining)
          _QuestListRow(
            quest: quest,
            progress: state.progressFor(quest),
            claimed: state.claimedQuestIds.contains(quest.id),
          ),
      ],
    );
  }

  Widget _mineEventContents() {
    final state = controller.state;
    final event = MineEventCatalog.byId[state.activeMineEventId];
    if (event == null) {
      return const _EmptyHint('Şu anda kuyuda bekleyen bir maden olayı yok.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionIntro('OLAY DETAYI', event.description),
        ActionTile(
          icon: Icons.auto_awesome_rounded,
          title: event.title,
          description: event.rewardDescription,
          buttonLabel: 'ÖDÜLÜ AL',
          enabled: true,
          onPressed: controller.resolveMineEvent,
          accent: MinePalette.amber,
        ),
      ],
    );
  }

  Widget _achievementContents() {
    final state = controller.state;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionIntro(
          'MADEN BAŞARIMLARI',
          'Her rozet kasa ödülü ve kalıcı %0,5 kazı hızı verir. Etkiler birikerek tüm vardiyalara uygulanır.',
        ),
        _subheading(
          '${state.unlockedAchievements.length} / ${AchievementCatalog.all.length} ROZET AÇILDI',
        ),
        for (final achievement in AchievementCatalog.all)
          _AchievementRow(
            achievement: achievement,
            progress: _achievementProgress(achievement, state),
            unlocked: state.unlockedAchievements.contains(achievement.id),
          ),
      ],
    );
  }

  List<ResourceDefinition> _visibleInventory() {
    final state = controller.state;
    final minerals = ResourceCatalog.minerals.where((resource) {
      final firstDepth =
          MrMineLevelTable.firstDepthMetersByResource[resource.id] ??
          resource.minDepthMeters.toInt();
      return firstDepth <= state.deepestMeters + 1200 &&
          (state.amount(resource.id) > 0 || firstDepth == 0);
    });
    final carriedSpecials = ResourceCatalog.all.where(
      (resource) =>
          resource.kind != ResourceKind.mineral &&
          state.amount(resource.id) > 0,
    );
    return [...minerals, ...carriedSpecials].take(35).toList();
  }

  Widget _specialWorkerRosterSection(GameState state) {
    final unlocked = state.unlockedBuildings.contains('super_miners');
    final cost = GameEngine.specialWorkerCost(state);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _subheading('ÖZEL MADENCİLER • HURDA ${state.workerScrap}'),
        if (!unlocked)
          const _EmptyHint('Özel madenciler 10 km derinlikte keşfedilir.')
        else ...[
          ActionTile(
            icon: Icons.engineering_rounded,
            title:
                'Özel madenci işe al • ${state.specialWorkerRoster.length}/12',
            description: 'Sekiz farklı yetenekten biriyle kadroya katılır. Her beş dakikada başka kata geçebilir; elle atadığında sabit kalır.',
            buttonLabel: state.specialWorkerRoster.length >= 12
                ? 'KADRO DOLU'
                : '$cost KASA',
            enabled:
                state.specialWorkerRoster.length < 12 &&
                state.canAfford(cost.toDouble()),
            onPressed: controller.hireSpecialWorker,
            accent: MinePalette.violet,
          ),
          if (state.specialWorkerRoster.isEmpty)
            const _EmptyHint(
              'Kopya özel madencileri hurdaya çevirip seviye malzemesi kazanabilirsin.',
            ),
          for (final worker in state.specialWorkerRoster)
            _specialWorkerCard(worker, state),
        ],
      ],
    );
  }

  List<int> _workerFloors(GameState state, int world) {
    final entryDepth = GameState.worldEntryDepths[world];
    final lastDepth = world < 2
        ? math.min(
            state.deepestMeters,
            GameState.worldEntryDepths[world + 1] - 1,
          )
        : state.deepestMeters;
    final firstFloor = (entryDepth / 100000).floor();
    final lastFloor = math.max(firstFloor, (lastDepth / 100000).floor());
    return [for (var floor = firstFloor; floor <= lastFloor; floor++) floor];
  }

  Widget _specialWorkerCard(SpecialWorkerState worker, GameState state) {
    const worldNames = ['Dünya', 'Ay', 'Titan'];
    final ability = SpecialWorkerAbilityCatalog.byId[worker.abilityId]!;
    final isSeller = worker.abilityId == 'auto_seller';
    final sellableResources = ResourceCatalog.unlockedAt(state.deepestMeters)
        .where((resource) => resource.kind == ResourceKind.mineral)
        .toList(growable: false);
    final selectedResourceId =
        sellableResources.any(
          (resource) => resource.id == worker.selectedResourceId,
        )
        ? worker.selectedResourceId!
        : sellableResources.first.id;
    final openWorlds = [
      for (var world = 0; world < worldNames.length; world++)
        if (state.deepestMeters >= GameState.worldEntryDepths[world]) world,
    ];
    final selectedWorld = openWorlds.contains(worker.assignedWorld)
        ? worker.assignedWorld
        : openWorlds.first;
    final floors = _workerFloors(state, selectedWorld);
    final selectedFloor = floors.contains(worker.assignedFloor)
        ? worker.assignedFloor
        : floors.first;
    final upgradeCost = GameEngine.specialWorkerUpgradeCost(worker);
    final rarityColor = Color(worker.rarity.colorHex);
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF10252C),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: rarityColor.withValues(alpha: .5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _AnimatedPortraitSprite(
                asset: 'special-workers-atlas.png',
                index: SpecialWorkerAbilityCatalog.all.indexWhere(
                  (ability) => ability.id == worker.abilityId,
                ),
                width: 38,
                height: 42,
                haloColor: rarityColor,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${worker.name} • ${worker.rarity.name} • Lv ${worker.level}',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: rarityColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '×${worker.power.toStringAsFixed(1)}',
                style: const TextStyle(
                  color: MinePalette.amber,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              isSeller
                  ? '${ability.name} • Her saniye ${worker.rarity.sellerUnitsPerLevel * worker.level} adet seçilen madeni satar.'
                  : '${ability.name} • ${ability.description}',
              style: const TextStyle(color: MinePalette.muted, fontSize: 8),
            ),
          ),
          if (isSeller)
            DropdownButton<String>(
              isExpanded: true,
              value: selectedResourceId,
              underline: const SizedBox.shrink(),
              style: const TextStyle(color: MinePalette.cream, fontSize: 9),
              dropdownColor: MinePalette.panel,
              hint: const Text('Satılacak maden'),
              items: [
                for (final resource in sellableResources)
                  DropdownMenuItem(
                    value: resource.id,
                    child: Text(resource.name),
                  ),
              ],
              onChanged: (resourceId) {
                if (resourceId != null) {
                  controller.setSpecialWorkerResource(worker.id, resourceId);
                }
              },
            ),
          if (!isSeller)
            Row(
              children: [
                Expanded(
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: selectedWorld,
                    underline: const SizedBox.shrink(),
                    style: const TextStyle(
                      color: MinePalette.cream,
                      fontSize: 9,
                    ),
                    dropdownColor: MinePalette.panel,
                    items: [
                      for (final world in openWorlds)
                        DropdownMenuItem(
                          value: world,
                          child: Text(worldNames[world]),
                        ),
                    ],
                    onChanged: (world) {
                      if (world == null) return;
                      final targetFloors = _workerFloors(state, world);
                      controller.moveSpecialWorker(
                        worker.id,
                        world,
                        targetFloors.first,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: selectedFloor,
                    underline: const SizedBox.shrink(),
                    style: const TextStyle(
                      color: MinePalette.cream,
                      fontSize: 9,
                    ),
                    dropdownColor: MinePalette.panel,
                    items: [
                      for (final floor in floors)
                        DropdownMenuItem(
                          value: floor,
                          child: Text('$floor. kat'),
                        ),
                    ],
                    onChanged: (floor) {
                      if (floor != null) {
                        controller.moveSpecialWorker(
                          worker.id,
                          selectedWorld,
                          floor,
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          if (!isSeller)
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '5 dk’da kat değiştir',
                          style: TextStyle(
                            color: MinePalette.muted,
                            fontSize: 8,
                          ),
                        ),
                      ),
                      Switch(
                        value: worker.autoMove,
                        onChanged: (value) => controller
                            .setSpecialWorkerAutoMove(worker.id, value),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        activeThumbColor: MinePalette.teal,
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: upgradeCost > 0 && state.workerScrap >= upgradeCost
                      ? () => controller.upgradeSpecialWorker(worker.id)
                      : null,
                  icon: const Icon(Icons.arrow_upward_rounded, size: 13),
                  label: Text(
                    upgradeCost == 0 ? 'MAX' : 'Lv +1 • $upgradeCost',
                    style: const TextStyle(fontSize: 8),
                  ),
                ),
                IconButton(
                  tooltip: 'Hurdaya ayır: +${worker.rarity.scrapValue} hurda',
                  onPressed: () => controller.dismantleSpecialWorker(worker.id),
                  icon: const Icon(
                    Icons.delete_sweep_rounded,
                    color: MinePalette.muted,
                    size: 17,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _specialistAction(
    String role,
    String name,
    String description,
    IconData icon,
  ) {
    final state = controller.state;
    final level = state.specialists[role] ?? 0;
    final cost = GameEngine.specialistCost(state, role);
    return ActionTile(
      icon: icon,
      title: '$name • $level / 3',
      description: description,
      buttonLabel: level >= 3 ? 'TAM KADRO' : '$cost KASA',
      enabled: level < 3 && state.canAfford(cost.toDouble()),
      onPressed: () => controller.hireSpecialist(role),
      accent: MinePalette.cyan,
    );
  }

  void _openNested(BuildContext context, String id) => showDialog<void>(
    context: context,
    builder: (_) => BuildingDialog(controller: controller, buildingId: id),
  );

  void _confirmPrestige(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: MinePalette.panel,
        title: const Text('Yeni çekirdek döngüsü başlatılsın mı?'),
        content: Text(
          'Mevcut derinlik, kasa, ambar, sondaj parçası seviyeleri, vardiya yöneticisi ve reaktör ilerlemesi sıfırlanacak. ${math.max(1, (controller.state.deepestMeters / 500000).floor())} kalıcı çekirdek parçası korunacak.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('VAZGEÇ'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              controller.prestige();
            },
            child: const Text('YENİDEN DOĞ'),
          ),
        ],
      ),
    );
  }

  Widget _workerAssignmentsSection(GameState state) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: const Color(0xFF0B222C),
      border: Border.all(color: MinePalette.border),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _subheading('EKİP GÖREV DAĞILIMI'),
        Text(
          '${state.diggingWorkers} kazıcı • ${state.transportWorkers} taşıyıcı • ${state.scannerWorkers} tarayıcı • ${state.sortingWorkers} ayıklayıcı',
          style: const TextStyle(color: MinePalette.muted, fontSize: 9),
        ),
        const SizedBox(height: 3),
        _workerRoleRow(
          state,
          role: 'digging',
          name: 'Kazı',
          benefit: 'Düşük öncelikliyse yeni atamada bu ekipten kişi alınır.',
          icon: Icons.construction_rounded,
        ),
        _workerRoleRow(
          state,
          role: 'transport',
          name: 'Taşıma',
          benefit: 'Her çalışan ambar kapasitesini %4 artırır.',
          icon: Icons.local_shipping_rounded,
        ),
        _workerRoleRow(
          state,
          role: 'scanner',
          name: 'Tarama',
          benefit: 'Üretim olurken sandık bulma olasılığını artırır.',
          icon: Icons.radar_rounded,
        ),
        _workerRoleRow(
          state,
          role: 'sorting',
          name: 'Ayıklama',
          benefit: 'Her çalışan kaynak satışına %2 ekler.',
          icon: Icons.filter_alt_rounded,
        ),
        const Text(
          'Öncelik 1 en düşük, 4 en yüksek. Yeni görev açılırken düşük öncelikli ekipten kişi alınır; yeni işe alınanlar kazıya katılır.',
          style: TextStyle(color: MinePalette.muted, fontSize: 8, height: 1.3),
        ),
      ],
    ),
  );

  Widget _workerRoleRow(
    GameState state, {
    required String role,
    required String name,
    required String benefit,
    required IconData icon,
  }) {
    final count = role == 'digging'
        ? state.diggingWorkers
        : state.workerAssignments[role] ?? 0;
    final unlocked = state.workerRoleUnlocked(role);
    final priority = state.workerRolePriority.indexOf(role) + 1;
    return Row(
      children: [
        Icon(icon, size: 16, color: MinePalette.cyan),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: MinePalette.cream,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                unlocked ? benefit : 'Danışman göreviyle açılacak. $benefit',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: MinePalette.muted, fontSize: 8),
              ),
            ],
          ),
        ),
        if (role != 'digging' && unlocked)
          IconButton(
            tooltip: 'Bir çalışanı kazıya döndür',
            constraints: const BoxConstraints.tightFor(width: 48, height: 48),
            onPressed: count > 0
                ? () => controller.assignWorkerRole(role, -1)
                : null,
            icon: const Icon(Icons.remove_circle_outline_rounded),
          )
        else
          const SizedBox(width: 48),
        SizedBox(
          width: 20,
          child: Text(
            '$count',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: MinePalette.amber,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (role != 'digging' && unlocked)
          IconButton(
            tooltip: 'Bir kazıcıyı bu göreve ata',
            constraints: const BoxConstraints.tightFor(width: 48, height: 48),
            onPressed:
                state.workerRolePriority
                    .take(priority - 1)
                    .any(
                      (candidate) => candidate == 'digging'
                          ? state.diggingWorkers > 0
                          : (state.workerAssignments[candidate] ?? 0) > 0,
                    )
                ? () => controller.assignWorkerRole(role, 1)
                : null,
            icon: const Icon(Icons.add_circle_outline_rounded),
          )
        else if (role != 'digging')
          Tooltip(
            message: 'Danışman göreviyle açılacak',
            child: const SizedBox(
              width: 48,
              height: 48,
              child: Icon(Icons.lock_rounded, color: MinePalette.muted),
            ),
          )
        else
          const SizedBox(width: 48),
        if (unlocked)
          PopupMenuButton<int>(
            tooltip: 'Görev önceliğini değiştir',
            onSelected: (position) =>
                controller.setWorkerRolePriority(role, position - 1),
            itemBuilder: (context) => [
              for (var position = 1; position <= 4; position++)
                PopupMenuItem(
                  value: position,
                  child: Text(
                    'Öncelik $position${position == 1
                        ? ' • düşük'
                        : position == 4
                        ? ' • yüksek'
                        : ''}',
                  ),
                ),
            ],
            child: Container(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF102F3B),
                border: Border.all(color: MinePalette.border),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$priority',
                style: const TextStyle(
                  color: MinePalette.amber,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          )
        else
          const SizedBox(width: 48, height: 48),
      ],
    );
  }

  Widget _gemForgeSection(GameState state) {
    if (!state.unlockedBuildings.contains('gem_forge')) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _subheading('MÜCEVHER OCAĞI'),
          const _EmptyHint(
            'Mücevher Ocağı 325 km derinlikte açılır. Beş tarif, 100 puanlık paylaştırılabilir üretim iş yükü kullanır.',
          ),
        ],
      );
    }
    final totalWorkload = state.gemWorkload.values.fold<int>(
      0,
      (sum, value) => sum + value,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _subheading('MÜCEVHER OCAĞI'),
        _sectionIntro(
          'İŞ YÜKÜ $totalWorkload / 100',
          'Her saniye ayrılan iş yükü üretim zamanından düşer. İlerleme kaydedilir ve uygulama kapalıyken sürer.',
        ),
        for (final gem in GemCatalog.all)
          Container(
            margin: const EdgeInsets.only(bottom: 7),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0B222C),
              border: Border.all(color: MinePalette.border),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.diamond_rounded,
                      color: Color(gem.colorHex),
                      size: 17,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        '${gem.name} • ${state.gems[gem.id] ?? 0}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: (state.gems[gem.id] ?? 0) > 0
                          ? () => controller.toggleGemEquipment(gem.id)
                          : null,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        minimumSize: const Size(0, 40),
                        textStyle: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      child: Text(
                        state.equippedGems.contains(gem.id)
                            ? 'YUVADAN ÇIKAR'
                            : 'KUŞAN',
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'İŞ YÜKÜ',
                        style: TextStyle(
                          color: MinePalette.muted,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'İş yükünü %5 azalt',
                      constraints: const BoxConstraints.tightFor(
                        width: 48,
                        height: 48,
                      ),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => controller.adjustGemWorkload(gem.id, -5),
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                    ),
                    Text(
                      '${state.gemWorkload[gem.id] ?? 0}%',
                      style: const TextStyle(
                        color: MinePalette.cyan,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    IconButton(
                      tooltip: 'İş yükünü %5 artır',
                      constraints: const BoxConstraints.tightFor(
                        width: 48,
                        height: 48,
                      ),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => controller.adjustGemWorkload(gem.id, 5),
                      icon: const Icon(Icons.add_circle_outline_rounded),
                    ),
                  ],
                ),
                Text(
                  'Tarif: ${gem.recipe.entries.map((entry) => '${entry.value} ${ResourceCatalog.byId[entry.key]?.name ?? entry.key}').join(' + ')}',
                  style: const TextStyle(color: MinePalette.muted, fontSize: 9),
                ),
                Text(
                  gem.bonus,
                  style: TextStyle(
                    color: Color(gem.colorHex),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                ActionTile(
                  icon: Icons.local_fire_department_rounded,
                  title: state.gemCraftRemainingSeconds.containsKey(gem.id)
                      ? 'Mücevher dövülüyor'
                      : 'Ocağa iş ver',
                  description:
                      'Temel süre ${gem.craftSeconds} sn • bu tarif için ayırdığın iş yükü %${state.gemWorkload[gem.id] ?? 0}.',
                  buttonLabel:
                      state.gemCraftRemainingSeconds.containsKey(gem.id)
                      ? '${_duration(state.gemCraftRemainingSeconds[gem.id]!.ceil())} KALDI'
                      : 'ÜRET',
                  enabled:
                      !state.gemCraftRemainingSeconds.containsKey(gem.id) &&
                      (state.gemWorkload[gem.id] ?? 0) > 0 &&
                      gem.recipe.entries.every(
                        (entry) =>
                            state.amount(entry.key) -
                                state.reserve(entry.key) >=
                            entry.value,
                      ),
                  onPressed: () => controller.craftGem(gem.id),
                  accent: Color(gem.colorHex),
                ),
              ],
            ),
          ),
      ],
    );
  }

  bool _canSellResources(GameState state) =>
      state.inventory.entries.any((entry) {
        final resource = ResourceCatalog.byId[entry.key];
        return resource != null &&
            (resource.kind == ResourceKind.mineral ||
                resource.kind == ResourceKind.isotope) &&
            entry.value > state.reserve(entry.key) &&
            !state.lockedResources.contains(entry.key);
      });

  Widget _worldCard(int index, String title, String subtitle, IconData icon) {
    final state = controller.state;
    final unlocked =
        index == 0 || state.deepestMeters >= GameState.worldEntryDepths[index];
    final current = state.currentWorldIndex == index;
    final depth = index == state.currentWorldIndex
        ? state.depthMeters
        : state.worldDepths[index.toString()] ??
              GameState.worldEntryDepths[index];
    return Semantics(
      button: unlocked,
      enabled: unlocked && !current,
      label:
          '$title, ${depth.floor()} metre, ${current
              ? 'aktif'
              : unlocked
              ? 'geçiş yapılabilir'
              : 'kilitli'}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: unlocked && !current
              ? () => controller.switchWorld(index)
              : null,
          borderRadius: BorderRadius.circular(7),
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
            decoration: BoxDecoration(
              color: current
                  ? const Color(0xFF164452)
                  : const Color(0xFF102D38),
              border: Border.all(
                color: current || unlocked
                    ? MinePalette.teal
                    : MinePalette.border,
              ),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: unlocked ? MinePalette.teal : MinePalette.muted,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '$subtitle • ${depth.floor()} m',
                        style: const TextStyle(
                          color: MinePalette.muted,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  current
                      ? 'AKTİF'
                      : unlocked
                      ? 'GEÇ'
                      : 'KİLİTLİ',
                  style: TextStyle(
                    color: unlocked ? MinePalette.teal : MinePalette.muted,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 5),
                Icon(
                  current
                      ? Icons.check_circle_rounded
                      : unlocked
                      ? Icons.arrow_forward_rounded
                      : Icons.lock_rounded,
                  color: unlocked ? MinePalette.teal : MinePalette.muted,
                  size: 15,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({required this.data});

  final (String, String, int, IconData) data;

  @override
  Widget build(BuildContext context) => Container(
    height: 78,
    padding: const EdgeInsets.symmetric(horizontal: 15),
    decoration: const BoxDecoration(
      gradient: LinearGradient(colors: [Color(0xFF194554), Color(0xFF0D2732)]),
      border: Border(bottom: BorderSide(color: MinePalette.border)),
    ),
    child: Row(
      children: [
        if (data.$3 >= 0)
          AtlasSprite(
            asset: 'surface-buildings-sheet.png',
            index: data.$3,
            columns: 3,
            rows: 2,
            width: 74,
            height: 65,
          ),
        if (data.$3 < 0)
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFF08202B),
              border: Border.all(color: MinePalette.border),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.$4, color: MinePalette.amber, size: 30),
          ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.$1,
                style: const TextStyle(
                  color: MinePalette.cream,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .5,
                ),
              ),
              Text(
                data.$2,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: MinePalette.muted, fontSize: 10),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Pencereyi kapat',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    ),
  );
}

class _InventoryRow extends StatelessWidget {
  const _InventoryRow({required this.controller, required this.resource});

  final GameController controller;
  final ResourceDefinition resource;

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final amount = state.amount(resource.id);
    final reserve = state.reserve(resource.id);
    final isTradable =
        resource.kind == ResourceKind.mineral ||
        resource.kind == ResourceKind.isotope;
    final isLocked = state.lockedResources.contains(resource.id);
    final canSell = amount > reserve && isTradable && !isLocked;
    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0B222C),
        border: Border.all(color: const Color(0xFF294650)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          AtlasSprite(
            asset: 'resources-treasure-sheet.png',
            index: resource.iconIndex,
            columns: 4,
            rows: 4,
            width: 39,
            height: 39,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              resource.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: MinePalette.cream,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            '×$amount',
            style: const TextStyle(
              color: MinePalette.cyan,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (isTradable && amount > 0) ...[
            IconButton(
              tooltip: reserve > 0
                  ? 'Rezervi kaldır'
                  : 'En çok 10 adet rezerve et',
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(width: 40, height: 40),
              onPressed: () => controller.toggleReserve(resource.id),
              icon: Icon(
                reserve > 0
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                color: reserve > 0 ? MinePalette.amber : MinePalette.muted,
                size: 18,
              ),
            ),
            IconButton(
              tooltip: isLocked
                  ? 'Kaynak kilidini aç'
                  : 'Kaynağı satıştan koru',
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(width: 40, height: 40),
              onPressed: () => controller.toggleResourceLock(resource.id),
              icon: Icon(
                isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                color: isLocked ? MinePalette.amber : MinePalette.muted,
                size: 17,
              ),
            ),
            SizedBox(
              width: 48,
              height: 34,
              child: FilledButton(
                onPressed: canSell ? () => controller.sell(resource.id) : null,
                style: FilledButton.styleFrom(padding: EdgeInsets.zero),
                child: Text(
                  '+${resource.baseValue}',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ] else
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                'DEĞERLİ',
                style: TextStyle(
                  color: MinePalette.muted,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RelicRow extends StatelessWidget {
  const _RelicRow({
    required this.name,
    required this.id,
    required this.level,
    required this.equipped,
    required this.duplicateCount,
    required this.upgradeCost,
    required this.onToggle,
    required this.onDismantle,
    required this.onUpgrade,
  });

  final String name;
  final String id;
  final int level;
  final bool equipped;
  final int duplicateCount;
  final int upgradeCost;
  final VoidCallback onToggle;
  final VoidCallback onDismantle;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 5),
    decoration: BoxDecoration(
      color: const Color(0xFF102D38),
      border: Border.all(
        color: equipped ? MinePalette.amber : MinePalette.border,
      ),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Padding(
      padding: const EdgeInsets.all(7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AtlasSprite(
            asset: 'resources-treasure-sheet.png',
            index: 14,
            columns: 4,
            rows: 4,
            width: 38,
            height: 38,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '$name • Lv $level/5',
                  style: const TextStyle(
                    color: MinePalette.cream,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Pasif kazanç: ${_relicEffect(id, level)}',
                  style: const TextStyle(color: MinePalette.muted, fontSize: 9),
                ),
                const SizedBox(height: 5),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 3,
                  runSpacing: 0,
                  children: [
                    if (duplicateCount > 0)
                      TextButton.icon(
                        onPressed: onDismantle,
                        icon: const Icon(Icons.recycling_rounded, size: 14),
                        label: Text('KOPYA $duplicateCount → +1 HURDA'),
                      ),
                    TextButton(
                      onPressed: onToggle,
                      child: Text(equipped ? 'ÇIKAR' : 'KUŞAN'),
                    ),
                    TextButton(
                      onPressed: upgradeCost > 0 ? onUpgrade : null,
                      child: Text(
                        upgradeCost == 0 ? 'MAKS.' : 'GELİŞTİR • $upgradeCost',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _QuestProgressCard extends StatelessWidget {
  const _QuestProgressCard({required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final quest = controller.currentQuest;
    final progress = controller.currentQuestProgress;
    final ratio = (progress / quest.target).clamp(0, 1).toDouble();
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFF102E3A),
        border: Border.all(color: MinePalette.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            quest.title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
          ),
          const SizedBox(height: 5),
          Text(
            quest.description,
            style: const TextStyle(color: MinePalette.muted, fontSize: 10),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: MinePalette.ink,
            color: MinePalette.teal,
          ),
          const SizedBox(height: 5),
          Text(
            '$progress / ${quest.target} • ödül ${quest.reward} kasa',
            style: const TextStyle(
              color: MinePalette.amber,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestListRow extends StatelessWidget {
  const _QuestListRow({
    required this.quest,
    required this.progress,
    required this.claimed,
  });

  final QuestDefinition quest;
  final int progress;
  final bool claimed;

  @override
  Widget build(BuildContext context) {
    final ratio = (progress / quest.target).clamp(0, 1).toDouble();
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF0B222C),
        border: Border.all(color: MinePalette.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(
            claimed
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: claimed ? MinePalette.teal : MinePalette.muted,
            size: 17,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quest.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: ratio,
                  minHeight: 5,
                  backgroundColor: MinePalette.ink,
                  color: MinePalette.teal,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '+${quest.reward}',
            style: const TextStyle(
              color: MinePalette.amber,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementRow extends StatelessWidget {
  const _AchievementRow({
    required this.achievement,
    required this.progress,
    required this.unlocked,
  });

  final AchievementDefinition achievement;
  final int progress;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final ratio = (progress / achievement.target).clamp(0, 1).toDouble();
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFF0B222C),
        border: Border.all(
          color: unlocked ? MinePalette.amber : MinePalette.border,
        ),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        children: [
          Icon(
            unlocked ? Icons.emoji_events_rounded : Icons.lock_outline_rounded,
            color: unlocked ? MinePalette.amber : MinePalette.muted,
            size: 23,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: const TextStyle(
                    color: MinePalette.cream,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  achievement.description,
                  style: const TextStyle(color: MinePalette.muted, fontSize: 9),
                ),
                const SizedBox(height: 5),
                LinearProgressIndicator(
                  value: ratio,
                  minHeight: 5,
                  backgroundColor: MinePalette.ink,
                  color: unlocked ? MinePalette.amber : MinePalette.teal,
                ),
              ],
            ),
          ),
          const SizedBox(width: 9),
          Text(
            unlocked ? '✓ +${achievement.reward}' : '+${achievement.reward}',
            style: TextStyle(
              color: unlocked ? MinePalette.amber : MinePalette.muted,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: const Color(0xFF0B212B),
      border: Border.all(color: MinePalette.border),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.info_outline_rounded,
          color: MinePalette.cyan,
          size: 17,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: MinePalette.muted,
              fontSize: 10,
              height: 1.3,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _sectionIntro(String title, String description) => Container(
  margin: const EdgeInsets.only(bottom: 11),
  padding: const EdgeInsets.all(10),
  decoration: BoxDecoration(
    color: const Color(0xFF102D38),
    border: Border.all(color: MinePalette.border),
    borderRadius: BorderRadius.circular(8),
  ),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Icon(
        Icons.lightbulb_outline_rounded,
        color: MinePalette.amber,
        size: 19,
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: MinePalette.cream,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: .8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(
                color: MinePalette.muted,
                fontSize: 10,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    ],
  ),
);

Widget _meter(String label, double value, String trailing) => Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: MinePalette.cream,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          trailing,
          style: const TextStyle(
            color: MinePalette.muted,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
    const SizedBox(height: 4),
    LinearProgressIndicator(
      value: value.clamp(0, 1).toDouble(),
      minHeight: 8,
      backgroundColor: const Color(0xFF06161D),
      color: value > .75 ? MinePalette.danger : MinePalette.teal,
      borderRadius: BorderRadius.circular(4),
    ),
  ],
);

Widget _subheading(String label) => Padding(
  padding: const EdgeInsets.only(top: 5, bottom: 3),
  child: Text(
    label,
    style: const TextStyle(
      color: MinePalette.amber,
      fontSize: 10,
      fontWeight: FontWeight.w900,
      letterSpacing: .8,
    ),
  ),
);

Widget _statTile(String label, String value) => Container(
  margin: const EdgeInsets.only(bottom: 6),
  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
  decoration: BoxDecoration(
    color: const Color(0xFF0B222C),
    border: Border.all(color: MinePalette.border),
    borderRadius: BorderRadius.circular(7),
  ),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        flex: 2,
        child: Text(
          label,
          style: const TextStyle(color: MinePalette.muted, fontSize: 10),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        flex: 3,
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: const TextStyle(
            color: MinePalette.cream,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    ],
  ),
);

Widget _detailTile(String label, String value) => Container(
  margin: const EdgeInsets.only(bottom: 6),
  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
  decoration: BoxDecoration(
    color: const Color(0xFF0B222C),
    border: Border.all(color: MinePalette.border),
    borderRadius: BorderRadius.circular(7),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: MinePalette.muted,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        value,
        softWrap: true,
        style: const TextStyle(
          color: MinePalette.cream,
          fontSize: 10,
          height: 1.35,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  ),
);

(String, String, int, IconData) _buildingData(String id) => switch (id) {
  'workshop' => (
    'ATÖLYE',
    'İşçi ekibi, makine yükseltmeleri ve kuyu asansörü',
    0,
    Icons.elevator_rounded,
  ),
  'warehouse' => (
    'AMBAR',
    'Kargo, rezerv ve maden satışları',
    2,
    Icons.inventory_2_rounded,
  ),
  'trade' => (
    'TİCARET',
    'Tüccar, sandık ve nadir kaynaklar',
    3,
    Icons.storefront_rounded,
  ),
  'research' => (
    'ARAŞTIRMA',
    'Bilim, kalıntı ve katman rezonansı',
    4,
    Icons.biotech_rounded,
  ),
  'reactor' => (
    'ÇEKİRDEK REAKTÖRÜ',
    'Isı dengesi, enerji ve izotop üretimi',
    -1,
    Icons.bolt_rounded,
  ),
  'buff_lab' => (
    'BUFF LABORATUVARI',
    'Sürekli etkiler ve reaktör enerjisi',
    -1,
    Icons.speed_rounded,
  ),
  'armory' => (
    'YERALTI CEPHANELİĞİ',
    'Muhafız savaşları ve sondaj parçaları',
    -1,
    Icons.shield_rounded,
  ),
  'expedition' => (
    'SEFER GARAJI',
    'Dron keşifleri, mağaralar ve dünyalar',
    5,
    Icons.explore_rounded,
  ),
  'quests' => (
    'GÖREV DEFTERİ',
    'Günlük, haftalık ve derinlik hedefleri',
    -1,
    Icons.assignment_rounded,
  ),
  'mine_event' => (
    'KUYU OLAYI',
    'Maden fırsatı ve keşif ödülü',
    -1,
    Icons.auto_awesome_rounded,
  ),
  'achievements' => (
    'BAŞARIMLAR',
    'Vardiyanın kalıcı kilometre taşları',
    -1,
    Icons.emoji_events_rounded,
  ),
  'boss' => (
    'MUHAFIZ ARENASI',
    'Derinlik kapısı ve boss karşılaşmaları',
    -1,
    Icons.shield_moon_rounded,
  ),
  _ => (
    'ARAŞTIRMA',
    'Keşif ve geliştirme sistemleri',
    4,
    Icons.biotech_rounded,
  ),
};

String _relicEffect(String id, int level) {
  final levelScale = level;
  return switch (id) {
    'relic_1' => 'Kazı hızı +%${12 * levelScale}',
    'relic_2' => 'Cevher satış değeri +%${15 * levelScale}',
    'relic_3' => 'Mağara cevheri +%${25 * levelScale}',
    'relic_4' => 'Kargo kapasitesi +%${5 * levelScale}',
    'relic_5' =>
      'İzotop bulma şansı +%${(levelScale * 1.2).toStringAsFixed(1)}',
    'relic_6' => 'Basınç artışı -%${40 + levelScale * 10}',
    'relic_7' => 'Kazı hızı +%${5 * levelScale}, rezonans +$levelScale dk',
    'relic_8' => 'Görev ödülü +%${10 * levelScale}',
    'relic_9' => 'Sandık bulma şansı +%${levelScale * 0.12}',
    'relic_10' => 'Muhafız hasarı +%${20 + (levelScale - 1) * 10}',
    'relic_11' => 'Reaktör güç darbesi +${30 * levelScale} saniye',
    'relic_12' => 'Çekirdek sıfırlamasında +$levelScale parça',
    'relic_150' =>
      'İzotop T1->T2 bozunma şansı +%${switch (levelScale) {
        1 => '1',
        2 => '1,5',
        _ => '2',
      }} (Azami %10)',
    'relic_151' => 'İzotop T1->T2 bozunma şansı +%1,5 (Azami %10)',
    'relic_152' => 'İzotop T1->T2 bozunma şansı +%2 (Azami %10)',
    'relic_153' => switch (levelScale) {
      1 => 'Gözle görülür bir etkisi yok (Tüy Parçası)',
      2 => 'İzotop T2->T3 bozunma şansı +%0,5 (Azami %5)',
      _ => 'İzotop T2->T3 bozunma şansı +%1 (Azami %5)',
    },
    'relic_154' => 'İzotop T2->T3 bozunma şansı +%0,5 (Azami %5)',
    'relic_155' => 'İzotop T2->T3 bozunma şansı +%1 (Azami %5)',
    _ => 'Bilinmeyen kalıcı etki',
  };
}

String _relicDisplayName(String id, int level, String fallback) => switch (id) {
  'relic_150' => switch (level) {
    1 => 'Atom Kargısı',
    2 => 'Atom Kargısı+',
    _ => 'Atom Kargısı++',
  },
  'relic_153' => switch (level) {
    1 => 'Tüy Parçası',
    2 => 'Nükleer Kargı+',
    _ => 'Nükleer Kargı++',
  },
  _ => fallback,
};

int _achievementProgress(AchievementDefinition achievement, GameState state) =>
    switch (achievement.kind) {
      'mine' => state.totalMined,
      'depth' || 'world' => state.deepestMeters.floor(),
      'crew' => state.crewCount,
      'sale' =>
        state.totalSold.exponent >= 9
            ? 1000000000
            : state.totalSold.toDouble().clamp(0, 1000000000).floor(),
      'chest' => state.chestsOpened,
      'cave' => state.cavesCompleted,
      'relic' => state.relicsFound,
      'boss' => state.bossesDefeated,
      'resonance' => state.resonanceChains,
      'prestige' => state.prestigeCount,
      _ => 0,
    };

String _duration(int seconds) {
  final safe = math.max(0, seconds);
  return '${(safe ~/ 60).toString().padLeft(2, '0')}:${(safe % 60).toString().padLeft(2, '0')}';
}

class _AnimatedDroneSprite extends StatefulWidget {
  const _AnimatedDroneSprite({required this.droneId, required this.damaged});

  final String droneId;
  final bool damaged;

  @override
  State<_AnimatedDroneSprite> createState() => _AnimatedDroneSpriteState();
}

class _AnimatedDroneSpriteState extends State<_AnimatedDroneSprite>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseIndex = switch (widget.droneId) {
      'flying' => 1,
      'magnet' => 2,
      'healer' => 3,
      _ => 0,
    };
    final index = baseIndex + (widget.damaged ? 4 : 0);
    return SizedBox(
      width: 42,
      height: 34,
      child: AnimatedBuilder(
        animation: _floatController,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, -2 * math.sin(_floatController.value * math.pi)),
          child: child,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: AtlasSprite(
            key: ValueKey(index),
            asset: 'support-drones-atlas.png',
            index: index,
            columns: 4,
            rows: 2,
            width: 42,
            height: 34,
          ),
        ),
      ),
    );
  }
}

class _AnimatedPortraitSprite extends StatefulWidget {
  const _AnimatedPortraitSprite({
    required this.asset,
    required this.index,
    required this.width,
    required this.height,
    required this.haloColor,
    this.dimmed = false,
    this.badge,
  });

  final String asset;
  final int index;
  final double width;
  final double height;
  final Color haloColor;
  final bool dimmed;
  final IconData? badge;

  @override
  State<_AnimatedPortraitSprite> createState() =>
      _AnimatedPortraitSpriteState();
}

class _AnimatedPortraitSpriteState extends State<_AnimatedPortraitSprite>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock;

  @override
  void initState() {
    super.initState();
    _clock = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _clock,
    builder: (context, _) {
      final bob = math.sin(_clock.value * math.pi) * 1.2;
      final glow = .08 + math.sin(_clock.value * math.pi) * .07;
      Widget sprite = AtlasSprite(
        asset: widget.asset,
        index: widget.index,
        columns: 4,
        rows: 2,
        width: widget.width,
        height: widget.height,
      );
      if (widget.dimmed) {
        sprite = ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            .35,
            .45,
            .2,
            0,
            0,
            .35,
            .45,
            .2,
            0,
            0,
            .35,
            .45,
            .2,
            0,
            0,
            0,
            0,
            0,
            .76,
            0,
          ]),
          child: sprite,
        );
      }
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: widget.haloColor.withValues(alpha: glow),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: widget.haloColor.withValues(alpha: glow * .5),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: Transform.translate(
                offset: Offset(0, -bob),
                child: IgnorePointer(child: sprite),
              ),
            ),
            if (widget.badge != null)
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 15,
                  height: 15,
                  decoration: const BoxDecoration(
                    color: MinePalette.danger,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(widget.badge, color: MinePalette.ink, size: 10),
                ),
              ),
          ],
        ),
      );
    },
  );
}
