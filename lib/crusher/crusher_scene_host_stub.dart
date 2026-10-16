import 'package:flutter/material.dart';

import 'crusher_engine.dart';
import 'localization.dart';

class CrusherSceneRenderer extends StatelessWidget {
  const CrusherSceneRenderer({
    super.key,
    required this.game,
    required this.onPointer,
  });

  final CrusherGame game;
  final ValueChanged<String> onPointer;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xff111923),
    child: Center(
      child: Text(context.gameText('3D sahne bu platformda kullanılamıyor.')),
    ),
  );
}
