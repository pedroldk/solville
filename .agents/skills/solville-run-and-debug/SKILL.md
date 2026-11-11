---
name: solville-run-and-debug
description: >-
  Use this skill when running Solville locally, executing tests or static analysis,
  or debugging Android, Windows, or Web issues (crashes, R8/ProGuard errors, audio/BGM,
  AdMob, or ADB device logs).
---

# Solville Run & Debug Runbook

Project package: `pt.solal.solville` (`android/app/build.gradle.kts`, `minSdk >= 23`).

## 1. Pre-flight Checks (Same as CI)

Always run these before committing or pushing (`flutter analyze` fails CI on warnings):

```powershell
flutter pub get
flutter analyze
flutter test
```

## 2. Running Locally

List available targets:

```powershell
flutter devices
```

### Physical Android Device (Recommended for Mobile)

`adb.exe` is not on the default Windows `PATH`. Use the SDK path directly:

```powershell
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
& $adb devices
```

- Physical phone tested on this workstation: Motorola Edge 60 Fusion (`ZY22MBP2FS`).
- Local Android emulators may fail to boot on hosts without hardware acceleration (`x86_64 emulation currently requires hardware acceleration`). Prefer a USB-debugging physical phone.

Run debug build on Android (automatically uses Google's test Rewarded Ad unit ID because `kDebugMode` is true):

```powershell
flutter run -d ZY22MBP2FS
```

Run release APK locally on the physical device (matches Play Store R8/ProGuard behavior):

```powershell
flutter build apk --release
flutter install --release -d ZY22MBP2FS
```

> **Important Play Store / APK Conflict:** Local release APKs are signed with the upload keystore (`C:\Users\pedro\AppData\Local\SolvilleSigning\solville.keystore`), whereas Google Play Internal Testing signs with Google's Play App Signing key. Uninstall the existing app (`& $adb uninstall pt.solal.solville`) before switching between local release APKs and Play Store installs.

### Desktop (Windows) & Web

```powershell
flutter run -d windows
flutter run -d chrome
```

To test the paid Desktop/Steam edition with all Sun Pass content unlocked and ads/IAP disabled:

```powershell
flutter run -d windows --dart-define=FULL_EDITION=true
```

## 3. Debugging Android Issues with ADB

### Clear logs, launch app, and inspect live logs

```powershell
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
& $adb logcat -c
& $adb shell monkey -p pt.solal.solville -c android.intent.category.LAUNCHER 1
Start-Sleep -Seconds 4
& $adb logcat -d | Select-String -Pattern "pt.solal.solville|flutter|AndroidRuntime|FATAL|Exception|AudioTrack|AudioFocus"
```

Check native/startup crash buffer specifically:

```powershell
& $adb logcat -d -b crash
```

Verify active runtime PID:

```powershell
& $adb shell pidof pt.solal.solville
```

## 4. Known Project Pitfalls

1. **Release-only startup crashes (`WorkDatabase_Impl` / Room / Startup):**
   `google_mobile_ads` brings in `androidx.work:work-runtime` + Room. R8 strips no-arg reflection constructors unless kept in `android/app/proguard-rules.pro` (`* extends androidx.room.RoomDatabase`, `androidx.work.impl.WorkDatabase_Impl`, `* extends androidx.startup.Initializer`). Always test `flutter build apk --release` (not just debug) after adding Android plugins or updating ProGuard rules.
2. **Android BGM stops after tapping a tile:**
   In `lib/data/services/cozy_sound_service.dart`, `_sfxAudioContext` MUST keep `audioFocus: AndroidAudioFocus.none` while `_bgmAudioContext` uses `AndroidAudioFocus.gain`. Otherwise SFX players emit `AUDIOFOCUS_LOSS` and kill `_bgmPlayer`. Verify BGM playback on device by checking `AudioTrack` entries in `adb logcat`.
3. **AdMob in Debug vs Release:**
   `lib/data/services/monetization_bridge_io.dart` automatically selects `_androidTestRewardedId` (`ca-app-pub-3940256099942544/5224354917`) in `kDebugMode` and `_androidProdRewardedId` in release. Do not hardcode test IDs for release builds or fire live prod ads during debug testing.
