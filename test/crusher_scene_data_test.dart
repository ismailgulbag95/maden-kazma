import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tasin_alti/app/game_controller.dart';
import 'package:tasin_alti/crusher/crusher_engine.dart';
import 'package:tasin_alti/crusher/crusher_scene_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('crusher scene snapshot preserves fragment path and conveyor state', () {
    final controller = GameController();
    addTearDown(controller.dispose);
    final game = CrusherGame(controller);
    addTearDown(game.dispose);

    final shard = CrusherParticle(
      x: .4,
      y: -.46,
      z: .12,
      vx: .3,
      vy: -.1,
      vz: .02,
      color: const Color(0xffbc6735),
      size: .08,
      life: 3.2,
      kind: CrusherParticleKind.fragment,
      onOutputConveyor: true,
      isProminent: true,
      conveyorTargetX: .4,
      rotation: .25,
      vRotation: -.5,
    );
    game.particles.add(shard);

    final rocks = (crusherSceneSnapshot(game)['rocks']! as List)
        .cast<Map<String, Object?>>();
    expect(rocks, isNotEmpty);
    expect(rocks.first, containsPair('oreId', 'coal'));

    final particles = (crusherSceneSnapshot(game)['particles']! as List)
        .cast<Map<String, Object?>>();
    expect(particles, hasLength(1));
    expect(particles.single, containsPair('kind', 'fragment'));
    expect(particles.single, containsPair('x', .4));
    expect(particles.single, containsPair('y', -.46));
    expect(particles.single, containsPair('z', .12));
    expect(particles.single, containsPair('vx', .3));
    expect(particles.single, containsPair('vy', -.1));
    expect(particles.single, containsPair('vz', .02));
    expect(particles.single, containsPair('size', .08));
    expect(particles.single, containsPair('life', 3.2));
    expect(particles.single, containsPair('rotation', .25));
    expect(particles.single, containsPair('vRotation', -.5));
    expect(particles.single, containsPair('isProminent', true));
    expect(particles.single, containsPair('approachingRollerGap', false));
    expect(particles.single, containsPair('fallingThroughRollerGap', false));
    expect(particles.single, containsPair('onOutputConveyor', true));
    expect(particles.single, containsPair('conveyorTargetX', .4));
    expect(particles.single, containsPair('color', '#bc6735'));
  });
}
