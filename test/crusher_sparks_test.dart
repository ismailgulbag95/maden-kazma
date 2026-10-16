import 'dart:math';
import 'dart:ui' show Color, Offset, Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:tasin_alti/app/game_controller.dart';
import 'package:tasin_alti/crusher/crusher_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'rock fracture keeps dust hits and emits sparks only on a successful break',
    () {
      final controller = GameController();
      addTearDown(controller.dispose);
      final crusher = CrusherGame(controller, random: Random(7));
      addTearDown(crusher.dispose);

      crusher.rocks.clear();
      final rock = CrusherRock(
        material: oreMaterialById('coal'),
        hp: 1,
        maxHp: 1,
        initialRadius: .58,
        fractureStages: 2,
        stageHealth: .5,
        radius: .58,
        x: 6.2,
        y: 4.14 + .58 * .46 + .025,
        onBelt: true,
        isLarge: true,
        seed: 7001,
      );
      crusher.rocks.add(rock);
      final initialRadius = rock.radius;
      crusher.manualPress(rockId: rock.seed);

      expect(rock.fractureStage, 1);
      expect(rock.radius, lessThan(initialRadius));
      expect(crusher.particles, isNotEmpty);
      expect(
        crusher.particles.every(
          (particle) => particle.kind == CrusherParticleKind.dust,
        ),
        isTrue,
        reason: 'A normal fracture hit should retain the existing dust burst.',
      );
      expect(
        crusher.particles.where(
          (particle) => particle.kind == CrusherParticleKind.fragment,
        ),
        isEmpty,
        reason: 'A non-breaking hit must not emit break fragments.',
      );

      final crushedBefore = controller.state.totalOreCrushed;
      var attempts = 0;
      while (controller.state.totalOreCrushed == crushedBefore &&
          attempts < 20) {
        crusher.manualPress(rockId: rock.seed);
        attempts++;
      }

      expect(controller.state.totalOreCrushed, crushedBefore + 1);
      expect(crusher.messageKey, 'crushed');
      expect(crusher.messageAmount, greaterThan(0));
      expect(crusher.rocks, isNot(contains(rock)));
      final sparks = crusher.particles
          .where((particle) => particle.kind == CrusherParticleKind.spark)
          .toList();
      expect(sparks, hasLength(10));
      expect(sparks.every((particle) => particle.life > 0), isTrue);
      expect(sparks.every((particle) => particle.size >= .09), isTrue);

      final fragments = crusher.particles
          .where((particle) => particle.kind == CrusherParticleKind.fragment)
          .toList();
      expect(
        fragments.where((particle) => !particle.isProminent).length,
        inInclusiveRange(1, 2),
      );
      final conveyorShards = fragments
          .where((particle) => particle.isProminent)
          .toList();
      expect(conveyorShards, hasLength(3));
      expect(
        conveyorShards.map((particle) => particle.z).toSet(),
        hasLength(3),
      );
      final conveyorShard = conveyorShards.first;
      expect(conveyorShard.conveyorTargetX, 0);
      expect(conveyorShard.size, lessThan(.09));

      final leftRollerBody = Rect.fromCircle(
        center: const Offset(-.77, .69),
        radius: .68,
      );
      final rightRollerBody = Rect.fromCircle(
        center: const Offset(.77, .69),
        radius: .68,
      );
      var sawApproach = false;
      var sawGapFall = false;
      var steps = 0;
      while (conveyorShards.any((shard) => !shard.onOutputConveyor) &&
          steps < 240) {
        crusher.advanceParticlesForTesting(1 / 60);
        steps++;

        for (final shard in conveyorShards) {
          final visualBounds = Rect.fromCenter(
            center: Offset(shard.x, shard.y),
            width: shard.size * 2,
            height: shard.size * 2,
          );
          expect(
            visualBounds.overlaps(leftRollerBody),
            isFalse,
            reason: 'Output fragments must not pass through the left roller.',
          );
          expect(
            visualBounds.overlaps(rightRollerBody),
            isFalse,
            reason: 'Output fragments must not pass through the right roller.',
          );
          if (shard.approachingRollerGap) {
            sawApproach = true;
            expect(shard.y - shard.size, greaterThan(1.37));
          }
          if (shard.fallingThroughRollerGap) {
            sawGapFall = true;
            expect(shard.x, 0);
            expect(shard.rotation, 0);
            expect(shard.size * 2, lessThan(.18));
          }
        }
      }

      expect(sawApproach, isTrue);
      expect(sawGapFall, isTrue);
      expect(conveyorShards.every((shard) => shard.onOutputConveyor), isTrue);
      for (final shard in conveyorShards) {
        expect(shard.y, closeTo(-.46 + shard.size + .018, 1e-9));
      }

      final landedLives = conveyorShards.map((shard) => shard.life).toList();
      var conveyorSteps = 0;
      while (conveyorShard.x > -4.2 && conveyorSteps < 400) {
        crusher.advanceParticlesForTesting(1 / 60);
        conveyorSteps++;
        if (conveyorShard.x <= -4.2) break;
        for (var index = 0; index < conveyorShards.length; index++) {
          expect(crusher.particles, contains(conveyorShards[index]));
          expect(conveyorShards[index].life, landedLives[index]);
        }
      }
      expect(conveyorSteps, greaterThan(0));
      expect(conveyorShard.x, lessThanOrEqualTo(-4.2));
      expect(
        conveyorShards.every((shard) => !crusher.particles.contains(shard)),
        isTrue,
      );
    },
  );

  test('a rock crushed between rollers sends a shard through the open gap', () {
    final controller = GameController();
    addTearDown(controller.dispose);
    final crusher = CrusherGame(controller, random: Random(18));
    addTearDown(crusher.dispose);

    crusher.rocks.clear();
    final rock = CrusherRock(
      material: oreMaterialById('coal'),
      hp: .01,
      maxHp: .01,
      initialRadius: .30,
      fractureStages: 1,
      stageHealth: .01,
      radius: .30,
      x: 0,
      y: .69,
      seed: 7002,
    );
    crusher.rocks.add(rock);
    crusher.manualPress(rockId: rock.seed);

    final shards = crusher.particles
        .where((particle) => particle.isProminent)
        .toList();
    expect(shards, hasLength(3));
    final shard = shards.first;
    expect(shard.x, 0);
    expect(shard.y - shard.size, greaterThan(.69 + .68 + .02));
    expect(shard.fallingThroughRollerGap, isTrue);

    final leftRollerBody = Rect.fromCircle(
      center: const Offset(-.77, .69),
      radius: .68,
    );
    final rightRollerBody = Rect.fromCircle(
      center: const Offset(.77, .69),
      radius: .68,
    );
    var steps = 0;
    while (shards.any((shard) => !shard.onOutputConveyor) && steps < 240) {
      crusher.advanceParticlesForTesting(1 / 60);
      steps++;
      for (final shard in shards) {
        final bounds = Rect.fromCenter(
          center: Offset(shard.x, shard.y),
          width: shard.size * 2,
          height: shard.size * 2,
        );
        expect(bounds.overlaps(leftRollerBody), isFalse);
        expect(bounds.overlaps(rightRollerBody), isFalse);
      }
    }
    expect(shards.every((shard) => shard.onOutputConveyor), isTrue);
    expect(shard.y, closeTo(-.46 + shard.size + .018, 1e-9));
  });

  test(
    'fracture effect particles bounce off glass without changing expiry',
    () {
      final controller = GameController();
      addTearDown(controller.dispose);
      final crusher = CrusherGame(controller, random: Random(27));
      addTearDown(crusher.dispose);
      crusher.particles.clear();

      final particles = [
        CrusherParticle(
          x: 1.35,
          y: .8,
          z: 0,
          vx: 2,
          vy: 0,
          vz: 0,
          color: const Color(0xffffcc66),
          size: .06,
          life: .8,
          kind: CrusherParticleKind.dust,
        ),
        CrusherParticle(
          x: 1.57,
          y: 3.0,
          z: 0,
          vx: 2,
          vy: 0,
          vz: 0,
          color: const Color(0xffff8833),
          size: .06,
          life: .9,
          kind: CrusherParticleKind.spark,
        ),
        CrusherParticle(
          x: -1.35,
          y: .8,
          z: 0,
          vx: -2,
          vy: 0,
          vz: 0,
          color: const Color(0xffaaaaaa),
          size: .06,
          life: 1,
          kind: CrusherParticleKind.fragment,
        ),
      ];
      crusher.particles.addAll(particles);

      crusher.advanceParticlesForTesting(.05);

      expect(particles[0].x, lessThan(1.45));
      expect(particles[0].vx, closeTo(-.9, 1e-9));
      expect(particles[1].x, lessThan(1.67));
      expect(particles[1].vx, closeTo(-.9, 1e-9));
      expect(particles[2].x, greaterThan(-1.45));
      expect(particles[2].vx, closeTo(.9, 1e-9));
      expect(particles[0].life, closeTo(.75, 1e-9));
      expect(particles[1].life, closeTo(.85, 1e-9));
      expect(particles[2].life, closeTo(.95, 1e-9));
    },
  );
}
