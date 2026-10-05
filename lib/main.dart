import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

import 'app/game_controller.dart';
import 'app/tasin_alti_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
  ]);
  final controller = GameController();
  await controller.initialize();
  runApp(TasinAltiApp(controller: controller));
}
