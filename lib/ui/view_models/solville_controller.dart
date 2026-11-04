import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../data/repositories/save_game_repository.dart';
import '../../data/services/cozy_sound_service.dart';
import '../../data/services/platform_achievement_service.dart';
import '../../domain/models/catalog.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/grid_pos.dart';
import '../../domain/models/market_state.dart';
import '../../domain/models/tile_state.dart';
import '../../domain/simulation/farm_simulation_engine.dart';

/// Central MVVM controller coordinating the Flame isometric world, Flutter HUD
/// overlays, persistence, soothing background ambience, and achievements.
class SolvilleController extends ChangeNotifier {
  SolvilleController({
    FarmSimulationEngine? engine,
    SaveGameRepository? saveRepository,
    CozySoundService? soundService,
    PlatformAchievementService? achievementService,
  }) : _engine = engine ?? FarmSimulationEngine(),
       _saveRepo = saveRepository ?? SaveGameRepository(),
       _sound = soundService ?? CozySoundService(),
       _achievements = achievementService ?? PlatformAchievementService() {
    _state = _engine.createNewGame();
  }

  final FarmSimulationEngine _engine;
  final SaveGameRepository _saveRepo;
  final CozySoundService _sound;
  final PlatformAchievementService _achievements;

  late GameState _state;
  GameState get state => _state;

  GridPos? _hoveredTile;
  GridPos? get hoveredTile => _hoveredTile;

  GridPos? _inspectedTile;
  GridPos? get inspectedTile => _inspectedTile;

  GridPos? _lastPaintDragTile;

  String? _toastMessage;
  String? get toastMessage => _toastMessage;
  double _toastTimer = 0.0;

  bool _isPaused = false;
  bool get isPaused => _isPaused;

  bool get sfxEnabled => _sound.sfxEnabled;
  BgmTrack get bgmTrack => _sound.bgmTrack;
  double get bgmVolume => _sound.bgmVolume;
  bool get isSteamActive => _achievements.isSteamActive;

  double _hudRefreshAccumulator = 0.0;
  double _autoSaveAccumulator = 0.0;
  double _steamCallbackAccumulator = 0.0;

  /// Callback hook so the Flame world spawns particles & floating popups.
  void Function(SimEvent event)? onVisualSimEvent;

  /// Callback hook to recenter camera on farmer.
  VoidCallback? onRequestCenterCamera;

  /// Optional UI hooks so clicking landmarks in the 2.5D world opens modals!
  VoidCallback? onRequestOpenMarketModal;
  VoidCallback? onRequestOpenHomesteadModal;

  Future<void> initialize() async {
    _achievements.initialize();
    _sound.initialize();

    final audio = await _saveRepo.loadAudioSettings();
    _sound.sfxEnabled = audio.sfxEnabled;
    _sound.bgmTrack = audio.bgmTrack;
    _sound.bgmVolume = audio.bgmVolume;
    unawaited(_sound.applyBgmSettings());

    final loaded = await _saveRepo.loadSave();
    if (loaded != null) {
      _state = loaded;
      for (final trophyId in _state.unlockedTrophies) {
        _achievements.unlockTrophyById(trophyId);
      }
      _showToast('Welcome back to Solville! (Day ${_state.day})');
    } else {
      _showToast(
        'Welcome to Solville! Tap plots 1–3x to combo-queue Dig → Sow → Water!',
      );
    }
    notifyListeners();
  }

  /// Ensures browser autoplay unlocks background ambience on first user gesture.
  void notifyUserGestureForAudio() {
    unawaited(_sound.ensureBgmActive());
  }

  double beeFlowerBonusAt(GridPos pos) =>
      _engine.computeBeeFlowerBonusAt(_state, pos);

  /// Called every frame by `SolvilleGame.update(dt)`.
  void advanceFrame(double dt) {
    if (_toastTimer > 0.0) {
      _toastTimer -= dt;
      if (_toastTimer <= 0.0 && _toastMessage != null) {
        _toastMessage = null;
        notifyListeners();
      }
    }

    _steamCallbackAccumulator += dt;
    if (_steamCallbackAccumulator >= 0.5) {
      _steamCallbackAccumulator = 0.0;
      _achievements.pumpCallbacks();
    }

    if (_isPaused) return;

    final result = _engine.tick(_state, dt);
    _state = result.state;
    final hasEvents = result.events.isNotEmpty;
    _dispatchEvents(result.events);

    _hudRefreshAccumulator += dt;
    if (hasEvents || _hudRefreshAccumulator >= 0.20) {
      _hudRefreshAccumulator = 0.0;
      notifyListeners();
    }

    _autoSaveAccumulator += dt;
    if (_autoSaveAccumulator >= 15.0) {
      _autoSaveAccumulator = 0.0;
      unawaited(_saveRepo.saveGame(_state));
    }
  }

