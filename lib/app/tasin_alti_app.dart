import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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
  late String _languageCode;

  @override
  void initState() {
    super.initState();
    _languageCode = widget.controller.state.languageCode;
    widget.controller.addListener(_onControllerChanged);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(covariant TasinAltiApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller.removeListener(_onControllerChanged);
    _languageCode = widget.controller.state.languageCode;
    widget.controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    final nextLanguageCode = widget.controller.state.languageCode;
    if (_languageCode == nextLanguageCode) return;
    setState(() => _languageCode = nextLanguageCode);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(SoundService.instance.startBgm());
      widget.controller.onAppResumed();
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
    title: _languageCode == 'en' ? 'Beneath the Stone' : 'Taşın Altı',
    locale: Locale(_languageCode),
    supportedLocales: const [Locale('tr'), Locale('en')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    debugShowCheckedModeBanner: false,
    theme: MinePalette.theme,
    home: GameScreen(controller: widget.controller),
  );

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.dispose();
    super.dispose();
  }
}
