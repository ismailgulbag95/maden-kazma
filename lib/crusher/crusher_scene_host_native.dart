import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'crusher_scene_data.dart';
import 'crusher_engine.dart';

class CrusherSceneRenderer extends StatefulWidget {
  const CrusherSceneRenderer({
    super.key,
    required this.game,
    required this.onPointer,
  });

  final CrusherGame game;
  final ValueChanged<String> onPointer;

  @override
  State<CrusherSceneRenderer> createState() => _CrusherSceneRendererState();
}

class _CrusherSceneRendererState extends State<CrusherSceneRenderer> {
  late final WebViewController _controller;
  DateTime _lastFramePush = DateTime.fromMillisecondsSinceEpoch(0);
  bool _sceneReady = false;
  bool _sendingFrame = false;

  @override
  void initState() {
    super.initState();
    widget.game.sceneFrame.addListener(_pushSceneFrame);
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xff111923))
      ..addJavaScriptChannel(
        'Crusher',
        onMessageReceived: (message) => widget.onPointer(message.message),
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            _sceneReady = true;
            _pushSceneFrame();
          },
        ),
      )
      ..loadFlutterAsset('assets/scene/index.html');
  }

  @override
  void didUpdateWidget(covariant CrusherSceneRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.game != widget.game) {
      oldWidget.game.sceneFrame.removeListener(_pushSceneFrame);
      widget.game.sceneFrame.addListener(_pushSceneFrame);
      _pushSceneFrame();
    }
  }

  void _pushSceneFrame() {
    if (!_sceneReady || _sendingFrame) return;
    final now = DateTime.now();
    if (now.difference(_lastFramePush).inMilliseconds < 32) return;
    _lastFramePush = now;
    _sendingFrame = true;
    unawaited(_sendFrame(jsonEncode(crusherSceneSnapshot(widget.game))));
  }

  Future<void> _sendFrame(String json) async {
    try {
      await _controller.runJavaScript('window.updateGame($json);');
    } catch (_) {
      // The WebView may still be tearing down while the app is backgrounded.
    } finally {
      _sendingFrame = false;
    }
  }

  @override
  void dispose() {
    widget.game.sceneFrame.removeListener(_pushSceneFrame);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xff111923),
    child: WebViewWidget(controller: _controller),
  );
}
