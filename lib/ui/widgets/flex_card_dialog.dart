import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/game_controller.dart';
import '../../core/design/palette.dart';
import '../../services/haptic_service.dart';

class FlexCardDialog extends StatelessWidget {
  const FlexCardDialog({
    super.key,
    required this.controller,
  });

  final GameController controller;

  String _getPlayerTitle(double depthMeters) {
    if (depthMeters >= 1782000) return 'Gezegenler Arası Kolonizatör 🪐';
    if (depthMeters >= 1000000) return 'Titan Öncüsü 🚀';
    if (depthMeters >= 500000) return 'Çekirdek Fatihi 🌋';
    if (depthMeters >= 200000) return 'Derinlik Jeoloğu 💎';
    if (depthMeters >= 50000) return 'Maden Şefi ⛏️';
    if (depthMeters >= 10000) return 'Kıdemli Kazıcı ⚒️';
    return 'Acemi Madenci 🪨';
  }

  String _getWorldName(int worldIndex) {
    switch (worldIndex) {
      case 1:
        return 'Ay Kolonisi 🌙';
      case 2:
        return 'Titan Madeni 🪐';
      default:
        return 'Dünya Karakolu 🌍';
    }
  }

  String _buildShareText(BuildContext context) {
    final state = controller.state;
    final depthKm = (state.deepestMeters / 1000).toStringAsFixed(1);
    final title = _getPlayerTitle(state.deepestMeters);
    final world = _getWorldName(state.currentWorldIndex);

    return '⛏️ TAŞIN ALTI — KEŞİF KARNESİ\n'
        '🎖️ Unvan: $title\n'
        '📍 Konum: $world\n'
        '📏 En Derin Nokta: $depthKm km\n'
        '📦 Toplam Çıkarılan: ${state.totalMined} cevher\n'
        '💎 Kasa: ${state.coins.toDisplayString()}\n\n'
        'Yerin altındaki gizemi çözebilir misin? #TasinAlti #MobileGaming';
  }

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final depthKm = (state.deepestMeters / 1000).toStringAsFixed(1);
    final title = _getPlayerTitle(state.deepestMeters);
    final world = _getWorldName(state.currentWorldIndex);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF132F3C), Color(0xFF0A1820), Color(0xFF050E13)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: MinePalette.amber, width: 2),
            boxShadow: [
              BoxShadow(
                color: MinePalette.amber.withValues(alpha: 0.25),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: MinePalette.amber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: MinePalette.amber),
                    ),
                    child: const Text(
                      'KEŞİF KARNESİ',
                      style: TextStyle(
                        color: MinePalette.amber,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: MinePalette.cream),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title & Avatar icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1B4052),
                  border: Border.all(color: MinePalette.cyan, width: 2),
                ),
                child: const Icon(
                  Icons.military_tech_rounded,
                  color: MinePalette.amber,
                  size: 38,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: MinePalette.cream,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                world,
                style: const TextStyle(
                  color: MinePalette.cyan,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),

              // Stats Grid
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: MinePalette.border),
                ),
                child: Column(
                  children: [
                    _FlexStatRow(
                      label: 'En Derin Nokta',
                      value: '$depthKm km',
                      icon: Icons.south_rounded,
                      color: const Color(0xFF64FFDA),
                    ),
                    const Divider(color: MinePalette.border, height: 14),
                    _FlexStatRow(
                      label: 'Toplam Çıkarılan',
                      value: '${state.totalMined} Cevher',
                      icon: Icons.terrain_rounded,
                      color: MinePalette.amber,
                    ),
                    const Divider(color: MinePalette.border, height: 14),
                    _FlexStatRow(
                      label: 'Maden Kasası',
                      value: state.coins.toDisplayString(),
                      icon: Icons.monetization_on_rounded,
                      color: const Color(0xFFFFD54F),
                    ),
                    const Divider(color: MinePalette.border, height: 14),
                    _FlexStatRow(
                      label: 'Bilim Ekibi',
                      value: '${state.scientistRoster.length} Uzman',
                      icon: Icons.science_rounded,
                      color: const Color(0xFF80D8FF),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Share / Copy Button
              SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: MinePalette.amber,
                    foregroundColor: MinePalette.ink,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    HapticService.instance.mediumImpact();
                    final shareText = _buildShareText(context);
                    Clipboard.setData(ClipboardData(text: shareText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Keşif karnesi panoya kopyalandı! Arkadaşlarınla paylaşabilirsin.'),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  },
                  icon: const Icon(Icons.share_rounded),
                  label: const Text(
                    'KARNEYİ KOPYALA / PAYLAŞ',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}

class _FlexStatRow extends StatelessWidget {
  const _FlexStatRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: MinePalette.cream.withValues(alpha: 0.7),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: MinePalette.cream,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
