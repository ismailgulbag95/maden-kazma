import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'atlas_sprite.dart';

/// The small, looping actions used by the crew sprites in the mine and outpost.
enum CrewAction {
  mining,
  drilling,
  surveying,
  repairing,
  hauling,
  operatingLift,
  exploring,
  scanning,
  hovering,
}

const List<double> _miningFrameBottoms = [
  503 / 512,
  503 / 512,
  503 / 512,
  503 / 512,
  452 / 512,
  459 / 512,
  461 / 512,
  448 / 512,
];

Rect _miningFrameCrop(int frame) =>
    Rect.fromLTRB(0, 0, 1, _miningFrameBottoms[frame.clamp(0, 7).toInt()]);

/// Animates the existing pixel-art sprite and adds task-specific pixel effects.
///
/// The atlas remains a single-pose source image; movement is intentionally kept
/// subtle so the detailed art is not warped or blurred by large transformations.
class AnimatedCrewSprite extends StatefulWidget {
  const AnimatedCrewSprite({
    super.key,
    required this.index,
    required this.width,
    required this.height,
    required this.action,
    this.phaseOffset = 0,
    this.detailedMiningAnimation = false,
    this.advisorDroneAnimation = false,
  });

  final int index;
  final double width;
  final double height;
  final CrewAction action;
  final double phaseOffset;
  final bool detailedMiningAnimation;
  final bool advisorDroneAnimation;

  @override
  State<AnimatedCrewSprite> createState() => _AnimatedCrewSpriteState();
}

class _AnimatedCrewSpriteState extends State<AnimatedCrewSprite>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock;

  @override
  void initState() {
    super.initState();
    _clock = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: _periodFor(
          widget.action,
          advisorDroneAnimation: widget.advisorDroneAnimation,
        ),
      ),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant AnimatedCrewSprite oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.action != widget.action ||
        oldWidget.advisorDroneAnimation != widget.advisorDroneAnimation) {
      _clock.duration = Duration(
        milliseconds: _periodFor(
          widget.action,
          advisorDroneAnimation: widget.advisorDroneAnimation,
        ),
      );
      _clock.repeat();
    }
  }

  int _periodFor(CrewAction action, {required bool advisorDroneAnimation}) =>
      advisorDroneAnimation
      ? 6500
      : switch (action) {
          CrewAction.mining => 1680,
          CrewAction.drilling => 1250,
          CrewAction.surveying || CrewAction.scanning => 2350,
          CrewAction.repairing => 1980,
          CrewAction.hauling => 1450,
          CrewAction.operatingLift => 2100,
          CrewAction.exploring => 2600,
          CrewAction.hovering => 1800,
        };

  int _advisorDroneFrame(double phase) => switch (phase) {
    < .82 => 0,
    < .86 => 1,
    < .90 => 2,
    _ => 3,
  };

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _clock,
    builder: (context, _) {
      final phase = (_clock.value + widget.phaseOffset) % 1;
      final wave = math.sin(phase * math.pi * 2);
      final drone =
          widget.advisorDroneAnimation ||
          widget.index == 3 ||
          widget.action == CrewAction.hovering;
      final useDetailedMining =
          widget.detailedMiningAnimation && widget.action == CrewAction.mining;
      final miningFrame = (phase * 8).floor().clamp(0, 7).toInt();
      final advisorFrame = _advisorDroneFrame(phase);
      final bob = useDetailedMining
          ? 0.0
          : switch (widget.action) {
              CrewAction.mining => -math.max(0, wave) * 1.8,
              CrewAction.drilling => wave * 1.2,
              CrewAction.surveying => wave * .8,
              CrewAction.scanning => wave * (drone ? 2.4 : .8),
              CrewAction.repairing => -math.max(0, wave) * 1.0,
              CrewAction.hauling => math.sin(phase * math.pi * 4) * .8,
              CrewAction.operatingLift => wave * 1.0,
              CrewAction.exploring => wave * .6,
              CrewAction.hovering => wave * 2.4,
            };
      final sideStep = widget.action == CrewAction.hauling
          ? wave * 2.0
          : drone
          ? math.sin(phase * math.pi * 2) * 1.3
          : 0.0;
      final lean = useDetailedMining
          ? 0.0
          : switch (widget.action) {
              CrewAction.mining => math.sin(phase * math.pi * 2) * .035,
              CrewAction.drilling => math.sin(phase * math.pi * 2) * .018,
              CrewAction.hauling => wave * .025,
              CrewAction.exploring => math.sin(phase * math.pi * 2) * .012,
              _ => 0.0,
            };

      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            if (widget.action == CrewAction.hovering)
              Positioned.fill(
                child: CustomPaint(
                  painter: _CrewEffectPainter(
                    action: widget.action,
                    phase: phase,
                  ),
                ),
              ),
            Positioned.fill(
              child: IgnorePointer(
                child: Transform.translate(
                  offset: Offset(sideStep, bob),
                  child: Transform.rotate(
                    angle: lean,
                    child: AtlasSprite(
                      asset: useDetailedMining
                          ? 'miner-mining-cycle.png'
                          : widget.advisorDroneAnimation
                          ? 'advisor-drone-blink-sheet.png'
                          : 'crew-machines-sheet.png',
                      index: useDetailedMining
                          ? miningFrame
                          : widget.advisorDroneAnimation
                          ? advisorFrame
                          : widget.index,
                      columns: useDetailedMining
                          ? 4
                          : widget.advisorDroneAnimation
                          ? 4
                          : 3,
                      rows: useDetailedMining
                          ? 2
                          : widget.advisorDroneAnimation
                          ? 1
                          : 3,
                      fit: BoxFit.contain,
                      alignment: drone
                          ? Alignment.center
                          : Alignment.bottomCenter,
                      sourceCrop: useDetailedMining
                          ? _miningFrameCrop(miningFrame)
                          : null,
                    ),
                  ),
                ),
              ),
            ),
            if (widget.action != CrewAction.hovering &&
                !useDetailedMining &&
                !widget.advisorDroneAnimation)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _CrewEffectPainter(
                      action: widget.action,
                      phase: phase,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }
}

