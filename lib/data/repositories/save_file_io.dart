import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

bool get _isFlutterTest => Platform.environment.containsKey('FLUTTER_TEST');

/// Writes the JSON save file into the OS application support directory
/// (e.g., `%APPDATA%/.../saves/solville_save_v1.json` on Windows for Steam
/// Auto-Cloud, and app internal support storage on Android).
Future<void> writeSaveFileJson(String jsonContent) async {
  if (_isFlutterTest) return;
  try {
    final baseDir = await getApplicationSupportDirectory().timeout(
      const Duration(seconds: 2),
    );
    final savesDir = Directory(p.join(baseDir.path, 'saves'));
    if (!await savesDir.exists()) {
      await savesDir.create(recursive: true);
    }
    final saveFile = File(p.join(savesDir.path, 'solville_save_v1.json'));
    await saveFile.writeAsString(jsonContent, flush: true);
  } catch (_) {
    // Graceful fallback to SharedPreferences if filesystem is restricted.
  }
}

Future<String?> readSaveFileJson() async {
  if (_isFlutterTest) return null;
  try {
    final baseDir = await getApplicationSupportDirectory().timeout(
      const Duration(seconds: 2),
    );
    final saveFile = File(
      p.join(baseDir.path, 'saves', 'solville_save_v1.json'),
    );
    if (await saveFile.exists()) {
      return await saveFile.readAsString();
    }
  } catch (_) {
    // Fall back to SharedPreferences.
  }
  return null;
}
