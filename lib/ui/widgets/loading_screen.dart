import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/design/palette.dart';
import '../../crusher/localization.dart';
import 'atlas_sprite.dart';
import 'character_animation.dart';

/// Branded first frame shown while the save and game systems initialize.
class MineLoadingScreen extends StatefulWidget {
  const MineLoadingScreen({
    super.key,
    this.isLoaded = false,
    this.postLoadDuration = const Duration(seconds: 6),
    this.onFinished,
  });

  final bool isLoaded;
  final Duration postLoadDuration;
  final VoidCallback? onFinished;

  @override
  State<MineLoadingScreen> createState() => _MineLoadingScreenState();
}

class _MineLoadingScreenState extends State<MineLoadingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _shimmerController;
  late final AnimationController _progressController;
  bool _finished = false;
  bool _postLoadStarted = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed && _progressController.value >= 1.0) {
        _notifyFinished();
      }
    });

    if (widget.isLoaded) {
      _startPostLoadAnimation();
    } else {
      _progressController.animateTo(0.35, curve: Curves.easeOutCubic);
    }
  }

  void _startPostLoadAnimation() {
    if (_postLoadStarted || _finished) return;
    _postLoadStarted = true;

    if (widget.postLoadDuration == Duration.zero) {
      _progressController.value = 1.0;
      _notifyFinished();
      return;
    }

    _progressController.duration = widget.postLoadDuration;
    _progressController.animateTo(1.0, curve: Curves.easeInOutCubic);
  }

  void _notifyFinished() {
    if (_finished || !mounted) return;
    _finished = true;
    widget.onFinished?.call();
  }

  @override
  void didUpdateWidget(covariant MineLoadingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoaded && !oldWidget.isLoaded) {
      _startPostLoadAnimation();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shimmerController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  String _stageMessage(double progress, BuildContext context) {
    if (progress < 0.25) {
      return context.gameText('Asansör ve sondaj ekibi vardiyaya hazırlanıyor.');
    }
    if (progress < 0.50) {
      return context.gameText('Yeraltı katmanları ve sismik sensörler taranıyor.');
    }
    if (progress < 0.75) {
      return context.gameText(
        'Kuyu hattı, raylar ve cevher siloları kontrol ediliyor.',
      );
    }
    if (progress < 0.95) {
      return context.gameText('Matkap motorları ısıtılıyor ve ekip sahaya iniyor.');
    }
    return context.gameText('Tüm sistemler devrede! Yeraltına iniş başlıyor.');
  }

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
                compact ? 240.0 : 290.0,
                math.max(160.0, constraints.maxHeight * .34),
              );
              return Center(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 470),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 22 : 36,
                        vertical: 16,
                      ),
                    child: AnimatedBuilder(
                      animation: Listenable.merge([
                        _pulseController,
                        _shimmerController,
                        _progressController,
                      ]),
                      builder: (context, _) {
                        final progress = _progressController.value;
                        final pulse = _pulseController.value;
                        final shimmer = _shimmerController.value;
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _LoadingHeader(compact: compact),
                            SizedBox(height: compact ? 20 : 30),
                            _LoadingMineScene(
                              size: figureSize,
                              pulse: pulse,
                            ),
                            SizedBox(height: compact ? 16 : 22),
                            Text(
                              context.gameText('MADEN HAZIRLANIYOR'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: MinePalette.cream,
                                fontSize: compact ? 17 : 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(height: 7),
                            SizedBox(
                              height: 32,
                              child: Center(
                                child: Text(
                                  _stageMessage(progress, context),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: MinePalette.muted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: compact ? 14 : 20),
                            _LoadingProgressBar(
                              progress: progress,
                              shimmer: shimmer,
                              compact: compact,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Transform.scale(
                                  scale: 0.9 + 0.2 * pulse,
                                  child: const Icon(
                                    Icons.sensors_rounded,
                                    color: MinePalette.cyan,
                                    size: 13,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  context.gameText(
                                    'YERALTI SİSTEMLERİ KONTROL EDİLİYOR',
                                  ),
                                  style: const TextStyle(
                                    color: MinePalette.muted,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: .65,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
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
              context.gameText('TAŞIN ALTI'),
              style: TextStyle(
                color: MinePalette.cream,
                fontSize: compact ? 17 : 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              context.gameText('YERALTI MADENİ'),
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, color: MinePalette.cyan, size: 7),
            SizedBox(width: 5),
            Text(
              context.gameText('VARDİYA'),
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
  const _LoadingMineScene({required this.size, this.pulse = 0.0});

  final double size;
  final double pulse;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    clipBehavior: Clip.hardEdge,
    decoration: BoxDecoration(
      color: const Color(0xCC091B23),
      border: Border.all(color: MinePalette.border, width: 1.5),
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Color.lerp(
            const Color(0x3334D3CB),
            const Color(0x7734D3CB),
            pulse,
          )!,
          blurRadius: 20 + 14 * pulse,
          spreadRadius: 1 + 2 * pulse,
        ),
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

class _LoadingProgressBar extends StatelessWidget {
  const _LoadingProgressBar({
    required this.progress,
    required this.shimmer,
    required this.compact,
  });

  final double progress;
  final double shimmer;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).clamp(0, 100).toInt();
    final isDone = progress >= 1.0;
    return SizedBox(
      width: 320,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: isDone ? MinePalette.teal : MinePalette.amber,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isDone ? MinePalette.teal : MinePalette.amber)
                              .withValues(alpha: 0.6),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isDone
                        ? context.gameText('GİRİŞ YAPILIYOR...')
                        : context.gameText('YÜKLENİYOR...'),
                    style: const TextStyle(
                      color: MinePalette.muted,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Text(
                '%$percent',
                style: const TextStyle(
                  color: MinePalette.amber,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Container(
            height: 9,
            decoration: BoxDecoration(
              color: const Color(0xEE06161D),
              border: Border.all(color: MinePalette.border, width: 1.2),
              borderRadius: BorderRadius.circular(6),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4.5),
              child: Stack(
                children: [
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress.clamp(0.01, 1.0),
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            MinePalette.amber,
                            Color(0xFFFFC247),
                            MinePalette.cyan,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x66F0A52E),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final barWidth = constraints.maxWidth;
                        final shimmerLeft = (shimmer * (barWidth + 60)) - 30;
                        return Stack(
                          children: [
                            Positioned(
                              left: shimmerLeft,
                              top: 0,
                              bottom: 0,
                              width: 32,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withValues(alpha: 0.0),
                                      Colors.white.withValues(alpha: 0.35),
                                      Colors.white.withValues(alpha: 0.0),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
