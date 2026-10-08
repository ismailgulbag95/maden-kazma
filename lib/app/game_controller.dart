import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../data/save_store.dart';
import '../domain/models/game_state.dart';
import '../domain/models/mr_mine_big_number.dart';
import '../domain/models/quest_definition.dart';
import '../domain/models/advisor_guide.dart';
import '../domain/models/resource_definition.dart';
import '../domain/models/gem_definition.dart';
import '../domain/models/cave_route_definition.dart';
import '../domain/models/cave_exploration_definition.dart';
import '../domain/models/daily_challenge_definition.dart';
import '../domain/models/mine_event_definition.dart';
import '../domain/models/scientist_definition.dart';
import '../domain/models/reactor_definition.dart';
import '../domain/models/drill_assembly_definition.dart';
import '../domain/models/buff_lab_definition.dart';
import '../domain/simulation/game_engine.dart';
import '../services/sound_service.dart';

String _saleCashLabel(Object value) {
  final big = value is MrMineBigNumber
      ? value
      : (value is num ? MrMineBigNumber.fromNum(value) : MrMineBigNumber.zero);
  if (big.exponent >= 18) {
    if (big.exponent >= 21) {
      return big.toScientificString();
    }
    final d = big.toDouble();
    return '${(d / 1e18).toStringAsFixed(2)}Qi';
  }
  if (big.exponent >= 15) {
    return '${(big.toDouble() / 1e15).toStringAsFixed(2)}Qa';
  }
  if (big.exponent >= 12) {
    return '${(big.toDouble() / 1e12).toStringAsFixed(2)}T';
  }
  if (big.exponent >= 9) return '${(big.toDouble() / 1e9).toStringAsFixed(2)}B';
  if (big.exponent >= 6) return '${(big.toDouble() / 1e6).toStringAsFixed(2)}M';
  if (big.exponent >= 3) return '${(big.toDouble() / 1e3).toStringAsFixed(2)}K';
  final d = big.toDouble();
  return d.toStringAsFixed(d.truncateToDouble() == d ? 0 : 2);
}

class GameController extends ChangeNotifier {
  GameController({SaveStore? saveStore})
    : _saveStore = saveStore ?? SaveStoreFactory.create() {
    GameEngine.prepareChallengeWindows(state, DateTime.now());
    GameEngine.ensureOpenMineDeposits(state);
  }

  final SaveStore _saveStore;
  final List<String> _notices = [];
  GameState _state = GameState.newGame();
  GameState get state => _state;
  set state(GameState value) {
    _state = value;
    GameEngine.ensureOpenMineDeposits(_state);
  }

  Timer? _ticker;
  DateTime _lastTickAt = DateTime.now();
  Duration _tickRemainder = Duration.zero;
  bool isReady = false;
  String? initializationError;
  bool isSaving = false;
  String? saveError;
  int offlineSeconds = 0;
  double offlineDepthGained = 0;
  int offlineOreGained = 0;
  int _tickCount = 0;
  bool _lastCargoFull = false;
  bool _saveQueued = false;
  bool _disposed = false;

  QuestDefinition get currentQuest => QuestCatalog.all.firstWhere(
    (quest) =>
        !state.claimedQuestIds.contains(quest.id) && _isQuestAvailable(quest),
    orElse: () => QuestCatalog.endgameGoal,
  );

  int get currentQuestProgress =>
      state.progressFor(currentQuest).clamp(0, currentQuest.target).toInt();

  int get readyQuestCount =>
      QuestCatalog.all
          .where(
            (quest) =>
                !state.claimedQuestIds.contains(quest.id) &&
                _isQuestAvailable(quest) &&
                state.progressFor(quest) >= quest.target,
          )
          .length +
      (state.claimedQuestIds.containsAll(
                QuestCatalog.all.map((quest) => quest.id),
              ) &&
              state.progressFor(QuestCatalog.endgameGoal) >=
                  QuestCatalog.endgameGoal.target &&
              !state.claimedQuestIds.contains(QuestCatalog.endgameGoal.id)
          ? 1
          : 0);

  bool get currentQuestReady =>
      currentQuestProgress >= currentQuest.target &&
      !state.claimedQuestIds.contains(currentQuest.id);

  bool isQuestAvailable(QuestDefinition quest) => _isQuestAvailable(quest);

  bool _isQuestAvailable(QuestDefinition quest) {
    if (quest.id < 5) return true;
    final starterTutorialClaimed = const [
      0,
      1,
      2,
      3,
      4,
    ].every(state.claimedQuestIds.contains);
    if (!state.initialTutorialComplete && !starterTutorialClaimed) return false;
    return switch (quest.kind) {
      QuestKind.chest => state.totalChestsFound > 0 || state.chestsOpened > 0,
      QuestKind.cave => state.canOpenBuilding('expedition'),
      QuestKind.relic => state.canOpenBuilding('research'),
      QuestKind.boss => state.canOpenBuilding('boss'),
      QuestKind.resonance => state.canOpenBuilding('research'),
      _ => true,
    };
  }

  List<String> takeNotices() {
    final result = List<String>.of(_notices);
    _notices.clear();
    return state.notificationsEnabled ? result : const [];
  }

