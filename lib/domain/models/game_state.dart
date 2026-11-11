import 'catalog.dart';
import 'grid_pos.dart';
import 'market_state.dart';
import 'solville_toast.dart';
import 'tile_state.dart';

/// Active tool on the bottom HUD dock.
enum ToolMode { smart, dig, seed, water, compost, build, remove }

/// Weather state in Solville.
enum WeatherType {
  sunny,
  goldenBreeze,
  gentleRain;

  String get label => switch (this) {
    sunny => '☀️ Sunny',
    goldenBreeze => '🌤️ Warm Breeze',
    gentleRain => '🌧️ Sunshower (Auto-Water!)',
  };
}

/// Action queued on a farm tile (Alice Greenfingers multi-click flow).
enum ActionKind {
  smart,
  dig,
  plant,
  water,
  refillWater,
  compost,
  harvest,
  pickupCrate,
  storeInBarn,
  sellAtStall,
  tendAnimal,
  loadArtisan,
  placeBuild,
  removeStructure,
}

class QueuedAction {
  const QueuedAction({
    required this.id,
    required this.target,
    required this.kind,
    this.seedId,
    this.buildItem,
  });

  final int id;
  final GridPos target;
  final ActionKind kind;
  final ProductId? seedId;
  final BuildItemType? buildItem;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'target': target.toJson(),
    'kind': kind.name,
    if (seedId != null) 'seedId': seedId!.name,
    if (buildItem != null) 'buildItem': buildItem!.name,
  };

  factory QueuedAction.fromJson(Map<String, dynamic> json) {
    return QueuedAction(
      id: json['id'] as int,
      target: GridPos.fromJson(json['target'] as Map<String, dynamic>),
      kind: ActionKind.values.byName(json['kind'] as String),
      seedId: json['seedId'] != null
          ? ProductId.values.byName(json['seedId'] as String)
          : null,
      buildItem: json['buildItem'] != null
          ? BuildItemType.values.byName(json['buildItem'] as String)
          : null,
    );
  }
}

/// Continuous farmer position, tool charges, and stacked crates.
class FarmerState {
  const FarmerState({
    required this.x,
    required this.y,
    this.facingX = 0.0,
    this.facingY = 1.0,
    this.waterCharges = 5,
    this.carriedCrates = const <ProductId>[],
    this.activePath = const <GridPos>[],
    this.workTimer = 0.0,
    this.walkBobPhase = 0.0,
    this.lastActionEmoji,
  });

  final double x;
  final double y;
  final double facingX;
  final double facingY;
  final int waterCharges;
  final List<ProductId> carriedCrates;
  final List<GridPos> activePath;
  final double workTimer;
  final double walkBobPhase;
  final String? lastActionEmoji;

  GridPos get currentTile => GridPos(x.round(), y.round());

  FarmerState copyWith({
    double? x,
    double? y,
    double? facingX,
    double? facingY,
    int? waterCharges,
    List<ProductId>? carriedCrates,
    List<GridPos>? activePath,
    double? workTimer,
    double? walkBobPhase,
    String? lastActionEmoji,
  }) {
    return FarmerState(
      x: x ?? this.x,
      y: y ?? this.y,
      facingX: facingX ?? this.facingX,
      facingY: facingY ?? this.facingY,
      waterCharges: waterCharges ?? this.waterCharges,
      carriedCrates: carriedCrates ?? this.carriedCrates,
      activePath: activePath ?? this.activePath,
      workTimer: workTimer ?? this.workTimer,
      walkBobPhase: walkBobPhase ?? this.walkBobPhase,
      lastActionEmoji: lastActionEmoji ?? this.lastActionEmoji,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'x': x,
    'y': y,
    'facingX': facingX,
    'facingY': facingY,
    'waterCharges': waterCharges,
    'carriedCrates': carriedCrates.map((e) => e.name).toList(),
  };

  factory FarmerState.fromJson(Map<String, dynamic> json) {
    return FarmerState(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      facingX: (json['facingX'] as num?)?.toDouble() ?? 0.0,
      facingY: (json['facingY'] as num?)?.toDouble() ?? 1.0,
      waterCharges: json['waterCharges'] as int? ?? 5,
      carriedCrates: ((json['carriedCrates'] as List<dynamic>?) ?? const [])
          .map((e) => ProductId.values.byName(e as String))
          .toList(),
    );
  }
}

/// Transient feedback event emitted during simulation ticks for Flame VFX & SFX.
enum SimEventType {
  dig,
  plant,
  water,
  refill,
  compost,
  harvest,
  sprinklerPulse,
  coinsEarned,
  shopPurchase,
  trophyUnlocked,
  newDay,
  statusHint,
}

class SimEvent {
  const SimEvent({
    required this.type,
    this.tile,
    this.message,
    this.toast,
    this.amount = 0,
    this.trophyId,
    this.radius = 1,
  });

