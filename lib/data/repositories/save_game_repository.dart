import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/catalog.dart';
import '../../domain/models/game_state.dart';
import 'save_file_stub.dart' if (dart.library.io) 'save_file_io.dart';

/// Persisted user audio settings.
class SavedAudioSettings {
  const SavedAudioSettings({
    this.sfxEnabled = true,
    this.bgmTrack = BgmTrack.sunnyLullaby,
    this.bgmVolume = 0.38,
  });

  final bool sfxEnabled;
  final BgmTrack bgmTrack;
  final double bgmVolume;
}

/// Cross-platform persistence repository supporting Android, Windows/Steam
/// Auto-Cloud JSON files, and Web `SharedPreferences`.
class SaveGameRepository {
  static const String _prefsKey = 'solville_save_state_v1';
  static const String _sfxPrefsKey = 'solville_sound_enabled_v1';
  static const String _bgmTrackPrefsKey = 'solville_bgm_track_v2';
  static const String _bgmVolPrefsKey = 'solville_bgm_volume_v2';

  Future<GameState?> loadSave() async {
    try {
      final fileRaw = await readSaveFileJson();
      if (fileRaw != null && fileRaw.trim().isNotEmpty) {
        final decoded = jsonDecode(fileRaw) as Map<String, dynamic>;
        return GameState.fromJson(decoded);
      }

      final prefs = await SharedPreferences.getInstance();
      final prefsRaw = prefs.getString(_prefsKey);
      if (prefsRaw != null && prefsRaw.trim().isNotEmpty) {
        final decoded = jsonDecode(prefsRaw) as Map<String, dynamic>;
        return GameState.fromJson(decoded);
      }
    } catch (_) {}
    return null;
  }

  Future<void> saveGame(GameState state) async {
    try {
      final encoded = jsonEncode(state.toJson());
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, encoded);
      await writeSaveFileJson(encoded);
    } catch (_) {}
  }

  Future<void> clearSave() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
      await writeSaveFileJson('');
    } catch (_) {}
  }

  Future<SavedAudioSettings> loadAudioSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sfx = prefs.getBool(_sfxPrefsKey) ?? true;
      final trackName = prefs.getString(_bgmTrackPrefsKey);
      final vol = prefs.getDouble(_bgmVolPrefsKey) ?? 0.38;
      final track = trackName != null
          ? BgmTrack.values.firstWhere(
              (t) => t.name == trackName,
              orElse: () => BgmTrack.sunnyLullaby,
            )
          : BgmTrack.sunnyLullaby;
      return SavedAudioSettings(
        sfxEnabled: sfx,
        bgmTrack: track,
        bgmVolume: vol.clamp(0.0, 1.0),
      );
    } catch (_) {
      return const SavedAudioSettings();
    }
  }

  Future<void> saveAudioSettings(SavedAudioSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_sfxPrefsKey, settings.sfxEnabled);
      await prefs.setString(_bgmTrackPrefsKey, settings.bgmTrack.name);
      await prefs.setDouble(_bgmVolPrefsKey, settings.bgmVolume);
    } catch (_) {}
  }
}
