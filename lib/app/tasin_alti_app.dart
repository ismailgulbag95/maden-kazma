import 'dart:async';

import 'package:flutter/material.dart';

import '../core/design/palette.dart';
import 'game_controller.dart';
import '../ui/game_screen.dart';
import '../services/sound_service.dart';

class TasinAltiApp extends StatefulWidget {
  const TasinAltiApp({super.key, required this.controller});

  final GameController controller;

  @override
  State<TasinAltiApp> createState() => _TasinAltiAppState();
}

class _TasinAltiAppState extends State<TasinAltiApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(SoundService.instance.startBgm());
      return;
    }
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      widget.controller.onAppPaused();
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Taşın Altı',
    debugShowCheckedModeBanner: false,
    theme: MinePalette.theme,
    home: GameScreen(controller: widget.controller),
  );

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.dispose();
    super.dispose();
  }
}
