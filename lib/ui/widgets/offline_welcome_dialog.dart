import 'package:flutter/material.dart';

import '../../app/game_controller.dart';
import '../../core/design/palette.dart';
import '../../crusher/localization.dart';
import '../../services/ad_service.dart';
import '../../services/haptic_service.dart';
import '../../services/sound_service.dart';

class OfflineWelcomeDialog extends StatelessWidget {
  const OfflineWelcomeDialog({
    super.key,
    required this.report,
    required this.controller,
    required this.onDismiss,
  });

  final OfflineShiftReport report;
  final GameController controller;
  final VoidCallback onDismiss;

  String _formatDuration(BuildContext context, int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return context.gameText(
        '{hours} saat {minutes} dakika',
        values: {'hours': hours, 'minutes': minutes},
      );
    }
    return context.gameText('{minutes} dakika', values: {'minutes': minutes});
  }

  Future<void> _claimDoubleReward(BuildContext context) async {
    final success = await AdService.instance.showRewardedAd(
      context: context,
      placement: 'offline_double_reward',
      rewardTitle: context.gameText('2X ÇEVRİMDİŞİ KAZANÇ KATLAMA'),
      rewardSubtitle: context.gameText(
        '+{ore} ekstra cevher ve +{depth}m derinlik',
        values: {
          'ore': report.oreGained,
          'depth': report.depthGained.toStringAsFixed(0),
        },
      ),
    );
    if (success && context.mounted) {
      controller.doubleOfflineRewards(report);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: MinePalette.ink,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: MinePalette.border, width: 1.5),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Badge & Title
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF102D38),
                  shape: BoxShape.circle,
                  border: Border.all(color: MinePalette.amber, width: 1.5),
                ),
                child: const Icon(
                  Icons.construction_rounded,
                  color: MinePalette.amber,
                  size: 32,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                context.gameText('HOŞ GELDİN ŞEF!'),
                style: TextStyle(
                  color: MinePalette.cream,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.gameText(
                  'Sen yokken madencilerin durmaksızın çalıştı.\nİşte vardiya özeti:',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: MinePalette.cream.withValues(alpha: 0.8),
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 18),

              // Shift Statistics Card
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1B22),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: MinePalette.border),
                ),
                child: Column(
                  children: [
                    _StatRow(
                      icon: Icons.hourglass_top_rounded,
                      iconColor: MinePalette.cyan,
                      label: context.gameText('Geçen Süre'),
                      value: _formatDuration(context, report.durationSeconds),
                    ),
                    const Divider(color: MinePalette.border, height: 16),
                    _StatRow(
                      icon: Icons.terrain_rounded,
                      iconColor: MinePalette.amber,
                      label: context.gameText('Çıkarılan Cevher'),
                      value: '+${report.oreGained}',
                    ),
                    const Divider(color: MinePalette.border, height: 16),
                    _StatRow(
                      icon: Icons.south_rounded,
                      iconColor: const Color(0xFF64FFDA),
                      label: context.gameText('Sondaj İlerlemesi'),
                      value: '+${report.depthGained.toStringAsFixed(0)} m',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 1. STRATEJİK REKLAM BUTONU: 2X AL (YÜKSEK CTR)
              Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFB300), Color(0xFFFF8F00)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.4),
                      blurRadius: 14,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: const Color(0xFF1E1100),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: withButtonTapSound(() => _claimDoubleReward(context)),
                  icon: const Icon(Icons.bolt_rounded, size: 24),
                  label: Text(
                    context.gameText('2X AL · REKLAM İZLE'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Normal Confirm Button (Pasif / İkincil)
              SizedBox(
                width: double.infinity,
                height: 40,
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: MinePalette.cream.withValues(alpha: 0.7),
                  ),
                  onPressed: withButtonTapSound(() {
                    HapticService.instance.mediumImpact();
                    onDismiss();
                  }),
                  child: Text(
                    context.gameText('Normal Aktar (+${report.oreGained})'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: MinePalette.cream.withValues(alpha: 0.7),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: MinePalette.cream,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
