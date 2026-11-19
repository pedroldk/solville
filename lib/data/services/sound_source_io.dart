import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

final Map<String, Future<String?>> _windowsWavPaths =
    <String, Future<String?>>{};

int _quickHash(Uint8List bytes) {
  var hash = 0x811c9dc5;
  for (var i = 0; i < bytes.length; i++) {
    hash ^= bytes[i];
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash;
}

Future<String?> _writeWindowsWavFile(
  String versionedKey,
  Uint8List bytes,
) async {
  try {
    final tempDir = await getTemporaryDirectory();
    final audioDir = Directory(p.join(tempDir.path, 'solville_audio_v1'));
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }

    final wavFile = File(p.join(audioDir.path, '$versionedKey.wav'));
    if (await wavFile.exists() && await wavFile.length() == bytes.length) {
      return wavFile.path;
    }

    final tmpFile = File('${wavFile.path}.$pid.tmp');
    await tmpFile.writeAsBytes(bytes, flush: true);
    try {
      await tmpFile.rename(wavFile.path);
    } catch (_) {
      try {
        if (await tmpFile.exists()) {
          await tmpFile.delete();
        }
      } catch (_) {}
      if (!await wavFile.exists() || await wavFile.length() != bytes.length) {
        await wavFile.writeAsBytes(bytes, flush: true);
      }
    }
    return wavFile.path;
  } catch (_) {
    return null;
  }
}

/// Resolves the most reliable [Source] for synthesized PCM WAV [bytes] on the
/// current platform.
///
/// On Windows desktop runtime, caches the WAV to a temp `.wav` file and returns
/// [DeviceFileSource] to avoid `audioplayers_windows`'s slower `SetSourceBytes`
/// stream leak and reset behavior.
Future<Source> resolvePlatformAudioSource(
  String cacheKey,
  Uint8List bytes,
) async {
  if (!Platform.isWindows || Platform.environment.containsKey('FLUTTER_TEST')) {
    return BytesSource(bytes, mimeType: 'audio/wav');
  }

  final hashHex = _quickHash(bytes).toRadixString(16).padLeft(8, '0');
  final versionedKey = '${cacheKey}_${bytes.length}_$hashHex';
  final path = await (_windowsWavPaths[versionedKey] ??= _writeWindowsWavFile(
    versionedKey,
    bytes,
  ));
  if (path != null && File(path).existsSync()) {
    return DeviceFileSource(path, mimeType: 'audio/wav');
  }
  _windowsWavPaths.remove(versionedKey);
  return BytesSource(bytes, mimeType: 'audio/wav');
}
