import 'dart:async';
import 'package:flutter/material.dart';

import '../core/design/palette.dart';
import '../crusher/localization.dart';
import 'haptic_service.dart';
import 'sound_service.dart';

/// Oyun içi ödüllü reklamları (Rewarded Ads) yöneten merkezi servis.
/// Web, mobil ve masaüstünde kesintisiz çalışır. Gerçek AdMob/Unity Ads
/// entegrasyonunda sadece showRewardedAd içindeki platform çağrısı etkinleştirilir.
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  /// Oyuncu 'Reklamsızlık' (No Ads) paketi satın aldıysa true olur.
  /// True olduğunda reklam izletmeden ödülü anında verir!
  bool isAdFreePurchased = false;

  /// Toplam izlenen reklam sayısı
  int totalAdsWatched = 0;

  /// Son Lucky Drone çıkış zamanı (Spam engelleme - Cooldown)
  DateTime? lastDroneSpawnTime;

  /// Drone tekrar çıkabilir mi? (En az 180 saniye / 3 dakika aralık)
  bool get canSpawnLuckyDrone {
    if (lastDroneSpawnTime == null) return true;
    return DateTime.now().difference(lastDroneSpawnTime!).inSeconds >= 180;
  }

  void markDroneSpawned() {
    lastDroneSpawnTime = DateTime.now();
  }

  /// Ödüllü reklam gösterir.
  /// Reklam başarıyla tamamlanırsa `true`, oyuncu yarıda kapatırsa `false` döner.
  Future<bool> showRewardedAd({
    required BuildContext context,
    required String placement,
    required String rewardTitle,
    String? rewardSubtitle,
  }) async {
    // Eğer reklamsızlık satın alınmışsa beklemeden ödülü ver
    if (isAdFreePurchased) {
      totalAdsWatched++;
      HapticService.instance.mediumImpact();
      return true;
    }

    final completed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _RewardedAdDialog(
        placement: placement,
        rewardTitle: rewardTitle,
        rewardSubtitle: rewardSubtitle,
      ),
    );

    if (completed == true) {
      totalAdsWatched++;
      HapticService.instance.heavyImpact();
      unawaited(SoundService.instance.playChestOpen());
      return true;
    }
    return false;
  }
}

class _RewardedAdDialog extends StatefulWidget {
  const _RewardedAdDialog({
    required this.placement,
    required this.rewardTitle,
    this.rewardSubtitle,
  });

  final String placement;
  final String rewardTitle;
  final String? rewardSubtitle;

  @override
  State<_RewardedAdDialog> createState() => _RewardedAdDialogState();
}

class _RewardedAdDialogState extends State<_RewardedAdDialog> {
  static const int _adDurationSeconds = 4;
  int _secondsRemaining = _adDurationSeconds;
  Timer? _timer;
  bool _canSkip = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining > 1) {
        setState(() {
          _secondsRemaining--;
          if (_secondsRemaining <= 1) {
            _canSkip = true;
          }
        });
      } else {
        _timer?.cancel();
        setState(() {
          _secondsRemaining = 0;
          _canSkip = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (1.0 - (_secondsRemaining / _adDurationSeconds)).clamp(0.0, 1.0);
    final isDone = _secondsRemaining == 0;
    const accentGreen = Color(0xFF64FFDA);

    return PopScope(
      canPop: _canSkip,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            color: MinePalette.ink,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: MinePalette.amber, width: 2),
            boxShadow: [
              BoxShadow(
                color: MinePalette.amber.withValues(alpha: 0.35),
                blurRadius: 28,
                spreadRadius: 2,
              ),
            ],
          ),
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Tag
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: MinePalette.amber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: MinePalette.amber),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.stars_rounded, color: MinePalette.amber, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          context.gameText('SPONSOR DESTEK YAYINI'),
                          style: const TextStyle(
                            color: MinePalette.amber,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isDone)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${_secondsRemaining}s',
                        style: const TextStyle(
                          color: MinePalette.cream,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // Visual Ad Screen Simulation
              Container(
                width: double.infinity,
                height: 160,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF132A36), Color(0xFF09141B)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: MinePalette.border),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment.center,
                            radius: 0.8,
                            colors: [
                              (isDone ? accentGreen : MinePalette.cyan)
                                  .withValues(alpha: 0.15),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isDone ? Icons.verified_rounded : Icons.live_tv_rounded,
                          size: 48,
                          color: isDone ? accentGreen : MinePalette.cyan,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isDone
                              ? context.gameText('ÖDÜL KİLİDİ AÇILDI!')
                              : context.gameText('Sponsor Mesajı Aktarılıyor...'),
                          style: TextStyle(
                            color: isDone ? accentGreen : MinePalette.cream,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.placement.toUpperCase(),
                          style: TextStyle(
                            color: MinePalette.cream.withValues(alpha: 0.6),
                            fontSize: 11,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Reward Highlight Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF102833),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: MinePalette.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.card_giftcard_rounded, color: MinePalette.amber, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.rewardTitle,
                            style: const TextStyle(
                              color: MinePalette.cream,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (widget.rewardSubtitle != null)
                            Text(
                              widget.rewardSubtitle!,
                              style: TextStyle(
                                color: MinePalette.cream.withValues(alpha: 0.7),
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: const Color(0xFF1A3847),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDone ? accentGreen : MinePalette.amber,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Actions
              Row(
                children: [
                  if (!isDone)
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: MinePalette.cream.withValues(alpha: 0.7),
                          side: const BorderSide(color: MinePalette.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(context.gameText('Vazgeç')),
                      ),
                    ),
                  if (!isDone) const SizedBox(width: 12),
                  Expanded(
                    flex: isDone ? 2 : 1,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: isDone ? accentGreen : MinePalette.cyan,
                        foregroundColor: MinePalette.ink,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: isDone
                          ? () => Navigator.of(context).pop(true)
                          : null,
                      icon: Icon(isDone ? Icons.check_circle_rounded : Icons.hourglass_empty_rounded, size: 18),
                      label: Text(
                        isDone
                            ? context.gameText('ÖDÜLÜ AL')
                            : context.gameText('Bekleyin (${_secondsRemaining}s)'),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
