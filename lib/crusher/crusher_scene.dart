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
    if (!kIsWeb && game.soundEnabled) SystemSound.play(SystemSoundType.click);
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
          Positioned(
            top: compact ? 8 : 14,
            left: compact ? 8 : 15,
            child: _GlassLabel(
              icon: Icons.settings_input_component_rounded,
              label: gameText(
                game.language,
                compact ? 'machineShort' : 'machine',
              ),
            ),
          ),
          if (game.isHalted)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xeb1f0a0a),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xffff4444), width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: Colors.black87, blurRadius: 18, offset: Offset(0, 4)),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.pause_circle_filled_rounded, color: Color(0xffff5555), size: 24),
                    SizedBox(width: 10),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AMBAR DOLU',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            color: Color(0xffffdddd),
                          ),
                        ),
                        Text(
                          'Kırıcı durduruldu · Satış yapın',
                          style: TextStyle(
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
          if (!compact)
            Positioned(
              bottom: 14,
              right: 15,
              child: _AutoBadge(rpm: game.rpm, language: game.language),
            ),
          Positioned(
            top: compact ? 45 : 56,
            left: compact ? 8 : 15,
            child: _GlassLabel(
              icon: game.specialRockActive
                  ? Icons.auto_awesome_rounded
                  : Icons.diamond_outlined,
              label: game.specialRockActive
                  ? gameText(game.language, 'specialStone')
                  : '${gameText(game.language, 'currentOre')}: ${gameText(game.language, game.currentMaterial.id).toUpperCase()} ',
              accent: game.specialRockActive
                  ? const Color(0xffffd46a)
                  : game.currentMaterial.glow,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: compact ? 8 : 13,
            child: Center(
              child: _TouchHint(language: game.language, compact: compact),
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
                    child: _GamePopup(
                      key: ValueKey(game.messageId),
                      game: game,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GlassLabel extends StatelessWidget {
  const _GlassLabel({required this.icon, required this.label, this.accent});
  final IconData icon;
  final String label;
  final Color? accent;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
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
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xffdce3ec),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: .65,
          ),
        ),
      ],
    ),
  );
}

class _AutoBadge extends StatelessWidget {
  const _AutoBadge({required this.rpm, required this.language});
  final int rpm;
  final String language;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: const Color(0xd9141c28),
      border: Border.all(color: const Color(0xffc7ed6f).withValues(alpha: .28)),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Color(0xffc7ed6f),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Color(0xffc7ed6f), blurRadius: 7)],
          ),
        ),
        const SizedBox(width: 7),
        Text(
          gameText(language, 'automatic'),
          style: const TextStyle(
            color: Color(0xffd8e4ba),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: .8,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$rpm ${gameText(language, 'rpmUnit')}',
          style: const TextStyle(
            color: Color(0xff8e9aab),
            fontSize: 11,
            fontFamily: 'monospace',
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
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
    constraints: BoxConstraints(maxWidth: compact ? 310 : double.infinity),
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
          size: compact ? 13 : 14,
          color: const Color(0xffc8ef70),
        ),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            gameText(language, 'tap'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xffe3e9ef),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: .5,
            ),
          ),
        ),
      ],
    ),
  );
}

class _GamePopup extends StatelessWidget {
  const _GamePopup({super.key, required this.game});
  final CrusherGame game;

  @override
  Widget build(BuildContext context) {
    final key = game.messageKey!;
    final text = switch (key) {
      'crushed' => '+${game.messageAmount} Ambara Eklendi',
      'cargoFull' => 'AMBAR DOLU! KIRICI DURDU',
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
      key: key == 'crushed' ? ValueKey('${game.messageId}-coin') : null,
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
