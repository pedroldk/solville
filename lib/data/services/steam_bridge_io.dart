import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;

typedef _SteamApiInitNative = ffi.Bool Function();
typedef _SteamApiInitDart = bool Function();

typedef _SteamRunCallbacksNative = ffi.Void Function();
typedef _SteamRunCallbacksDart = void Function();

typedef _SteamUserStatsNative = ffi.Pointer<ffi.Void> Function();
typedef _SteamUserStatsDart = ffi.Pointer<ffi.Void> Function();

typedef _SetAchievementNative =
    ffi.Bool Function(ffi.Pointer<ffi.Void> self, ffi.Pointer<Utf8> pchName);
typedef _SetAchievementDart =
    bool Function(ffi.Pointer<ffi.Void> self, ffi.Pointer<Utf8> pchName);

typedef _StoreStatsNative = ffi.Bool Function(ffi.Pointer<ffi.Void> self);
typedef _StoreStatsDart = bool Function(ffi.Pointer<ffi.Void> self);

/// Optional dynamic FFI bridge to Valve's Steamworks SDK (`steam_api64.dll` /
/// `libsteam_api.so` / `libsteam_api.dylib`).
///
/// When launched outside Steam or during development/Android runs, silently
/// operates in standalone local Trophy Cabinet mode without requiring the DLL.
class PlatformSteamBridge {
  bool isSteamConnected = false;

  ffi.DynamicLibrary? _lib;
  _SteamRunCallbacksDart? _runCallbacks;
  _SteamUserStatsDart? _getUserStats;
  _SetAchievementDart? _setAchievement;
  _StoreStatsDart? _storeStats;

  void initialize() {
    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
      return;
    }

    try {
      final exeDir = p.dirname(Platform.resolvedExecutable);
      final dllName = Platform.isWindows
          ? 'steam_api64.dll'
          : (Platform.isMacOS ? 'libsteam_api.dylib' : 'libsteam_api.so');
      final dllPath = p.join(exeDir, dllName);
      if (!File(dllPath).existsSync()) {
        return;
      }

      final lib = ffi.DynamicLibrary.open(dllPath);
      final initFn = lib.lookupFunction<_SteamApiInitNative, _SteamApiInitDart>(
        'SteamAPI_Init',
      );
      if (!initFn()) {
        return;
      }

      _lib = lib;
      _runCallbacks = lib
          .lookupFunction<_SteamRunCallbacksNative, _SteamRunCallbacksDart>(
            'SteamAPI_RunCallbacks',
          );
      _getUserStats = lib
          .lookupFunction<_SteamUserStatsNative, _SteamUserStatsDart>(
            'SteamAPI_SteamUserStats_v012',
          );
      _setAchievement = lib
          .lookupFunction<_SetAchievementNative, _SetAchievementDart>(
            'SteamAPI_ISteamUserStats_SetAchievement',
          );
      _storeStats = lib.lookupFunction<_StoreStatsNative, _StoreStatsDart>(
        'SteamAPI_ISteamUserStats_StoreStats',
      );
      isSteamConnected = true;
    } catch (_) {
      isSteamConnected = false;
    }
  }

  void unlockAchievement(String steamApiName) {
    if (!isSteamConnected || _lib == null) return;
    try {
      final statsPtr = _getUserStats?.call();
      if (statsPtr == null || statsPtr == ffi.nullptr) return;
      final namePtr = steamApiName.toNativeUtf8();
      try {
        _setAchievement?.call(statsPtr, namePtr);
        _storeStats?.call(statsPtr);
      } finally {
        calloc.free(namePtr);
      }
    } catch (_) {}
  }

  void runCallbacks() {
    if (!isSteamConnected) return;
    try {
      _runCallbacks?.call();
    } catch (_) {}
  }
}
