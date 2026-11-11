import 'dart:async';
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
/// Caches the [SharedPreferences] instance, coalesces overlapping save
/// requests so rapid state updates never contend on disk I/O, and maintains
/// automatic `.bak` / backup preference slots for corruption recovery.
class SaveGameRepository {
  static const String _prefsKey = 'solville_save_state_v1';
  static const String _prefsBackupKey = 'solville_save_state_v1_bak';
  static const String _sfxPrefsKey = 'solville_sound_enabled_v1';
  static const String _bgmTrackPrefsKey = 'solville_bgm_track_v2';
  static const String _bgmVolPrefsKey = 'solville_bgm_volume_v2';
  static const String _entitlementPrefsKey = 'solville_entitlements_v1';
  static const String _entitlementBackupPrefsKey =
      'solville_entitlements_v1_bak';
  static const String _localePrefsKey = 'solville_locale_v1';

  Future<SharedPreferences>? _prefsFuture;
  GameState? _pendingSaveState;
  Future<void>? _activeSaveTask;

  Future<SharedPreferences> _getPrefs() {
    return _prefsFuture ??= SharedPreferences.getInstance().catchError((
      Object error,
    ) {
      _prefsFuture = null;
      throw error;
    });
  }

  GameState? _tryDecodeGameState(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final state = GameState.fromJson(decoded);
      if (state.gridSize < SolvilleCatalog.starterGridSize ||
          state.tiles.length != state.gridSize * state.gridSize) {
        return null;
      }
      return state;
    } catch (_) {
      return null;
    }
  }

  Future<GameState?> loadSave() async {
    // 1. Primary save file (Android app support / Windows Steam Auto-Cloud)
    try {
      final fileRaw = await readSaveFileJson();
      final state = _tryDecodeGameState(fileRaw);
      if (state != null) return state;
    } catch (_) {}

    // 2. Backup `.bak` save file if primary file was truncated or corrupted
    try {
      final backupFileRaw = await readBackupSaveFileJson();
      final state = _tryDecodeGameState(backupFileRaw);
      if (state != null) {
        unawaited(writeSaveFileJson(backupFileRaw!));
        return state;
      }
    } catch (_) {}

    // 3. Primary SharedPreferences slot
    SharedPreferences? prefs;
    try {
      prefs = await _getPrefs();
      final prefsRaw = prefs.getString(_prefsKey);
      final state = _tryDecodeGameState(prefsRaw);
      if (state != null) {
        unawaited(writeSaveFileJson(prefsRaw!));
        return state;
      }
    } catch (_) {}

    // 4. Backup SharedPreferences slot if primary slot was corrupted
    try {
      prefs ??= await _getPrefs();
      final backupPrefsRaw = prefs.getString(_prefsBackupKey);
      final state = _tryDecodeGameState(backupPrefsRaw);
      if (state != null) {
        unawaited(prefs.setString(_prefsKey, backupPrefsRaw!));
        unawaited(writeSaveFileJson(backupPrefsRaw));
        return state;
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
        String? encoded;
        try {
          encoded = jsonEncode(target.toJson());
        } catch (_) {
          continue;
        }

        try {
          final prefs = await _getPrefs();
          final previous = prefs.getString(_prefsKey);
          if (previous != null &&
              previous.isNotEmpty &&
              previous != encoded &&
              _tryDecodeGameState(previous) != null) {
            await prefs.setString(_prefsBackupKey, previous);
          }
          await prefs.setString(_prefsKey, encoded);
        } catch (_) {}

        try {
          await writeSaveFileJson(encoded);
        } catch (_) {}
      }
    } finally {
      _activeSaveTask = null;
    }
  }

  Future<void> clearSave() async {
    _pendingSaveState = null;
    final inFlight = _activeSaveTask;
    if (inFlight != null) {
      try {
        await inFlight;
      } catch (_) {}
    }
    try {
      final prefs = await _getPrefs();
      await prefs.remove(_prefsKey);
      await prefs.remove(_prefsBackupKey);
    } catch (_) {}
    try {
      await writeSaveFileJson('');
    } catch (_) {}
  }

  Future<SavedAudioSettings> loadAudioSettings() async {
    try {
      final prefs = await _getPrefs();
      final sfx = prefs.getBool(_sfxPrefsKey) ?? true;
      final trackName = prefs.getString(_bgmTrackPrefsKey);
      final rawVol = prefs.getDouble(_bgmVolPrefsKey) ?? 0.38;
      final safeVol = (rawVol.isNaN || rawVol.isInfinite)
          ? 0.38
          : rawVol.clamp(0.0, 1.0);
      final track = trackName != null
          ? BgmTrack.values.firstWhere(
              (t) => t.name == trackName,
              orElse: () => BgmTrack.sunnyLullaby,
            )
          : BgmTrack.sunnyLullaby;
      return SavedAudioSettings(
        sfxEnabled: sfx,
        bgmTrack: track,
        bgmVolume: safeVol,
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
      final safeVol = (settings.bgmVolume.isNaN || settings.bgmVolume.isInfinite)
          ? 0.38
          : settings.bgmVolume.clamp(0.0, 1.0);
      await prefs.setDouble(_bgmVolPrefsKey, safeVol);
    } catch (_) {}
  }

  EntitlementState? _tryDecodeEntitlementState(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return EntitlementState.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<EntitlementState> loadEntitlementState() async {
    SharedPreferences? prefs;
    try {
      prefs = await _getPrefs();
      final raw = prefs.getString(_entitlementPrefsKey);
      final parsed = _tryDecodeEntitlementState(raw);
      if (parsed != null) return parsed;
    } catch (_) {}

    try {
      prefs ??= await _getPrefs();
      final backupRaw = prefs.getString(_entitlementBackupPrefsKey);
      final parsed = _tryDecodeEntitlementState(backupRaw);
      if (parsed != null) {
        unawaited(prefs.setString(_entitlementPrefsKey, backupRaw!));
        return parsed;
      }
    } catch (_) {}

    return const EntitlementState();
  }

  Future<void> saveEntitlementState(EntitlementState state) async {
    try {
      final prefs = await _getPrefs();
      final encoded = jsonEncode(state.toJson());
      final previous = prefs.getString(_entitlementPrefsKey);
      if (previous != null &&
          previous.isNotEmpty &&
          previous != encoded &&
          _tryDecodeEntitlementState(previous) != null) {
        await prefs.setString(_entitlementBackupPrefsKey, previous);
      }
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
