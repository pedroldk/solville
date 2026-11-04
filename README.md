# Solville 🌻

A sunny, cozy **2.5D isometric farming & town-market game** inspired by *Alice Greenfingers*, built with **Flutter + Flame** for **PC / Steam** and **Android** (plus Web).

## Highlights

- **Multi-Click / Multi-Tap Action Queue:** Tap any grass tile `1–3` times in a row to queue **Dig → Sow Seed → Water** in one seamless combo! Sol automatically detours to the **Stone Well** when her watering can runs out of water.
- **Soothing Background Soundscape & Cozy SFX:** Built-in procedural PCM audio synthesizer with **3 click-free looping ambiences** (**🎸 Sunlit Lullaby**, **🐦 Meadow Breeze**, and **🌧️ Cozy Rain**), adjustable ambience volume, independent tactile garden SFX toggle, and `M` quick-cycle hotkey.
- **2.5D Isometric Diorama:** Bevelled floating terrain prisms, drifting sky clouds, Mediterranean cypress lane scenery, dynamic soil hydration shading, golden compost flecks, swaying multi-stage crops, evening lantern glow, twilight fireflies, A* stepping-stone route dots, and villager **🔥 Boom** craving bubbles.
- **Crate Logistics, Lemon Orchards & Artisan Preserves:** Harvest produce into stacked wooden crates (`1 → 2 → 4`), plant passive **🍋 Sunburst Lemon Trees**, simmer raw Barn produce into **🍯 Gourmet Preserves** in the **Artisan Preserves Kettle**, and sell during **🔥 Market Booms (+45%)**.
- **Cross-Platform Tactile UX:** Live **Tile Inspector Pill** (growth %, moisture %, bee flower synergy %), **Shift + Drag** row painting on PC, one-tap **🌾 Harvest Ripe** / **💧 Water Dry** helpers, and clickable 2.5D world landmarks (Farmhouse & Market Stall).
- **12 Milestone Trophies & Steam Readiness:** Built-in Trophy Cabinet plus dynamic FFI Steamworks support (`steam_api64.dll`) and Steam Auto-Cloud JSON saves.

## Running Locally

```bash
# Run native Windows desktop app (PC / Steam)
flutter run -d windows

# Run in Chrome (quick preview)
flutter run -d chrome

# Run on connected Android device or emulator
flutter run -d android
```

## Building Release Packages

```bash
# Native Windows / Steam build -> build/windows/x64/runner/Release/
flutter build windows --release

# Android APK / App Bundle
flutter build apk --release
flutter build appbundle --release
```

## Steamworks & Steam Auto-Cloud Setup

1. **Achievements:** Drop Valve's `steam_api64.dll` (and `steam_appid.txt` during local testing) next to `solville.exe` in `build/windows/x64/runner/Release/`. `PlatformAchievementService` automatically detects `steam_api64.dll` at startup and syncs all 12 Milestone Trophies (`ACH_FIRST_SPROUT` ... `ACH_GOLDEN_OASIS`).
2. **Steam Auto-Cloud:** Configure Steam Auto-Cloud root to `WinAppDataRoaming` with subdirectory `com.solville.game/solville/saves` and pattern `*.json`.
