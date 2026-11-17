import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show Locale, VoidCallback;

import '../../data/repositories/save_game_repository.dart';
import '../../data/services/cozy_sound_service.dart';
import '../../data/services/monetization_service.dart';
import '../../data/services/platform_achievement_service.dart';
import '../../domain/models/catalog.dart';
import '../../domain/models/entitlement_state.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/grid_pos.dart';
import '../../domain/models/market_state.dart';
import '../../domain/models/solville_toast.dart';
import '../../domain/models/tile_state.dart';
import '../../domain/simulation/farm_simulation_engine.dart';
import '../../l10n/solville_l10n_extensions.dart';

/// Central MVVM controller coordinating the Flame isometric world, Flutter HUD
/// overlays, persistence, soothing background ambience, achievements, and
/// cozy monetization (Sun Pass).
class SolvilleController extends ChangeNotifier {
  SolvilleController({
    FarmSimulationEngine? engine,
    SaveGameRepository? saveRepository,
    CozySoundService? soundService,
    PlatformAchievementService? achievementService,
    MonetizationService? monetizationService,
    EntitlementState? initialEntitlements,
    DateTime Function()? clock,
  }) : _engine = engine ?? FarmSimulationEngine(),
       _saveRepo = saveRepository ?? SaveGameRepository(),
       _sound = soundService ?? CozySoundService(),
       _achievements = achievementService ?? PlatformAchievementService(),
       _monetization = monetizationService ?? MonetizationService(),
       _entitlements = initialEntitlements ?? const EntitlementState(),
       _hasExplicitInitialEntitlements = initialEntitlements != null,
       _clock = clock ?? DateTime.now {
    _state = _engine.createNewGame();
  }

  final FarmSimulationEngine _engine;
  final SaveGameRepository _saveRepo;
  final CozySoundService _sound;
  final PlatformAchievementService _achievements;
  final MonetizationService _monetization;
  final bool _hasExplicitInitialEntitlements;
  final DateTime Function() _clock;

  late GameState _state;
  GameState get state => _state;

  EntitlementState _entitlements;
  EntitlementState get entitlements => _entitlements;

  DateTime get nowUtc => _clock().toUtc();
  bool get isSunPassActive => _entitlements.isSunPassActive(nowUtc);
  bool get isMonetizationBusy => _monetization.isBusy;
  bool get canClaimSunnySurgeToday =>
      _entitlements.canClaimSunnySurgeOnDay(_state.day) &&
      !_state.market.sunnySurgeActive;

  final ValueNotifier<GridPos?> hoverNotifier = ValueNotifier<GridPos?>(null);
  GridPos? get hoveredTile => hoverNotifier.value;

  GridPos? _inspectedTile;
  GridPos? get inspectedTile => _inspectedTile;

  /// Live inspector readout for whichever tile is currently tapped/inspected.
  TileInspectionInfo? get activeInspection {
    final target = _inspectedTile;
    if (target == null || !_state.inBounds(target)) return null;
    return _engine.describeTileAt(
      _state,
      target,
      isSunPassActive: isSunPassActive,
    );
  }

  String spotlightHarvestLabel = '👇 Harvest 🍅';
  String spotlightSellLabel = '👇 Sell at Stall 🏪';
  String spotlightPlantLabel = '👇 Tap 3× Plant 🌱';
  String landmarkHomesteadLabel = '🏡 Homestead';
  String landmarkRefillLabel = '🪣 Refill';
  String landmarkBarnLabel = '🏠 Barn';

  void syncLocalizedWorldLabels({
    required String spotlightHarvest,
    required String spotlightSell,
    required String spotlightPlant,
    required String landmarkHomestead,
    required String landmarkRefill,
    required String landmarkBarn,
  }) {
    spotlightHarvestLabel = spotlightHarvest;
    spotlightSellLabel = spotlightSell;
    spotlightPlantLabel = spotlightPlant;
    landmarkHomesteadLabel = landmarkHomestead;
    landmarkRefillLabel = landmarkRefill;
    landmarkBarnLabel = landmarkBarn;
  }

  GridPos? _lastPaintDragTile;

  String? _toastMessage;
  String? get toastMessage => _toastMessage;
  SolvilleToast? _toast;
  SolvilleToast? get toast => _toast;
  double _toastTimer = 0.0;

  Locale? _appLocale;
  Locale? get appLocale => _appLocale;

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

