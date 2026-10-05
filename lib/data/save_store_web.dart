import 'package:shared_preferences/shared_preferences.dart';

import 'save_store.dart';

SaveStore createSaveStore() => WebSaveStore();

class WebSaveStore implements SaveStore {
  static const _key = 'tasin_alti_save_v1';
  static const _backupKey = 'tasin_alti_save_v1_backup';
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  bool _recoveredBackup = false;

  @override
  bool get recoveredBackup => _recoveredBackup;

  @override
  Future<String?> load() async {
    final current = await _preferences.getString(_key);
    if (current != null && isValidGameSave(current)) {
      _recoveredBackup = false;
      return current;
    }
    final backup = await _preferences.getString(_backupKey);
    if (backup != null && isValidGameSave(backup)) {
      _recoveredBackup = true;
      return backup;
    }
    _recoveredBackup = false;
    return current ?? backup;
  }

  @override
  Future<void> save(String value) async {
    final current = await _preferences.getString(_key);
    if (current != null && isValidGameSave(current)) {
      await _preferences.setString(_backupKey, current);
    }
    await _preferences.setString(_key, value);
  }

  @override
  Future<void> clear() async {
    await _preferences.remove(_key);
    await _preferences.remove(_backupKey);
  }
}