  Future<void> initialize() async {
    // Audio is optional; do not make local storage or the audio browser plugin
    // a prerequisite for showing the first playable frame.
    unawaited(SoundService.instance.initialize().catchError((_) {}));
    final now = DateTime.now();
    try {
      final rawSave = await _saveStore.load();
      if (rawSave == null) {
        state = GameState.newGame(lastSavedAt: now);
      } else {
        final decoded = jsonDecode(rawSave);
        if (decoded is! Map) {
          throw const FormatException('Kayıt yapısı tanınmıyor.');
        }
        state = GameState.fromJson(Map<String, Object?>.from(decoded));
        if (_saveStore.recoveredBackup) {
          _notices.add(
            'Ana kayıt açılamadı; son geçerli vardiya yedeği yüklendi.',
          );
        }
        final lastSavedAt = state.lastSavedAt;
        if (lastSavedAt != null) {
          final elapsed = now.difference(lastSavedAt);
          final offlineLimit = GameEngine.maxOfflineFor(state);
          final applied = elapsed > offlineLimit ? offlineLimit : elapsed;
          final effective = Duration(
            milliseconds:
                (applied.inMilliseconds *
                        GameEngine.offlineRateMultiplier(state))
                    .round(),
          );
          if (applied.inSeconds >= 30 && effective.inSeconds > 0) {
            final oldDepth = state.deepestMeters;
            final oldMined = state.totalMined;
            GameEngine.advance(
              state,
              effective,
              now: now,
              allowRandomEvents: false,
            );
            offlineSeconds = applied.inSeconds;
            offlineDepthGained = state.deepestMeters - oldDepth;
            offlineOreGained = state.totalMined - oldMined;
            _notices.add(
              'Çevrimdışı vardiya tamamlandı: $offlineOreGained cevher, ${offlineDepthGained.toStringAsFixed(0)} m ilerleme.',
            );
          }
        }
      }
    } catch (error) {
      state = GameState.newGame(lastSavedAt: now);
      saveError = 'Kayıt okunamadı; yeni maden açıldı. Ayrıntı: $error';
      _notices.add(
        'Eski kayıt okunamadı. Yeni vardiya güvenli biçimde başlatıldı.',
      );
    }
    GameEngine.prepareChallengeWindows(state, now);
    GameEngine.ensureOpenMineDeposits(state);
    unawaited(
      SoundService.instance
          .setMusicEnabled(state.musicEnabled)
          .catchError((_) {}),
    );
    unawaited(
      SoundService.instance
          .setSoundEffectsEnabled(state.soundEffectsEnabled)
          .catchError((_) {}),
    );
    for (final achievement in GameEngine.checkAchievements(state)) {
      _notices.add(
        '${achievement.title} başarımı açıldı: +${achievement.reward} kasa.',
      );
    }
    _lastCargoFull = state.cargoFull;
    state.lastSavedAt = now;
    _lastTickAt = now;
    isReady = true;
    if (state.reactorShutdown) {
      unawaited(SoundService.instance.startReactorAlarm());
    }
    notifyListeners();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    unawaited(saveNow());
  }

  void reportInitializationFailure(Object error) {
    if (isReady || _disposed) return;
    initializationError = error.toString();
    saveError = 'Oyun başlatılırken hata oluştu: $error';
    isReady = true;
    notifyListeners();
  }

  void _tick() {
    if (!isReady || _disposed) return;
    final now = DateTime.now();
    final elapsed = now.difference(_lastTickAt) + _tickRemainder;
    _lastTickAt = now;
    if (elapsed.isNegative) {
      _tickRemainder = Duration.zero;
      return;
    }
    final wholeSeconds = elapsed.inSeconds;
    _tickRemainder = elapsed - Duration(seconds: wholeSeconds);
    if (wholeSeconds <= 0) return;
    final reactorWasShutdown = state.reactorShutdown;
    final result = GameEngine.advance(
      state,
      Duration(seconds: wholeSeconds),
      now: now,
    );
    if (state.reactorShutdown != reactorWasShutdown) {
      if (state.reactorShutdown) {
        unawaited(SoundService.instance.startReactorAlarm());
      } else {
        unawaited(SoundService.instance.stopReactorAlarm());
      }
    }
    _syncCargoFullAlarm();
    _notices.addAll(
      result.events.where((event) => !event.startsWith('Otomatik satış')),
    );
    for (final achievement in GameEngine.checkAchievements(state)) {
      _notices.add(
        '${achievement.title} başarımı açıldı: +${achievement.reward} kasa.',
      );
    }
    _tickCount++;
    notifyListeners();
    if (_tickCount % 12 == 0) unawaited(saveNow());
  }

  Future<void> saveNow() async {
    if (!isReady && _disposed) return;
    if (isSaving) {
      _saveQueued = true;
      return;
    }
    isSaving = true;
    do {
      _saveQueued = false;
      state.lastSavedAt = DateTime.now();
      try {
        await _saveStore.save(jsonEncode(state.toJson()));
        saveError = null;
      } catch (error) {
        saveError = 'Kayıt diske yazılamadı: $error';
      }
    } while (_saveQueued && !_disposed);
    isSaving = false;
    if (!_disposed) notifyListeners();
  }

  Future<void> onAppPaused() async {
    await SoundService.instance.stopBgm();
    await saveNow();
  }

  bool mine(String resourceId) {
    final previousResonanceChains = state.resonanceChains;
    final success = GameEngine.tapOre(state, resourceId);
    if (!success) {
      _notices.add('Bu maden damarı bu katta görünmüyor.');
      notifyListeners();
      return false;
    }
    if (state.resonanceChains > previousResonanceChains) {
      _notices.add('Katman Rezonansı tamamlandı; üretim beş dakika hızlandı.');
    }
    if (state.soundEffectsEnabled) {
      unawaited(SoundService.instance.playOreCollect());
    }
    _refreshState();
    return true;
  }

  bool mineDeposit(String depositId) {
    final success = GameEngine.tapMineDeposit(state, depositId);
    if (!success) {
      _notices.add('Bu damar henüz kazılabilir durumda değil.');
      notifyListeners();
      return false;
    }
    if (state.soundEffectsEnabled) {
      unawaited(SoundService.instance.playOreCollect());
    }
    _refreshState();
    return true;
  }

  bool switchWorld(int worldIndex) {
    if (worldIndex == state.currentWorldIndex) return true;
    if (!GameEngine.switchWorld(state, worldIndex)) {
      final requiredDepth =
          worldIndex >= 0 && worldIndex < GameState.worldEntryDepths.length
          ? GameState.worldEntryDepths[worldIndex].floor()
          : 0;
      _notices.add('Bu bölge $requiredDepth m derinlikte açılır.');
      notifyListeners();
      return false;
    }
    _notices.add(
      '${state.currentWorldName} vardiyasına geçildi. Derinlik ve ekip bu dünya için kaydedilir; ambar ortaktır.',
    );
    _refreshState();
    return true;
  }

  bool upgrade(String track) {
    final oldLevel = state.upgradeLevel(track);
    if (!GameEngine.buyUpgrade(state, track)) {
      if (track == 'reactor' &&
          state.energy < GameEngine.reactorUpgradeEnergyCost(oldLevel + 1)) {
        _notices.add(
          'Reaktör yükseltmesi için ${GameEngine.reactorUpgradeEnergyCost(oldLevel + 1)} enerji gerekir.',
        );
        notifyListeners();
        return false;
      }
      if (track == 'drill' && state.crewCount <= 0) {
        _notices.add('Sondajı geliştirmeden önce ilk madenciyi işe al.');
        notifyListeners();
        return false;
      }
      final materialDeficits = GameEngine.upgradeMaterialDeficits(state, track);
      if (materialDeficits.isNotEmpty) {
        final missing = materialDeficits.entries
            .map((entry) {
              final name = ResourceCatalog.byId[entry.key]?.name ?? entry.key;
              return '${entry.value} $name';
            })
            .join(', ');
        _notices.add('Yükseltme tarifi için eksik cevher: $missing.');
      } else {
        _notices.add('Yükseltme için yeterli kasa yok.');
      }
      notifyListeners();
      return false;
    }
    _notices.add('${_upgradeName(track)} seviyesi ${oldLevel + 1} oldu.');
    _refreshState();
    return true;
  }