  /// Callback hook to smoothly pan camera onto a specific farm tile.
  void Function(GridPos pos)? onRequestFocusTile;

  /// Optional UI hooks so clicking landmarks in the 2.5D world opens modals!
  VoidCallback? onRequestOpenMarketModal;
  VoidCallback? onRequestOpenHomesteadModal;
  VoidCallback? onRequestOpenSunPassModal;

  Future<void> initialize() async {
    _achievements.initialize();
    _sound.initialize();

    if (!_hasExplicitInitialEntitlements) {
      _entitlements = await _saveRepo.loadEntitlementState();
    }

    unawaited(
      _monetization.initialize(
        onOwnedProductRestored: _handleOwnedProductRestored,
      ),
    );

    final audio = await _saveRepo.loadAudioSettings();
    _sound.sfxEnabled = audio.sfxEnabled;
    _sound.bgmTrack = audio.bgmTrack;
    _sound.bgmVolume = audio.bgmVolume;
    unawaited(_sound.applyBgmSettings());

    _appLocale = SolvilleLocaleHelper.parseLocaleCode(
      await _saveRepo.loadLocaleCode(),
    );

    final loaded = await _saveRepo.loadSave();
    if (loaded != null) {
      _state = _engine.ensureMinimumIslandSize(loaded);
      _ensureValidEquippedSelection();
      if (_state.gridSize != loaded.gridSize) {
        unawaited(_saveRepo.saveGame(_state));
      }
      for (final trophyId in _state.unlockedTrophies) {
        _achievements.unlockTrophyById(trophyId);
      }
    }
    notifyListeners();
  }

  Future<void> setAppLocale(Locale? locale) async {
    if (_appLocale == locale) return;
    _appLocale = locale;
    await _saveRepo.saveLocaleCode(SolvilleLocaleHelper.toStorageCode(locale));
    notifyListeners();
  }

  /// Ensures browser autoplay unlocks background ambience on first user gesture.
  void notifyUserGestureForAudio() {
    unawaited(_sound.ensureBgmActive());
  }

  void onAppBackgrounded() {
    unawaited(_sound.pauseBgm());
    unawaited(_saveRepo.saveGame(_state));
  }

  void onAppResumed() {
    unawaited(_sound.ensureBgmActive());
  }

  double beeFlowerBonusAt(GridPos pos) =>
      _engine.computeBeeFlowerBonusAt(_state, pos);

  /// Called every frame by `SolvilleGame.update(dt)`.
  void advanceFrame(double dt) {
    if (_toastTimer > 0.0) {
      _toastTimer -= dt;
      if (_toastTimer <= 0.0 && (_toastMessage != null || _toast != null)) {
        _toastMessage = null;
        _toast = null;
        notifyListeners();
      }
    }

    _steamCallbackAccumulator += dt;
    if (_steamCallbackAccumulator >= 0.5) {
      _steamCallbackAccumulator = 0.0;
      _achievements.pumpCallbacks();
    }

    if (_isPaused) return;

    final result = _engine.tick(
      _state,
      dt,
      isSunPassActive: isSunPassActive,
    );
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
    if (hoverNotifier.value == pos) return;
    hoverNotifier.value = pos;
  }

  void inspectTile(GridPos? pos) {
    if (_inspectedTile == pos) return;
    _inspectedTile = pos;
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
          (a) =>
              a.kind == ActionKind.harvest || a.kind == ActionKind.pickupCrate,
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

    if (tile.structure.requiresSunPass &&
        !isSunPassActive &&
        !tile.isReadyToHarvest &&
        _state.activeTool != ToolMode.remove) {
      final buildDef = SolvilleCatalog.buildItems.values
          .where((b) => b.name.isNotEmpty)
          .firstWhere(
            (b) => switch (tile.structure) {
              StructureType.sprinklerSolar =>
                b.type == BuildItemType.sprinklerSolar,
              StructureType.lemonTree => b.type == BuildItemType.lemonTree,
              StructureType.artisanPress =>
                b.type == BuildItemType.artisanPress,
              StructureType.beehive => b.type == BuildItemType.beehive,
              StructureType.cowPaddock => b.type == BuildItemType.cowPaddock,
              StructureType.flowerArch => b.type == BuildItemType.flowerArch,
              _ => false,
            },
            orElse: () =>
                SolvilleCatalog.buildItems[BuildItemType.artisanPress]!,
          );
      _promptSunPassFor(
        buildDef.name,
        toast: SolvilleToast(
          SolvilleToastKind.sunPassRequiredBuild,
          buildItem: buildDef.type,
        ),
      );
      return;
    }

    final prevQueueLen = _state.actionQueue.length;
    final result = _engine.enqueueTileTap(_state, pos);
    if (result.state.actionQueue.length == prevQueueLen &&
        tile.structure == StructureType.artisanPress &&
        isSunPassActive &&
        !tile.producerActive &&
        tile.producerCrates == 0) {
      toggleKettleRecipe(pos);
      return;
    }
    _applyStep(result, haptic: result.state.actionQueue.length > prevQueueLen);
  }