  final SimEventType type;
  final GridPos? tile;
  final String? message;
  final SolvilleToast? toast;
  final int amount;
  final String? trophyId;
  final int radius;
}

/// Complete serializable snapshot of the Solville farm.
class GameState {
  GameState({
    required this.gridSize,
    required this.tiles,
    required this.farmer,
    required this.actionQueue,
    required this.nextActionId,
    required this.coins,
    required this.lifetimeCoinsEarned,
    required this.day,
    required this.dayProgress,
    required this.weather,
    required this.activeTool,
    required this.selectedSeed,
    required this.selectedBuildItem,
    required this.unlockedSeeds,
    required this.barnStock,
    required this.market,
    required this.upgradeTiers,
    required this.unlockedTrophies,
    required this.totalCratesHarvested,
    required this.boomCratesSold,
    required this.compostedPlotsCount,
    required this.requestsCompleted,
  });

  final int gridSize;

  /// Row-major `gridSize * gridSize` list of tiles (`index = y * gridSize + x`).
  final List<TileState> tiles;

  final FarmerState farmer;
  final List<QueuedAction> actionQueue;
  final int nextActionId;

  final int coins;
  final int lifetimeCoinsEarned;
  final int day;

  /// `0.0` (Morning) -> `0.5` (Golden Afternoon) -> `1.0` (Cozy Sunset).
  final double dayProgress;
  final WeatherType weather;

  final ToolMode activeTool;
  final ProductId selectedSeed;
  final BuildItemType selectedBuildItem;

  final Set<ProductId> unlockedSeeds;
  final Map<ProductId, int> barnStock;
  final MarketState market;
  final Map<UpgradeTrack, int> upgradeTiers;
  final Set<String> unlockedTrophies;

  // Milestone counters
  final int totalCratesHarvested;
  final int boomCratesSold;
  final int compostedPlotsCount;
  final int requestsCompleted;

  bool inBounds(GridPos pos) =>
      pos.x >= 0 && pos.y >= 0 && pos.x < gridSize && pos.y < gridSize;

  TileState tileAt(GridPos pos) => tiles[pos.y * gridSize + pos.x];

  int upgradeTier(UpgradeTrack track) => upgradeTiers[track] ?? 0;

  int get maxWaterCharges =>
      SolvilleCatalog.maxWaterForTier(upgradeTier(UpgradeTrack.wateringCan));

  int get maxCarryCrates =>
      SolvilleCatalog.maxCratesForTier(upgradeTier(UpgradeTrack.crateStacker));

  double get speedMultiplier => SolvilleCatalog.speedMultiplierForTier(
    upgradeTier(UpgradeTrack.gardenBoots),
  );

  /// Memoized total crate count across all Barn slots.
  late final int totalBarnCrates = _computeTotalBarnCrates();

  int _computeTotalBarnCrates() {
    var sum = 0;
    for (final count in barnStock.values) {
      sum += count;
    }
    return sum;
  }

  /// Memoized cumulative Garden Charm bonus (`0.0..0.50`).
  late final double charmBonus = _computeCharmBonus();