  bool upgradeDrillAssembly(String componentId) {
    final currentLevel = GameEngine.drillAssemblyLevel(state, componentId);
    final cost = GameEngine.drillAssemblyUpgradeCost(state, componentId);
    if (!GameEngine.upgradeDrillAssembly(state, componentId)) {
      final blueprintId = DrillAssemblyCatalog.blueprintIdFor(
        componentId,
        currentLevel + 1,
      );
      if (currentLevel + 1 >= 24 &&
          !state.unlockedBuildings.contains('robot_mk2')) {
        _notices.add('Sondaj Robotu Mk II şemaları 1.257 km’de açılır.');
      } else if (blueprintId != null &&
          !state.knownBlueprintIds.contains(blueprintId)) {
        _notices.add('Bu seviye için montaj şeması henüz keşfedilmedi.');
      } else {
        final deficits = GameEngine.drillAssemblyMaterialDeficits(
          state,
          componentId,
        );
        if (deficits.isNotEmpty) {
          final missing = deficits.entries
              .map((entry) {
                final name = ResourceCatalog.byId[entry.key]?.name ?? entry.key;
                return '${entry.value} $name';
              })
              .join(', ');
          _notices.add('Şema için eksik kaynak: $missing.');
        } else if (state.crewCount <= 0) {
          _notices.add('Sondaj takımını geliştirmek için önce bir madenci al.');
        } else if (!state.canAfford(cost.toDouble())) {
          _notices.add(
            'Bu sondaj parçası için ${_saleCashLabel(cost)} kasa gerekir.',
          );
        }
      }
      notifyListeners();
      return false;
    }
    final name = switch (componentId) {
      'bit' => 'Sondaj ucu',
      'fan' => 'Soğutma fanı',
      'engine' => 'Sondaj motoru',
      _ => 'Sondaj parçası',
    };
    _notices.add('$name şeması ${currentLevel + 1}. seviyeye yükseltildi.');
    _refreshState();
    return true;
  }

  bool claimBlueprintEncounter(String id) {
    if (!GameEngine.claimBlueprintEncounter(state, id)) return false;
    final name = GameEngine.blueprintEncounters[id]?.$1 ?? 'Keşif';
    _notices.add('$name bulundu; yeni montaj şemaları arşive eklendi.');
    _refreshState();
    return true;
  }

  bool upgradeManager() {
    final nextLevel = state.managerLevel + 1;
    final deficits = GameEngine.managerUpgradeDeficits(state);
    if (!GameEngine.upgradeManager(state)) {
      if (nextLevel <= 3 &&
          state.deepestMeters < GameEngine.managerRequiredDepth(nextLevel)) {
        _notices.add(
          'Vardiya yöneticisinin $nextLevel. kademesi ${GameEngine.managerRequiredDepth(nextLevel)} m’de açılır.',
        );
      } else if (deficits.isNotEmpty) {
        final missing = deficits.entries
            .map((entry) {
              final name = ResourceCatalog.byId[entry.key]?.name ?? entry.key;
              return '${entry.value} $name';
            })
            .join(', ');
        _notices.add('Yönetici geliştirmesi için eksik kaynak: $missing.');
      }
      notifyListeners();
      return false;
    }
    final hours = GameEngine.maxOfflineFor(state).inHours;
    _notices.add(
      'Vardiya yöneticisi geliştirildi: çevrimdışı sınır $hours saat oldu.',
    );
    _refreshState();
    return true;
  }

  bool hireMiner() {
    if (!GameEngine.hireMiner(state)) {
      _notices.add(
        state.activeMinerCount >= 10
            ? 'Bu dünyanın madenci ekibi 10 kişiye ulaştı.'
            : 'Madenci işe almak için ${GameEngine.minerCost(state).round()} kasa gerekir; kömürünü ambar ekranında sat.',
      );
      notifyListeners();
      return false;
    }
    _notices.add('Yeni madenci vardiyaya katıldı.');
    _refreshState();
    return true;
  }

  bool assignWorkerRole(String role, int delta) {
    final success = GameEngine.assignWorkerRole(state, role, delta);
    if (!success) {
      _notices.add(
        'Bu görev için boşta bir madenci veya atanmış ekip gerekir.',
      );
      notifyListeners();
      return false;
    }
    final roleName = switch (role) {
      'transport' => 'taşıma',
      'scanner' => 'tarama',
      'sorting' => 'ayıklama',
      _ => 'kazı',
    };
    _notices.add(
      delta > 0
          ? 'Bir madenci $roleName görevine atandı.'
          : 'Bir madenci kazı ekibine döndü.',
    );
    _refreshState();
    return true;
  }

  bool setWorkerRolePriority(String role, int position) {
    final success = GameEngine.setWorkerRolePriority(state, role, position);
    if (success) {
      _notices.add('Ekip görev önceliği güncellendi.');
      _refreshState();
    }
    return success;
  }

  bool hireSpecialist(String role) {
    if (!GameEngine.hireSpecialist(state, role)) {
      _notices.add(
        state.unlockedBuildings.contains('super_miners')
            ? 'Uzman için yeterli kasa veya boş uzmanlık seviyesi yok.'
            : 'Uzman madenciler 10 km kilometre taşında açılır.',
      );
      notifyListeners();
      return false;
    }
    _notices.add('Yeni ${_specialistName(role)} vardiyaya katıldı.');
    _refreshState();
    return true;
  }

  bool hireSpecialWorker() {
    final success = GameEngine.hireSpecialWorker(state);
    if (success) {
      final worker = state.specialWorkerRoster.last;
      _notices.add('${worker.rarity.name} ${worker.name} vardiyaya katıldı.');
      _refreshState();
    } else {
      _notices.add(
        'Özel madenci için 10 km, ${GameEngine.specialWorkerCost(state)} kasa ve boş kadro gerekir.',
      );
      notifyListeners();
    }
    return success;
  }