  /// Opens the Market & Barn modal (e.g. from the stall's on-canvas signpost).
  void openMarketModal() {
    notifyUserGestureForAudio();
    onRequestOpenMarketModal?.call();
    notifyListeners();
  }

  /// Cycles the active craft recipe on an idle Artisan Kettle at [pos].
  void toggleKettleRecipe(GridPos pos) {
    _applyStep(_engine.toggleKettleRecipe(_state, pos), haptic: true);
  }

  /// Awards +3☀️ when tapping a fluttering butterfly in the meadow.
  void boopButterfly(GridPos nearPos) {
    _applyStep(_engine.boopButterfly(_state, nearPos), haptic: true);
  }

  /// Shift+Drag row painting on PC/Steam or Sweep-mode drag on touch devices.
  bool _paintSweepMode = false;
  bool get paintSweepMode => _paintSweepMode;

  void togglePaintSweepMode() {
    _paintSweepMode = !_paintSweepMode;
    _triggerGentleHaptic();
    notifyListeners();
  }

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
    final allowStructureSweep =
        _state.activeTool == ToolMode.remove && tile.structure.isRemovable;
    if (!allowStructureSweep &&
        tile.structure != StructureType.none &&
        tile.structure != StructureType.lemonTree &&
        tile.structure != StructureType.artisanPress &&
        tile.animal == null) {
      return;
    }

    final prevLen = _state.actionQueue.length;
    final result = _engine.enqueueTileTap(_state, pos);
    _applyStep(
      result,
      gestureAudio: false,
      haptic: result.state.actionQueue.length > prevLen,
    );
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

  void untillTile(GridPos pos) {
    final prevLen = _state.actionQueue.length;
    final result = _engine.enqueueUntillAt(_state, pos);
    final added = result.state.actionQueue.length > prevLen;
    _applyStep(result, haptic: added);
  }

  void expandIsle() => purchaseUpgrade(UpgradeTrack.farmExpansion);

  void claimActiveQuestReward() => _applyStep(
    _engine.claimActiveQuestReward(_state),
    haptic: true,
    save: true,
  );

  void claimOrFocusActiveQuest({
    required void Function(int initialTab) onOpenShop,
    required VoidCallback onOpenMarket,
  }) {
    notifyUserGestureForAudio();
    final quest = _state.activeQuest;
    if (quest == null) return;
    if (_state.activeQuestProgress.isReadyToClaim) {
      claimActiveQuestReward();
      return;
    }

    switch (quest.id) {
      case QuestId.buyGloves:
        onOpenShop(0);
      case QuestId.unlockStrawberry:
        onOpenShop(1);
      case QuestId.buildCoopOrExpand:
        onOpenShop(2);
      case QuestId.firstSale:
      case QuestId.fulfillVillageOrder:
        if (_state.farmer.carriedCrates.isNotEmpty) {
          _inspectedTile = FarmSimulationEngine.marketStallPos;
          onRequestFocusTile?.call(FarmSimulationEngine.marketStallPos);
          final result = _engine.enqueueTileTap(
            _state,
            FarmSimulationEngine.marketStallPos,
          );
          _applyStep(result, haptic: true);
        } else {
          onOpenMarket();
        }
      case QuestId.enrichCompost:
        selectTool(ToolMode.compost);
        final soilPos = _findFirstMatchingTile(
          (t) => t.ground == GroundType.soil && !t.fertilized,
        );
        if (soilPos != null) {
          _inspectedTile = soilPos;
          onRequestFocusTile?.call(soilPos);
        }
        notifyListeners();
      case QuestId.buildSprinkler:
        selectBuildItem(BuildItemType.sprinklerRotary);
        final openPos = _findFirstMatchingTile(
          (t) =>
              t.structure == StructureType.none &&
              t.crop == null &&
              t.ground == GroundType.grass,
        );
        if (openPos != null) {
          _inspectedTile = openPos;
          onRequestFocusTile?.call(openPos);
        }
        notifyListeners();
      case QuestId.firstHarvest:
        selectTool(ToolMode.smart);
        final ripePos =
            _findFirstMatchingTile((t) => t.crop != null && t.crop!.isRipe) ??
            const GridPos(4, 3);
        _inspectedTile = ripePos;
        onRequestFocusTile?.call(ripePos);
        notifyListeners();
      case QuestId.smartComboPlant:
        selectTool(ToolMode.smart);
        final emptyPos =
            _findFirstMatchingTile(
              (t) =>
                  t.structure == StructureType.none &&
                  t.landmark == LandmarkKind.none &&
                  t.crop == null &&
                  (t.ground == GroundType.soil || t.ground == GroundType.grass),
            ) ??
            const GridPos(6, 3);
        _inspectedTile = emptyPos;
        onRequestFocusTile?.call(emptyPos);
        notifyListeners();
      case QuestId.clearWeeds:
        selectTool(ToolMode.smart);
        final weedPos = _findFirstMatchingTile(
          (t) => t.ground == GroundType.weeds,
        );
        if (weedPos != null) {
          _inspectedTile = weedPos;
          onRequestFocusTile?.call(weedPos);
        }
        notifyListeners();
    }
  }

