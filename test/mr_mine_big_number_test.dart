import 'package:flutter_test/flutter_test.dart';
import 'package:tasin_alti/domain/models/game_state.dart';
import 'package:tasin_alti/domain/models/mr_mine_big_number.dart';
import 'package:tasin_alti/domain/models/quest_definition.dart';
import 'package:tasin_alti/domain/simulation/game_engine.dart';

void main() {
  group('MrMineBigNumber - first-party BigNumber.js reference tests', () {
    test('value assignment and normalization match source', () {
      final a = MrMineBigNumber(1);
      expect(a.coefficient, 1.0);
      expect(a.exponent, 0);

      final b = MrMineBigNumber(10);
      expect(b.coefficient, 1.0);
      expect(b.exponent, 1);

      final c = MrMineBigNumber(0.1);
      expect(c.coefficient, 1.0);
      expect(c.exponent, -1);

      final d = MrMineBigNumber(-0.1);
      expect(d.coefficient, -1.0);
      expect(d.exponent, -1);

      final e = MrMineBigNumber.fromString('123456789');
      expect(e.coefficient, 1.23456789);
      expect(e.exponent, 8);

      final f = MrMineBigNumber.fromString('432e38');
      expect(f.coefficient, 4.32);
      expect(f.exponent, 40);

      final g = MrMineBigNumber.fromParts(1.5, 10);
      expect(g.coefficient, 1.5);
      expect(g.exponent, 10);
    });

    test('comparisons match source', () {
      final a = MrMineBigNumber(1);
      final b = MrMineBigNumber(1);
      expect(a.equals(b), isTrue);
      expect(b.equals(a), isTrue);
      expect(a == b, isTrue);

      final c = MrMineBigNumber(123456789);
      final d = MrMineBigNumber.fromParts(1.23456789, 8);
      expect(c.equals(d), isTrue);
      expect(d.equals(c), isTrue);
      expect(c < d, isFalse);
      expect(d < c, isFalse);
      expect(c > d, isFalse);
      expect(d > c, isFalse);
      expect(c <= d, isTrue);
      expect(c >= d, isTrue);

      final e = MrMineBigNumber(123);
      final f = MrMineBigNumber(12);
      expect(e.equals(f), isFalse);
      expect(f.equals(e), isFalse);
      expect(e < f, isFalse);
      expect(f < e, isTrue);
      expect(e > f, isTrue);
      expect(f > e, isFalse);

      final g = MrMineBigNumber(-9999999999999);
      final h = MrMineBigNumber(1);
      expect(g.equals(h), isFalse);
      expect(h.equals(g), isFalse);
      expect(g < h, isTrue);
      expect(h < g, isFalse);
      expect(g > h, isFalse);
      expect(h > g, isTrue);
    });

    test('arithmetic matches source testBigNumbers suite', () {
      final a = MrMineBigNumber(1234);
      final b = MrMineBigNumber(200);

      expect(a.add(b), MrMineBigNumber(1434));
      expect(a + b, MrMineBigNumber(1434));
      expect(a.subtract(b), MrMineBigNumber(1034));
      expect(a - b, MrMineBigNumber(1034));
      expect(a.multiply(b), MrMineBigNumber(246800));
      expect(a * b, MrMineBigNumber(246800));
      expect(a.divide(b), MrMineBigNumber.fromParts(6.17, 0));
      expect(a / b, MrMineBigNumber.fromParts(6.17, 0));
      expect(a.invert().equals(MrMineBigNumber(1.0 / 1234)), isTrue);
      expect(a.negate(), MrMineBigNumber(-1234));
      expect(-a, MrMineBigNumber(-1234));

      final c = MrMineBigNumber(16);
      expect(c.add(MrMineBigNumber(14)), MrMineBigNumber(30));
      expect(c.subtract(MrMineBigNumber(8)), MrMineBigNumber(8));
      expect(c.multiply(MrMineBigNumber(4)), MrMineBigNumber(64));
      expect(c.divide(MrMineBigNumber(99)), MrMineBigNumber(16.0 / 99.0));
      expect(c.invert(), MrMineBigNumber(1.0 / 16.0));
      expect(c.negate(), MrMineBigNumber(-16));
    });

    test('precision cutoff (>10 exponent difference) drops small addition', () {
      final big = MrMineBigNumber.fromParts(1.0, 15); // 10^15
      final smallDropped = MrMineBigNumber.fromParts(1.0, 4); // 10^4 (diff = 11 > 10)
      final smallKept = MrMineBigNumber.fromParts(1.0, 5); // 10^5 (diff = 10 <= 10)

      // powerDifference > 10 drops addition completely
      expect(big.add(smallDropped), big);
      expect(smallDropped.add(big), big);
      expect(big.subtract(smallDropped), big);

      // powerDifference == 10 keeps addition
      final sumKept = big.add(smallKept);
      expect(sumKept, isNot(equals(big)));
      expect(sumKept.coefficient, closeTo(1.0000000001, 1e-10));
      expect(sumKept.exponent, 15);
    });

    test('numbers beyond double.maxFinite (>1.79e308) compute accurately', () {
      final hugeA = MrMineBigNumber.fromString('4.5e400');
      final hugeB = MrMineBigNumber.fromString('1.5e400');

      expect(hugeA.exponent, 400);
      expect(hugeA.coefficient, 4.5);
      expect(hugeA > hugeB, isTrue);

      final sum = hugeA + hugeB;
      expect(sum.coefficient, 6.0);
      expect(sum.exponent, 400);

      final diff = hugeA - hugeB;
      expect(diff.coefficient, 3.0);
      expect(diff.exponent, 400);

      final product = hugeA * MrMineBigNumber(2);
      expect(product.coefficient, 9.0);
      expect(product.exponent, 400);

      final quotient = hugeA / MrMineBigNumber(3);
      expect(quotient.coefficient, 1.5);
      expect(quotient.exponent, 400);

      // Even higher exponents
      final superHuge = MrMineBigNumber.fromString('2.5e1000');
      expect(superHuge.exponent, 1000);
      expect(superHuge.coefficient, 2.5);
      expect(superHuge > hugeA, isTrue);
    });

    test('floor and ceiling match source behavior and return zero outside (-15, 15)', () {
      final a = MrMineBigNumber(12.7);
      expect(a.floor(), MrMineBigNumber(12));
      expect(a.ceiling(), MrMineBigNumber(13));
      expect(a.round(), MrMineBigNumber(13));

      final b = MrMineBigNumber(12.2);
      expect(b.round(), MrMineBigNumber(12));

      // Exponent >= 15 returns zero in official source
      final bigExp = MrMineBigNumber.fromParts(1.5, 15);
      expect(bigExp.floor(), MrMineBigNumber.zero);
      expect(bigExp.ceiling(), MrMineBigNumber.zero);

      // Exponent <= -15 returns zero in official source
      final smallExp = MrMineBigNumber.fromParts(1.5, -15);
      expect(smallExp.floor(), MrMineBigNumber.zero);
      expect(smallExp.ceiling(), MrMineBigNumber.zero);
    });

    test('parse rejects invalid input including bare dot and missing digits', () {
      expect(() => MrMineBigNumber.parse('.'), throwsFormatException);
      expect(() => MrMineBigNumber.parse('+.'), throwsFormatException);
      expect(() => MrMineBigNumber.parse('-.'), throwsFormatException);
      expect(() => MrMineBigNumber.parse('.e5'), throwsFormatException);
      expect(() => MrMineBigNumber.parse('e5'), throwsFormatException);
      expect(() => MrMineBigNumber.parse('1.2.3'), throwsFormatException);
      expect(() => MrMineBigNumber.parse(''), throwsFormatException);
      expect(() => MrMineBigNumber.parse('   '), throwsFormatException);
      expect(() => MrMineBigNumber.parse('abc'), throwsFormatException);

      // Valid cases
      expect(MrMineBigNumber.parse('1.'), MrMineBigNumber(1));
      expect(MrMineBigNumber.parse('.5'), MrMineBigNumber(0.5));
      expect(MrMineBigNumber.parse('0'), MrMineBigNumber.zero);
      expect(MrMineBigNumber.parse('100'), MrMineBigNumber(100));
    });

    test('exact equals and hashCode match source without tolerance divergence', () {
      final a = MrMineBigNumber.fromParts(1.23456789, 8);
      final b = MrMineBigNumber.fromParts(1.23456789, 8);
      expect(a.equals(b), isTrue);
      expect(a == b, isTrue);
      expect(a.hashCode, equals(b.hashCode));

      final c = MrMineBigNumber.fromParts(1.234567890000001, 8);
      expect(a.equals(c), isFalse);
      expect(a == c, isFalse);
    });

    test('source display toString semantics and lossless toJson save round-trip', () {
      // Source display semantics
      expect(MrMineBigNumber.zero.toString(), '0');
      expect(MrMineBigNumber(100).toString(), '100');
      expect(MrMineBigNumber.fromParts(1.5, 18).toString(), '1500000000000000000');
      // Values < 1 produce '0' in source display toString because floor(toFloat(15)) is 0
      expect(MrMineBigNumber(0.5).toString(), '0');

      // Lossless persistence round-trip via toJson / fromJson for huge money values
      final numbers = [
        MrMineBigNumber.zero,
        MrMineBigNumber(1),
        MrMineBigNumber(240),
        MrMineBigNumber(123456789),
        MrMineBigNumber.fromParts(1.5, 18),
        MrMineBigNumber.fromParts(4.32, 40),
        MrMineBigNumber.fromString('4.5e400'),
        MrMineBigNumber.fromString('2.5e1000'),
      ];

      for (final n in numbers) {
        final json = n.toJson();
        final fromJson = MrMineBigNumber.fromJson(json);
        expect(fromJson, equals(n), reason: 'Failed round-trip for $n -> $json');
        expect(fromJson == n, isTrue);
        expect(fromJson.hashCode, equals(n.hashCode));
      }

      // Legacy num fromJson
      expect(MrMineBigNumber.fromJson(240), MrMineBigNumber(240));
      expect(MrMineBigNumber.fromJson(100.5), MrMineBigNumber(100.5));
      expect(MrMineBigNumber.fromJson('1000'), MrMineBigNumber(1000));
    });
  });

  group('GameState money and save migration with MrMineBigNumber', () {
    test('GameState defaults to 240 BigNumber coins and newGame defaults to 0', () {
      final stateDefault = GameState();
      expect(stateDefault.coins, MrMineBigNumber(240));

      final stateNew = GameState.newGame();
      expect(stateNew.coins, MrMineBigNumber.zero);
    });

    test('addCoins, spendCoins, and canAfford operate safely at huge values >1e308', () {
      final state = GameState(coins: MrMineBigNumber.fromString('5.0e400'));

      // canAfford checks
      expect(state.canAfford(MrMineBigNumber.fromString('4.0e400')), isTrue);
      expect(state.canAfford(MrMineBigNumber.fromString('6.0e400')), isFalse);
      expect(state.canAfford(1000), isTrue);

      // addCoins at > 1e308
      state.addCoins(MrMineBigNumber.fromString('1.0e400'));
      expect(state.coins, MrMineBigNumber.fromString('6.0e400'));

      // spendCoins at > 1e308
      final spent = state.spendCoins(MrMineBigNumber.fromString('2.5e400'));
      expect(spent, isTrue);
      expect(state.coins, MrMineBigNumber.fromString('3.5e400'));

      // spendCoins over budget fails
      final overSpent = state.spendCoins(MrMineBigNumber.fromString('1.0e401'));
      expect(overSpent, isFalse);
      expect(state.coins, MrMineBigNumber.fromString('3.5e400'));

      // debug money overrides affordability and spending
      state.debugModeEnabled = true;
      state.debugUnlimitedMoney = true;
      expect(state.canAfford(MrMineBigNumber.fromString('1.0e500')), isTrue);
      expect(state.spendCoins(MrMineBigNumber.fromString('1.0e500')), isTrue);
      expect(state.coins, MrMineBigNumber.fromString('3.5e400')); // unmodified in debug mode
    });

    test('save migration reads legacy numeric coins and new string coins without data loss', () {
      // Legacy numeric save (e.g. coins: 1500)
      final legacyJson = <String, Object?>{
        'schema': 20,
        'coins': 1500,
        'depthMeters': 1200.0,
      };
      final stateFromLegacy = GameState.fromJson(legacyJson);
      expect(stateFromLegacy.coins, MrMineBigNumber(1500));

      // Modern string save (e.g. coins: "4.5e400")
      final modernJson = <String, Object?>{
        'schema': 20,
        'coins': '4.5e400',
        'depthMeters': 50000.0,
      };
      final stateFromModern = GameState.fromJson(modernJson);
      expect(stateFromModern.coins, MrMineBigNumber.fromString('4.5e400'));

      // Round-trip serialization produces scientific string and restores exactly
      final serialized = stateFromModern.toJson();
      expect(serialized['coins'], '4.5e400');

      final roundTripped = GameState.fromJson(serialized);
      expect(roundTripped.coins, stateFromModern.coins);
      expect(roundTripped.coins.exponent, 400);
      expect(roundTripped.coins.coefficient, 4.5);
    });

    test('totalSold save migration handles legacy num and modern scientific string', () {
      // Legacy numeric totalSold
      final legacyJson = <String, Object?>{
        'schema': 20,
        'coins': 1000,
        'totalSold': 250000,
      };
      final stateLegacy = GameState.fromJson(legacyJson);
      expect(stateLegacy.totalSold, MrMineBigNumber(250000));

      // Modern string totalSold (> 1e308)
      final modernJson = <String, Object?>{
        'schema': 20,
        'coins': '1.0e10',
        'totalSold': '8.75e350',
      };
      final stateModern = GameState.fromJson(modernJson);
      expect(stateModern.totalSold, MrMineBigNumber.fromString('8.75e350'));

      // Round-trip serialization
      final serialized = stateModern.toJson();
      expect(serialized['totalSold'], '8.75e350');
      final roundTripped = GameState.fromJson(serialized);
      expect(roundTripped.totalSold, stateModern.totalSold);
    });

    test('QuestKind.sell clamps giant totalSold safely without integer overflow', () {
      const sellQuest = QuestDefinition(
        id: 1,
        chapter: 1,
        title: 'Satış Testi',
        description: 'Test',
        kind: QuestKind.sell,
        target: 1000,
        reward: 10,
      );

      final state = GameState(
        totalSold: MrMineBigNumber.fromString('5.2e40'),
      );
      expect(state.progressFor(sellQuest), 1000000000);

      final stateSmall = GameState(
        totalSold: MrMineBigNumber(350),
      );
      expect(stateSmall.progressFor(sellQuest), 350);
    });
  });

  group('GameEngine sale routes and BigNumber revenue aggregation', () {
    test('sellResource calculates revenue with chained BigNumber factors and updates totalSold', () {
      final state = GameState.newGame();
      state.inventory['coal'] = 500;

      final revenue = GameEngine.sellResource(state, 'coal', requested: 200);
      // coal baseValue = 1.0; 200 * 1 = 200
      expect(revenue, MrMineBigNumber(200));
      expect(state.coins, MrMineBigNumber(200));
      expect(state.totalSold, MrMineBigNumber(200));
      expect(state.amount('coal'), 300);
    });

    test('sellAll aggregates values accurately using BigNumber addition', () {
      final state = GameState.newGame();
      state.inventory['coal'] = 100; // 100 * 1 = 100
      state.inventory['copper'] = 50; // 50 * 2 = 100

      final totalRevenue = GameEngine.sellAll(state);
      expect(totalRevenue, MrMineBigNumber(200));
      expect(state.coins, MrMineBigNumber(200));
      expect(state.totalSold, MrMineBigNumber(200));
      expect(state.amount('coal'), 0);
      expect(state.amount('copper'), 0);
    });
  });
}
