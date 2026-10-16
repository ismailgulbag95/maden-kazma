import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'crusher_scene_host_stub.dart'
    if (dart.library.io) 'crusher_scene_host_native.dart'
    if (dart.library.js_interop) 'crusher_scene_host_web.dart'
    as scene_host;
import 'crusher_engine.dart';
import 'localization.dart';
import '../services/sound_service.dart';

class CrusherScene extends StatefulWidget {
  const CrusherScene({super.key, required this.game, this.compact = false});
  final CrusherGame game;
  final bool compact;

  @override
  State<CrusherScene> createState() => _CrusherSceneState();
}

class _CrusherSceneState extends State<CrusherScene> {
  Timer? _holdTimer;

  CrusherGame get game => widget.game;

  void _onSceneMessage(String message) {
    if (message == 'up') {
      _holdTimer?.cancel();
      _holdTimer = null;
      return;
    }
    if (!message.startsWith('down:')) return;
    final rockId = int.tryParse(message.substring(5));
    if (rockId == null) return;
    game.manualPress(rockId: rockId);
    if (!kIsWeb && game.hapticsEnabled) HapticFeedback.lightImpact();
    if (game.soundEnabled) unawaited(SoundService.instance.playButtonTap());
    _holdTimer?.cancel();
    _holdTimer = Timer.periodic(
      const Duration(milliseconds: 180),
      (_) => game.manualPress(rockId: rockId),
    );
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = widget.compact;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        fit: StackFit.expand,
        children: [
          scene_host.CrusherSceneRenderer(
            game: game,
            onPointer: _onSceneMessage,
          ),
          CrusherSceneHud(game: game, compact: compact),
        ],
      ),
    );
  }
}

class CrusherSceneHud extends StatelessWidget {
  const CrusherSceneHud({super.key, required this.game, this.compact = false});

  final CrusherGame game;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final language = game.language;
    final mostValuableOre = game.mostValuableRawOre;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (game.isHalted)
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xeb1f0a0a),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xffff4444), width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black87,
                    blurRadius: 18,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.pause_circle_filled_rounded,
                    color: Color(0xffff5555),
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        gameText(language, 'AMBAR DOLU'),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          color: Color(0xffffdddd),
                        ),
                      ),
                      Text(
                        gameText(language, 'Kırıcı durduruldu · Satış yapın'),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xffffaaaa),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        Positioned(
          top: 8,
          left: 8,
          right: 8,
          child: _GlassLabel(
            icon: Icons.diamond_outlined,
            label:
                '${gameText(game.language, 'mostValuableOre')}: '
                '${mostValuableOre == null ? gameText(language, 'noOre') : gameUppercase(language, gameText(language, mostValuableOre.id))}',
            accent: mostValuableOre?.glow ?? const Color(0xffcbd5e1),
            compact: compact,
          ),
        ),
        Positioned(
          left: 8,
          right: 8,
          bottom: 8,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tight = compact || constraints.maxWidth < 380;
              return Row(
                children: [
                  Expanded(
                    child: _TouchHint(language: language, compact: tight),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    fit: FlexFit.loose,
                    child: _AutoBadge(
                      rpm: game.rpm,
                      language: language,
                      compact: tight,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        if (game.messageLife > 0 && game.messageKey != null)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: CrusherPopup(
                    key: ValueKey(game.messageId),
                    game: game,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _GlassLabel extends StatelessWidget {
  const _GlassLabel({
    required this.icon,
    required this.label,
    this.accent,
    this.compact = false,
  });
  final IconData icon;
  final String label;
  final Color? accent;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: compact ? 8 : 11,
      vertical: compact ? 6 : 8,
    ),
    decoration: BoxDecoration(
      color: const Color(0xd9141c28),
      border: Border.all(color: Colors.white.withValues(alpha: .1)),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: accent ?? const Color(0xffcced78)),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: const Color(0xffdce3ec),
              fontSize: compact ? 9 : 11,
              fontWeight: FontWeight.w800,
              letterSpacing: compact ? .15 : .65,
            ),
          ),
        ),
      ],
    ),
  );
}

class _AutoBadge extends StatelessWidget {
  const _AutoBadge({
    required this.rpm,
    required this.language,
    this.compact = false,
  });
  final int rpm;
  final String language;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: compact ? 7 : 10,
      vertical: compact ? 6 : 7,
    ),
    decoration: BoxDecoration(
      color: const Color(0xd9141c28),
      border: Border.all(color: const Color(0xffc7ed6f).withValues(alpha: .28)),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            gameText(language, 'crusherRpm', {'rpm': rpm}),
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: const Color(0xffd8e4ba),
              fontSize: compact ? 9 : 11,
              fontWeight: FontWeight.w800,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    ),
  );
}

class _TouchHint extends StatelessWidget {
  const _TouchHint({required this.language, this.compact = false});
  final String language;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: compact ? 8 : 13,
      vertical: compact ? 6 : 8,
    ),
    decoration: BoxDecoration(
      color: const Color(0xcd121a25),
      border: Border.all(color: Colors.white.withValues(alpha: .12)),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.touch_app_rounded,
          size: compact ? 12 : 14,
          color: const Color(0xffc8ef70),
        ),
        SizedBox(width: compact ? 4 : 7),
        Flexible(
          child: Text(
            gameText(language, 'tap'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Color(0xffe3e9ef),
              fontSize: compact ? 9 : 11,
              fontWeight: FontWeight.w800,
              letterSpacing: compact ? .1 : .5,
            ),
          ),
        ),
      ],
    ),
  );
}

class CrusherPopup extends StatelessWidget {
  const CrusherPopup({super.key, required this.game});
  final CrusherGame game;

  @override
  Widget build(BuildContext context) {
    final key = game.messageKey!;
    if (key == 'crushed') return const SizedBox.shrink();
    final text = switch (key) {
      'cargoFull' => gameText(game.language, 'AMBAR DOLU! KIRICI DURDU'),
      'newLevel' => '${gameText(game.language, key)}  ${game.messageAmount}',
      'missionDone' =>
        '${gameText(game.language, key)}  +${game.messageAmount} ◉',
      'contractComplete' =>
        '${gameText(game.language, key)}  +${game.messageAmount} ◉',
      'oreMilestone' =>
        '${gameText(game.language, key)}  +${game.messageAmount} ◉',
      'boostActive' =>
        '${game.messageAmount}×  ${gameText(game.language, 'boostActive')}',
      _ => gameText(game.language, key),
    };
    final positive = key != 'notEnough' && key != 'cargoFull';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xe816202d),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (positive ? const Color(0xffc8ef70) : const Color(0xffff987e))
              .withValues(alpha: .65),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: positive ? const Color(0xffe7f5c7) : const Color(0xffffb4a2),
          fontSize: 14,
          fontWeight: FontWeight.w900,
          letterSpacing: .4,
        ),
      ),
    );
  }
}