  bool dismantleSpecialWorker(String id) {
    final worker = GameEngine.specialWorkerById(state, id);
    final name = worker?.name ?? 'Özel madenci';
    final success = GameEngine.dismantleSpecialWorker(state, id);
    if (success) {
      _notices.add(
        '$name söküldü; kadroya ${worker!.rarity.scrapValue} hurda eklendi.',
      );
    }
    _refreshState();
    return success;
  }

  bool upgradeSpecialWorker(String id) {
    final success = GameEngine.upgradeSpecialWorker(state, id);
    if (success) {
      _notices.add('Özel madenci seviye atladı.');
    } else {
      _notices.add('Bu yükseltme için yeterli özel hurda yok.');
    }
    _refreshState();
    return success;
  }

  bool moveSpecialWorker(String id, int world, int floor) {
    final success = GameEngine.moveSpecialWorker(state, id, world, floor);
    if (success) {
      _notices.add(
        'Özel madenci ${const ['Dünya', 'Ay', 'Titan'][world]} $floor. kata yerleştirildi.',
      );
    }
    _refreshState();
    return success;
  }

  bool setSpecialWorkerAutoMove(String id, bool autoMove) {
    final success = GameEngine.setSpecialWorkerAutoMove(state, id, autoMove);
    if (success) _refreshState();
    return success;
  }

  bool setSpecialWorkerResource(String id, String resourceId) {
    final success = GameEngine.setSpecialWorkerResource(state, id, resourceId);
    if (success) _refreshState();
    return success;
  }

  bool refineMaterials() {
    final success = GameEngine.refineBuildingMaterial(state);
    if (success) {
      _notices.add('Dökümhanede iki yapı malzemesi üretildi.');
    } else {
      _notices.add('Tarif için dökümhane Lv 1, 5 bakır ve 10 kömür gerekir.');
    }
    _refreshState();
    return success;
  }

  bool refineOil() {
    final success = GameEngine.refineOil(state);
    _notices.add(
      success
          ? 'Beş petrol iki yapı malzemesine dönüştürüldü.'
          : 'İşleme için yeraltı şehri ve beş petrol gerekir.',
    );
    _refreshState();
    return success;
  }

  bool upgradeOilPump() {
    final cost = GameEngine.oilPumpUpgradeCost(state);
    final success = GameEngine.upgradeOilPump(state);
    if (success) {
      _notices.add(
        'Petrol pompası ${state.oilPumpLevel}. seviyeye çıktı; üretim ve depo kapasitesi arttı.',
      );
    } else if (state.oilPumpLevel >= GameEngine.oilPumpMaximumLevel) {
      _notices.add('Petrol pompası en yüksek seviyede.');
    } else {
      _notices.add('Pompa geliştirmesi için $cost kasa gerekir.');
    }
    _refreshState();
    return success;
  }

  bool sellOil() {
    final quantity = GameEngine.unreservedOil(state);
    final success = GameEngine.sellOil(state);
    _notices.add(
      success
          ? '$quantity petrol varili ${quantity * GameEngine.oilPumpSaleValuePerBarrel} kasa karşılığında satıldı.'
          : 'Satılabilecek, rezerve edilmemiş petrol yok.',
    );
    _refreshState();
    return success;
  }

  bool forgeDrillPart() {
    final success = GameEngine.forgeDrillPart(state);
    if (success) {
      _notices.add('Dökümhane bir sondaj parçası üretti.');
    } else {
      _notices.add(
        'Tarif için dökümhane Lv 2, 4 demir, 3 bakır ve 1 yapı malzemesi gerekir.',
      );
    }
    _refreshState();
    return success;
  }

  bool craftGem(String gemId) {
    final gem = GemCatalog.byId[gemId];
    final success = GameEngine.startGemCraft(state, gemId);
    if (success) {
      _notices.add('${gem!.name} Mücevher Ocağına alındı.');
    } else if (gem != null) {
      final missing = gem.recipe.entries
          .where(
            (entry) =>
                state.amount(entry.key) - state.reserve(entry.key) <
                entry.value,
          )
          .map((entry) {
            final name = ResourceCatalog.byId[entry.key]?.name ?? entry.key;
            return '${entry.value} $name';
          })
          .join(', ');
      _notices.add(
        missing.isNotEmpty
            ? 'Tarif için eksik kaynak: $missing.'
            : 'Bu mücevher üretimde, iş yükü sıfır veya ocak kilitli.',
      );
    }
    _refreshState();
    return success;
  }

  void adjustGemWorkload(String gemId, int delta) {
    GameEngine.adjustGemWorkload(state, gemId, delta);
    _refreshState();
  }

  bool toggleGemEquipment(String gemId) {
    final wasEquipped = state.equippedGems.contains(gemId);
    final success = GameEngine.toggleGemEquipment(state, gemId);
    if (success) {
      final gem = GemCatalog.byId[gemId];
      _notices.add(
        wasEquipped
            ? '${gem?.name ?? 'Mücevher'} yuvadan çıkarıldı.'
            : '${gem?.name ?? 'Mücevher'} yuvaya takıldı.',
      );
    } else {
      _notices.add(
        'Mücevheri yuvaya takmak için boş yuva veya mücevher gerekir.',
      );
    }
    _refreshState();
    return success;
  }

  MrMineBigNumber sell(String resourceId, {int? quantity}) {
    final value = GameEngine.sellResource(
      state,
      resourceId,
      requested: quantity,
    );
    if (value.greaterThan(MrMineBigNumber.zero)) {
      _notices.add('Satış tamamlandı: +${_saleCashLabel(value)} kasa.');
    }
    _refreshState();
    return value;
  }

  MrMineBigNumber sellAll({int? worldIndex, bool? isotopesOnly}) {
    final value = GameEngine.sellAll(
      state,
      worldIndex: worldIndex,
      isotopesOnly: isotopesOnly,
    );
    if (value.greaterThan(MrMineBigNumber.zero)) {
      _notices.add('Ambar satışından +${_saleCashLabel(value)} kasa geldi.');
    }
    _refreshState();
    return value;
  }

  MrMineBigNumber sellFraction(double fraction) {
    final value = GameEngine.sellFraction(state, fraction);
    if (value.greaterThan(MrMineBigNumber.zero)) {
      _notices.add('Kısmi satış tamamlandı: +${_saleCashLabel(value)} kasa.');
    }
    _refreshState();
    return value;
  }

