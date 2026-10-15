import 'dart:convert';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import 'crusher_scene_data.dart';
import 'crusher_engine.dart';

const _viewType = 'crusher-three-js-scene';
const _pointerChannel = 'Crusher';
final Map<int, web.HTMLIFrameElement> _frames = {};
bool _viewFactoryRegistered = false;

void _registerViewFactory() {
  if (_viewFactoryRegistered) return;
  ui_web.platformViewRegistry.registerViewFactory(_viewType, (viewId) {
    final frame = web.HTMLIFrameElement()
      ..src = Uri.base.resolve('assets/assets/scene/index.html').toString()
      ..style.border = '0'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.display = 'block'
      ..style.backgroundColor = '#171816';
    frame.setAttribute('title', 'Three.js crusher scene');
    frame.addEventListener(
      'error',
      ((web.Event _) {
        frame.src = Uri.base.resolve('scene/index.html').toString();
      }).toJS,
    );
    _frames[viewId] = frame;
    return frame;
  });
  _viewFactoryRegistered = true;
}

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
  DateTime _lastFramePush = DateTime.fromMillisecondsSinceEpoch(0);
  web.HTMLIFrameElement? _frame;
  int? _viewId;
  bool _sendingFrame = false;
  late final JSFunction _messageListener = _onWindowMessage.toJS;

  @override
  void initState() {
    super.initState();
    _registerViewFactory();
    widget.game.sceneFrame.addListener(_pushSceneFrame);
    web.window.addEventListener('message', _messageListener);
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

  void _onPlatformViewCreated(int viewId) {
    _viewId = viewId;
    _frame = _frames[viewId];
    _pushSceneFrame();
  }

  void _onWindowMessage(web.Event rawEvent) {
    final frame = _frame;
    if (frame == null) return;
    final event = rawEvent as web.MessageEvent;
    if (event.source != frame.contentWindow) return;
    final rawData = event.data.dartify();
    if (rawData is! String) return;
    try {
      final decoded = jsonDecode(rawData);
      if (decoded is Map && decoded['channel'] == _pointerChannel) {
        final action = decoded['message'];
        if (action is String) widget.onPointer(action);
      }
    } on FormatException {
      // Ignore messages that are not part of this game's iframe bridge.
    }
  }

  void _pushSceneFrame() {
    final frame = _frame;
    if (_sendingFrame || frame == null) return;
    final now = DateTime.now();
    if (now.difference(_lastFramePush).inMilliseconds < 32) return;
    _lastFramePush = now;
    _sendingFrame = true;
    final json = jsonEncode({
      'channel': 'crusher-state',
      'state': crusherSceneSnapshot(widget.game),
    });
    try {
      frame.contentWindow?.postMessage(json.toJS, '*'.toJS);
    } finally {
      _sendingFrame = false;
    }
  }

  @override
  void dispose() {
    widget.game.sceneFrame.removeListener(_pushSceneFrame);
    web.window.removeEventListener('message', _messageListener);
    if (_viewId case final viewId?) _frames.remove(viewId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HtmlElementView(
    viewType: _viewType,
    onPlatformViewCreated: _onPlatformViewCreated,
  );
}
