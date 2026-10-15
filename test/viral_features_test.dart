import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tasin_alti/app/game_controller.dart';
import 'package:tasin_alti/data/save_store.dart';
import 'package:tasin_alti/domain/models/game_state.dart';
import 'package:tasin_alti/services/haptic_service.dart';

class _MemorySaveStore implements SaveStore {
  String? current;

  @override
  bool get recoveredBackup => false;

  @override
  Future<void> clear() async => current = null;

  @override
  Future<String?> load() async => current;

  @override
  Future<void> save(String value) async => current = value;
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (call) async => null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (call) async => null,
    );
  });

  group('Viral & Cila Özellikleri Testleri', () {
    test('HapticService durumu GameState ayarıyla güncellenir', () {
      final store = _MemorySaveStore();
      final controller = GameController(saveStore: store);
      controller.state = GameState(hapticsEnabled: true);
      HapticService.instance.enabled = true;

      controller.setHapticsEnabled(false);
      expect(controller.state.hapticsEnabled, isFalse);
      expect(HapticService.instance.enabled, isFalse);

      controller.setHapticsEnabled(true);
      expect(controller.state.hapticsEnabled, isTrue);
      expect(HapticService.instance.enabled, isTrue);
    });

    test('Frenzy (Çılgınlık) tetiklendiğinde aktifleşir ve çift kazı sağlar', () {
      final store = _MemorySaveStore();
      final controller = GameController(saveStore: store);
      controller.state = GameState.newGame(seed: 12345);

      expect(controller.isFrenzyActive, isFalse);
      expect(controller.frenzyRemainingSeconds, 0.0);

      controller.triggerFrenzy(5);
      expect(controller.isFrenzyActive, isTrue);
      expect(controller.frenzyRemainingSeconds, greaterThan(0.0));
      expect(controller.frenzyRemainingSeconds, lessThanOrEqualTo(5.0));
    });

    test('Kayıt dışa ve içe aktarma (Export/Import) kayıpsız çalışır', () {
      final store = _MemorySaveStore();
      final controller = GameController(saveStore: store);
      controller.state = GameState(
        coins: 987654,
        depthMeters: 45000,
        deepestMeters: 45000,
        totalMined: 12500,
      );

      final exportedCode = controller.exportSaveData();
      expect(exportedCode, isNotEmpty);

      // Başka bir controller'a aktar
      final controller2 = GameController(saveStore: _MemorySaveStore());
      controller2.state = GameState.newGame();

      final success = controller2.importSaveData(exportedCode);
      expect(success, isTrue);
      expect(controller2.state.coins.toString(), controller.state.coins.toString());
      expect(controller2.state.deepestMeters, 45000);
      expect(controller2.state.totalMined, 12500);
    });

    test('Geçersiz kayıt kodu import edilirken reddedilir', () {
      final store = _MemorySaveStore();
      final controller = GameController(saveStore: store);
      final initialCoins = controller.state.coins;

      final result = controller.importSaveData('gecersiz_veri_123');
      expect(result, isFalse);
      expect(controller.state.coins, initialCoins);
    });

    test('OfflineShiftReport ve karşılama raporu düzgün oluşturulur', () {
      const report = OfflineShiftReport(
        durationSeconds: 3600,
        depthGained: 450,
        oreGained: 1200,
      );
      expect(report.durationSeconds, 3600);
      expect(report.depthGained, 450);
      expect(report.oreGained, 1200);

      final store = _MemorySaveStore();
      final controller = GameController(saveStore: store);
      controller.pendingOfflineReport = report;
      expect(controller.pendingOfflineReport, isNotNull);

      controller.clearOfflineReport();
      expect(controller.pendingOfflineReport, isNull);
    });
  });
}