  bool claimDailyChallenge(String challengeId) {
    final challenge = DailyChallengeCatalog.byId[challengeId];
    final success = GameEngine.claimDailyChallenge(state, challengeId);
    _notices.add(
      success
          ? 'Günlük hedef tamamlandı: +${challenge?.rewardCoins ?? 0} kasa.'
          : 'Bu günlük hedef henüz tamamlanmadı veya ödülü alındı.',
    );
    _refreshState();
    return success;
  }

  bool claimWeeklyChallenge() {
    final success = GameEngine.claimWeeklyChallenge(state);
    _notices.add(
      success
          ? 'Haftalık kilometre taşı tamamlandı: +${DailyChallengeCatalog.weeklyRewardCoins} kasa ve +${DailyChallengeCatalog.weeklyRewardCoreShards} çekirdek parçası.'
          : 'Haftalık kilometre taşı için 12 günlük hedefi tamamla.',
    );
    _refreshState();
    return success;
  }

  bool resolveMineEvent() {
    final event = MineEventCatalog.byId[state.activeMineEventId];
    final success = GameEngine.resolveMineEvent(state);
    if (success) {
      _notices.add(
        '${event?.title ?? 'Maden olayı'} tamamlandı; ödül ambara alındı.',
      );
    } else {
      _notices.add('Maden olayı şu anda tamamlanamıyor.');
    }
    _refreshState();
    return success;
  }

  void toggleReserve(String resourceId) {
    GameEngine.toggleReserve(state, resourceId);
    _refreshState();
  }

  void setResourceReserve(String resourceId, int amount) {
    GameEngine.setResourceReserve(state, resourceId, amount);
    _refreshState();
  }

  bool upgradeCargo() {
    if (!GameEngine.upgradeCargo(state)) {
      final deficits = GameEngine.cargoUpgradeDeficits(state);
      if (deficits.isNotEmpty) {
        final missing = deficits.entries
            .map(
              (entry) =>
                  '${entry.value} ${ResourceCatalog.byId[entry.key]?.name ?? entry.key}',
            )
            .join(', ');
        _notices.add('Kargo şeması için eksik malzeme: $missing.');
      } else {
        _notices.add('Kargo yükseltmesi için yeterli kasa yok.');
      }
      notifyListeners();
      return false;
    }
    _notices.add('Kargo donanımı ${state.cargoLevel}. seviyeye yükseltildi.');
    _refreshState();
    return true;
  }

  bool upgradeWorkerLevel() {
    if (!GameEngine.upgradeWorkerLevel(state)) {
      _notices.add(
        state.activeMinerCount < 10
            ? 'Eğitim için bu dünyada 10 madenci gerekir.'
            : 'Madenci eğitimi için ${GameEngine.workerLevelCost(state).round()} kasa gerekir.',
      );
      notifyListeners();
      return false;
    }
    _notices.add('Bu dünyanın madencileri Lv ${state.activeWorkerLevel} oldu.');
    _refreshState();
    return true;
  }

  void setMusicEnabled(bool enabled) {
    state.musicEnabled = enabled;
    unawaited(SoundService.instance.setMusicEnabled(enabled));
    _refreshState();
  }

  void setSoundEffectsEnabled(bool enabled) {
    state.soundEffectsEnabled = enabled;
    unawaited(SoundService.instance.setSoundEffectsEnabled(enabled));
    _refreshState();
  }

  void setVisualEffectsEnabled(bool enabled) {
    state.visualEffectsEnabled = enabled;
    _refreshState();
  }

  void setNotificationsEnabled(bool enabled) {
    state.notificationsEnabled = enabled;
    _refreshState();
  }

  void setDebugModeEnabled(bool enabled) {
    state.debugModeEnabled = enabled;
    if (!enabled) state.debugUnlimitedMoney = false;
    _refreshState();
  }

  void setDebugUnlimitedMoney(bool enabled) {
    state.debugUnlimitedMoney = enabled && state.debugModeEnabled;
    _refreshState();
  }

  void debugJumpToEnd() {
    GameEngine.debugJumpToEnd(state);
    _notices.add('Oyunun son derinliğine geçildi.');
    _refreshState();
  }

  void toggleResourceLock(String resourceId) {
    final wasLocked = state.lockedResources.contains(resourceId);
    GameEngine.toggleResourceLock(state, resourceId);
    _notices.add(
      wasLocked
          ? 'Kaynak kilidi kaldırıldı.'
          : 'Kaynak kilitlendi; toplu ve otomatik satış koruyacak.',
    );
    _refreshState();
  }

  void setAutoSellEnabled(bool enabled) {
    state.autoSellEnabled = enabled;
    _refreshState();
  }

  void setAutoSellThreshold(double threshold) {
    GameEngine.setAutoSellThreshold(state, threshold);
    _refreshState();
  }

  int openChest({String tier = 'basic'}) {
    final reward = GameEngine.openChestTier(state, tier);
    if (reward > 0) {
      unawaited(SoundService.instance.playChestOpen());
      final tierName = switch (tier) {
        'gold' => 'Altın sandık',
        'deep' => 'Derin sandık',
        _ => 'Sandık',
      };
      _notices.add('$tierName açıldı: +$reward kasa ve cevher ganimeti.');
    } else if (state.totalChestsFound > 0) {
      _notices.add('Sandık ganimeti için önce ambarda yer aç.');
    }
    _refreshState();
    return reward;
  }

  bool claimCollectedChests() {
    final amount = state.collectorStoredChests;
    final success = GameEngine.claimCollectedChests(state);
    if (success) _notices.add('$amount sandık toplayıcıdan ambara alındı.');
    _refreshState();
    return success;
  }

  bool upgradeChestCollector() {
    final cost = GameEngine.chestCollectorUpgradeCost(state);
    if (!GameEngine.upgradeChestCollector(state)) {
      _notices.add('Toplayıcı kapasitesi için $cost kasa gerekir.');
      notifyListeners();
      return false;
    }
    _notices.add(
      'Sandık toplayıcı kapasitesi ${state.chestCollectorCapacity} oldu.',
    );
    _refreshState();
    return true;
  }

