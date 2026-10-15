import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/game_controller.dart';
import '../domain/models/game_state.dart';
import '../domain/models/mr_mine_big_number.dart';

const _rockGeometryRadius = .46;
const _beltSurfaceY = 4.14;
const _beltRightX = 6.2;
const _conveyorDropX = .42;
const _baseConveyorSpeed = 1.35;
const _rollerCenterX = .77;
const _rollerCenterY = .69;
const _rollerRadius = .68;
const _rollerGapWidth = .18;
const _chamberNeckHalfWidth = _rollerCenterX + _rollerRadius;
const _chamberNeckY = 1.52;
const _outletFunnelTopY = .23;
const _outletFunnelBottomY = -.28;
const _outletFunnelTopHalfWidth = .96;
const _outletHalfWidth = .34;
const _outletCaptureHalfWidth = .58;
const _outletFunnelBottomHalfDepth = .455;
const _outputBeltSurfaceY = -.46;
const _outputBeltSpeed = 2.45;
const _outputBeltAngle = .42;
const _mineGroundY = -1.05;
const _cameraHalfHeight = 3.12;
const _portraitCameraHalfWidth = 3.7;
const _portraitCameraPanX = 0.0;
const _cameraRightX = .934;
const _cameraRightZ = -.356;

class OreMaterial {
  const OreMaterial({
    required this.id,
    required this.name,
    required this.level,
    required this.health,
    required this.value,
    required this.xp,
    required this.radius,
    required this.color,
    required this.highlight,
    required this.shadow,
    required this.glow,
    required this.visualStyle,
  });

  final String id;
  final String name;
  final int level;
  final double health;
  final int value;
  final int xp;
  final double radius;
  final Color color;
  final Color highlight;
  final Color shadow;
  final Color glow;
  final String visualStyle;
}

const oreMaterials = <OreMaterial>[
  OreMaterial(
    id: 'coal',
    name: 'Kömür',
    level: 1,
    health: 1.0,
    value: 6,
    xp: 10,
    radius: .34,
    color: Color(0xff39363a),
    highlight: Color(0xff6e6770),
    shadow: Color(0xff18171a),
    glow: Color(0xff575259),
    visualStyle: 'basalt',
  ),
  OreMaterial(
    id: 'copper',
    name: 'Bakır',
    level: 2,
    health: 1.4,
    value: 14,
    xp: 18,
    radius: .36,
    color: Color(0xffcb7337),
    highlight: Color(0xffffb075),
    shadow: Color(0xff69310e),
    glow: Color(0xffff8f45),
    visualStyle: 'granite',
  ),
  OreMaterial(
    id: 'silver',
    name: 'Gümüş',
    level: 5,
    health: 2.0,
    value: 32,
    xp: 35,
    radius: .35,
    color: Color(0xffbfc7d5),
    highlight: Color(0xffffffff),
    shadow: Color(0xff5f697a),
    glow: Color(0xffe8f1ff),
    visualStyle: 'quartz',
  ),
  OreMaterial(
    id: 'gold',
    name: 'Altın',
    level: 10,
    health: 2.8,
    value: 75,
    xp: 65,
    radius: .38,
    color: Color(0xfffab617),
    highlight: Color(0xfffff099),
    shadow: Color(0xff7a5300),
    glow: Color(0xffffd043),
    visualStyle: 'topaz',
  ),
  OreMaterial(
    id: 'platinum',
    name: 'Platin',
    level: 16,
    health: 3.8,
    value: 160,
    xp: 110,
    radius: .38,
    color: Color(0xff77abb7),
    highlight: Color(0xffe5ffff),
    shadow: Color(0xff2d4e56),
    glow: Color(0xffa1f2ff),
    visualStyle: 'quartz',
  ),
  OreMaterial(
    id: 'diamond',
    name: 'Elmas',
    level: 22,
    health: 5.2,
    value: 360,
    xp: 190,
    radius: .40,
    color: Color(0xff4dc0e8),
    highlight: Color(0xffe0f8ff),
    shadow: Color(0xff124f63),
    glow: Color(0xff8be5ff),
    visualStyle: 'sapphire',
  ),
  OreMaterial(
    id: 'coltan',
    name: 'Koltan',
    level: 30,
    health: 6.8,
    value: 750,
    xp: 320,
    radius: .42,
    color: Color(0xff57456d),
    highlight: Color(0xffbfa2e3),
    shadow: Color(0xff271b36),
    glow: Color(0xff9971c7),
    visualStyle: 'amethyst',
  ),
  OreMaterial(
    id: 'painite',
    name: 'Paynit',
    level: 40,
    health: 9.0,
    value: 1800,
    xp: 600,
    radius: .44,
    color: Color(0xffa82939),
    highlight: Color(0xffff808f),
    shadow: Color(0xff4a0a13),
    glow: Color(0xffff3b53),
    visualStyle: 'ruby',
  ),
];

