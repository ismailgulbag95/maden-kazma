import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'crusher_engine.dart';

class CrusherCanvasRenderer extends StatefulWidget {
  const CrusherCanvasRenderer({
    super.key,
    required this.game,
    required this.onPointer,
  });

  final CrusherGame game;
  final ValueChanged<String> onPointer;

  @override
  State<CrusherCanvasRenderer> createState() => _CrusherCanvasRendererState();
}

class _CrusherCanvasRendererState extends State<CrusherCanvasRenderer> {
  final List<_ImpactRipple> _ripples = [];

  void _handleTapDown(TapDownDetails details, Size size) {
    final pos = details.localPosition;
    _ripples.add(_ImpactRipple(pos: pos, createdAt: DateTime.now()));
    if (_ripples.length > 8) _ripples.removeAt(0);

    // Canvas koordinatından oyun dünyası koordinatına dönüştür
    final worldPos = _screenToWorld(pos, size);

    // Tıklanan taşı bul
    CrusherRock? hitRock;
    double minDistance = double.infinity;
    for (final rock in widget.game.rocks) {
      final dx = rock.x - worldPos.dx;
      final dy = rock.y - worldPos.dy;
      final dist = math.sqrt(dx * dx + dy * dy);
      if (dist < rock.radius * 1.6 && dist < minDistance) {
        minDistance = dist;
        hitRock = rock;
      }
    }

    if (hitRock != null) {
      widget.onPointer('down:${hitRock.seed}');
    } else {
      widget.game.manualPress();
      widget.onPointer('down:0');
    }

    setState(() {});
  }

  void _handleTapUp(TapUpDetails details) {
    widget.onPointer('up');
  }

  void _handleTapCancel() {
    widget.onPointer('up');
  }

  Offset _screenToWorld(Offset screen, Size size) {
    const worldWidth = 6.8;
    const worldHeight = 6.2;
    const worldCenterX = 1.6;
    const worldCenterY = 1.7;

    final scaleX = size.width / worldWidth;
    final scaleY = size.height / worldHeight;
    final scale = math.min(scaleX, scaleY);

    final originX = size.width / 2 - (worldCenterX * scale);
    final originY = size.height / 2 + (worldCenterY * scale);

    final worldX = (screen.dx - originX) / scale;
    final worldY = (originY - screen.dy) / scale;
    return Offset(worldX, worldY);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: widget.game.sceneFrame,
      builder: (context, _, __) {
        final now = DateTime.now();
        _ripples.removeWhere(
          (r) => now.difference(r.createdAt).inMilliseconds > 450,
        );

        return GestureDetector(
          onTapDown: (details) => _handleTapDown(details, context.size ?? Size.zero),
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          behavior: HitTestBehavior.opaque,
          child: CustomPaint(
            painter: _CrusherWorldPainter(
              game: widget.game,
              ripples: _ripples,
              now: now,
            ),
            child: const SizedBox.expand(),
          ),
        );
      },
    );
  }
}

class _ImpactRipple {
  _ImpactRipple({required this.pos, required this.createdAt});
  final Offset pos;
  final DateTime createdAt;
}

class _CrusherWorldPainter extends CustomPainter {
  _CrusherWorldPainter({
    required this.game,
    required this.ripples,
    required this.now,
  });

  final CrusherGame game;
  final List<_ImpactRipple> ripples;
  final DateTime now;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Sarsıntı ofseti
    final shake = game.shake;
    if (shake > 0) {
      final sx = (math.sin(now.millisecondsSinceEpoch * .08) * shake * 6);
      final sy = (math.cos(now.millisecondsSinceEpoch * .09) * shake * 6);
      canvas.translate(sx, sy);
    }

    // Koordinat projeksiyonu
    const worldWidth = 6.8;
    const worldHeight = 6.2;
    const worldCenterX = 1.6;
    const worldCenterY = 1.7;

    final scaleX = w / worldWidth;
    final scaleY = h / worldHeight;
    final scale = math.min(scaleX, scaleY);

    final originX = w / 2 - (worldCenterX * scale);
    final originY = h / 2 + (worldCenterY * scale);

    Offset toScreen(double wx, double wy) {
      return Offset(originX + wx * scale, originY - wy * scale);
    }

    double toScale(double val) => val * scale;

    // 1. Arka plan ve maden bacası derinlik efekti
    _drawBackground(canvas, size, originX, originY, scale);

    // 2. Kırıcı şasisi ve hunisi
    _drawChamber(canvas, toScreen, toScale);

