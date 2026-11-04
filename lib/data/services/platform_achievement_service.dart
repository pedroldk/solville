import '../../domain/models/catalog.dart';
import 'steam_bridge_stub.dart'
    if (dart.library.ffi) 'steam_bridge_io.dart';

/// Unified achievement bridge syncing Solville's Milestone Trophies to Steam
/// Achievements on PC (when Steamworks is active) and maintaining local sync.
class PlatformAchievementService {
  final PlatformSteamBridge _steam = PlatformSteamBridge();

  bool get isSteamActive => _steam.isSteamConnected;

  void initialize() {
    _steam.initialize();
  }

  void unlockTrophyById(String trophyId) {
    for (final def in SolvilleCatalog.trophies) {
      if (def.id == trophyId) {
        _steam.unlockAchievement(def.steamApiName);
        break;
      }
    }
  }

  void pumpCallbacks() {
    _steam.runCallbacks();
  }
}
