import 'package:flutter/material.dart';

import 'crusher_engine.dart';

String crusherColorHex(Color color) =>
    '#${(color.toARGB32() & 0xffffff).toRadixString(16).padLeft(6, '0')}';

Map<String, Object?> crusherSceneSnapshot(CrusherGame game) => {
  'angle': game.rotorAngle,
  'rpm': game.rpm,
  'conveyorSpeed': game.conveyorSpeed,
  'shake': game.shake,
  'skin': game.selectedSkin,
  'level': game.level,
  'rockCapacity': game.rockCapacity,
  'hopperTopY': game.hopperTopY,
  'hopperHalfWidth': game.hopperHalfWidth,
  'cameraHalfHeight': game.sceneCameraHalfHeight,
  'cameraPanX': game.sceneCameraPanX,
  'rollerBase': crusherColorHex(game.rollerBase),
  'rollerLight': crusherColorHex(game.rollerLight),
  'rollerDark': crusherColorHex(game.rollerDark),
  'rocks': game.rocks
      .map(
        (rock) => <String, Object?>{
          'id': rock.seed,
          'x': rock.x,
          'y': rock.y,
          'z': rock.z,
          'rotation': rock.rotation,
          'radius': rock.radius,
          'hp': rock.hp,
          'maxHp': rock.maxHp,
          'inGap': rock.inGap,
          'fractureStage': rock.fractureStage,
          'fractureStages': rock.fractureStages,
          'stageProgress': rock.stageDamage / rock.stageHealth,
          'style': rock.material.visualStyle,
          'color': crusherColorHex(rock.material.color),
          'light': crusherColorHex(rock.material.highlight),
          'dark': crusherColorHex(rock.material.shadow),
          'glow': crusherColorHex(rock.material.glow),
          'isSpecial': rock.isSpecial,
        },
      )
      .toList(growable: false),
  'particles': game.particles
      .map(
        (particle) => <String, Object?>{
          'x': particle.x,
          'y': particle.y,
          'z': particle.z,
          'size': particle.size,
          'life': particle.life,
          'color': crusherColorHex(particle.color),
        },
      )
      .toList(growable: false),
};