    // 3. Üst ve alt konveyör bantları
    _drawConveyors(canvas, toScreen, toScale);

    // 4. Çift Dönen Dişli Merdaneler (Twin Rollers)
    _drawRollers(canvas, toScreen, toScale);

    // 5. Taşlar (Rocks)
    _drawRocks(canvas, toScreen, toScale);

    // 6. Ezilme partikülleri
    _drawParticles(canvas, toScreen, toScale);

    // 7. Dokunma darbe halkaları
    _drawRipples(canvas);
  }

  void _drawBackground(Canvas canvas, Size size, double ox, double oy, double scale) {
    // Koyu metalik maden arka planı
    final bgPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0, -0.2),
        radius: 1.2,
        colors: [Color(0xff182230), Color(0xff0d131a)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Endüstriyel grid çizgileri
    final gridPaint = Paint()
      ..color = const Color(0xff222e3d).withOpacity(0.35)
      ..strokeWidth = 1.0;

    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _drawChamber(Canvas canvas, Offset Function(double, double) toScreen, double Function(double) toScale) {
    // Kırıcı hunisi yan plakaları (Funnel walls)
    final funnelLeft = Path()
      ..moveTo(toScreen(-2.6, 3.8).dx, toScreen(-2.6, 3.8).dy)
      ..lineTo(toScreen(-1.35, 1.5).dx, toScreen(-1.35, 1.5).dy)
      ..lineTo(toScreen(-1.35, 0.2).dx, toScreen(-1.35, 0.2).dy)
      ..lineTo(toScreen(-2.9, 0.2).dx, toScreen(-2.9, 0.2).dy)
      ..lineTo(toScreen(-2.9, 3.8).dx, toScreen(-2.9, 3.8).dy)
      ..close();

    final funnelRight = Path()
      ..moveTo(toScreen(2.6, 3.8).dx, toScreen(2.6, 3.8).dy)
      ..lineTo(toScreen(1.35, 1.5).dx, toScreen(1.35, 1.5).dy)
      ..lineTo(toScreen(1.35, 0.2).dx, toScreen(1.35, 0.2).dy)
      ..lineTo(toScreen(2.9, 0.2).dx, toScreen(2.9, 0.2).dy)
      ..lineTo(toScreen(2.9, 3.8).dx, toScreen(2.9, 3.8).dy)
      ..close();

    final platePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xff2a3648), Color(0xff161f2c)],
      ).createShader(Rect.fromLTWH(0, 0, 1000, 1000));

    final borderPaint = Paint()
      ..color = const Color(0xff3f526b)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawPath(funnelLeft, platePaint);
    canvas.drawPath(funnelLeft, borderPaint);
    canvas.drawPath(funnelRight, platePaint);
    canvas.drawPath(funnelRight, borderPaint);

    // Endüstriyel sarı-siyah uyarı çizgileri
    _drawHazardStripes(canvas, toScreen(-2.8, 3.7), toScreen(-1.4, 3.5), toScale(0.18));
    _drawHazardStripes(canvas, toScreen(1.4, 3.5), toScreen(2.8, 3.7), toScale(0.18));
  }

  void _drawHazardStripes(Canvas canvas, Offset p1, Offset p2, double height) {
    final paint1 = Paint()..color = const Color(0xffffb822);
    final paint2 = Paint()..color = const Color(0xff1b232c);

    final rect = Rect.fromPoints(p1, Offset(p2.dx, p1.dy + height));
    canvas.save();
    canvas.clipRect(rect);
    canvas.drawRect(rect, paint1);

    final stripePaint = Paint()
      ..color = paint2.color
      ..strokeWidth = 6.0;

    for (double i = -100; i < rect.width + 100; i += 16) {
      canvas.drawLine(
        Offset(rect.left + i, rect.top - 10),
        Offset(rect.left + i + 20, rect.bottom + 10),
        stripePaint,
      );
    }
    canvas.restore();
  }

  void _drawConveyors(Canvas canvas, Offset Function(double, double) toScreen, double Function(double) toScale) {
    // 1. Üst Giriş Bandı (Sağdan merdaneye besleme)
    final topBeltStart = toScreen(6.4, 4.14);
    final topBeltEnd = toScreen(0.42, 4.14);
    final beltHeight = toScale(0.24);

    final beltPaint = Paint()..color = const Color(0xff151b24);
    final beltBorder = Paint()
      ..color = const Color(0xff3e4e63)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final topRect = Rect.fromPoints(
      topBeltEnd,
      Offset(topBeltStart.dx, topBeltStart.dy + beltHeight),
    );
    canvas.drawRRect(RRect.fromRectAndRadius(topRect, const Radius.circular(4)), beltPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(topRect, const Radius.circular(4)), beltBorder);

    // Dönen makara dişleri / hareket hissi
    final animOffset = (now.millisecondsSinceEpoch * 0.05 * game.conveyorSpeed) % 18;
    final tickPaint = Paint()
      ..color = const Color(0xff334152)
      ..strokeWidth = 2.5;
    for (double x = topRect.left; x < topRect.right; x += 18) {
      final drawX = x - animOffset;
      if (drawX >= topRect.left && drawX <= topRect.right) {
        canvas.drawLine(Offset(drawX, topRect.top), Offset(drawX, topRect.bottom), tickPaint);
      }
    }

    // 2. Alt Çıkış Bandı (Soldan kırıcının altına uzanır)
    final botBeltStart = toScreen(-7.0, -0.46);
    final botBeltEnd = toScreen(1.5, -0.46);
    final botRect = Rect.fromPoints(
      botBeltStart,
      Offset(botBeltEnd.dx, botBeltStart.dy + beltHeight),
    );
    canvas.drawRRect(RRect.fromRectAndRadius(botRect, const Radius.circular(4)), beltPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(botRect, const Radius.circular(4)), beltBorder);

    final botAnimOffset = (now.millisecondsSinceEpoch * 0.08) % 18;
    for (double x = botRect.left; x < botRect.right; x += 18) {
      final drawX = x - botAnimOffset;
      if (drawX >= botRect.left && drawX <= botRect.right) {
        canvas.drawLine(Offset(drawX, botRect.top), Offset(drawX, botRect.bottom), tickPaint);
      }
    }
  }

  void _drawRollers(Canvas canvas, Offset Function(double, double) toScreen, double Function(double) toScale) {
    const leftX = -0.77;
    const rightX = 0.77;
    const rollerY = 0.69;
    const rollerR = 0.68;

    final rRadius = toScale(rollerR);
    final leftCenter = toScreen(leftX, rollerY);
    final rightCenter = toScreen(rightX, rollerY);

    final angle = game.rotorAngle;

    // Sol Merdane (Saat yönünde döner)
    _drawSingleRoller(canvas, leftCenter, rRadius, angle, clockwise: true);

    // Sağ Merdane (Saat yönünün tersine döner)
    _drawSingleRoller(canvas, rightCenter, rRadius, -angle, clockwise: false);
  }

  void _drawSingleRoller(Canvas canvas, Offset center, double radius, double angle, {required bool clockwise}) {
    // Dış gövde
    final rollerPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.25, -0.25),
        radius: 0.9,
        colors: [
          const Color(0xff55647a),
          const Color(0xff2b3442),
          const Color(0xff181f2a),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, rollerPaint);

    // Dişli Merdane Dişleri (8 adet sağlam çelik diş)
    const teethCount = 8;
    final toothPaint = Paint()
      ..color = const Color(0xff7a8c9e)
      ..style = PaintingStyle.fill;
    final toothBorder = Paint()
      ..color = const Color(0xff1b232e)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final toothLen = radius * 0.28;
    final toothWidth = radius * 0.22;

    for (var i = 0; i < teethCount; i++) {
      final a = angle + (i * 2 * math.pi / teethCount);
      final cosA = math.cos(a);
      final sinA = math.sin(a);
      final perpCos = -sinA;
      final perpSin = cosA;

      final tip = Offset(
        center.dx + (radius + toothLen) * cosA,
        center.dy + (radius + toothLen) * sinA,
      );
      final base1 = Offset(
        center.dx + radius * cosA - perpCos * toothWidth,
        center.dy + radius * sinA - perpSin * toothWidth,
      );
      final base2 = Offset(
        center.dx + radius * cosA + perpCos * toothWidth,
        center.dy + radius * sinA + perpSin * toothWidth,
      );

      final path = Path()
        ..moveTo(base1.dx, base1.dy)
        ..lineTo(tip.dx, tip.dy)
        ..lineTo(base2.dx, base2.dy)
        ..close();

      canvas.drawPath(path, toothPaint);
      canvas.drawPath(path, toothBorder);
    }

    // Göbek / Rulman Kapağı (Hub)
    final hubRadius = radius * 0.36;
    final hubPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.2, -0.2),
        colors: [const Color(0xff8da1b5), const Color(0xff283340)],
      ).createShader(Rect.fromCircle(center: center, radius: hubRadius));
    canvas.drawCircle(center, hubRadius, hubPaint);

    final hubBorder = Paint()
      ..color = const Color(0xffc8ef70).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, hubRadius, hubBorder);

    // Cıvatalar
    final boltPaint = Paint()..color = const Color(0xffc8ef70);
    for (var b = 0; b < 4; b++) {
      final ba = angle + (b * math.pi / 2);
      final bx = center.dx + math.cos(ba) * (hubRadius * 0.65);
      final by = center.dy + math.sin(ba) * (hubRadius * 0.65);
      canvas.drawCircle(Offset(bx, by), 2.2, boltPaint);
    }
  }

  void _drawRocks(Canvas canvas, Offset Function(double, double) toScreen, double Function(double) toScale) {
    for (final rock in game.rocks) {
      final center = toScreen(rock.x, rock.y);
      final r = toScale(rock.radius);

      // Özel taş ise parıldayan neon halka
      if (rock.isSpecial) {
        final auraPaint = Paint()
          ..color = const Color(0xffffd46a).withOpacity(0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
        canvas.drawCircle(center, r * 1.35, auraPaint);
      }

      // 3D Küresel Kaya Gövdesi (Degrade)
      final rockPaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.35),
          radius: 0.85,
          colors: [
            rock.material.highlight,
            rock.material.color,
            rock.material.shadow,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: r));

      canvas.drawCircle(center, r, rockPaint);

      // Dış kenar çizgisi
      final edgePaint = Paint()
        ..color = rock.material.shadow.withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(center, r, edgePaint);

      // Çatlak Efekti (Hasar aldıkça)
      if (rock.hp < rock.maxHp) {
        final crackAlpha = ((1.0 - (rock.hp / rock.maxHp))).clamp(0.2, 1.0);
        final crackPaint = Paint()
          ..color = Colors.white.withOpacity(crackAlpha * 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6;

        // Çatlak çizgileri
        final path = Path()
          ..moveTo(center.dx - r * 0.5, center.dy - r * 0.4)
          ..lineTo(center.dx - r * 0.1, center.dy)
          ..lineTo(center.dx + r * 0.4, center.dy - r * 0.2)
          ..moveTo(center.dx - r * 0.1, center.dy)
          ..lineTo(center.dx + r * 0.2, center.dy + r * 0.5);

        canvas.drawPath(path, crackPaint);
      }

      // Kırıcı aralığındaysa küçük can barı (Health Bar)
      if (rock.inGap || rock.hp < rock.maxHp) {
        final barW = r * 1.8;
        const barH = 4.0;
        final barRect = Rect.fromCenter(
          center: Offset(center.dx, center.dy - r - 8),
          width: barW,
          height: barH,
        );

        canvas.drawRRect(
          RRect.fromRectAndRadius(barRect, const Radius.circular(2)),
          Paint()..color = Colors.black54,
        );

        final hpRatio = (rock.hp / rock.maxHp).clamp(0.0, 1.0);
        final fillRect = Rect.fromLTWH(
          barRect.left,
          barRect.top,
          barW * hpRatio,
          barH,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(fillRect, const Radius.circular(2)),
          Paint()..color = hpRatio > 0.4 ? const Color(0xffc8ef70) : const Color(0xffff5555),
        );
      }
    }
  }

  void _drawParticles(Canvas canvas, Offset Function(double, double) toScreen, double Function(double) toScale) {
    for (final p in game.particles) {
      final center = toScreen(p.x, p.y);
      final r = toScale(p.size);
      final alpha = (p.life / 0.5).clamp(0.0, 1.0);

      final pPaint = Paint()
        ..color = p.color.withOpacity(alpha)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(center, math.max(1.5, r), pPaint);
    }
  }

  void _drawRipples(Canvas canvas) {
    final rippleBorder = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    for (final ripple in ripples) {
      final elapsed = now.difference(ripple.createdAt).inMilliseconds / 450.0;
      final progress = elapsed.clamp(0.0, 1.0);
      final radius = 10.0 + progress * 40.0;
      final alpha = (1.0 - progress).clamp(0.0, 1.0);

      rippleBorder.color = const Color(0xffc8ef70).withOpacity(alpha);
      canvas.drawCircle(ripple.pos, radius, rippleBorder);
    }
  }

  @override
  bool shouldRepaint(covariant _CrusherWorldPainter oldDelegate) => true;
}
