import 'catalog.dart';
import 'game_state.dart';

/// Semantic toast/notification identifiers emitted by the pure simulation
/// engine and controller, resolved into localized strings by the UI layer.
enum SolvilleToastKind {
  sunnySurge,
  actionQueueFull,
  noHarvestsReady,
  queuedHarvests,
  allCropsHydrated,
  queuedWatering,
  stallFull,
  needCoinsSeedLicense,
  unlockedSeeds,
  needCoinsForUpgrade,
  expandedIsle,
  purchasedUpgrade,
  newDay,
  pathBlocked,
  waterRefilled,
  needCoinsForSeed,
  needCoinsForCompost,
  simmeringPreserves,
  handsFull,
  harvestCratesFirst,
  storedInBarn,
  needCoinsForFeed,
  fedAnimal,
  needCoinsForBuild,
  placedBuild,
  villageGrant,
  villagerOrderComplete,
  soldCrate,
  trophyUnlocked,
  welcomeBack,
  welcomeNew,
  sunPassEnded,
  queuedUntill,
  sunPassRequiredSeed,
  sunPassRequiredSeedLicense,
  sunPassRequiredBuild,
  sunPassRequiredUpgrade,
  sunPassMaxed,
  adCancelled,
  sunPassUnlocked,
  sunnySurgeAlreadyActive,
  adCancelledSurge,
  purchaseCancelled,
  annualPassActivated,
  lifetimePassActivated,
  purchasesRestored,
  noPreviousPurchases,
  ambienceChanged,
  farmSaved,
  startedFreshFarm,
}

/// Structured toast payload carrying parameters for localized formatting.
class SolvilleToast {
  const SolvilleToast(
    this.kind, {
    this.count,
    this.coins,
    this.cost,
    this.day,
    this.gridSize,
    this.x,
    this.y,
    this.tier,
    this.product,
    this.animal,
    this.buildItem,
    this.upgradeTrack,
    this.weather,
    this.bgmTrack,
    this.trophyId,
    this.villagerName,
    this.duration,
  });

  final SolvilleToastKind kind;
  final int? count;
  final int? coins;
  final int? cost;
  final int? day;
  final int? gridSize;
  final int? x;
  final int? y;
  final int? tier;
  final ProductId? product;
  final AnimalType? animal;
  final BuildItemType? buildItem;
  final UpgradeTrack? upgradeTrack;
  final WeatherType? weather;
  final BgmTrack? bgmTrack;
  final String? trophyId;
  final String? villagerName;
  final Duration? duration;
}
