import 'package:flutter_test/flutter_test.dart';
import 'package:tasin_alti/domain/models/game_state.dart';
import 'package:tasin_alti/domain/simulation/game_engine.dart';
import 'package:tasin_alti/app/game_controller.dart';
import 'package:tasin_alti/crusher/crusher_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Kırma & Ayrıştırma Ünitesi (Crusher Unit) Testleri', () {
    test('Madencilerin kazdığı maden parçaları kırma ünitesine gider ve kırıcı haznesinde birikir', () {
      final state = GameState.newGame();
      expect(state.rawOreInventory['coal'] ?? 0, 0);

      // 50 adet ham kömür ekle
      state.addRawOre('coal', 50);
      expect(state.rawOreInventory['coal'], 50);
      expect(state.totalRawOreCount, 50);
    });

    test('Kırma ünitesi ham parçaları kırarak ambara (inventory) saf kaynak olarak aktarır', () {
      final state = GameState.newGame();
      state.addRawOre('copper', 20);
      expect(state.amount('copper'), 0);

      // 10 adet ham bakır kır
      final yieldResult = state.crushRawOre(
        oreId: 'copper',
        amount: 10,
        yieldMultiplier: 1.2,
      );

      expect(yieldResult, 12); // 10 * 1.2 = 12
      expect(state.amount('copper'), 12); // Ambara aktarıldı
      expect(state.rawOreInventory['copper'], 10); // Kalan ham parça
      expect(state.totalOreCrushed, 10);
      expect(state.crusherXp, 20);
    });

    test('İki farklı ekonomi yoktur; kırıcı geliştirmeleri ana oyunun parasıyla (coins) yapılır', () {
      final controller = GameController();
      controller.state.addCoins(1000);
      final initialCoins = controller.state.coins.toDouble();

      final crusherGame = CrusherGame(controller);
      final initialSpeedLvl = crusherGame.speedLevel;
      final cost = crusherGame.upgradeCost('speed');

      crusherGame.buyUpgrade('speed');

      expect(crusherGame.speedLevel, initialSpeedLvl + 1);
      expect(controller.state.crusherUpgrades['speed'], initialSpeedLvl + 1);
      expect(controller.state.coins.toDouble(), initialCoins - cost);
    });

    test('_advanceCrusher dolu haznede kırmaya başlar ve ürünü ambara gönderir', () {
      final state = GameState.newGame();
      state.crusherRepaired = true;
      state.addRawOre('coal', 30);
      expect(state.amount('coal'), 0);

      // 1 saniye simülasyon ilerlet
      GameEngine.advance(state, const Duration(seconds: 1));

      // Kırıcı bir kaya işler. Aynı simülasyon adımında gelen yeni kaya,
      // işlenen kayayı dengeleyebileceği için hazne adedi sabit kalabilir.
      expect(state.amount('coal'), greaterThan(0));
      expect(state.totalOreCrushed, greaterThan(0));
      expect(state.rawOreInventory['coal'] ?? 0, lessThanOrEqualTo(30));
    });

    test('Ambar dolunca kırıcı durur, oyuncu satış yapınca yer açılır ve kırıcı devam eder', () {
      final controller = GameController();
      final state = controller.state;
      state.guidedProgression = false;
      state.unlockedBuildings.add('warehouse');

      // Ambarı tamamen doldur
      state.cargoUsed = state.effectiveCargoCapacity;
      expect(state.cargoFull, isTrue);

      final crusherGame = CrusherGame(controller);
      expect(crusherGame.isHalted, isTrue);
      expect(crusherGame.rpm, 0);

      // Kırıcıya 50 ham kömür ekle
      state.addRawOre('coal', 50);

      // Ambar doluyken kırma denemesi başarısız olmalı (0 ürün)
      final yieldResult = state.crushRawOre(oreId: 'coal', amount: 5);
      expect(yieldResult, 0);
      expect(state.rawOreInventory['coal'], 50); // Eksilmedi

      // Simülasyon ilerlese bile ambar dolu olduğu için kırıcı çalışmaz
      GameEngine.advance(state, const Duration(seconds: 2));
      expect(state.rawOreInventory['coal'], 50);

      // Ambara biraz mineral ekleyip satalım ve yer açalım
      state.inventory['coal'] = 100;
      expect(state.cargoFull, isTrue);

      // Oyuncu satış yapar
      final revenue = controller.sellAll();
      expect(revenue.toDouble(), greaterThan(0));
      expect(state.cargoFull, isFalse); // Ambar boşaldı!
      expect(crusherGame.isHalted, isFalse);
      expect(crusherGame.rpm, greaterThan(0));

      // Yer açıldığı için artık kırıcı çalışır
      final newYield = state.crushRawOre(oreId: 'coal', amount: 5);
      expect(newYield, greaterThan(0));
      expect(state.rawOreInventory['coal'], 45); // Kırıldı ve azaldı
    });

    test('Kırıcı dört kaya birikince arka planda çalışmaya başlar', () {
      final state = GameState.newGame();
      state.crusherRepaired = true;
      state.rawOreInventory.clear();
      expect(state.totalRawOreCount, 0);
      final initialMined = state.totalMined;

      // Başlangıçta birkaç kaya haznede birikir.
      GameEngine.advance(
        state,
        const Duration(seconds: 3),
        allowRandomEvents: false,
      );
      expect(state.totalRawOreCount, 3);
      expect(state.totalOreCrushed, 0);

      // Dördüncü kaya gelince bir taş kırılır, üçü haznede kalır.
      GameEngine.advance(
        state,
        const Duration(seconds: 1),
        allowRandomEvents: false,
      );

      expect(state.totalMined, greaterThan(initialMined));
      expect(state.cargoUsed, greaterThan(0));
      expect(state.totalRawOreCount, 3);
      expect(state.totalOreCrushed, 1);
    });

    test('Yıkık istasyon onarılmadan otomatik kırma başlamaz', () {
      final state = GameState.newGame();
      state.addRawOre('coal', 30);
      GameEngine.advance(state, const Duration(seconds: 2));
      expect(state.rawOreInventory['coal'], 30);
      expect(state.crusherRepaired, isFalse);
    });

    test('7 km istasyonu 50 kasaya onarılır ve kayıtla korunur', () {
      final controller = GameController();
      addTearDown(controller.dispose);
      final state = controller.state;
      state.addCoins(50);
      expect(controller.repairCrusherStation(), isFalse);
      state.deepestMeters = 7000;
      expect(state.crusherStationDiscovered, isFalse);
      expect(controller.repairCrusherStation(), isFalse);
      state.deepestMeters = 7999;
      expect(state.crusherStationDiscovered, isFalse);
      state.deepestMeters = 8000;
      expect(state.crusherStationDiscovered, isTrue);
      expect(controller.repairCrusherStation(), isTrue);
      expect(state.coins.toDouble(), 0);
      expect(state.crusherRepaired, isTrue);
      expect(controller.repairCrusherStation(), isFalse);
      expect(GameState.fromJson(state.toJson()).crusherRepaired, isTrue);
    });

    test('Derinlere indikçe konveyör hızı, büyük kaya ihtimali ve nadir maden çeşitliliği artar', () {
      final controller = GameController();
      final state = controller.state;
      state.depthMeters = 1000; // 1 km derinlik
      final gameShallow = CrusherGame(controller);
      final shallowSpeed = gameShallow.conveyorSpeed;
      final shallowLargeChance = gameShallow.largeRockChance;

      // 80 km derinliğe inildiğinde
      state.depthMeters = 80000;
      state.deepestMeters = 80000;
      final gameDeep = CrusherGame(controller);
      final deepSpeed = gameDeep.conveyorSpeed;
      final deepLargeChance = gameDeep.largeRockChance;

      expect(deepSpeed, greaterThan(shallowSpeed));
      expect(deepLargeChance, greaterThan(shallowLargeChance));
    });
  });
}
