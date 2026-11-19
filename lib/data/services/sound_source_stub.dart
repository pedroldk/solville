import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

/// Web fallback audio source resolver; plays synthesized PCM WAV bytes directly.
Future<Source> resolvePlatformAudioSource(
  String cacheKey,
  Uint8List bytes,
) async => BytesSource(bytes, mimeType: 'audio/wav');