  bool startChestCompression(String outputTier) {
    final success = GameEngine.startChestCompression(
      state,
      outputTier,
      now: DateTime.now(),
    );
    if (success) {
      _notices.add(
        outputTier == 'gold'
            ? '${GameEngine.chestCompressionBasicCost(state)} temel sandık altın sandık kuyruğuna girdi.'
            : '${GameEngine.chestCompressionGoldCost(state)} altın sandık derin sandık kuyruğuna girdi.',
      );
    } else {
      _notices.add('Sıkıştırıcıda boş yuva veya yeterli sandık yok.');
    }
    _refreshState();
    return success;
  }

  bool upgradeChestCompressor() {
    final cost = GameEngine.chestCompressorUpgradeCost(state);
    if (!GameEngine.upgradeChestCompressor(state)) {
      _notices.add('Sıkıştırıcı yükseltmesi için $cost kasa gerekir.');
      notifyListeners();
      return false;
    }
    _notices.add(
      'Sandık sıkıştırıcı seviyesi ${state.chestCompressionLevel} oldu.',
    );
    _refreshState();
    return true;
  }

  bool scanResonance() {
    final success = GameEngine.scanResonance(state);
    if (!success) {
      _notices.add('Tarayıcıyı kullanmak için 80 kasa gerekir.');
    } else {
      final sequence = state.resonancePattern
          .map((id) => ResourceCatalog.byId[id]?.name ?? id)
          .join(' → ');
      _notices.add('Damar dizisi: $sequence. Kuyuya dönüp sırayla seç.');
    }
    _refreshState();
    return success;
  }

  bool tapResonanceNode(String resourceId) {
    final oldChains = state.resonanceChains;
    final completed = GameEngine.tapResonance(state, resourceId);
    if (completed) {
      _notices.add('Katman Rezonansı: beş dakikalık üretim artışı açıldı!');
    } else if (state.resonanceChains == oldChains &&
        state.resonanceProgress == 0) {
      _notices.add('Dizi bozuldu. Ceza yok; işaretli damardan tekrar başla.');
    }
    _refreshState();
    return completed;
  }

  bool ventPressure() {
    final success = GameEngine.ventPressure(state);
    if (!success) {
      _notices.add(
        'Havalandırma için 90 kasa veya bir yapı malzemesi gerekir.',
      );
    }
    _refreshState();
    return success;
  }

  bool startCaveExpedition() {
    final success = GameEngine.startCaveExpedition(state, DateTime.now());
    if (!success) {
      _notices.add(
        'Mağara keşfi için 45 km derinlik ve hazır bir dron gerekiyor.',
      );
    } else {
      _notices.add('Harita açıldı. Sağlam bir yol seçip ganimeti topla.');
      unawaited(SoundService.instance.playCaveDrone());
    }
    _refreshState();
    return success;
  }

  bool selectCaveRoute(String routeId) {
    final success = GameEngine.selectCaveRoute(state, routeId);
    if (success) {
      _notices.add(
        '${CaveRouteCatalog.byId[routeId]!.name} sefer rotası seçildi.',
      );
    }
    _refreshState();
    return success;
  }

  bool setCaveDroneCount(int count) {
    final success = GameEngine.setCaveDroneCount(state, count);
    if (success) _notices.add('$count keşif dronu rotaya atandı.');
    _refreshState();
    return success;
  }

  bool selectCaveDrone(String droneId) {
    final success = GameEngine.selectCaveDrone(state, droneId);
    if (success) {
      _notices.add('Sefer dronu: ${CaveDroneCatalog.byId[droneId]!.name}.');
      _refreshState();
    }
    return success;
  }

  bool chooseCaveNode(int lane) {
    final row = state.caveStep;
    final nodeId = lane >= 0 && lane < 3 && row < state.caveNodeMap.length
        ? state.caveNodeMap[row][lane]
        : null;
    final success = GameEngine.chooseCaveNode(state, lane, now: DateTime.now());
    if (success && nodeId != null) {
      _notices.add('Keşif: ${CaveNodeCatalog.byId[nodeId]?.name ?? 'Düğüm'}.');
      if (!state.caveExploring) {
        _notices.add(
          state.caveDroneHealth <= 0
              ? 'Dron geri çekildi; bulduğun ganimet alınmaya hazır.'
              : 'Keşif rotası tamamlandı; ganimetini garajdan al.',
        );
      }
      _refreshState();
    }
    return success;
  }

  bool retreatCave() {
    final success = GameEngine.retreatCave(state);
    if (success) {
      _notices.add('Dron ganimetle geri çağrıldı.');
      _refreshState();
    }
    return success;
  }

  bool claimCaveExpedition() {
    final success = GameEngine.claimCaveExpedition(state, DateTime.now());
    if (success) {
      _notices.add('Dron ganimeti ambarına aktarıldı.');
    } else if (state.caveCompletedPending) {
      _notices.add('Dron ganimeti için önce ambarda yer aç.');
    }
    _refreshState();
    return success;
  }

  bool startExcavation() {
    final success = GameEngine.startExcavation(state, DateTime.now());
    if (!success) {
      _notices.add('Kazı için 50 km derinlik ve bir bilim insanı gerekiyor.');
    }
    _refreshState();
    return success;
  }

  bool claimExcavation() {
    final success = GameEngine.claimExcavation(state, DateTime.now());
    if (success) _notices.add('Kalıntı ve sondaj parçası bulundu.');
    _refreshState();
    return success;
  }

  bool hireScientist() {
    final success = GameEngine.hireScientist(state);
    if (success) {
      _notices.add('${state.scientistRoster.last.name} bilim ekibine katıldı.');
      _refreshState();
    } else {
      _notices.add(
        state.deepestMeters < 50000
            ? 'Bilim insanları 50 km kilometre taşında bulunur.'
            : 'Bilim insanı için ${GameEngine.scientistCost(state)} kasa ve boş kadro gerekir.',
      );
      notifyListeners();
    }
    return success;
  }

  bool startScientistExpedition(String scientistId, String missionId) {
    final success = GameEngine.startScientistExpedition(
      state,
      scientistId,
      missionId,
      DateTime.now(),
    );
    if (success) {
      final mission = ScientistExpeditionCatalog.byId[missionId]!;
      _notices.add('${mission.name} seferi başladı.');
      _refreshState();
    } else {
      _notices.add(
        'Bu bilim insanı şu an göreve çıkamaz veya bölge henüz açılmadı.',
      );
      notifyListeners();
    }
    return success;
  }

