import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/design/palette.dart';
import 'atlas_sprite.dart';
import 'character_animation.dart';

/// Branded first frame shown while the save and game systems initialize.
class MineLoadingScreen extends StatelessWidget {
  const MineLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: MinePalette.ink,
    body: Stack(
      fit: StackFit.expand,
      children: [
        const Positioned.fill(
          child: Opacity(
            opacity: .55,
            child: CaveTextureBackground(
              asset: 'mine-earth-crystal-wall.png',
              verticalOffset: 0,
              minorTint: null,
            ),
          ),
        ),
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xE80A2029),
                  Color(0xB80A2029),
                  Color(0xF20A2029),
                ],
              ),
            ),
          ),
        ),
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -.05),
                radius: .8,
                colors: [Color(0x3329CFC5), Color(0x000A2029)],
              ),
            ),
          ),
        ),
        SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 560;
              final figureSize = math.min(
                compact ? 292.0 : 330.0,
                constraints.maxHeight * .39,
              );
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 470),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 22 : 36,
                      vertical: 20,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _LoadingHeader(compact: compact),
                        SizedBox(height: compact ? 24 : 34),
                        _LoadingMineScene(size: figureSize),
                        SizedBox(height: compact ? 18 : 24),
                        Text(
                          'MADEN HAZIRLANIYOR',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: MinePalette.cream,
                            fontSize: compact ? 17 : 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 7),
                        const Text(
                          'Asansör ve sondaj ekibi vardiyaya hazırlanıyor.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: MinePalette.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: compact ? 20 : 26),
                        SizedBox(
                          width: 310,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: const LinearProgressIndicator(
                              minHeight: 6,
                              color: MinePalette.amber,
                              backgroundColor: MinePalette.border,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.sensors_rounded,
                              color: MinePalette.cyan,
                              size: 13,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'YERALTI SİSTEMLERİ KONTROL EDİLİYOR',
                              style: TextStyle(
                                color: MinePalette.muted,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                letterSpacing: .65,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}

class _LoadingHeader extends StatelessWidget {
  const _LoadingHeader({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xD90A2832),
          border: Border.all(color: MinePalette.amber, width: 1.5),
          borderRadius: BorderRadius.circular(11),
          boxShadow: const [
            BoxShadow(color: Color(0x44F0A52E), blurRadius: 14),
          ],
        ),
        child: const Icon(
          Icons.landscape_rounded,
          color: MinePalette.amber,
          size: 24,
        ),
      ),
      const SizedBox(width: 11),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TAŞIN ALTI',
              style: TextStyle(
                color: MinePalette.cream,
                fontSize: compact ? 17 : 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'YERALTI MADENİ',
              style: TextStyle(
                color: MinePalette.muted,
                fontSize: 8,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
          ],
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xAA0B3440),
          border: Border.all(color: MinePalette.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, color: MinePalette.cyan, size: 7),
            SizedBox(width: 5),
            Text(
              'VARDİYA',
              style: TextStyle(
                color: MinePalette.cream,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: .5,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _LoadingMineScene extends StatelessWidget {
  const _LoadingMineScene({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    clipBehavior: Clip.hardEdge,
    decoration: BoxDecoration(
      color: const Color(0xCC091B23),
      border: Border.all(color: MinePalette.border, width: 1.5),
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [
        BoxShadow(color: Color(0x4434D3CB), blurRadius: 24, spreadRadius: 1),
      ],
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        const Positioned.fill(
          child: Opacity(
            opacity: .62,
            child: VerticalShaftBackground(verticalOffset: 0),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, .35),
                radius: .78,
                colors: [const Color(0x00102029), const Color(0xC8091B23)],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -size * .05,
          child: ContinuousDrillRig(width: size * .66, height: size * .74),
        ),
        Positioned(
          top: size * .08,
          right: size * .08,
          child: AnimatedCrewSprite(
            index: 3,
            action: CrewAction.scanning,
            width: size * .29,
            height: size * .29,
            phaseOffset: .2,
            advisorDroneAnimation: true,
          ),
        ),
      ],
    ),
  );
}
