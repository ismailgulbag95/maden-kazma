import 'save_store.dart';

SaveStore createSaveStore() => UnsupportedSaveStore();

class UnsupportedSaveStore implements SaveStore {
  @override
  bool get recoveredBackup => false;

  @override
  Future<void> clear() async {}

  @override
  Future<String?> load() async => null;

  @override
  Future<void> save(String value) async {}
}
