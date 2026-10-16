import 'package:flutter/material.dart';

import '../../core/design/palette.dart';
import '../../crusher/localization.dart';
import '../../services/haptic_service.dart';
import '../../services/sound_service.dart';

class NotificationPermissionDialog extends StatelessWidget {
  const NotificationPermissionDialog({
    super.key,
    required this.onEnable,
    required this.onDismiss,
  });

  final Future<void> Function() onEnable;
  final VoidCallback onDismiss;

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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: dynamicSize(context),
              children: [
                // Header Badge & Icon
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF102D38),
                    shape: BoxShape.circle,
                    border: Border.all(color: MinePalette.amber, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: MinePalette.amber.withValues(alpha: 0.25),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    color: MinePalette.amber,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  context.gameText('MADEN TELSİZİ FREKANSI'),
                  style: TextStyle(
                    color: MinePalette.cream,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  context.gameText(
                    'Madenin derinliklerindeki fırsatları kaçırmamak için telsiz bağlantısını aktif et şef!',
                  ),
                  style: TextStyle(
                    color: MinePalette.muted,
                    fontSize: 13,
                    height: 1.35,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Benefits List
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: MinePalette.panel,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: MinePalette.border),
                  ),
                  child: const Column(
                    children: [
                      _BenefitRow(
                        icon: Icons.inventory_2_rounded,
                        iconColor: MinePalette.amber,
                        title: 'Ambar Dolum Alarmı',
                        description: 'Madencilerin ambarı doldurunca boş durmasın, anında satıp kazan.',
                      ),
                      Divider(color: MinePalette.border, height: 18),
                      _BenefitRow(
                        icon: Icons.assignment_turned_in_rounded,
                        iconColor: MinePalette.cyan,
                        title: 'Günlük Vardiya Görevleri',
                        description: 'Her gece yenilenen müfettiş görevleri ve maden parası ödülleri.',
                      ),
                      Divider(color: MinePalette.border, height: 18),
                      _BenefitRow(
                        icon: Icons.diamond_rounded,
                        iconColor: Color(0xFF90CAF9),
                        title: 'Sismik Damar Keşifleri',
                        description: 'Nadir elmas ve yakut damarları yüzeye çıktığında telsizden haber al.',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // Action Buttons
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: withButtonTapSound(() async {
                      HapticService.instance.selectionClick();
                      Navigator.of(context).pop();
                      await onEnable();
                    }),
                    icon: const Icon(Icons.check_circle_rounded, size: 20),
                    label: Text(
                      context.gameText(
                        'TELSİZİ AÇ (BİLDİRİMLERİ ETKİNLEŞTİR)',
                      ),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        fontSize: 13,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MinePalette.amber,
                      foregroundColor: MinePalette.ink,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: withButtonTapSound(() {
                      HapticService.instance.lightTap();
                      Navigator.of(context).pop();
                      onDismiss();
                    }),
                    child: Text(
                      context.gameText('ŞİMDİ DEĞİL, DAHA SONRA'),
                      style: TextStyle(
                        color: MinePalette.muted,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        letterSpacing: 0.5,
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

  MainAxisSize dynamicSize(BuildContext context) => MainAxisSize.min;
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.gameText(title),
                style: const TextStyle(
                  color: MinePalette.cream,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                context.gameText(description),
                style: const TextStyle(
                  color: MinePalette.muted,
                  fontSize: 11.5,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
