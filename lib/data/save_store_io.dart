import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'save_store.dart';

SaveStore createSaveStore() => FileSaveStore();

class FileSaveStore implements SaveStore {
  static const _fileName = 'tasin_alti_save.json';
  bool _recoveredBackup = false;

  @override
  bool get recoveredBackup => _recoveredBackup;

  Future<File> _file() async {
    final directory = await getApplicationSupportDirectory();
    await directory.create(recursive: true);
    return File('${directory.path}${Platform.pathSeparator}$_fileName');
  }

  @override
  Future<String?> load() async {
    final file = await _file();
    final backup = File('${file.path}.bak');
    String? firstUnreadable;
    for (final (index, candidate) in [file, backup].indexed) {
      try {
        if (!await candidate.exists()) continue;
        final contents = await candidate.readAsString();
        if (!isValidGameSave(contents)) {
          firstUnreadable ??= contents;
          continue;
        }
        _recoveredBackup = index == 1;
        return contents;
      } on FileSystemException {
        continue;
      }
    }
    return firstUnreadable;
  }

  @override
  Future<void> save(String value) async {
    final file = await _file();
    final temporary = File('${file.path}.tmp');
    final backup = File('${file.path}.bak');
    await temporary.writeAsString(value, flush: true);
    if (await file.exists()) {
      final current = await file.readAsString();
      if (isValidGameSave(current)) await file.copy(backup.path);
      await file.delete();
    }
    await temporary.rename(file.path);
  }

  @override
  Future<void> clear() async {
    final file = await _file();
    for (final candidate in [
      file,
      File('${file.path}.bak'),
      File('${file.path}.tmp'),
    ]) {
      if (await candidate.exists()) await candidate.delete();
    }
  }
}
