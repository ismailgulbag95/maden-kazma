import 'package:flutter/material.dart';

import '../../app/game_controller.dart';
import '../../core/design/palette.dart';

class SettingsDialog extends StatelessWidget {
  const SettingsDialog({
    super.key,
    required this.controller,
    this.onReplayOpeningComic,
  });

  final GameController controller;
  final VoidCallback? onReplayOpeningComic;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: MinePalette.ink,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: MinePalette.border, width: 1.4),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.sizeOf(context).height * .88,
        ),
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final state = controller.state;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 14, 8, 14),
                  decoration: const BoxDecoration(
                    color: Color(0xFF102D38),
                    border: Border(
                      bottom: BorderSide(color: MinePalette.border),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.settings_rounded,
                        color: MinePalette.cyan,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'AYARLAR',
                          style: TextStyle(
                            color: MinePalette.cream,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .7,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Kapat',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                    children: [
                      const _SettingsSectionTitle('OYUN'),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary: const Icon(Icons.music_note_rounded),
                        title: const Text('Arka plan müziği'),
                        value: state.musicEnabled,
                        onChanged: controller.setMusicEnabled,
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary: const Icon(Icons.volume_up_rounded),
                        title: const Text('Ses efektleri'),
                        value: state.soundEffectsEnabled,
                        onChanged: controller.setSoundEffectsEnabled,
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary: const Icon(Icons.auto_awesome_rounded),
                        title: const Text('Görsel efektler'),
                        subtitle: const Text(
                          'Maden ve oyun içi hareket efektleri',
                        ),
                        value: state.visualEffectsEnabled,
                        onChanged: controller.setVisualEffectsEnabled,
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary: const Icon(
                          Icons.notifications_active_rounded,
                        ),
                        title: const Text('Bildirimler'),
                        subtitle: const Text('Oyun içi kısa mesajları göster'),
                        value: state.notificationsEnabled,
                        onChanged: controller.setNotificationsEnabled,
                      ),
                      if (onReplayOpeningComic != null)
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            onReplayOpeningComic!.call();
                          },
                          icon: const Icon(Icons.auto_stories_rounded),
                          label: const Text(
                            'AÇILIŞ ÇİZGİ ROMANINI TEKRAR İZLE',
                          ),
                        ),
                      const Divider(height: 20, color: MinePalette.border),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await controller.saveNow();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Oyun kaydedildi.')),
                            );
                          }
                        },
                        icon: const Icon(Icons.save_rounded),
                        label: const Text('ŞİMDİ KAYDET'),
                      ),
                      const Divider(height: 20, color: MinePalette.border),
                      const _SettingsSectionTitle('GELİŞTİRİCİ'),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary: const Icon(Icons.bug_report_rounded),
                        title: const Text('Debug modu'),
                        subtitle: const Text('Geliştirici araçlarını aç'),
                        value: state.debugModeEnabled,
                        onChanged: controller.setDebugModeEnabled,
                      ),
                      if (state.debugModeEnabled) ...[
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          secondary: const Icon(Icons.all_inclusive_rounded),
                          title: const Text('Sınırsız para'),
                          subtitle: const Text(
                            'Satın alımlar para düşürmeden çalışır',
                          ),
                          value: state.debugUnlimitedMoney,
                          onChanged: controller.setDebugUnlimitedMoney,
                        ),
                        const SizedBox(height: 6),
                        OutlinedButton.icon(
                          onPressed: () => _confirmAction(
                            context,
                            title: 'Oyunun sonuna git?',
                            message: 'Derinlik Titan madeninin son açık katına alınacak ve tüm dünya bölgeleri açılacak.',
                            label: 'SON DERİNLİĞE GİT',
                            icon: Icons.south_rounded,
                            action: controller.debugJumpToEnd,
                          ),
                          icon: const Icon(Icons.south_rounded),
                          label: const Text('OYUN SONUNA GİT'),
                        ),
                        const SizedBox(height: 6),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: MinePalette.danger,
                          ),
                          onPressed: () => _confirmAction(
                            context,
                            title: 'Oyunu sıfırla?',
                            message: 'Mevcut vardiya ve ilerleme silinecek. Yeni oyun sıfırdan başlayacak.',
                            label: 'OYUNU SIFIRLA',
                            icon: Icons.restart_alt_rounded,
                            action: controller.startNewGame,
                          ),
                          icon: const Icon(Icons.restart_alt_rounded),
                          label: const Text('OYUNU SIFIRLA'),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmAction(
    BuildContext context, {
    required String title,
    required String message,
    required String label,
    required IconData icon,
    required VoidCallback action,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: MinePalette.panel,
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('VAZGEÇ'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: Icon(icon),
            label: Text(label),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    action();
    Navigator.pop(context);
  }
}

class _SettingsSectionTitle extends StatelessWidget {
  const _SettingsSectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 3, bottom: 5),
    child: Text(
      label,
      style: const TextStyle(
        color: MinePalette.cyan,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: .8,
      ),
    ),
  );
}
