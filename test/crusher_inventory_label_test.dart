import 'package:flutter_test/flutter_test.dart';
import 'package:tasin_alti/app/game_controller.dart';
import 'package:tasin_alti/crusher/crusher_engine.dart';
import 'package:tasin_alti/crusher/localization.dart';
import 'package:tasin_alti/domain/models/mr_mine_progression.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every progression ore has localized names for both languages', () {
    for (final ore in MrMineProgression.minerals) {
      expect(
        gameText('tr', ore.resourceId),
        isNot(ore.resourceId),
        reason: 'Missing Turkish name for ${ore.resourceId}',
      );
      expect(
        gameText('en', ore.resourceId),
        isNot(ore.resourceId),
        reason: 'Missing English name for ${ore.resourceId}',
      );
    }
  });

  test('ore labels use language-aware uppercase rules', () {
    expect(gameUppercase('tr', gameText('tr', 'black_opal')), 'SİYAH OPAL');
    expect(
      gameUppercase('tr', gameText('tr', 'lunar_titanium')),
      'AY TİTANYUMU',
    );
    expect(gameUppercase('en', gameText('en', 'red_diamond')), 'RED DIAMOND');
  });

  test('crusher label material comes from the most valuable stocked ore', () {
    final controller = GameController();
    addTearDown(controller.dispose);
    final crusher = CrusherGame(controller);
    addTearDown(crusher.dispose);

    controller.state.rawOreInventory
      ..clear()
      ..addAll({'coal': 200, 'copper': 7, 'silver': 0, 'gold': 2});

    expect(crusher.mostValuableRawOre?.id, 'gold');
    expect(gameText('tr', 'mostValuableOre'), 'EN DEĞERLİ CEVHER');
    expect(gameText('en', 'mostValuableOre'), 'MOST VALUABLE ORE');
    expect(gameText('tr', 'gold'), 'Altın');
    expect(gameText('en', 'gold'), 'Gold');

    controller.state.rawOreInventory
      ..clear()
      ..addAll({'coal': 20, 'copper': 1});
    expect(crusher.mostValuableRawOre?.id, 'copper');

    controller.state.rawOreInventory.clear();
    expect(crusher.mostValuableRawOre, isNull);
    expect(gameText('tr', 'noOre'), 'CEVHER YOK');
    expect(gameText('en', 'noOre'), 'NO ORE');
  });
}