  GridPos? _findFirstMatchingTile(bool Function(TileState tile) predicate) {
    for (var y = 1; y < _state.gridSize; y++) {
      for (var x = 0; x < _state.gridSize; x++) {
        final pos = GridPos(x, y);
        if (predicate(_state.tileAt(pos))) return pos;
      }
    }
    return null;
  }

  void queueAllReadyHarvests() =>
      _applyStep(_engine.queueAllReadyHarvests(_state), haptic: true);

  void queueAllThirstyPlots() =>
      _applyStep(_engine.queueAllThirstyPlots(_state), haptic: true);

  void selectTool(ToolMode tool) {
    _inspectedTile = null;
    _applyState(_engine.selectTool(_state, tool), haptic: true);
  }

  void selectSeed(ProductId seed) {
    final hasTrial = (_state.trialSeeds[seed] ?? 0) > 0;
    if (SolvilleCatalog.isCropSunPassOnly(seed) &&
        !isSunPassActive &&
        !hasTrial) {
      _promptSunPassFor(
        '${SolvilleCatalog.productName(seed)} seeds',
        toast: SolvilleToast(
          SolvilleToastKind.sunPassRequiredSeed,
          product: seed,
        ),
      );
      return;
    }
    _applyState(_engine.selectSeed(_state, seed), haptic: true);
  }

  void selectBuildItem(BuildItemType item) {
    if (SolvilleCatalog.isBuildSunPassOnly(item) && !isSunPassActive) {
      final name = SolvilleCatalog.buildItems[item]?.name ?? 'Structure';
      _promptSunPassFor(
        name,
        toast: SolvilleToast(
          SolvilleToastKind.sunPassRequiredBuild,
          buildItem: item,
        ),
      );
      return;
    }
    _applyState(_engine.selectBuildItem(_state, item), haptic: true);
  }

  void setPricingStance(PricingStance stance) => _applyState(
    _engine.setPricingStance(_state, stance),
    gestureAudio: false,
    save: true,
  );

