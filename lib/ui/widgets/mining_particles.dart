import 'dart:math' as math;
import 'package:flutter/material.dart';

class ParticleShard {
  ParticleShard({
    required this.dx,
    required this.dy,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
  });

  double dx;
  double dy;
  final double vx;
  final double vy;
  final double size;
  final Color color;
}

class MiningParticleBurst extends StatefulWidget {
  const MiningParticleBurst({
    super.key,
    required this.color,
    this.particleCount = 10,
    this.burstRadius = 40.0,
  });

  final Color color;
  final int particleCount;
  final double burstRadius;

  @override
  State<MiningParticleBurst> createState() => _MiningParticleBurstState();
}

class _MiningParticleBurstState extends State<MiningParticleBurst>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<ParticleShard> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    for (var i = 0; i < widget.particleCount; i++) {
      final angle = _random.nextDouble() * 2 * math.pi;
      final speed = 25.0 + _random.nextDouble() * widget.burstRadius;
      final size = 2.5 + _random.nextDouble() * 3.5;
      final variant = HSVColor.fromColor(widget.color);
      final adjusted = variant.withValue(
        (variant.value + (_random.nextDouble() * .3 - .15)).clamp(0.2, 1.0),
      ).toColor();

      _particles.add(
        ParticleShard(
          dx: 0,
          dy: 0,
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed - 15, // slight upward impulse
          size: size,
          color: adjusted,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final opacity = (1.0 - t).clamp(0.0, 1.0);
        return Opacity(
          opacity: opacity,
          child: CustomPaint(
            size: Size.zero,
            painter: _ParticlePainter(
              particles: _particles,
              progress: t,
            ),
          ),
        );
      },
    );
  }
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({
    required this.particles,
    required this.progress,
  });

  final List<ParticleShard> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final p in particles) {
      // Simple gravity trajectory
      final currentX = p.dx + p.vx * progress;
      final currentY = p.dy + p.vy * progress + (60 * progress * progress);
      paint.color = p.color;
      canvas.drawCircle(
        Offset(currentX, currentY),
        p.size * (1.0 - progress * 0.4),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