OreMaterial oreMaterialById(String id) {
  for (final material in oreMaterials) {
    if (material.id == id) return material;
  }
  return oreMaterials.first;
}

class CrusherRock {
  CrusherRock({
    required this.material,
    required this.hp,
    required this.maxHp,
    required this.initialRadius,
    required this.fractureStages,
    required this.stageHealth,
    required this.radius,
    required this.x,
    required this.y,
    this.z = 0,
    this.vx = 0,
    this.vy = 0,
    this.vz = 0,
    this.rotation = 0,
    this.vRot = 0,
    this.onBelt = false,
    this.falling = false,
    this.inGap = false,
    this.onOutputConveyor = false,
    this.passedRollers = false,
    this.fractureStage = 0,
    this.stageDamage = 0,
    this.isSpecial = false,
    this.isLarge = false,
    required this.seed,
  });

  final OreMaterial material;
  double hp;
  final double maxHp;
  final double initialRadius;
  final int fractureStages;
  final double stageHealth;
  double radius;
  double x;
  double y;
  double z;
  double vx;
  double vy;
  double vz;
  double rotation;
  double vRot;
  bool onBelt;
  bool falling;
  bool inGap;
  bool onOutputConveyor;
  bool passedRollers;
  int fractureStage;
  double stageDamage;
  final bool isSpecial;
  final bool isLarge;
  final int seed;
}

class CrusherParticle {
  CrusherParticle({
    required this.x,
    required this.y,
    required this.z,
    required this.vx,
    required this.vy,
    required this.vz,
    required this.color,
    required this.size,
    required this.life,
    this.onOutputConveyor = false,
  });

  double x;
  double y;
  double z;
  double vx;
  double vy;
  double vz;
  final Color color;
  final double size;
  double life;
  bool onOutputConveyor;
}

class CrusherGame extends ChangeNotifier {
  CrusherGame(this.controller) {
    spawnRock();
  }

  final GameController controller;
  GameState get state => controller.state;

  final ValueNotifier<int> sceneFrame = ValueNotifier<int>(0);
  final List<CrusherRock> rocks = [];
  final List<CrusherParticle> particles = [];
  final math.Random _random = math.Random();

  Timer? _timer;
  DateTime? _lastTick;
  DateTime _lastUiUpdate = DateTime.now();

  double _spawnClock = 0, _spawnIn = .38, _rotorAngle = 0;
  double _pressPulse = 0, _manualCooldown = 0, _autoClock = 0, _shake = 0;
  bool _disposed = false;

  String? messageKey;
  int messageAmount = 0;
  int messageId = 0;
  double messageLife = 0;

  bool debugUnlimitedCoins = false;
  String language = 'tr';
  bool get soundEnabled => state.soundEffectsEnabled;
  bool get hapticsEnabled => state.hapticsEnabled;
  int selectedSkin = 0;

  int get level => state.crusherLevel;
  int get experience => state.crusherXp;
  int get experienceGoal => 100 + level * 150;
  int get totalCrushed => state.totalOreCrushed;

  // Ortak Ana Ekonomi Para Birimi
  int get coins =>
      state.coins.toDouble().clamp(0.0, 9007199254740991.0).toInt();

  // Yükseltme Seviyeleri (Doğrudan GameState'ten)
  int get speedLevel => state.crusherUpgrades['speed'] ?? 1;
  int get powerLevel => state.crusherUpgrades['power'] ?? 1;
  int get gravityLevel => state.crusherUpgrades['gravity'] ?? 1;
  int get gearboxLevel => state.crusherUpgrades['gearbox'] ?? 1;
  int get feedLevel => state.crusherUpgrades['feed'] ?? 1;
  int get teethLevel => state.crusherUpgrades['teeth'] ?? 1;
  int get oreLevel => state.crusherUpgrades['ore'] ?? 1;
  int get storageLevel => state.crusherUpgrades['storage'] ?? 1;