  void stockStallFromBarn(ProductId product) => _applyStep(
    _engine.moveBarnCrateToStall(_state, product),
    gestureAudio: false,
    save: true,
  );

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
    if (SolvilleCatalog.isCropSunPassOnly(cropId) && !isSunPassActive) {
      _promptSunPassFor(
        '${SolvilleCatalog.productName(cropId)} license',
        toast: SolvilleToast(
          SolvilleToastKind.sunPassRequiredSeedLicense,
          product: cropId,
        ),
      );
      return;
    }
    _applyStep(
      _engine.unlockSeedLicense(_state, cropId),
      gestureAudio: false,
      save: true,
    );
  }

  void purchaseUpgrade(UpgradeTrack track) {
    final currentTier = _state.upgradeTier(track);
    if (SolvilleCatalog.isNextUpgradeSunPassOnly(track, currentTier) &&
        !isSunPassActive) {
      final nextDef = SolvilleCatalog.nextUpgradeFor(track, currentTier);
      _promptSunPassFor(
        nextDef?.name ?? 'Upgrade',
        toast: SolvilleToast(
          SolvilleToastKind.sunPassRequiredUpgrade,
          upgradeTrack: track,
          tier: currentTier + 1,
        ),
      );
      return;
    }
    _applyStep(_engine.purchaseUpgrade(_state, track), save: true);
  }

  void openSunPassModal() {
    notifyUserGestureForAudio();
    onRequestOpenSunPassModal?.call();
    notifyListeners();
  }

  void _promptSunPassFor(String itemName, {SolvilleToast? toast}) {
    _showToast(
      '☀️ $itemName is part of the Full Game! Unlock everything forever for 0,49€.',
      toast: toast,
    );
    onRequestOpenSunPassModal?.call();
    notifyListeners();
  }

  void _ensureValidEquippedSelection() {
    if (isSunPassActive) return;
    var next = _state;
    if (SolvilleCatalog.isCropSunPassOnly(next.selectedSeed) &&
        (_state.trialSeeds[next.selectedSeed] ?? 0) <= 0) {
      next = next.copyWith(selectedSeed: ProductId.tomato);
    }
    if (SolvilleCatalog.isBuildSunPassOnly(next.selectedBuildItem)) {
      next = next.copyWith(selectedBuildItem: BuildItemType.sprinklerRotary);
    }
    _state = next;
  }

  /// Activates the daily "Sunny Surge" (Sunshower 100% hydration + +25% Market Boost).
  /// Included free every day once the Full Game is unlocked.
  Future<bool> activateSunnySurge() async {
    notifyUserGestureForAudio();
    if (!canClaimSunnySurgeToday) {
      _showToast(
        '🌦️ Sunny Surge is already active for Day ${_state.day}!',
        toast: SolvilleToast(
          SolvilleToastKind.sunnySurgeAlreadyActive,
          day: _state.day,
        ),
      );
      notifyListeners();
      return false;
    }

    if (!isSunPassActive) {
      _promptSunPassFor('Sunny Surge');
      return false;
    }

    final step = _engine.activateSunnySurge(_state);
    _entitlements = _entitlements.copyWith(lastSunnySurgeDay: _state.day);
    await _saveRepo.saveEntitlementState(_entitlements);
    _applyStep(step, gestureAudio: false, haptic: true, save: true);
    return true;
  }

  /// Purchases the 0,49€ one-time Full Game / Lifetime Cozy Edition unlock.
  Future<bool> purchaseLifetimePass() async {
    notifyUserGestureForAudio();
    notifyListeners();
    final res = await _monetization.purchaseLifetimePass();
    if (!res.isSuccess) {
      _showToast(
        'Purchase cancelled.',
        toast: const SolvilleToast(SolvilleToastKind.purchaseCancelled),
      );
      notifyListeners();
      return false;
    }
    _entitlements = _entitlements.copyWith(hasLifetimePass: true);
    await _saveRepo.saveEntitlementState(_entitlements);
    unawaited(_sound.playForEvent(SimEventType.trophyUnlocked));
    _showToast(
      '👑 Thank you! Solville Lifetime Cozy Edition is yours forever!',
      toast: const SolvilleToast(SolvilleToastKind.lifetimePassActivated),
    );
    notifyListeners();
    return true;
  }

  /// Restores previous Full Game purchases from the platform store.
  Future<void> restorePurchases() async {
    notifyUserGestureForAudio();
    notifyListeners();
    final restored = await _monetization.restorePurchases();
    final hasLifetime =
        restored.contains(EntitlementState.lifetimePassProductId) ||
        restored.contains('solville_sun_pass_yearly');
    if (hasLifetime) {
      _entitlements = _entitlements.copyWith(hasLifetimePass: true);
      await _saveRepo.saveEntitlementState(_entitlements);
      _showToast(
        '✅ Restored your Solville Sun Pass purchases!',
        toast: const SolvilleToast(SolvilleToastKind.purchasesRestored),
      );
    } else {
      _showToast(
        'No previous store purchases found for this account.',
        toast: const SolvilleToast(SolvilleToastKind.noPreviousPurchases),
      );
    }
    notifyListeners();
  }

  void restToNextMorning() =>
      _applyStep(_engine.advanceToNextMorning(_state), save: true);

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
    _showToast(
      'Ambience: ${_sound.bgmTrack.label}',
      toast: SolvilleToast(
        SolvilleToastKind.ambienceChanged,
        bgmTrack: _sound.bgmTrack,
      ),
    );
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

  Future<void> saveNow({bool showToast = true}) async {
    await _saveRepo.saveGame(_state);
    if (showToast) {
      _showToast(
        '💾 Farm progress saved!',
        toast: const SolvilleToast(SolvilleToastKind.farmSaved),
      );
      notifyListeners();
    }
  }

  /// Handles Android system back gestures on the root screen by dismissing
  /// transient selections/queues first and auto-saving farm state.
  bool handleBackNavigation() {
    if (_inspectedTile != null) {
      clearInspectedTile();
      return true;
    }
    if (_state.actionQueue.isNotEmpty) {
      clearActionQueue();
      return true;
    }
    if (_state.activeTool != ToolMode.smart) {
      selectTool(ToolMode.smart);
      return true;
    }
    unawaited(_saveRepo.saveGame(_state));
    return false;
  }

  Future<void> resetNewFarm() async {
    await _saveRepo.clearSave();
    _state = _engine.createNewGame();
    _inspectedTile = null;
    _showToast(
      '🌱 Started a fresh sunny farm in Solville!',
      toast: const SolvilleToast(SolvilleToastKind.startedFreshFarm),
    );
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

  void _applyState(
    GameState nextState, {
    bool gestureAudio = true,
    bool haptic = false,
    bool save = false,
  }) {
    if (gestureAudio) notifyUserGestureForAudio();
    _state = nextState;
    if (haptic) _triggerGentleHaptic();
    if (save) unawaited(_saveRepo.saveGame(_state));
    notifyListeners();
  }

  void _applyStep(
    SimulationStepResult result, {
    bool gestureAudio = true,
    bool haptic = false,
    bool save = false,
  }) {
    if (gestureAudio) notifyUserGestureForAudio();
    _state = result.state;
    _dispatchEvents(result.events);
    if (haptic) _triggerGentleHaptic();
    if (save) unawaited(_saveRepo.saveGame(_state));
    notifyListeners();
  }

  static const Set<SolvilleToastKind> _routineVisualOnlyToasts =
      <SolvilleToastKind>{
        SolvilleToastKind.waterRefilled,
        SolvilleToastKind.storedInBarn,
        SolvilleToastKind.soldCrate,
        SolvilleToastKind.queuedHarvests,
        SolvilleToastKind.queuedWatering,
        SolvilleToastKind.noHarvestsReady,
        SolvilleToastKind.allCropsHydrated,
        SolvilleToastKind.placedBuild,
        SolvilleToastKind.fedAnimal,
        SolvilleToastKind.simmeringPreserves,
        SolvilleToastKind.queuedUntill,
        SolvilleToastKind.harvestCratesFirst,
      };

  void _dispatchEvents(List<SimEvent> events) {
    for (final event in events) {
      onVisualSimEvent?.call(event);
      if (event.type == SimEventType.harvest && event.amount >= 2) {
        unawaited(_sound.playHarvestCombo(event.amount));
      } else {
        unawaited(_sound.playForEvent(event.type));
      }

      if (event.type == SimEventType.trophyUnlocked && event.trophyId != null) {
        _achievements.unlockTrophyById(event.trophyId!);
        unawaited(_saveRepo.saveGame(_state));
      }

      final kind = event.toast?.kind;
      final suppressToast =
          kind != null && _routineVisualOnlyToasts.contains(kind);
      if (!suppressToast &&
          event.message != null &&
          event.message!.isNotEmpty) {
        _showToast(event.message!, toast: event.toast);
      }
    }
  }

  void _showToast(String message, {SolvilleToast? toast}) {
    _toastMessage = message;
    _toast = toast;
    _toastTimer = 4.2;
  }

  void _triggerGentleHaptic() {
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      HapticFeedback.selectionClick();
    }
  }

  void _handleOwnedProductRestored(String productId) {
    if ((productId == EntitlementState.lifetimePassProductId ||
            productId == 'solville_sun_pass_yearly') &&
        !_entitlements.hasLifetimePass) {
      _entitlements = _entitlements.copyWith(hasLifetimePass: true);
      unawaited(_saveRepo.saveEntitlementState(_entitlements));
      notifyListeners();
    }
  }

  @override
  void dispose() {
    hoverNotifier.dispose();
    _monetization.dispose();
    unawaited(_saveRepo.saveGame(_state));
    unawaited(_sound.dispose());
    super.dispose();
  }
}
