import 'package:flutter/material.dart';

import '../../app/game_controller.dart';
import '../../core/design/palette.dart';
import '../../crusher/localization.dart';

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
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _alarmFadeController;
  bool _wasFrenzyActive = false;
  double _lastRemainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _alarmFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );

    _wasFrenzyActive = widget.controller.isFrenzyActive;
    _lastRemainingSeconds = widget.controller.frenzyRemainingSeconds;

    widget.controller.addListener(_onControllerTick);

    if (widget.controller.isFrenzyActive) {
      _triggerAlarm();
    }
  }

  void _triggerAlarm() {
    _pulseController.repeat(reverse: true);
    _alarmFadeController.forward(from: 0.0).then((_) {
      if (mounted) {
        _pulseController.stop();
      }
    });
  }

  void _onControllerTick() {
    final isFrenzy = widget.controller.isFrenzyActive;
    final remaining = widget.controller.frenzyRemainingSeconds;

    if (isFrenzy) {
      if (!_wasFrenzyActive || remaining > _lastRemainingSeconds + 2.0) {
        _triggerAlarm();
      }
    } else if (_wasFrenzyActive) {
      if (_pulseController.isAnimating) _pulseController.stop();
      if (_alarmFadeController.isAnimating) _alarmFadeController.reset();
    }

    _wasFrenzyActive = isFrenzy;
    _lastRemainingSeconds = remaining;
  }

  @override
  void didUpdateWidget(FrenzyOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerTick);
      widget.controller.addListener(_onControllerTick);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerTick);
    _pulseController.dispose();
    _alarmFadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.controller,
        _pulseController,
        _alarmFadeController,
      ]),
      builder: (context, _) {
        final isFrenzy = widget.controller.isFrenzyActive;
        if (!isFrenzy) return const SizedBox.shrink();

        final remaining = widget.controller.frenzyRemainingSeconds;
        final pulse = _pulseController.value;

        // Alarm efekti: İlk 2.2 sn yanıp söner, son 1.3 sn içinde yumuşakça solarak biter
        final fadeProgress = _alarmFadeController.value;
        final alarmOpacity = _alarmFadeController.isCompleted
            ? 0.0
            : (fadeProgress < 0.65
                ? 1.0
                : ((1.0 - fadeProgress) / 0.35).clamp(0.0, 1.0));

        return IgnorePointer(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Ekran kenarlarındaki yanıp sönen alarm ışığı (sadece ilk ~3.5 saniye sürer ve tamamen kaybolur)
              if (alarmOpacity > 0.01)
                Opacity(
                  opacity: alarmOpacity,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Color.lerp(
                          const Color(0xFFFF5722),
                          const Color(0xFFFFC107),
                          pulse,
                        )!.withValues(alpha: (0.35 + 0.35 * pulse) * alarmOpacity),
                        width: 3.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6D00)
                              .withValues(alpha: (0.25 + 0.25 * pulse) * alarmOpacity),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
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
                          context.gameText(
                            'ÇILGINLIK 2X  •  {seconds}s',
                            values: {
                              'seconds': remaining.toStringAsFixed(1),
                            },
                          ),
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
