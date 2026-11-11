---
name: solville-release-and-signing
description: >-
  Use this skill when preparing a new Solville release, bumping app versions,
  configuring or troubleshooting Android keystore signing, building signed APKs/AABs,
  building Desktop/Steam Full Edition binaries, or triggering the GitHub Actions
  release workflow.
---

# Solville Release, Build & Signing Runbook

## 1. Versioning & App Identity

- **Android Package / Namespace:** `pt.solal.solville` (`android/app/build.gradle.kts`)
- **Version source of truth:** `version: X.Y.Z+N` in `pubspec.yaml` (for example `1.0.2+3`, where `1.0.2` is `versionName` and `3` is `versionCode`).
- **Rule for Google Play uploads:** Always increment the `+N` build number (`versionCode`) in `pubspec.yaml` before building or pushing a release.

## 2. Android Signing Setup (Never Commit Secrets)

`android/app/build.gradle.kts` reads signing credentials in this priority order:
1. Environment variables (used by GitHub Actions):
   - `ANDROID_KEYSTORE_PATH`
   - `ANDROID_KEY_ALIAS`
   - `ANDROID_KEY_PASSWORD`
   - `ANDROID_KEYSTORE_PASSWORD`
2. Local gitignored file `android/key.properties` (stripped of UTF-8 BOM via `.trimStart('\uFEFF')`).

Local keystore assets live **outside** the repository:
- Upload keystore: `C:\Users\pedro\AppData\Local\SolvilleSigning\solville.keystore` (`keyAlias=solville-upload`)
- Credentials note: `C:\Users\pedro\AppData\Local\SolvilleSigning\keystore-credentials.txt`

> **Windows PowerShell BOM Hazard:** Never write `android/key.properties` with PowerShell 5.1 `Set-Content -Encoding UTF8` (it prepends a UTF-8 BOM that can corrupt Java `Properties` keys). Use `[System.IO.File]::WriteAllText(..., [System.Text.UTF8Encoding]::new($false))` if regenerating `android/key.properties`. Even though `build.gradle.kts` strips `\uFEFF`, always write BOM-free UTF-8.

Verify `.gitignore` keeps `/android/key.properties`, `*.keystore`, and `*.jks` untracked before committing.

## 3. Building Signed Android Artifacts Locally

1. Verify tests and analyzer pass:
   ```powershell
   flutter analyze
   flutter test
   ```
2. Build signed Android App Bundle (for Google Play Console):
   ```powershell
   flutter build appbundle --release
   ```
   Output: `build/app/outputs/bundle/release/app-release.aab`
3. Verify the bundle is signed by `solville-upload` (not debug-signed):
   ```powershell
   jarsigner -verify -verbose -certs build\app\outputs\bundle\release\app-release.aab | Select-String -Pattern "jar verified|CN="
   ```
   Expected certificate DN includes `CN=Solville, O=Solal, L=Lisbon, C=PT`.
4. Build signed release APK (for direct phone testing via USB):
   ```powershell
   flutter build apk --release
   ```
   Output: `build/app/outputs/flutter-apk/app-release.apk`

## 4. GitHub Actions CI / Release Pipeline

Workflow file: `.github/workflows/build-android-bundle.yml`

- **Triggers:** Push to `main` or manual `workflow_dispatch`.
- **Checks run in CI:** `flutter pub get`, `flutter analyze`, `flutter test`. Any analyzer warning fails the build (`exit code 1`).
- **Required GitHub repository secrets:**
  - `ANDROID_KEYSTORE_BASE64`
  - `ANDROID_KEY_ALIAS`
  - `ANDROID_KEY_PASSWORD`
  - `ANDROID_KEYSTORE_PASSWORD`
- **Artifacts published:**
  - Creates/updates a GitHub Release tagged `v<versionName>-b<versionCode>` with `app-release.aab` attached (`--clobber`).
  - Also uploads workflow artifact `solville-signed-aab`.

Check workflow runs locally if `gh` CLI is installed:

```powershell
gh run list --limit 5
gh release list --limit 5
```

## 5. Desktop / Steam Paid Edition Build

Use `FULL_EDITION=true` to unlock all Sun Pass crops/structures/tiers and disable mobile ads/IAP:

```powershell
flutter build windows --release --dart-define=FULL_EDITION=true
```

## 6. Monetization Identifiers Reference

- **AdMob App ID (Android):** `android/app/build.gradle.kts` (`manifestPlaceholders["admobAppId"]`, overrideable via `ADMOB_APP_ID` env var). Currently defaults to `ca-app-pub-3113832650326844~3293995632`.
- **AdMob Rewarded Ad Unit (Android Release):** `lib/data/services/monetization_bridge_io.dart` (`ca-app-pub-3113832650326844/3002351599`, overrideable via `--dart-define=ADMOB_REWARDED_AD_UNIT_ID=...`).
- **AdMob iOS overrides:** Add iOS App ID in `ios/Runner/Info.plist` (`GADApplicationIdentifier`) and pass `--dart-define=ADMOB_IOS_REWARDED_AD_UNIT_ID=...` when shipping iOS.
- **Play / StoreKit IAP Product IDs (`lib/domain/models/entitlement_state.dart`):**
  - Annual Sun Pass subscription: `solville_sun_pass_yearly`
  - Lifetime Cozy Edition one-time: `solville_lifetime_cozy`
