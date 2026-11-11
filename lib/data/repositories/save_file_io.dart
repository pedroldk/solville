import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

bool get _isFlutterTest => Platform.environment.containsKey('FLUTTER_TEST');

File? _cachedSaveFile;

Future<File> _resolveSaveFile() async {
  if (_cachedSaveFile != null) return _cachedSaveFile!;
  final baseDir = await getApplicationSupportDirectory().timeout(
    const Duration(seconds: 2),
  );
  final savesDir = Directory(p.join(baseDir.path, 'saves'));
  if (!await savesDir.exists()) {
    await savesDir.create(recursive: true);
  }
  final file = File(p.join(savesDir.path, 'solville_save_v1.json'));
  _cachedSaveFile = file;
  return file;
}

/// Writes the JSON save file atomically into the OS application support
/// directory (e.g., `%APPDATA%/.../saves/solville_save_v1.json` on Windows for
/// Steam Auto-Cloud, and app internal support storage on Android).
///
/// Uses a temporary staging file (`.tmp`) with `flush: true` and preserves the
/// previous valid save in `.bak` so an OS kill during Android backgrounding
/// never leaves a truncated/corrupted primary save file.
Future<void> writeSaveFileJson(String jsonContent) async {
  if (_isFlutterTest) return;
  try {
    final saveFile = await _resolveSaveFile();
    final tmpFile = File('${saveFile.path}.tmp');
    final bakFile = File('${saveFile.path}.bak');

    if (jsonContent.isEmpty) {
      for (final f in <File>[saveFile, tmpFile, bakFile]) {
        try {
          if (await f.exists()) {
            await f.delete();
          }
        } catch (_) {}
      }
      return;
    }

    await tmpFile.writeAsString(jsonContent, flush: true);

    try {
      if (await saveFile.exists() && await saveFile.length() > 0) {
        await saveFile.copy(bakFile.path);
      }
    } catch (_) {}

    try {
      await tmpFile.rename(saveFile.path);
    } catch (_) {
      await saveFile.writeAsString(jsonContent, flush: true);
      try {
        if (await tmpFile.exists()) {
          await tmpFile.delete();
        }
      } catch (_) {}
    }
  } catch (_) {
    // Graceful fallback to SharedPreferences if filesystem is restricted.
  }
}

Future<String?> readSaveFileJson() async {
  if (_isFlutterTest) return null;
  try {
    final saveFile = await _resolveSaveFile();
    if (await saveFile.exists()) {
      return await saveFile.readAsString();
    }
  } catch (_) {
    // Fall back to backup file or SharedPreferences.
  }
  return null;
}

Future<String?> readBackupSaveFileJson() async {
  if (_isFlutterTest) return null;
  try {
    final saveFile = await _resolveSaveFile();
    final bakFile = File('${saveFile.path}.bak');
    if (await bakFile.exists()) {
      return await bakFile.readAsString();
    }
  } catch (_) {}
  return null;
}