  // Three.js Sahne Parametreleri
  double get rotorAngle => _rotorAngle;
  bool get isHalted => state.cargoFull;
  int get rpm =>
      isHalted ? 0 : (28 + speedLevel * 8 + (_pressPulse > 0 ? 32 : 0)).round();

  // Derinlere inildikçe akış hızı, konveyör sürati ve taş frekansı artar
  double get depthMultiplier {
    final depthMeters = math.max(state.depthMeters, state.deepestMeters);
    final depthKm = depthMeters / 1000.0;
    return (1.0 + math.log(1.0 + depthKm * 0.4) * 0.35).clamp(1.0, 3.8);
  }

  double get conveyorSpeed => isHalted
      ? 0.0
      : _baseConveyorSpeed * (1 + feedLevel * .14) * depthMultiplier;
  double get shake => _shake;
  int get rockCapacity => state.crusherHopperCapacity;
  double get hopperTopY => 3.9;
  double get hopperHalfWidth => 1.8;
  double get sceneCameraHalfHeight => _cameraHalfHeight;
  double get sceneCameraPanX => _portraitCameraPanX;

  Color get rollerBase => const Color(0xff2b3442);
  Color get rollerLight => const Color(0xff55647a);
  Color get rollerDark => const Color(0xff181f2a);

  // Derinlere inildikçe büyük kaya (boulder) çıkma ihtimali (%20'den %85'e kadar artar)
  double get largeRockChance {
    final depthMeters = math.max(state.depthMeters, state.deepestMeters);
    final depthKm = depthMeters / 1000.0;
    final depthBonus = (depthKm * 0.015).clamp(0.0, 0.62);
    final gearBonus = (gearboxLevel - 1) * 0.01;
    return (0.20 + depthBonus + gearBonus).clamp(0.20, 0.85);
  }

  OreMaterial get currentMaterial => _pickMaterialForDepth();

  OreMaterial _pickMaterialForDepth() {
    final rawEntries = state.rawOreInventory.entries
        .where((e) => e.value > 0)
        .toList();
    if (rawEntries.isNotEmpty) {
      final chosen = rawEntries[_random.nextInt(rawEntries.length)].key;
      return oreMaterialById(chosen);
    }

    final depthMeters = math.max(state.depthMeters, state.deepestMeters);
    final depthKm = depthMeters / 1000.0;

    // Alt katlara inildikçe derinlik seviyesine göre açılan madenler
    final available = oreMaterials.where((m) {
      if (m.id == 'coal') return true;
      if (m.id == 'copper') return depthKm >= 0.5 || level >= 2;
      if (m.id == 'silver') return depthKm >= 3.0 || level >= 5;
      if (m.id == 'gold') return depthKm >= 8.0 || level >= 10;
      if (m.id == 'platinum') return depthKm >= 20.0 || level >= 16;
      if (m.id == 'diamond') return depthKm >= 40.0 || level >= 22;
      if (m.id == 'coltan') return depthKm >= 80.0 || level >= 30;
      if (m.id == 'painite') return depthKm >= 120.0 || level >= 40;
      return false;
    }).toList();

    // Derine inildikçe nadir madenlerin gelme olasılığı katlanarak artar
    final weights = available.map((m) {
      final idx = oreMaterials.indexOf(m);
      final depthFactor = (depthKm / 8.0).clamp(0.2, 35.0);
      return math.pow(1.0 + depthFactor * 0.75, idx).toDouble();
    }).toList();

    final totalWeight = weights.fold<double>(0.0, (sum, w) => sum + w);
    var roll = _random.nextDouble() * totalWeight;
    for (var i = 0; i < available.length; i++) {
      roll -= weights[i];
      if (roll <= 0) return available[i];
    }
    return available.last;
  }

  bool get specialRockActive => rocks.any((r) => r.isSpecial);