  double _computeCharmBonus() {
    var total = 0.0;
    for (var i = 0; i < tiles.length; i++) {
      total += tiles[i].structure.charmBonus;
    }
    return total.clamp(0.0, 0.50);
  }

  /// Memoized count of unqueued tiles with ripe crops, ready animal goods, or crates.
  late final int readyHarvestCount = _computeReadyHarvestCount();

  int _computeReadyHarvestCount() {
    var count = 0;
    for (var y = 1; y < gridSize; y++) {
      final rowOffset = y * gridSize;
      for (var x = 0; x < gridSize; x++) {
        if (!tiles[rowOffset + x].isReadyToHarvest) continue;
        var isQueued = false;
        for (var i = 0; i < actionQueue.length; i++) {
          final target = actionQueue[i].target;
          if (target.x == x && target.y == y) {
            isQueued = true;
            break;
          }
        }
        if (!isQueued) count++;
      }
    }
    return count;
  }

  /// Memoized count of unqueued growing garden beds with moisture below 65%.
  late final int thirstyPlotCount = _computeThirstyPlotCount();

  int _computeThirstyPlotCount() {
    var count = 0;
    for (var y = 1; y < gridSize; y++) {
      final rowOffset = y * gridSize;
      for (var x = 0; x < gridSize; x++) {
        if (!tiles[rowOffset + x].isThirstyPlot) continue;
        var alreadyQueued = false;
        for (var i = 0; i < actionQueue.length; i++) {
          final a = actionQueue[i];
          if (a.kind == ActionKind.water &&
              a.target.x == x &&
              a.target.y == y) {
            alreadyQueued = true;
            break;
          }
        }
        if (!alreadyQueued) count++;
      }
    }
    return count;
  }