  void setHoveredTile(GridPos? pos) {
    if (_hoveredTile == pos) return;
    _hoveredTile = pos;
    notifyListeners();
  }

  void handleTileTap(GridPos pos) {
    notifyUserGestureForAudio();
    if (!_state.inBounds(pos)) return;
    _inspectedTile = pos;

    final tile = _state.tileAt(pos);

    // Direct world-landmark shortcuts when appropriate!
    if (tile.structure == StructureType.farmhouse) {
      onRequestOpenHomesteadModal?.call();
      notifyListeners();
      return;
    }

    final willHaveCrates =
        _state.farmer.carriedCrates.isNotEmpty ||
        _state.actionQueue.any(
          (a) => a.kind == ActionKind.harvest || a.kind == ActionKind.pickupCrate,
        );

    if (tile.structure == StructureType.marketStall && !willHaveCrates) {
      onRequestOpenMarketModal?.call();
      notifyListeners();
      return;
    }

    if (tile.structure == StructureType.barn &&
        !willHaveCrates &&
        _state.totalBarnCrates == 0) {
      onRequestOpenMarketModal?.call();
      notifyListeners();
      return;
    }

    final prevQueueLen = _state.actionQueue.length;
    final result = _engine.enqueueTileTap(_state, pos);
    _state = result.state;
    _dispatchEvents(result.events);

    if (_state.actionQueue.length > prevQueueLen) {
      _triggerGentleHaptic();
    }
    notifyListeners();
  }

  /// Shift+Drag row painting on PC/Steam.
  void resetPaintDrag() {
    _lastPaintDragTile = null;
  }

  void handlePaintDragTile(GridPos pos) {
    if (!_state.inBounds(pos) || _lastPaintDragTile == pos) return;
    _lastPaintDragTile = pos;
    _inspectedTile = pos;

    // Avoid combo-stacking multiple steps on the same tile during a drag sweep
    if (_state.actionQueue.any((a) => a.target == pos)) return;

    final tile = _state.tileAt(pos);
    if (tile.structure != StructureType.none &&
        tile.structure != StructureType.lemonTree &&
        tile.structure != StructureType.artisanPress &&
        tile.animal == null) {
      return;
    }

    final result = _engine.enqueueTileTap(_state, pos);
    _state = result.state;
    _dispatchEvents(result.events);
    notifyListeners();
  }

  void handleTileSecondaryTap(GridPos pos) {
    notifyUserGestureForAudio();
    final before = _state.actionQueue.length;
    _state = _engine.cancelActionsAt(_state, pos);
    if (_state.actionQueue.length < before) {
      _triggerGentleHaptic();
      notifyListeners();
    }
  }

  void clearActionQueue() {
    if (_state.actionQueue.isEmpty) return;
    _state = _engine.clearQueue(_state);
    _triggerGentleHaptic();
    notifyListeners();
  }

  void queueAllReadyHarvests() {
    notifyUserGestureForAudio();
    final result = _engine.queueAllReadyHarvests(_state);
    _state = result.state;
    _dispatchEvents(result.events);
    _triggerGentleHaptic();
    notifyListeners();
  }

  void queueAllThirstyPlots() {
    notifyUserGestureForAudio();
    final result = _engine.queueAllThirstyPlots(_state);
    _state = result.state;
    _dispatchEvents(result.events);
    _triggerGentleHaptic();
    notifyListeners();
  }

  void selectTool(ToolMode tool) {
    notifyUserGestureForAudio();
    _state = _engine.selectTool(_state, tool);
    _triggerGentleHaptic();
    notifyListeners();
  }

  void selectSeed(ProductId seed) {
    notifyUserGestureForAudio();
    _state = _engine.selectSeed(_state, seed);
    _triggerGentleHaptic();
    notifyListeners();
  }

  void selectBuildItem(BuildItemType item) {
    notifyUserGestureForAudio();
    _state = _engine.selectBuildItem(_state, item);
    _triggerGentleHaptic();
    notifyListeners();
  }

