import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tasin_alti/app/game_controller.dart';
import 'package:tasin_alti/crusher/crusher_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('successful fractures create recursive, breakable rock generations', () {
    final controller = GameController();
    addTearDown(controller.dispose);
    final crusher = CrusherGame(controller, random: Random(9));
    addTearDown(crusher.dispose);
    crusher.rocks.clear();

    final material = oreMaterialById('coal');
    final root = _rock(
      material: material,
      seed: 1,
      generation: 0,
      radius: 1.2,
      isLarge: true,
    );
    crusher.rocks.add(root);
    final baselineCrushed = controller.state.totalOreCrushed;
    final baselineInventory = controller.state.inventory['coal'] ?? 0;

    var current = root;
    var splitCount = 0;
    while (true) {
      final scaledRadius = current.initialRadius * .58;
      final expectedChildRadius = scaledRadius < .14 ? .14 : scaledRadius;
      final nextGeneration = current.generation + 1;
      final nextGenerationBefore = crusher.rocks
          .where((rock) => rock.generation == nextGeneration)
          .length;

      _break(crusher, current);

      final descendants = crusher.rocks
          .where((rock) => rock.generation == nextGeneration)
          .toList();
      final newlyCreated = descendants.length - nextGenerationBefore;
      expect(
        descendants.every(
          (rock) => identical(rock.rewardLineage, root.rewardLineage),
        ),
        isTrue,
        reason: 'Every live child must share its parent lineage budget.',
      );
      expect(
        descendants.every((rock) => rock.initialRadius < current.initialRadius),
        isTrue,
        reason: 'Each generation must be physically smaller than its parent.',
      );
      _expectSeparatedRow(descendants, minimumX: .42, maximumX: 6.4);
      expect(crusher.rocks.length, lessThanOrEqualTo(crusher.liveRockCapacity));

      if (current.initialRadius <= .14 || current.generation >= 8) {
        expect(newlyCreated, 0, reason: 'A terminal rock must stop splitting.');
        break;
      }

      expect(
        newlyCreated,
        inInclusiveRange(2, 3),
        reason: 'An eligible fracture must produce two or three live rocks.',
      );
      expect(
        descendants.every(
          (rock) => (rock.initialRadius - expectedChildRadius).abs() < 1e-9,
        ),
        isTrue,
        reason:
            'Children clamp to the terminal chip radius instead of vanishing.',
      );
      expect(
        descendants
            .where(
              (rock) =>
                  identical(rock.rewardLineage, root.rewardLineage) &&
                  rock.generation == nextGeneration,
            )
            .every((rock) => rock.hp > 0 && rock.fractureStages > 0),
        isTrue,
        reason: 'New pieces must remain valid, breakable CrusherRock objects.',
      );

      splitCount++;
      current = descendants.first;
    }

    expect(splitCount, greaterThanOrEqualTo(4));
    expect(controller.state.totalOreCrushed, baselineCrushed + 1);
    expect(controller.state.inventory['coal'], greaterThan(baselineInventory));
    expect(
      root.rewardLineage.rewardClaimed,
      isTrue,
      reason: 'The lineage payout is claimed exactly once across generations.',
    );
  });

  test('live-rock cap backpressures a fracture until two slots open', () {
    final controller = GameController();
    addTearDown(controller.dispose);
    controller.state.crusherUpgrades['storage'] = 100;
    final crusher = CrusherGame(controller, random: Random(12));
    addTearDown(crusher.dispose);
    crusher.rocks.clear();

    final material = oreMaterialById('coal');
    final source = _rock(
      material: material,
      seed: 2,
      generation: 0,
      radius: .9,
    );
    crusher.rocks.add(source);
    final fillers = <CrusherRock>[];
    while (crusher.rocks.length < crusher.liveRockCapacity) {
      final filler = _rock(
        material: material,
        seed: 100 + crusher.rocks.length,
        generation: 0,
        radius: .5,
      );
      fillers.add(filler);
      crusher.rocks.add(filler);
    }
    final cap = crusher.liveRockCapacity;

    crusher.manualPress(rockId: source.seed);
    expect(crusher.rocks, contains(source));
    expect(source.rewardLineage.rewardClaimed, isFalse);
    expect(
      crusher.rocks.where((rock) => rock.generation == 1),
      isEmpty,
      reason: 'One free slot must not consume the parent or its reward.',
    );

    crusher.rocks.remove(fillers[0]);
    crusher.rocks.remove(fillers[1]);
    _break(crusher, source);

    expect(crusher.rocks.length, lessThanOrEqualTo(cap));
    expect(
      crusher.rocks.where((rock) => rock.generation == 1).length,
      inInclusiveRange(2, 3),
      reason: 'Once slots open, the retry must produce two or three children.',
    );
    expect(source.rewardLineage.rewardClaimed, isTrue);
  });

  test('chamber children shift together and stay apart at a side wall', () {
    final controller = GameController();
    addTearDown(controller.dispose);
    final crusher = CrusherGame(controller, random: Random(23));
    addTearDown(crusher.dispose);
    crusher.rocks.clear();

    final source = _rock(
      material: oreMaterialById('coal'),
      seed: 4,
      generation: 0,
      radius: .9,
      x: 1.9,
      y: 2.2,
      onBelt: false,
    );
    crusher.rocks.add(source);
    crusher.manualPress(rockId: source.seed);

    final children = crusher.rocks
        .where((rock) => rock.generation == 1)
        .toList();
    expect(children.length, inInclusiveRange(2, 3));
    _expectSeparatedRow(children, minimumX: -1.95, maximumX: 1.95);
  });

  test('full raw hopper preserves an unclaimed fracture for retry', () {
    final controller = GameController();
    addTearDown(controller.dispose);
    final crusher = CrusherGame(controller, random: Random(18));
    addTearDown(crusher.dispose);
    crusher.rocks.clear();

    controller.state.addRawOre(
      'copper',
      controller.state.crusherHopperCapacity,
    );
    final source = _rock(
      material: oreMaterialById('coal'),
      seed: 3,
      generation: 0,
      radius: .9,
    );
    crusher.rocks.add(source);

    crusher.manualPress(rockId: source.seed);
    expect(crusher.rocks, contains(source));
    expect(source.rewardLineage.rewardClaimed, isFalse);
    expect(crusher.rocks.where((rock) => rock.generation == 1), isEmpty);

    controller.state.rawOreInventory['copper'] =
        controller.state.crusherHopperCapacity - 1;
    _break(crusher, source);
    expect(source.rewardLineage.rewardClaimed, isTrue);
    expect(
      crusher.rocks.where((rock) => rock.generation == 1).length,
      inInclusiveRange(2, 3),
    );
  });
}

