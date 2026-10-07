import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

class SoundService {
  SoundService._();

  static SoundService? _instance;
  static SoundService get instance => _instance ??= SoundService._();

  static Future<void> disposeIfCreated() async {
    final service = _instance;
    if (service == null) return;
    await service.dispose();
    _instance = null;
  }

  final AudioPlayer _effects = AudioPlayer();
  final AudioPlayer _music = AudioPlayer();
  final AudioPlayer _alarm = AudioPlayer();
  bool sfxEnabled = true;
  bool bgmEnabled = true;
  bool _initialized = false;
  bool _musicPlaying = false;
  bool _alarmPlaying = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    try {
      await _music.setReleaseMode(ReleaseMode.loop);
      await _alarm.setReleaseMode(ReleaseMode.loop);
    } catch (_) {
      // Unsupported audio devices can still run the game without sound.
    }
  }

  Future<void> playChestOpen() => _playEffect('chest_open.wav', .7);

  Future<void> playCaveDrone() => _playEffect('cave_drone.wav', .55);

  Future<void> playOreCollect() => _playEffect('ore_collect.wav', .35);

  Future<void> _playEffect(String fileName, double volume) async {
    if (!sfxEnabled) return;
    try {
      await _effects.play(AssetSource('audio/$fileName'), volume: volume);
    } catch (_) {
      // Audio is optional; gameplay continues if a platform cannot play it.
    }
  }

  Future<void> startReactorAlarm() async {
    if (!sfxEnabled || _alarmPlaying) return;
    await initialize();
    _alarmPlaying = true;
    try {
      await _alarm.play(AssetSource('audio/reactor_alarm.wav'), volume: .7);
    } catch (_) {
      _alarmPlaying = false;
    }
  }

  Future<void> stopReactorAlarm() async {
    if (!_alarmPlaying) return;
    _alarmPlaying = false;
    try {
      await _alarm.stop();
    } catch (_) {
      // Ignore plugin shutdown errors on devices without an audio route.
    }
  }

  Future<void> startBgm() async {
    if (!bgmEnabled || _musicPlaying) return;
    await initialize();
    _musicPlaying = true;
    try {
      await _music.play(AssetSource('audio/bgm_loop.wav'), volume: .4);
    } catch (_) {
      _musicPlaying = false;
    }
  }

  Future<void> stopBgm() async {
    if (!_musicPlaying) return;
    try {
      await _music.stop();
    } catch (_) {
      // Ignore plugin shutdown errors on devices without an audio route.
    } finally {
      _musicPlaying = false;
    }
  }

  void toggleSfx() {
    unawaited(setSoundEffectsEnabled(!sfxEnabled));
  }

  Future<void> setSoundEffectsEnabled(bool enabled) async {
    sfxEnabled = enabled;
    if (!enabled) {
      unawaited(stopReactorAlarm());
      unawaited(_effects.stop());
    }
  }

  void toggleBgm() {
    unawaited(setMusicEnabled(!bgmEnabled));
  }

  Future<void> setMusicEnabled(bool enabled) async {
    bgmEnabled = enabled;
    if (enabled) {
      await startBgm();
    } else {
      await stopBgm();
    }
  }

  Future<void> dispose() async {
    await stopBgm();
    await stopReactorAlarm();
    for (final player in [_effects, _music, _alarm]) {
      try {
        await player.dispose();
      } catch (_) {
        // Platform audio plugins are optional in tests and unsupported hosts.
      }
    }
    _initialized = false;
  }
}
