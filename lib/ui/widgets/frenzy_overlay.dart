import 'package:flutter/material.dart';

import '../../app/game_controller.dart';
import '../../core/design/palette.dart';

class FrenzyOverlay extends StatefulWidget {
  const FrenzyOverlay({
    super.key,
    required this.controller,
  });

  final GameController controller;

  @override
  State<FrenzyOverlay> createState() => _FrenzyOverlayState();
}

class _FrenzyOverlayState extends State<FrenzyOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    if (widget.controller.isFrenzyActive) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.controller, _pulseController]),
      builder: (context, _) {
        final isFrenzy = widget.controller.isFrenzyActive;
        if (!isFrenzy) {
          if (_pulseController.isAnimating) {
            _pulseController.stop();
          }
          return const SizedBox.shrink();
        } else if (!_pulseController.isAnimating) {
          _pulseController.repeat(reverse: true);
        }

        final remaining = widget.controller.frenzyRemainingSeconds;
        final pulse = _pulseController.value;

        return IgnorePointer(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Edge fiery glow
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Color.lerp(
                      const Color(0xFFFF5722),
                      const Color(0xFFFFC107),
                      pulse,
                    )!.withValues(alpha: 0.35 + 0.35 * pulse),
                    width: 3.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6D00)
                          .withValues(alpha: 0.25 + 0.25 * pulse),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),

              // Frenzy Banner on Top Center
              Positioned(
                top: MediaQuery.paddingOf(context).top + 54,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE65100), Color(0xFFFF8F00)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      border: Border.all(
                        color: const Color(0xFFFFD54F),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.local_fire_department_rounded,
                          color: MinePalette.cream,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'ÇILGINLIK 2X  •  ${remaining.toStringAsFixed(1)}s',
                          style: const TextStyle(
                            color: MinePalette.cream,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