CrusherRock _rock({
  required OreMaterial material,
  required int seed,
  required int generation,
  required double radius,
  bool isLarge = false,
  double x = 6.2,
  double? y,
  bool onBelt = true,
}) => CrusherRock(
  material: material,
  hp: .1,
  maxHp: .1,
  initialRadius: radius,
  fractureStages: 1,
  stageHealth: .01,
  radius: radius,
  x: x,
  y: y ?? 4.14 + radius * .46 + .025,
  onBelt: onBelt,
  isLarge: isLarge,
  generation: generation,
  seed: seed,
);

void _expectSeparatedRow(
  List<CrusherRock> rocks, {
  required double minimumX,
  required double maximumX,
}) {
  if (rocks.isEmpty) return;
  final sortedX = rocks.map((rock) => rock.x).toList()..sort();
  final spacing = max(.30, rocks.first.initialRadius * 2.1);
  expect(sortedX.toSet(), hasLength(sortedX.length));
  expect(sortedX.first, greaterThanOrEqualTo(minimumX));
  expect(sortedX.last, lessThanOrEqualTo(maximumX));
  for (var index = 1; index < sortedX.length; index++) {
    expect(
      sortedX[index] - sortedX[index - 1],
      closeTo(spacing, 1e-9),
      reason: 'Adjacent children need more than their visible radius of room.',
    );
  }
}

void _break(CrusherGame crusher, CrusherRock rock) {
  var attempts = 0;
  while (crusher.rocks.contains(rock) && attempts < 12) {
    crusher.manualPress(rockId: rock.seed);
    attempts++;
  }
  expect(
    crusher.rocks,
    isNot(contains(rock)),
    reason: 'The test rock should fracture after a bounded number of presses.',
  );
}