/// A continuously running down-facing rig used on the lowest visible gallery.
class ContinuousDrillRig extends StatefulWidget {
  const ContinuousDrillRig({
    super.key,
    required this.width,
    required this.height,
  });

  final double width;
  final double height;

  @override
  State<ContinuousDrillRig> createState() => _ContinuousDrillRigState();
}

class _ContinuousDrillRigState extends State<ContinuousDrillRig>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock;

  @override
  void initState() {
    super.initState();
    _clock = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 920),
    )..repeat();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _clock,
    builder: (context, _) {
      final phase = _clock.value;
      final vibration = math.sin(phase * math.pi * 12);
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Transform.translate(
                offset: Offset(
                  vibration * .7,
                  math.sin(phase * math.pi * 2) * .4,
                ),
                child: Image.asset(
                  'assets/packs/deep-drill-rig.png',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.none,
                  alignment: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _DeepDrillImpactPainter(phase: phase),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }
}

class _DeepDrillImpactPainter extends CustomPainter {
  const _DeepDrillImpactPainter({required this.phase});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final impact = (1 - ((phase - .68).abs() / .20)).clamp(0.0, 1.0);
    final center = Offset(size.width * .51, size.height * .94);
    final paint = Paint()..isAntiAlias = false;
    if (impact > 0) {
      paint.color = Color.lerp(
        const Color(0xFFFF9A35),
        const Color(0xFFFFE78C),
        impact,
      )!;
      for (var i = 0; i < 5; i++) {
        final angle = i * math.pi * .4 - math.pi;
        final distance = 2 + impact * (4 + i % 2 * 3);
        canvas.drawRect(
          Rect.fromLTWH(
            center.dx + math.cos(angle) * distance,
            center.dy + math.sin(angle) * distance,
            2.5,
            2.5,
          ),
          paint,
        );
      }
    }

    final chipPhase = (phase * 4) % 1;
    paint.color = const Color(0xFF41E9DF).withValues(alpha: .30 + impact * .65);
    canvas.drawRect(
      Rect.fromLTWH(
        center.dx - 1,
        size.height * (.90 + chipPhase * .035),
        2,
        4,
      ),
      paint,
    );
    paint.color = const Color(0xFFFFBE54).withValues(alpha: .45 + impact * .5);
    canvas.drawRect(
      Rect.fromLTWH(
        center.dx + (chipPhase - .5) * 14,
        size.height * (.90 + (1 - chipPhase) * .035),
        2,
        2,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _DeepDrillImpactPainter oldDelegate) =>
      oldDelegate.phase != phase;
}

class _CrewEffectPainter extends CustomPainter {
  const _CrewEffectPainter({required this.action, required this.phase});

  final CrewAction action;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final pixel = Paint()..isAntiAlias = false;
    final center = Offset(size.width * .78, size.height * .42);

    switch (action) {
      case CrewAction.mining:
        final impact = (1 - ((phase - .67).abs() / .13)).clamp(0.0, 1.0);
        if (impact > 0) {
          pixel.color = Color.lerp(
            const Color(0xFFFF7A29),
            const Color(0xFFFFE17A),
            impact,
          )!;
          for (var i = 0; i < 4; i++) {
            final direction = i * math.pi / 2 + .35;
            final distance = 3 + impact * (5 + i % 2 * 2);
            canvas.drawRect(
              Rect.fromLTWH(
                center.dx + math.cos(direction) * distance,
                center.dy + math.sin(direction) * distance,
                i.isEven ? 2.5 : 2,
                i.isEven ? 2.5 : 2,
              ),
              pixel,
            );
          }
          pixel.color = const Color(0xAAFFD06B);
          canvas.drawRect(
            Rect.fromLTWH(center.dx - 4, center.dy + 4, 3, 2),
            pixel,
          );
        }
        break;

      case CrewAction.drilling:
        final pulse = (.38 + .62 * (math.sin(phase * math.pi * 8) + 1) / 2);
        pixel
          ..color = Color(0xFF42F1E0).withValues(alpha: .34 + pulse * .54)
          ..strokeWidth = 1.2 + pulse * 1.6
          ..strokeCap = StrokeCap.square;
        canvas.drawLine(
          Offset(size.width * .72, size.height * .53),
          Offset(size.width * .98, size.height * .53),
          pixel,
        );
        if (phase > .72 && phase < .9) {
          pixel
            ..color = const Color(0xFFAEFFF4)
            ..strokeWidth = 1;
          for (var i = 0; i < 3; i++) {
            final y = size.height * (.48 + i * .055);
            canvas.drawRect(Rect.fromLTWH(size.width * .93, y, 3, 2), pixel);
          }
        }
        break;

      case CrewAction.surveying:
      case CrewAction.scanning:
        final radius = 3 + phase * math.min(size.width, size.height) * .25;
        pixel
          ..color = const Color(0xFF62F5E5).withValues(alpha: .62 * (1 - phase))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;
        canvas.drawCircle(center, radius, pixel);
        pixel
          ..color = const Color(0xFFB4FFF6).withValues(alpha: .4)
          ..style = PaintingStyle.fill;
        canvas.drawRect(
          Rect.fromLTWH(center.dx - 1, center.dy - 1, 3, 3),
          pixel,
        );
        break;

      case CrewAction.repairing:
        final spark = (math.sin(phase * math.pi * 6) + 1) / 2;
        pixel.color = const Color(0xFFFFC15C)
            .withValues(alpha: .3 + spark * .7);
        canvas.drawRect(
          Rect.fromLTWH(size.width * .75, size.height * .40, 3, 3),
          pixel,
        );
        if (spark > .78) {
          pixel.color = const Color(0xFFFFE7A3);
          canvas.drawRect(
            Rect.fromLTWH(size.width * .82, size.height * .34, 2, 2),
            pixel,
          );
        }
        break;

      case CrewAction.hauling:
        final dust = (math.sin(phase * math.pi * 4) + 1) / 2;
        pixel.color = const Color(0xFFD6A56E)
            .withValues(alpha: .2 + dust * .45);
        for (var i = 0; i < 3; i++) {
          canvas.drawRect(
            Rect.fromLTWH(
              size.width * (.12 + i * .09),
              size.height * (.77 - dust * .08 + i * .025),
              2,
              2,
            ),
            pixel,
          );
        }
        break;

      case CrewAction.operatingLift:
        final lamp = .45 + .55 * (math.sin(phase * math.pi * 2) + 1) / 2;
        pixel.color = const Color(0xFFFFC14E).withValues(alpha: lamp);
        canvas.drawRect(
          Rect.fromLTWH(size.width * .48, size.height * .16, 3, 3),
          pixel,
        );
        break;

      case CrewAction.exploring:
        final lamp = .16 + .12 * (math.sin(phase * math.pi * 2) + 1) / 2;
        final beam = Path()
          ..moveTo(size.width * .64, size.height * .21)
          ..lineTo(size.width * .98, size.height * .37)
          ..lineTo(size.width * .94, size.height * .58)
          ..close();
        canvas.drawPath(
          beam,
          Paint()
            ..color = const Color(0xFFFFD16B).withValues(alpha: lamp)
            ..style = PaintingStyle.fill,
        );
        break;

      case CrewAction.hovering:
        final pulse = (1 - phase) * .6;
        final rect = Rect.fromCenter(
          center: Offset(size.width * .5, size.height * .82),
          width: size.width * (.2 + phase * .55),
          height: size.height * (.08 + phase * .1),
        );
        pixel
          ..color = const Color(0xFF50EDE4).withValues(alpha: pulse)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3;
        canvas.drawOval(rect, pixel);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _CrewEffectPainter oldDelegate) =>
      oldDelegate.action != action || oldDelegate.phase != phase;
}