  void start() {
    _lastTick = DateTime.now();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) => _tick());
  }

  void pause() {
    _timer?.cancel();
    _timer = null;
  }

  void resume() {
    start();
  }

  void _emit(String key, [int amount = 0]) {
    messageKey = key;
    messageAmount = amount;
    messageId++;
    messageLife = 1.6;
    notifyListeners();
  }

  int upgradeCost(String id) {
    final lvl = state.crusherUpgrades[id] ?? 1;
    final base = switch (id) {
      'speed' => 25,
      'power' => 35,
      'gravity' => 30,
      'gearbox' => 50,
      'feed' => 40,
      'teeth' => 45,
      'ore' => 60,
      'storage' => 30,
      _ => 25,
    };
    return (base * math.pow(1.36, lvl - 1)).round();
  }

  bool isUpgradeMaxed(String id) {
    final lvl = state.crusherUpgrades[id] ?? 1;
    return lvl >= 100;
  }

  void buyUpgrade(String id) {
    if (isUpgradeMaxed(id)) return;
    final cost = upgradeCost(id);
    if (!debugUnlimitedCoins && state.coins.toDouble() < cost) {
      _emit('notEnough');
      return;
    }
    if (!debugUnlimitedCoins) {
      state.spendCoins(cost);
    }
    state.crusherUpgrades[id] = (state.crusherUpgrades[id] ?? 1) + 1;
    _emit('upgradeDone', state.crusherUpgrades[id]!);
    notifyListeners();
    controller.saveNow();
  }

  void manualPress({int? rockId}) {
    if (isHalted) {
      _emit('cargoFull', 0);
      return;
    }
    _pressPulse = .35;
    _shake = math.min(.45, _shake + .12);
    final damage = (0.2 + powerLevel * .25) * (1 + teethLevel * .2);

    CrusherRock? target;
    if (rockId != null) {
      for (final r in rocks) {
        if (r.seed == rockId) {
          target = r;
          break;
        }
      }
    }
    target ??= rocks.isNotEmpty ? rocks.first : null;

    if (target != null) {
      _damageRock(target, damage, fromManual: true);
    }
    sceneFrame.value++;
    notifyListeners();
  }

  void _damageRock(CrusherRock rock, double damage, {bool fromManual = false}) {
    if (isHalted || rock.passedRollers) return;
    rock.hp -= damage;
    rock.stageDamage += damage;
    _spawnParticles(rock.x, rock.y, rock.material.color, fromManual ? 6 : 3);

    // Kademeli ufalanma: Hasar aldıkça taş parçalanarak küçülür
    if (rock.stageDamage >= rock.stageHealth &&
        rock.fractureStage < rock.fractureStages) {
      rock.stageDamage = 0;
      rock.fractureStage++;
      const passRadius = 0.195;
      final progress = rock.fractureStage / rock.fractureStages;
      rock.radius =
          rock.initialRadius + (passRadius - rock.initialRadius) * progress;
      _spawnParticles(rock.x, rock.y, rock.material.highlight, 5);
      _shake = math.min(.5, _shake + .08);
    }

    if (rock.hp <= 0 || rock.fractureStage >= rock.fractureStages) {
      _crushRock(rock);
    }
  }

  void _crushRock(CrusherRock rock) {
    if (isHalted || rock.passedRollers) return;
    _shake = math.min(.6, _shake + .18);
    _spawnParticles(rock.x, rock.y, rock.material.glow, 16);

    final oreId = rock.material.id;
    final depthMeters = math.max(state.depthMeters, state.deepestMeters);
    final depthKm = depthMeters / 1000.0;

    // Derinlik ve kaya boyutuna göre gelir artışı: Büyük kayalar kat kat daha fazla mineral bırakır
    final sizeYieldBonus = rock.isLarge
        ? (2.0 + (depthKm * 0.015).clamp(0.0, 2.5))
        : 1.0;
    final depthYieldBonus = 1.0 + (depthKm * 0.005).clamp(0.0, 1.5);
    final yieldMultiplier =
        (1.0 + (oreLevel - 1) * 0.05 + (gearboxLevel - 1) * 0.02) *
        sizeYieldBonus *
        depthYieldBonus;

    // AMBARA SAF KAYNAK AKTARIMI
    final yieldResult = state.crushRawOre(
      oreId: oreId,
      amount: 1,
      yieldMultiplier: yieldMultiplier,
      allowWithoutRawOre: (state.rawOreInventory[oreId] ?? 0) <= 0,
    );

    // Kırıcı doğrudan altın üretmez, çıkan maden ambara aktarılır.
    // Oyuncu ambardan satış yaparak gelir elde eder.
    _emit('crushed', yieldResult > 0 ? yieldResult : 1);
    controller.notifyListeners();

    // Ezilip tamamen parçalanan taş artık merdanenin arasından geçip alt konveyöre düşer
    rock.passedRollers = true;
    rock.inGap = false;
    rock.radius = 0.18; // Merdane aralığından geçecek boyuta indi
    rock.hp = 1.0; // Konveyör sonuna kadar sahnede kalır
    rock.fractureStage = rock.fractureStages;
    rock.x = rock.x * 0.3; // Merdane merkezine yönelir
    rock.vx = (rock.x < 0 ? 0.2 : -0.2);
    rock.vy = -1.4; // Merdanelerin arasından aşağı hızla fırlar
  }

  void _spawnParticles(double x, double y, Color color, int count) {
    for (var i = 0; i < count; i++) {
      final angle = _random.nextDouble() * math.pi * 2;
      final speed = .8 + _random.nextDouble() * 2.2;
      particles.add(
        CrusherParticle(
          x: x,
          y: y,
          z: (_random.nextDouble() - .5) * .3,
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed,
          vz: (_random.nextDouble() - .5) * 1.5,
          color: color,
          size: .06 + _random.nextDouble() * .08,
          life: .35 + _random.nextDouble() * .3,
        ),
      );
    }
  }

  void spawnRock({bool force = false}) {
    if (isHalted) return;
    final maxRocks = math.min(
      26,
      (5 + storageLevel + (depthMultiplier * 4).round()),
    );
    if (!force && rocks.length >= maxRocks) return;

    final mat = currentMaterial;
    final depthMeters = math.max(state.depthMeters, state.deepestMeters);
    final depthKm = depthMeters / 1000.0;

    // Büyük kaya ihtimali: Derine inildikçe büyük kaya gelme olasılığı %85'e kadar artar
    final isLarge = _random.nextDouble() < largeRockChance;
    final depthSizeBonus = (depthKm * 0.012).clamp(0.0, 1.3);
    final sizeScale = isLarge
        ? (2.0 + depthSizeBonus * 0.45) +
              _random.nextDouble() *
                  (1.6 + depthSizeBonus * 0.55) // Dev kayalar (2.0x - 4.5x)
        : (1.30 + depthSizeBonus * 0.15) +
              _random.nextDouble() * 0.65; // Standart taşlar
    final radius = mat.radius * sizeScale;

    final isSpecial = _random.nextDouble() < (.03 + teethLevel * .008);
    final fractureStages = isLarge ? (depthKm >= 15.0 ? 6 : 5) : 3;
    final stageHealth =
        (mat.health * (isSpecial ? 2.5 : 1.0) * (isLarge ? 2.2 : 1.0)) /
        fractureStages;
    final maxHp = fractureStages * stageHealth;

    final rock = CrusherRock(
      material: mat,
      hp: maxHp,
      maxHp: maxHp,
      initialRadius: radius,
      fractureStages: fractureStages,
      stageHealth: stageHealth,
      radius: radius,
      x: _beltRightX,
      y: _beltSurfaceY + radius * _rockGeometryRadius + .025,
      onBelt: true,
      isSpecial: isSpecial,
      isLarge: isLarge,
      seed: DateTime.now().microsecondsSinceEpoch ^ _random.nextInt(10000),
    );
    rocks.add(rock);
  }

  void _tick() {
    final now = DateTime.now();
    final dt = _lastTick == null
        ? .016
        : (now.difference(_lastTick!).inMilliseconds / 1000.0).clamp(.001, .05);
    _lastTick = now;

    if (_disposed) return;

    if (_shake > 0) {
      _shake = math.max(0, _shake - dt * 1.6);
    }
    if (_pressPulse > 0) {
      _pressPulse = math.max(0, _pressPulse - dt * 2.2);
    }
    if (messageLife > 0) {
      messageLife = math.max(0, messageLife - dt);
      if (messageLife <= 0) messageKey = null;
    }

    // Merdane dönüşü
    final rotationSpeed = (rpm / 60.0) * math.pi * 2;
    _rotorAngle = (_rotorAngle + rotationSpeed * dt) % (math.pi * 2);

    if (!isHalted) {
      // Otomatik kırma vuruşu: Derinlere inildikçe vuruş sıklığı da hızlanır
      _autoClock += dt;
      final autoInterval = 1.0 / ((0.2 + speedLevel * 0.25) * depthMultiplier);
      if (_autoClock >= autoInterval) {
        _autoClock = 0;
        final gapRocks = rocks.where((r) => r.inGap).toList();
        if (gapRocks.isNotEmpty) {
          final r = gapRocks[_random.nextInt(gapRocks.length)];
          final autoDmg = (0.1 + powerLevel * .2) * (1 + teethLevel * .12);
          _damageRock(r, autoDmg);
        }
      }

      // Taş üretimi: Derinlere inildikçe daha sık taş spawn olur
      _spawnClock += dt;
      final baseInterval = math.max(.20, 1.35 - feedLevel * .06);
      final spawnInterval = math.max(.12, baseInterval / depthMultiplier);
      if (_spawnClock >= spawnInterval) {
        _spawnClock = 0;
        spawnRock();
      }
    }

    // Taş fiziği ve hareketi
    final grav = 9.8 * (1 + gravityLevel * .15);
    final cSpeed = conveyorSpeed;

    // 1. Taş-Taş Çarpışması (Haznede taşların üst üste birikmesi ve yığılması)
    for (var a = 0; a < rocks.length; a++) {
      for (var b = a + 1; b < rocks.length; b++) {
        final ra = rocks[a];
        final rb = rocks[b];
        if (ra.onBelt ||
            rb.onBelt ||
            ra.onOutputConveyor ||
            rb.onOutputConveyor)
          continue;
        if (ra.passedRollers != rb.passedRollers) continue;

        final dx = rb.x - ra.x;
        final dy = rb.y - ra.y;
        final distSq = dx * dx + dy * dy;
        final minDist = (ra.radius + rb.radius) * _rockGeometryRadius;
        if (distSq < minDist * minDist && distSq > 0.0001) {
          final dist = math.sqrt(distSq);
          final nx = dx / dist;
          final ny = dy / dist;
          final overlap = (minDist - dist) * 0.5;
          ra.x -= nx * overlap;
          ra.y -= ny * overlap;
          rb.x += nx * overlap;
          rb.y += ny * overlap;

          final relVx = rb.vx - ra.vx;
          final relVy = rb.vy - ra.vy;
          final relNorm = relVx * nx + relVy * ny;
          if (relNorm < 0) {
            ra.vx += nx * relNorm * 0.35;
            ra.vy += ny * relNorm * 0.35;
            rb.vx -= nx * relNorm * 0.35;
            rb.vy -= ny * relNorm * 0.35;
          }
        }
      }
    }

    // 2. Taş Fiziği, Merdane Bariyeri ve Konveyör Hareketi
    for (final r in rocks) {
      if (r.onBelt) {
        r.x -= cSpeed * dt;
        r.y = _beltSurfaceY + r.radius * _rockGeometryRadius + .025;
        r.rotation += (r.vx + .4) * dt;
        if (r.x <= _conveyorDropX) {
          r.onBelt = false;
          r.falling = true;
          r.vx = -cSpeed * .5;
          r.vy = 0;
        }
      } else if (r.onOutputConveyor) {
        // Çıkış konveyörü üzerinde SOLA doğru akış
        r.x -= _outputBeltSpeed * math.cos(_outputBeltAngle) * dt;
        r.z += _outputBeltSpeed * math.sin(_outputBeltAngle) * dt;
        r.y = _outputBeltSurfaceY + r.radius * _rockGeometryRadius + .025;
        r.vx = -_outputBeltSpeed * math.cos(_outputBeltAngle);
        r.vy = 0;
        r.vz = _outputBeltSpeed * math.sin(_outputBeltAngle);
        r.rotation += (r.vx + r.vz + .4) * dt;
        if (r.x <= -4.2) {
          r.hp = 0; // Konveyörün solundan ambara döküldü
        }
      } else {
        // Yerçekimi ve serbest düşüş
        r.vy -= grav * dt;
        r.x += r.vx * dt;
        r.y += r.vy * dt;
        r.z += r.vz * dt;
        r.rotation += (r.vx + .4) * dt;

        final extent = r.radius * _rockGeometryRadius;

        // Kırma haznesi hunisi yan duvarları
        final funnelTopY = 3.6;
        final funnelBottomY = _rollerCenterY;
        if (!r.passedRollers && r.y < funnelTopY && r.y > funnelBottomY) {
          final t = ((funnelTopY - r.y) / (funnelTopY - funnelBottomY)).clamp(
            0.0,
            1.0,
          );
          final currentHalfW =
              (2.1 * (1 - t) + (_rollerCenterX + 0.1) * t) - extent;
          if (r.x < -currentHalfW) {
            r.x = -currentHalfW;
            r.vx = r.vx.abs() * .35;
          } else if (r.x > currentHalfW) {
            r.x = currentHalfW;
            r.vx = -r.vx.abs() * .35;
          }
        }

        // ÇİFT DÖNEN DİŞLİ MERDANE BARİYERİ (Kırılmamış taşlar merdanelerin üstünde birikir)
        if (!r.passedRollers) {
          var touchedRoller = false;
          for (final cx in [-_rollerCenterX, _rollerCenterX]) {
            final dx = r.x - cx;
            final dy = r.y - _rollerCenterY;
            final dist = math.sqrt(dx * dx + dy * dy);
            final contactDist = _rollerRadius + extent;
            if (dist < contactDist) {
              final nx = dx / (dist > 0.0001 ? dist : 1.0);
              final ny = dy / (dist > 0.0001 ? dist : 1.0);
              final overlap = contactDist - dist;
              r.x += nx * overlap;
              r.y += ny * overlap;

              final normalVel = r.vx * nx + r.vy * ny;
              if (normalVel < 0) {
                r.vx -= 1.15 * normalVel * nx;
                r.vy -= 1.15 * normalVel * ny;
              }

              // Merdane dönüşü taşı aralığa doğru çeker
              if (!isHalted && ny > 0.25 && r.x.abs() < 1.4) {
                r.vx += (cx < 0 ? 1 : -1) * dt * (1.8 + feedLevel * 0.08);
              }
              touchedRoller = true;
            }
          }

          // Merdane aralığı boğazı: Kırılmamış iri taşlar asla aradan aşağı düşemez!
          if (r.y < _rollerCenterY + 0.4 && r.x.abs() < 1.1) {
            r.inGap = true;
            final throatFloor = _rollerCenterY - 0.02;
            if (r.y < throatFloor) {
              r.y = throatFloor;
              if (r.vy < 0) r.vy = 0;
            }
          } else {
            r.inGap = touchedRoller;
          }
        }

        // Çıkış konveyörüne varış (Sadece merdaneden kırılıp geçen taşlar alt banda konar)
        if (r.passedRollers) {
          final outletFloor = _outputBeltSurfaceY + extent + .025;
          if (r.y <= outletFloor) {
            r.onOutputConveyor = true;
            r.falling = false;
            r.inGap = false;
            r.y = outletFloor;
            r.vx = -_outputBeltSpeed * math.cos(_outputBeltAngle);
            r.vy = 0;
            r.vz = _outputBeltSpeed * math.sin(_outputBeltAngle);
          }
        }

        // Sahneden çıkış
        if (r.x < -6.0 || r.x > 9.0 || r.y < -3.0) {
          r.hp = 0;
        }
      }
    }

    // Ölen / sahne dışına çıkan taşları temizle
    rocks.removeWhere((r) => r.hp <= 0);

    // Partiküller (Ezilme kıvılcımları ve tozları)
    for (final p in particles) {
      if (p.onOutputConveyor) {
        p.x -= _outputBeltSpeed * math.cos(_outputBeltAngle) * dt;
        p.z += _outputBeltSpeed * math.sin(_outputBeltAngle) * dt;
        p.y = _outputBeltSurfaceY + p.size + .018;
        p.vx = -_outputBeltSpeed * math.cos(_outputBeltAngle);
        p.vy = 0;
        p.vz = _outputBeltSpeed * math.sin(_outputBeltAngle);
        if (p.x <= -4.2 || p.life <= 0) p.life = 0;
      } else {
        p.vy -= 9.8 * dt;
        p.x += p.vx * dt;
        p.y += p.vy * dt;
        p.z += p.vz * dt;
        final pFloor = _outputBeltSurfaceY + p.size + .018;
        if (p.y <= pFloor) {
          p.onOutputConveyor = true;
          p.y = pFloor;
          p.vy = 0;
          p.vx = -_outputBeltSpeed * math.cos(_outputBeltAngle);
          p.vz = _outputBeltSpeed * math.sin(_outputBeltAngle);
        }
      }
      p.life -= dt;
    }
    particles.removeWhere((p) => p.life <= 0);

    // Sahne güncellemesi (30 FPS)
    if (now.difference(_lastUiUpdate).inMilliseconds >= 32) {
      _lastUiUpdate = now;
      sceneFrame.value++;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    sceneFrame.dispose();
    super.dispose();
  }
}