  GameState copyWith({
    int? gridSize,
    List<TileState>? tiles,
    FarmerState? farmer,
    List<QueuedAction>? actionQueue,
    int? nextActionId,
    int? coins,
    int? lifetimeCoinsEarned,
    int? day,
    double? dayProgress,
    WeatherType? weather,
    ToolMode? activeTool,
    ProductId? selectedSeed,
    BuildItemType? selectedBuildItem,
    Set<ProductId>? unlockedSeeds,
    Map<ProductId, int>? barnStock,
    MarketState? market,
    Map<UpgradeTrack, int>? upgradeTiers,
    Set<String>? unlockedTrophies,
    int? totalCratesHarvested,
    int? boomCratesSold,
    int? compostedPlotsCount,
    int? requestsCompleted,
  }) {
    return GameState(
      gridSize: gridSize ?? this.gridSize,
      tiles: tiles ?? this.tiles,
      farmer: farmer ?? this.farmer,
      actionQueue: actionQueue ?? this.actionQueue,
      nextActionId: nextActionId ?? this.nextActionId,
      coins: coins ?? this.coins,
      lifetimeCoinsEarned: lifetimeCoinsEarned ?? this.lifetimeCoinsEarned,
      day: day ?? this.day,
      dayProgress: dayProgress ?? this.dayProgress,
      weather: weather ?? this.weather,
      activeTool: activeTool ?? this.activeTool,
      selectedSeed: selectedSeed ?? this.selectedSeed,
      selectedBuildItem: selectedBuildItem ?? this.selectedBuildItem,
      unlockedSeeds: unlockedSeeds ?? this.unlockedSeeds,
      barnStock: barnStock ?? this.barnStock,
      market: market ?? this.market,
      upgradeTiers: upgradeTiers ?? this.upgradeTiers,
      unlockedTrophies: unlockedTrophies ?? this.unlockedTrophies,
      totalCratesHarvested: totalCratesHarvested ?? this.totalCratesHarvested,
      boomCratesSold: boomCratesSold ?? this.boomCratesSold,
      compostedPlotsCount: compostedPlotsCount ?? this.compostedPlotsCount,
      requestsCompleted: requestsCompleted ?? this.requestsCompleted,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'version': 2,
    'gridSize': gridSize,
    'tiles': tiles.map((t) => t.toJson()).toList(),
    'farmer': farmer.toJson(),
    'actionQueue': actionQueue.map((a) => a.toJson()).toList(),
    'nextActionId': nextActionId,
    'coins': coins,
    'lifetimeCoinsEarned': lifetimeCoinsEarned,
    'day': day,
    'dayProgress': dayProgress,
    'weather': weather.name,
    'activeTool': activeTool.name,
    'selectedSeed': selectedSeed.name,
    'selectedBuildItem': selectedBuildItem.name,
    'unlockedSeeds': unlockedSeeds.map((s) => s.name).toList(),
    'barnStock': <String, int>{
      for (final entry in barnStock.entries)
        if (entry.value > 0) entry.key.name: entry.value,
    },
    'market': market.toJson(),
    'upgradeTiers': <String, int>{
      for (final entry in upgradeTiers.entries) entry.key.name: entry.value,
    },
    'unlockedTrophies': unlockedTrophies.toList(),
    'totalCratesHarvested': totalCratesHarvested,
    'boomCratesSold': boomCratesSold,
    'compostedPlotsCount': compostedPlotsCount,
    'requestsCompleted': requestsCompleted,
  };

  factory GameState.fromJson(Map<String, dynamic> json) {
    final rawBarn = json['barnStock'] as Map<String, dynamic>? ?? const {};
    final rawUpgrades =
        json['upgradeTiers'] as Map<String, dynamic>? ?? const {};

    return GameState(
      gridSize: json['gridSize'] as int,
      tiles: (json['tiles'] as List<dynamic>)
          .map((t) => TileState.fromJson(t as Map<String, dynamic>))
          .toList(),
      farmer: FarmerState.fromJson(json['farmer'] as Map<String, dynamic>),
      actionQueue: ((json['actionQueue'] as List<dynamic>?) ?? const [])
          .map((a) => QueuedAction.fromJson(a as Map<String, dynamic>))
          .toList(),
      nextActionId: json['nextActionId'] as int? ?? 1,
      coins: json['coins'] as int? ?? 90,
      lifetimeCoinsEarned: json['lifetimeCoinsEarned'] as int? ?? 0,
      day: json['day'] as int? ?? 1,
      dayProgress: (json['dayProgress'] as num?)?.toDouble() ?? 0.15,
      weather: json['weather'] != null
          ? WeatherType.values.byName(json['weather'] as String)
          : WeatherType.sunny,
      activeTool: json['activeTool'] != null
          ? ToolMode.values.byName(json['activeTool'] as String)
          : ToolMode.smart,
      selectedSeed: json['selectedSeed'] != null
          ? ProductId.values.byName(json['selectedSeed'] as String)
          : ProductId.tomato,
      selectedBuildItem: json['selectedBuildItem'] != null
          ? BuildItemType.values.byName(json['selectedBuildItem'] as String)
          : BuildItemType.sprinklerRotary,
      unlockedSeeds: ((json['unlockedSeeds'] as List<dynamic>?) ?? const [])
          .map((s) => ProductId.values.byName(s as String))
          .toSet(),
      barnStock: <ProductId, int>{
        for (final entry in rawBarn.entries)
          ProductId.values.byName(entry.key): entry.value as int,
      },
      market: MarketState.fromJson(json['market'] as Map<String, dynamic>),
      upgradeTiers: <UpgradeTrack, int>{
        for (final entry in rawUpgrades.entries)
          UpgradeTrack.values.byName(entry.key): entry.value as int,
      },
      unlockedTrophies:
          ((json['unlockedTrophies'] as List<dynamic>?) ?? const [])
              .map((e) => e as String)
              .toSet(),
      totalCratesHarvested: json['totalCratesHarvested'] as int? ?? 0,
      boomCratesSold: json['boomCratesSold'] as int? ?? 0,
      compostedPlotsCount: json['compostedPlotsCount'] as int? ?? 0,
      requestsCompleted: json['requestsCompleted'] as int? ?? 0,
    );
  }
}