  bool claimScientistExpedition() {
    final scientist = state.scientistById(state.activeScientistId);
    final name = scientist?.name ?? 'Bilim insanı';
    final outcome = state.scientistExpeditionOutcome;
    final success = GameEngine.claimScientistExpedition(state, DateTime.now());
    if (success) {
      final resolved = scientist;
      if (outcome == 'injury' && resolved?.dead == true) {
        _notices.add(
          '$name ikinci yaralanmasının ardından hayatını kaybetti. Nadir canlandırma mührüyle geri dönebilir.',
        );
      } else if (outcome == 'injury') {
        _notices.add(
          '$name yaralandı; iyileşmesi bitene kadar yeni sefere çıkamaz.',
        );
      } else if (outcome == 'partial') {
        _notices.add('$name kısmi ganimetle döndü.');
      } else {
        _notices.add('$name başarılı oldu; sefer ganimeti teslim alındı.');
      }
      _refreshState();
    } else if (state.scientistExpeditionReadyAt?.isAfter(DateTime.now()) ==
        true) {
      notifyListeners();
    } else {
      _notices.add('Sefer ganimeti için cevher ambarında yer aç.');
      notifyListeners();
    }
    return success;
  }

  bool reviveScientist(String id) {
    final scientist = state.scientistById(id);
    final success = GameEngine.reviveScientist(state, id);
    if (success) {
      _notices.add('${scientist?.name ?? 'Bilim insanı'} canlandırıldı.');
      _refreshState();
    } else {
      _notices.add('Canlandırmak için bir nadir canlandırma mührü gerekir.');
      notifyListeners();
    }
    return success;
  }

  bool buyDrone() {
    final cost = 260 + state.drones * 240;
    if (!state.unlockedBuildings.contains('caves') ||
        !state.canAfford(cost) ||
        state.drones >= 12) {
      _notices.add(
        'Dron alımı için mağara kilometre taşı ve $cost kasa gerekir.',
      );
      notifyListeners();
      return false;
    }
    state.spendCoins(cost);
    state.drones++;
    _refreshState();
    return true;
  }

  bool upgradeExpedition() {
    final cost = 380 + state.expeditionLevel * 520;
    if (!state.canAfford(cost) || state.expeditionLevel >= 15) {
      _notices.add('Sefer yükseltmesi için $cost kasa gerekir.');
      notifyListeners();
      return false;
    }
    state.spendCoins(cost);
    state.expeditionLevel++;
    _refreshState();
    return true;
  }

  bool acceptTrade() {
    final offer = GameEngine.merchantOffer(state);
    final success = GameEngine.acceptMerchantDeal(state);
    if (!success) {
      _notices.add(
        offer.blueprintId != null
            ? 'Montaj şemasını almak için yeterli kasa yok.'
            : 'Takas için gereken cevher yok veya rezerve edilmiş.',
      );
    } else if (offer.blueprintId != null) {
      _notices.add(
        '${GameEngine.blueprintName(offer.blueprintId!)} planı arşive eklendi.',
      );
    }
    _refreshState();
    return success;
  }

  bool setReactorComponent(int x, int y, String componentId) {
    final success = GameEngine.setReactorComponent(state, x, y, componentId);
    if (!success) {
      _notices.add('Bu reaktör modülü bu yuvaya yerleştirilemiyor.');
    } else if (state.reactorShutdown) {
      _notices.add('Isı dengesi aşıldı; reaktör güvenlik için kapandı.');
      unawaited(SoundService.instance.startReactorAlarm());
    } else {
      unawaited(SoundService.instance.stopReactorAlarm());
    }
    _refreshState();
    return success;
  }

  bool restartReactor() {
    final success = GameEngine.restartReactor(state);
    if (!success) {
      _notices.add('Reaktörü başlatmak için önce ısı dengesini kur.');
    } else {
      _notices.add('Reaktör yeniden çalışıyor.');
      unawaited(SoundService.instance.stopReactorAlarm());
    }
    _refreshState();
    return success;
  }

  bool synthesizeReactorIsotope(String isotopeId) {
    final success = GameEngine.synthesizeReactorIsotope(state, isotopeId);
    if (success) {
      final recipe = ReactorCatalog.isotopeById[isotopeId];
      _notices.add('${recipe?.name ?? isotopeId} üretildi.');
    } else {
      _notices.add(
        'İzotop üretimi için gereken enerji, derinlik veya ambar yeri yok.',
      );
    }
    _refreshState();
    return success;
  }

  bool activateReactorBuff() {
    final success = GameEngine.activateReactorBuff(state, DateTime.now());
    if (!success) {
      _notices.add('Reaktör buffı için 25 enerji ve açık bir reaktör gerekir.');
    }
    _refreshState();
    return success;
  }

  bool toggleBuffLabEffect(String buffId, bool active) {
    final success = GameEngine.setBuffLabActive(state, buffId, active);
    final buff = BuffLabCatalog.byId[buffId];
    if (success) {
      _notices.add(
        active
            ? '${buff?.name ?? 'Buff'} etkinleştirildi.'
            : '${buff?.name ?? 'Buff'} kapatıldı.',
      );
    } else {
      _notices.add(
        state.energy < (buff?.energyDrainPerSecond ?? 0)
            ? 'Bu Buff Lab etkisini çalıştırmak için yeterli enerji yok.'
            : 'Buff Lab etkisi kullanılamıyor.',
      );
    }
    _refreshState();
    return success;
  }

  bool sacrificeScientistToCore(String scientistId) {
    final success = GameEngine.sacrificeScientistToCore(state, scientistId);
    if (success) {
      _notices.add(
        'Bilim insanı çekirdeğe katıldı; kalıcı çekirdek parçası kazanıldı.',
      );
    } else {
      _notices.add('Bilim insanı şu anda çekirdeğe adanamıyor.');
    }
    _refreshState();
    return success;
  }

  int attackBoss() {
    final reward = GameEngine.attackBoss(state);
    if (reward > 0) {
      _notices.add(
        'Muhafız yenildi! +$reward kasa ve sondaj parçası kazandın.',
      );
    } else if (reward == -2) {
      _notices.add('Zayıf noktaya kritik isabet! Üç kat hasar verdin.');
    } else if (reward == -1) {
      _notices.add('Zayıf noktaya isabet! Vuruşa devam et.');
    }
    _refreshState();
    return reward;
  }