  void setPricingStance(PricingStance stance) {
    _state = _engine.setPricingStance(_state, stance);
    unawaited(_saveRepo.saveGame(_state));
    notifyListeners();
  }

  void stockStallFromBarn(ProductId product) {
    final result = _engine.moveBarnCrateToStall(_state, product);
    _state = result.state;
    _dispatchEvents(result.events);
    unawaited(_saveRepo.saveGame(_state));
    notifyListeners();
  }

  void stockAllBoomFromBarn() {
    for (final entry in _state.barnStock.entries.toList()) {
      final trend = _state.market.trendFor(entry.key);
      if (trend == MarketTrend.boom || trend == MarketTrend.high) {
        for (var i = 0; i < entry.value; i++) {
          final res = _engine.moveBarnCrateToStall(_state, entry.key);
          _state = res.state;
          _dispatchEvents(res.events);
        }
      }
    }
    unawaited(_saveRepo.saveGame(_state));
    notifyListeners();
  }

  void unlockSeedLicense(ProductId cropId) {
    final result = _engine.unlockSeedLicense(_state, cropId);
    _state = result.state;
    _dispatchEvents(result.events);
    unawaited(_saveRepo.saveGame(_state));
    notifyListeners();
  }

  void purchaseUpgrade(UpgradeTrack track) {
    final result = _engine.purchaseUpgrade(_state, track);
    _state = result.state;
    _dispatchEvents(result.events);
    unawaited(_saveRepo.saveGame(_state));
    notifyListeners();
  }

  void restToNextMorning() {
    notifyUserGestureForAudio();
    final result = _engine.advanceToNextMorning(_state);
    _state = result.state;
    _dispatchEvents(result.events);
    unawaited(_saveRepo.saveGame(_state));
    notifyListeners();
  }

  void togglePause() {
    _isPaused = !_isPaused;
    notifyListeners();
  }

  void toggleSfx() {
    _sound.sfxEnabled = !_sound.sfxEnabled;
    unawaited(_persistAudioSettings());
    notifyListeners();
  }

  Future<void> setBgmTrack(BgmTrack track) async {
    await _sound.applyBgmSettings(track: track);
    await _persistAudioSettings();
    notifyListeners();
  }

  Future<void> cycleBgmTrack() async {
    final nextIndex = (_sound.bgmTrack.index + 1) % BgmTrack.values.length;
    await setBgmTrack(BgmTrack.values[nextIndex]);
    _showToast('Ambience: ${_sound.bgmTrack.label}');
  }

  Future<void> setBgmVolume(double volume) async {
    await _sound.applyBgmSettings(volume: volume);
    await _persistAudioSettings();
    notifyListeners();
  }

  Future<void> _persistAudioSettings() {
    return _saveRepo.saveAudioSettings(
      SavedAudioSettings(
        sfxEnabled: _sound.sfxEnabled,
        bgmTrack: _sound.bgmTrack,
        bgmVolume: _sound.bgmVolume,
      ),
    );
  }

  Future<void> saveNow() async {
    await _saveRepo.saveGame(_state);
    _showToast('💾 Farm progress saved!');
    notifyListeners();
  }

  Future<void> resetNewFarm() async {
    await _saveRepo.clearSave();
    _state = _engine.createNewGame();
    _inspectedTile = null;
    _showToast('🌱 Started a fresh sunny farm in Solville!');
    await _saveRepo.saveGame(_state);
    onRequestCenterCamera?.call();
    notifyListeners();
  }

  void requestCenterCamera() {
    onRequestCenterCamera?.call();
  }

  void clearInspectedTile() {
    _inspectedTile = null;
    notifyListeners();
  }

  void _dispatchEvents(List<SimEvent> events) {
    for (final event in events) {
      onVisualSimEvent?.call(event);
      unawaited(_sound.playForEvent(event.type));

      if (event.type == SimEventType.trophyUnlocked && event.trophyId != null) {
        _achievements.unlockTrophyById(event.trophyId!);
        unawaited(_saveRepo.saveGame(_state));
      }

      if (event.message != null && event.message!.isNotEmpty) {
        _showToast(event.message!);
      }
    }
  }

  void _showToast(String message) {
    _toastMessage = message;
    _toastTimer = 4.2;
  }

  void _triggerGentleHaptic() {
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      HapticFeedback.selectionClick();
    }
  }

  @override
  void dispose() {
    unawaited(_saveRepo.saveGame(_state));
    unawaited(_sound.dispose());
    super.dispose();
  }
}
