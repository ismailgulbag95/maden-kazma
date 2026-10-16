import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/game_controller.dart';
import '../../core/design/palette.dart';
import '../../crusher/localization.dart';
import '../../services/sound_service.dart';

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
                      Expanded(
                        child: Text(
                          context.gameText('AYARLAR'),
                          style: TextStyle(
                            color: MinePalette.cream,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .7,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: context.gameText('Kapat'),
                        onPressed: withButtonTapSound(
                          () => Navigator.pop(context),
                        ),
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
                      _SettingsSectionTitle(context.gameText('OYUN')),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.language_rounded),
                        title: Text(context.gameText('Oyun dili')),
                        subtitle: Text(
                          context.gameText('Tercih ettiğin dili seç.'),
                        ),
                        trailing: DropdownButton<String>(
                          value: state.languageCode,
                          items: const [
                            DropdownMenuItem(
                              value: 'tr',
                              child: Text('Türkçe'),
                            ),
                            DropdownMenuItem(
                              value: 'en',
                              child: Text('English'),
                            ),
                          ],
                          onChanged: withButtonTapSoundValue<String?>((
                            languageCode,
                          ) {
                            if (languageCode != null) {
                              controller.setLanguageCode(languageCode);
                            }
                          }),
                        ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary: const Icon(Icons.music_note_rounded),
                        title: Text(context.gameText('Arka plan müziği')),
                        value: state.musicEnabled,
                        onChanged: withButtonTapSoundValue(
                          controller.setMusicEnabled,
                        ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary: const Icon(Icons.volume_up_rounded),
                        title: Text(context.gameText('Ses efektleri')),
                        value: state.soundEffectsEnabled,
                        onChanged: withButtonTapSoundValue(
                          controller.setSoundEffectsEnabled,
                        ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary: const Icon(Icons.vibration_rounded),
                        title: Text(context.gameText('Titreşim (Haptik)')),
                        subtitle: Text(
                          context.gameText('Kazma ve vuruş geribildirimleri'),
                        ),
                        value: state.hapticsEnabled,
                        onChanged: withButtonTapSoundValue(
                          controller.setHapticsEnabled,
                        ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary: const Icon(Icons.auto_awesome_rounded),
                        title: Text(context.gameText('Görsel efektler')),
                        subtitle: Text(
                          context.gameText(
                            'Maden ve oyun içi hareket efektleri',
                          ),
                        ),
                        value: state.visualEffectsEnabled,
                        onChanged: withButtonTapSoundValue(
                          controller.setVisualEffectsEnabled,
                        ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary: const Icon(
                          Icons.notifications_active_rounded,
                        ),
                        title: Text(
                          context.gameText('Maden Telsizi & Bildirimler'),
                        ),
                        subtitle: Text(
                          context.gameText(
                            'Ambar dolumu, günlük vardiya ve sismik alarmlar',
                          ),
                        ),
                        value: state.notificationsEnabled,
                        onChanged: withButtonTapSoundValue(
                          (val) => controller.setNotificationsEnabled(val),
                        ),
                      ),
                      if (onReplayOpeningComic != null) ...[
                        const SizedBox(height: 6),
                        OutlinedButton.icon(
                          onPressed: withButtonTapSound(() {
                            Navigator.of(context).pop();
                            onReplayOpeningComic!.call();
                          }),
                          icon: const Icon(Icons.auto_stories_rounded),
                          label: Text(
                            context.gameText(
                              'AÇILIŞ ÇİZGİ ROMANINI TEKRAR İZLE',
                            ),
                          ),
                        ),
                      ],
                      const Divider(height: 20, color: MinePalette.border),
                      _SettingsSectionTitle(context.gameText('KAYIT YÖNETİMİ')),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: withButtonTapSound(() async {
                                await controller.saveNow();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        context.gameText('Oyun kaydedildi.'),
                                      ),
                                    ),
                                  );
                                }
                              }),
                              icon: const Icon(Icons.save_rounded, size: 18),
                              label: Text(context.gameText('ŞİMDİ KAYDET')),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: withButtonTapSound(() {
                                final exportCode = controller.exportSaveData();
                                Clipboard.setData(
                                  ClipboardData(text: exportCode),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      context.gameText(
                                        'Kayıt kodu panoya kopyalandı! Güvenle saklayabilirsiniz.',
                                      ),
                                    ),
                                  ),
                                );
                              }),
                              icon: const Icon(Icons.copy_rounded, size: 18),
                              label: Text(context.gameText('KAYDI KOPYALA')),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: withButtonTapSound(
                                () => _showImportSaveDialog(context),
                              ),
                              icon: const Icon(
                                Icons.file_upload_rounded,
                                size: 18,
                              ),
                              label: Text(context.gameText('KAYIT YÜKLE')),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: MinePalette.danger,
                        ),
                        onPressed: withButtonTapSound(
                          () => _confirmAction(
                            context,
                            title: context.gameText('Oyunu sıfırla?'),
                            message: context.gameText(
                              'Mevcut vardiya ve ilerleme silinecek. Yeni oyun sıfırdan başlayacak.',
                            ),
                            label: context.gameText('OYUNU SIFIRLA'),
                            icon: Icons.restart_alt_rounded,
                            action: controller.startNewGame,
                          ),
                        ),
                        icon: const Icon(Icons.restart_alt_rounded),
                        label: Text(context.gameText('OYUNU SIFIRLA')),
                      ),
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
        title: Text(context.gameText(title)),
        content: Text(context.gameText(message)),
        actions: [
          TextButton(
            onPressed: withButtonTapSound(
              () => Navigator.pop(dialogContext, false),
            ),
            child: Text(context.gameText('VAZGEÇ')),
          ),
          FilledButton.icon(
            onPressed: withButtonTapSound(
              () => Navigator.pop(dialogContext, true),
            ),
            icon: Icon(icon),
            label: Text(context.gameText(label)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    action();
    Navigator.pop(context);
  }

  Future<void> _showImportSaveDialog(BuildContext context) async {
    final textController = TextEditingController();
    try {
      final imported = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: MinePalette.panel,
          title: Text(context.gameText('Kayıt Kodu Yükle')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.gameText(
                  'Daha önce kopyaladığınız kayıt kodunu veya JSON verisini buraya yapıştırın:',
                ),
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                maxLines: 4,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  hintText: context.gameText('Kayıt kodunu yapıştırın...'),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: withButtonTapSound(
                () => Navigator.pop(dialogContext, false),
              ),
              child: Text(context.gameText('VAZGEÇ')),
            ),
            FilledButton.icon(
              onPressed: withButtonTapSound(() {
                final text = textController.text.trim();
                if (text.isEmpty) return;
                final success = controller.importSaveData(text);
                Navigator.pop(dialogContext, success);
              }),
              icon: const Icon(Icons.file_upload_rounded),
              label: Text(context.gameText('YÜKLE')),
            ),
          ],
        ),
      );

      if (imported == true && context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.gameText('Kayıt başarıyla yüklendi ve güncellendi!'),
            ),
          ),
        );
      }
    } finally {
      textController.dispose();
    }
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