  bool focusBossWeakPoint() {
    final success = GameEngine.focusBossWeakPoint(state, DateTime.now());
    if (success) {
      _notices.add('Zayıf nokta dört saniyeliğine açıldı!');
    }
    _refreshState();
    return success;
  }

  void claimCurrentQuest() {
    final quest = currentQuest;
    if (!currentQuestReady) return;
    state.claimedQuestIds.add(quest.id);
    final reward =
        (quest.reward *
                (state.equippedRelics.contains('relic_8')
                    ? 1 + .1 * state.relicLevel('relic_8')
                    : 1))
            .round();
    state.addCoins(reward);
    if ((quest.id + 1) % 5 == 0) {
      state.inventory['ticket'] = state.amount('ticket') + 1;
      state.relicScrap++;
      state.workerScrap++;
    }
    if (state.guidedProgression && state.initialTutorialComplete) {
      GameEngine.completeStarterTutorial(state, _notices);
      _notices.add(
        'İlk vardiya tamamlandı. Danışman robot yeni sistemleri sırayla tanıtacak.',
      );
    }
    _notices.add('Görev tamamlandı: +$reward kasa.');
    _refreshState();
  }

  void acknowledgeAdvisorGuide(String guideId) {
    if (!state.guidedProgression || !state.initialTutorialComplete) return;
    final guide = AdvisorGuideCatalog.byId[guideId];
    if (guide == null ||
        guide.isTutorial ||
        state.deepestMeters < guide.requiredDepthMeters ||
        state.activeMinerCount < guide.requiredMinerCount ||
        !state.completedAdvisorGuideIds.add(guideId)) {
      return;
    }
    if (guide.unlockBuildingId == 'elevator') {
      state.unlockedBuildings.add('elevator');
    }
    final unlockedWorkerRole = guide.unlockWorkerRole;
    if (unlockedWorkerRole != null) {
      state.completedAdvisorGuideIds.add('worker_role_$unlockedWorkerRole');
    }
    GameEngine.unlockReachedMilestones(state, _notices);
    _refreshState();
  }

  void toggleRelic(String relicId) {
    if (!state.unlockedRelics.contains(relicId)) return;
    if (!state.equippedRelics.add(relicId)) {
      state.equippedRelics.remove(relicId);
    }
    while (state.equippedRelics.length > 3) {
      state.equippedRelics.remove(state.equippedRelics.first);
    }
    _refreshState();
  }

  bool dismantleRelicDuplicate(String relicId) {
    final success = GameEngine.dismantleRelicDuplicate(state, relicId);
    if (success) _notices.add('Kalıntı kopyası söküldü: +1 yazıt hurdası.');
    _refreshState();
    return success;
  }

  bool upgradeRelic(String relicId) {
    final cost = GameEngine.relicUpgradeCost(state, relicId);
    final success = GameEngine.upgradeRelic(state, relicId);
    if (success) {
      _notices.add(
        'Kalıntı ${relicId.replaceFirst('relic_', '')} güçlendirildi.',
      );
    } else if (cost > state.relicScrap) {
      _notices.add('Geliştirme için $cost yazıt hurdası gerekir.');
    }
    _refreshState();
    return success;
  }

  bool craftWeapon() {
    if ((state.upgrades['weapon'] ?? 0) >= 20 ||
        state.drillParts < 2 ||
        !state.canAfford(400)) {
      _notices.add('Silah üretimi için 2 sondaj parçası ve 400 kasa gerekir.');
      notifyListeners();
      return false;
    }
    state.spendCoins(400);
    state.drillParts -= 2;
    state.upgrades['weapon'] = state.upgradeLevel('weapon') + 1;
    _notices.add('Derinlik silahı üretildi. Boss vuruşların güçlendi.');
    _refreshState();
    return true;
  }

  bool prestige() {
    if (!state.unlockedBuildings.contains('deep_core') ||
        state.deepestMeters < 500000) {
      _notices.add('Derin çekirdek için 500 km kilometre taşı gerekir.');
      notifyListeners();
      return false;
    }
    GameEngine.applyPrestige(state);
    _notices.add(
      'Çekirdek sıfırlaması tamamlandı; kalıcı çekirdek gücü arttı.',
    );
    _refreshState();
    return true;
  }

  void startNewGame() {
    final wasMusicEnabled = state.musicEnabled;
    final wereSoundEffectsEnabled = state.soundEffectsEnabled;
    _notices.clear();
    state = GameState.newGame(lastSavedAt: DateTime.now());
    if (!wasMusicEnabled) {
      unawaited(SoundService.instance.setMusicEnabled(state.musicEnabled));
    }
    if (!wereSoundEffectsEnabled) {
      unawaited(
        SoundService.instance.setSoundEffectsEnabled(state.soundEffectsEnabled),
      );
    }
    _lastTickAt = DateTime.now();
    _tickRemainder = Duration.zero;
    offlineSeconds = 0;
    offlineDepthGained = 0;
    offlineOreGained = 0;
    _notices.add('Yeni maden vardiyası başladı.');
    _refreshState();
  }

  void _refreshState() {
    _syncCargoFullAlarm();
    for (final achievement in GameEngine.checkAchievements(state)) {
      _notices.add(
        '${achievement.title} başarımı açıldı: +${achievement.reward} kasa.',
      );
    }
    notifyListeners();
    unawaited(saveNow());
  }

  void _syncCargoFullAlarm() {
    if (!_lastCargoFull && state.cargoFull) {
      unawaited(SoundService.instance.playCargoFull());
    }
    _lastCargoFull = state.cargoFull;
  }

  void showNotice(String message) {
    if (state.notificationsEnabled) _notices.add(message);
    notifyListeners();
  }

  String _upgradeName(String track) => switch (track) {
    'drill' => 'Sondaj',
    'workers' => 'İşçi eğitimi',
    'lift' => 'Asansör',
    'warehouse' => 'Ambar',
    'scanner' => 'Tarayıcı',
    'foundry' => 'Dökümhane',
    'weapon' => 'Derinlik Silahı',
    'reactor' => 'Reaktör',
    _ => track,
  };

  String _specialistName(String role) => switch (role) {
    'geologist' => 'jeolog',
    'engineer' => 'mühendis',
    'scout' => 'kâşif',
    'guardian' => 'muhafız uzmanı',
    _ => 'uzman',
  };

  @override
  void dispose() {
    _disposed = true;
    _ticker?.cancel();
    unawaited(saveNow());
    unawaited(SoundService.disposeIfCreated());
    super.dispose();
  }
}
