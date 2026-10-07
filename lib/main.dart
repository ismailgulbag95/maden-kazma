import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

import 'app/game_controller.dart';
import 'app/tasin_alti_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = GameController();
  runApp(TasinAltiApp(controller: controller));

  // Keep the first frame independent from plugins and local storage. A browser
  // that cannot lock orientation or initialize audio must still show the game.
  if (!kIsWeb) {
    unawaited(
      SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.portraitUp,
      ]).catchError((_) {}),
    );
  }
  unawaited(
    controller.initialize().catchError((Object error, StackTrace stackTrace) {
      controller.reportInitializationFailure(error);
    }),
  );
}
