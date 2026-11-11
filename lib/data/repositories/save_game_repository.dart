import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/catalog.dart';
import '../../domain/models/entitlement_state.dart';
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
///
/// Caches the [SharedPreferences] instance and coalesces overlapping save
/// requests so rapid state updates never contend on disk I/O.
class SaveGameRepository {
  static const String _prefsKey = 'solville_save_state_v1';
  static const String _sfxPrefsKey = 'solville_sound_enabled_v1';
  static const String _bgmTrackPrefsKey = 'solville_bgm_track_v2';
  static const String _bgmVolPrefsKey = 'solville_bgm_volume_v2';
  static const String _entitlementPrefsKey = 'solville_entitlements_v1';
  static const String _localePrefsKey = 'solville_locale_v1';

  Future<SharedPreferences>? _prefsFuture;
  GameState? _pendingSaveState;
  Future<void>? _activeSaveTask;

  Future<SharedPreferences> _getPrefs() =>
      _prefsFuture ??= SharedPreferences.getInstance();

  Future<GameState?> loadSave() async {
    try {
      final fileRaw = await readSaveFileJson();
      if (fileRaw != null && fileRaw.trim().isNotEmpty) {
        final decoded = jsonDecode(fileRaw) as Map<String, dynamic>;
        return GameState.fromJson(decoded);
      }

      final prefs = await _getPrefs();
      final prefsRaw = prefs.getString(_prefsKey);
      if (prefsRaw != null && prefsRaw.trim().isNotEmpty) {
        final decoded = jsonDecode(prefsRaw) as Map<String, dynamic>;
        return GameState.fromJson(decoded);
      }
    } catch (_) {}
    return null;
  }

  Future<void> saveGame(GameState state) {
    _pendingSaveState = state;
    return _activeSaveTask ??= _drainSaveQueue();
  }

  Future<void> _drainSaveQueue() async {
    try {
      while (_pendingSaveState != null) {
        final target = _pendingSaveState!;
        _pendingSaveState = null;
        try {
          final encoded = jsonEncode(target.toJson());
          final prefs = await _getPrefs();
          await prefs.setString(_prefsKey, encoded);
          await writeSaveFileJson(encoded);
        } catch (_) {}
      }
    } finally {
      _activeSaveTask = null;
    }
  }

  Future<void> clearSave() async {
    _pendingSaveState = null;
    try {
      final prefs = await _getPrefs();
      await prefs.remove(_prefsKey);
      await writeSaveFileJson('');
    } catch (_) {}
  }

  Future<SavedAudioSettings> loadAudioSettings() async {
    try {
      final prefs = await _getPrefs();
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
      final prefs = await _getPrefs();
      await prefs.setBool(_sfxPrefsKey, settings.sfxEnabled);
      await prefs.setString(_bgmTrackPrefsKey, settings.bgmTrack.name);
      await prefs.setDouble(_bgmVolPrefsKey, settings.bgmVolume);
    } catch (_) {}
  }

  Future<EntitlementState> loadEntitlementState() async {
    try {
      final prefs = await _getPrefs();
      final raw = prefs.getString(_entitlementPrefsKey);
      if (raw != null && raw.trim().isNotEmpty) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        return EntitlementState.fromJson(decoded);
      }
    } catch (_) {}
    return const EntitlementState();
  }

  Future<void> saveEntitlementState(EntitlementState state) async {
    try {
      final prefs = await _getPrefs();
      final encoded = jsonEncode(state.toJson());
      await prefs.setString(_entitlementPrefsKey, encoded);
    } catch (_) {}
  }

  Future<String?> loadLocaleCode() async {
    try {
      final prefs = await _getPrefs();
      return prefs.getString(_localePrefsKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveLocaleCode(String? code) async {
    try {
      final prefs = await _getPrefs();
      if (code == null || code.isEmpty) {
        await prefs.remove(_localePrefsKey);
      } else {
        await prefs.setString(_localePrefsKey, code);
      }
    } catch (_) {}
  }
}
