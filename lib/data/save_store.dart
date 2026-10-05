import 'dart:convert';

import '../domain/models/game_state.dart';
import 'save_store_stub.dart'
    if (dart.library.io) 'save_store_io.dart'
    if (dart.library.js_interop) 'save_store_web.dart'
    as platform;

abstract interface class SaveStore {
  bool get recoveredBackup;
  Future<String?> load();
  Future<void> save(String value);
  Future<void> clear();
}

bool isValidGameSave(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return false;
    GameState.fromJson(Map<String, Object?>.from(decoded));
    return true;
  } catch (_) {
    return false;
  }
}

abstract final class SaveStoreFactory {
  static SaveStore create() => platform.createSaveStore();
}
