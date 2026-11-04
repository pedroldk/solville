import 'dart:math' as math;

import '../models/catalog.dart';
import '../models/game_state.dart';
import '../models/grid_pos.dart';
import '../models/market_state.dart';
import '../models/tile_state.dart';
import '../pathfinding/astar_pathfinder.dart';

/// Result of a simulation update or player command.
class SimulationStepResult {
  const SimulationStepResult({
    required this.state,
    this.events = const <SimEvent>[],
  });

  final GameState state;
  final List<SimEvent> events;
}

/// Deterministic core simulation engine for Solville.
class FarmSimulationEngine {
  FarmSimulationEngine({
    math.Random? random,
    this.pathfinder = const AStarPathfinder(),
  }) : _rng = random ?? math.Random();

  static const GridPos farmhousePos = GridPos(1, 1);
  static const GridPos wellPos = GridPos(2, 3);
  static const GridPos barnPos = GridPos(1, 5);
  static const GridPos marketStallPos = GridPos(5, 1);

  /// Duration of one full cozy daylight cycle in seconds (~3 minutes).
  static const double dayLengthSeconds = 180.0;

  static const List<String> _villagerNames = <String>[
    'Baker Mateo',
    'Chef Clara',
    'Florist Mina',
    'Grandpa Leo',
    'Mayor Sunny',
  ];

  final math.Random _rng;
  final AStarPathfinder pathfinder;

  /// Creates a welcoming, immediately lively starter farm.
  GameState createNewGame() {
    const gridSize = 11;
    final tiles = List<TileState>.generate(gridSize * gridSize, (index) {
      final y = index ~/ gridSize;
      if (y == 0) {
        return const TileState(ground: GroundType.cobbleLane);
      }
      return const TileState(ground: GroundType.grass);
    });

    void setTile(int x, int y, TileState state) {
      tiles[y * gridSize + x] = state;
    }

    // Core Solville homestead landmarks
    setTile(
      farmhousePos.x,
      farmhousePos.y,
      const TileState(
        ground: GroundType.stonePath,
        structure: StructureType.farmhouse,
      ),
    );
    setTile(
      wellPos.x,
      wellPos.y,
      const TileState(
        ground: GroundType.stonePath,
        structure: StructureType.well,
      ),
    );
    setTile(
      barnPos.x,
      barnPos.y,
      const TileState(
        ground: GroundType.stonePath,
        structure: StructureType.barn,
      ),
    );
    setTile(
      marketStallPos.x,
      marketStallPos.y,
      const TileState(
        ground: GroundType.cobbleLane,
        structure: StructureType.marketStall,
      ),
    );

    // Warm Sunstone Paths linking landmarks
    for (final p in const <GridPos>[
      GridPos(2, 1),
      GridPos(2, 2),
      GridPos(3, 3),
      GridPos(2, 4),
      GridPos(2, 5),
      GridPos(5, 2),
    ]) {
      setTile(p.x, p.y, const TileState(ground: GroundType.stonePath));
    }

    // Starter garden beds: 2 ripening tomatoes, 2 tilled beds, 6 weed patches
    setTile(
      4,
      3,
      const TileState(
        ground: GroundType.soil,
        moisture: 0.85,
        crop: PlantedCrop(
          cropId: ProductId.tomato,
          growth: 0.78,
          harvestsLeft: 3,
        ),
      ),
    );
    setTile(
      5,
      3,
      const TileState(
        ground: GroundType.soil,
        moisture: 0.70,
        crop: PlantedCrop(
          cropId: ProductId.tomato,
          growth: 0.55,
          harvestsLeft: 3,
        ),
      ),
    );
    setTile(
      6,
      3,
      const TileState(ground: GroundType.soil, moisture: 0.45),
    );
    setTile(
      4,
      4,
      const TileState(ground: GroundType.soil, moisture: 0.45),
    );

    for (final weedPos in const <GridPos>[
      GridPos(5, 4),
      GridPos(6, 4),
      GridPos(7, 3),
      GridPos(4, 5),
      GridPos(7, 6),
      GridPos(8, 5),
    ]) {
      setTile(weedPos.x, weedPos.y, const TileState(ground: GroundType.weeds));
    }

    final unlockedSeeds = <ProductId>{ProductId.tomato, ProductId.carrot};
    final market = _generateMorningMarket(
      unlockedSeeds: unlockedSeeds,
      existingStallCrates: const <ProductId>[],
      pricing: PricingStance.fair,
      extraAccessible: const <ProductId>[],
    );

    return GameState(
      gridSize: gridSize,
      tiles: tiles,
      farmer: const FarmerState(
        x: 3.0,
        y: 3.0,
        waterCharges: 5,
      ),
      actionQueue: const <QueuedAction>[],
      nextActionId: 1,
      coins: 90,
      lifetimeCoinsEarned: 0,
      day: 1,
      dayProgress: 0.12,
      weather: WeatherType.sunny,
      activeTool: ToolMode.smart,
      selectedSeed: ProductId.tomato,
      selectedBuildItem: BuildItemType.sprinklerRotary,
      unlockedSeeds: unlockedSeeds,
      barnStock: const <ProductId, int>{},
      market: market,
      upgradeTiers: const <UpgradeTrack, int>{},
      unlockedTrophies: const <String>{},
      totalCratesHarvested: 0,
      boomCratesSold: 0,
      compostedPlotsCount: 0,
      requestsCompleted: 0,
    );
  }

  /// Advances the world by [dt] seconds (clamped for frame stability).
  SimulationStepResult tick(GameState state, double dt) {
    final safeDt = dt.clamp(0.0, 0.25);
    if (safeDt <= 0.0) {
      return SimulationStepResult(state: state);
    }

    final events = <SimEvent>[];
    var current = state;

    // 1. Daylight progression (rolls over peacefully into a fresh morning)
    final nextDayProgress = current.dayProgress + (safeDt / dayLengthSeconds);
    if (nextDayProgress >= 1.0) {
      final advanced = advanceToNextMorning(current);
      current = advanced.state;
      events.addAll(advanced.events);
    } else {
      current = current.copyWith(dayProgress: nextDayProgress);
    }

    // 2. Soil moisture, crops, sprinklers, orchard trees, artisan press & animals
    current = _tickTilesAndAutomation(current, safeDt, events);

    // 3. Townsfolk purchases at the Market Stall
    current = _tickMarketStallSales(current, safeDt, events);

    // 4. Farmer movement & Action Queue execution
    current = _tickFarmerAndQueue(current, safeDt, events);

    // 5. Cozy safety net: never allow a 0-coin soft-lock
    current = _ensureNoSoftLock(current, events);

    // 6. Check Milestone Trophies
    current = _evaluateTrophies(current, events);

    return SimulationStepResult(state: current, events: events);
  }

  /// Computes flower synergy speed bonus (`0.0..1.05`) for a Beehive at [pos].
  double computeBeeFlowerBonusAt(GameState state, GridPos pos) {
    return _computeBeeFlowerBonus(state.tiles, state.gridSize, pos.x, pos.y);
  }

  /// Appends an action to the Alice Greenfingers multi-click queue when a tile
  /// is tapped or clicked. Supports combo-tapping the same tile (Dig -> Sow -> Water)!
  SimulationStepResult enqueueTileTap(GameState state, GridPos pos) {
    if (!state.inBounds(pos)) {
      return SimulationStepResult(state: state);
    }

    final resolved = _decideQueuedAction(state, pos);
    if (resolved == null) {
      return SimulationStepResult(state: state);
    }

    if (state.actionQueue.length >= 16) {
      return SimulationStepResult(
        state: state,
        events: const <SimEvent>[
          SimEvent(
            type: SimEventType.statusHint,
            message: 'Action queue is full (16 tasks)!',
          ),
        ],
      );
    }

    final action = QueuedAction(
      id: state.nextActionId,
      target: pos,
      kind: resolved.kind,
      seedId: resolved.seedId,
      buildItem: resolved.buildItem,
    );

    return SimulationStepResult(
      state: state.copyWith(
        actionQueue: <QueuedAction>[...state.actionQueue, action],
        nextActionId: state.nextActionId + 1,
      ),
    );
  }

  /// Batch-queues harvests on ripe crops, ready animals, lemon trees & presses.
  SimulationStepResult queueAllReadyHarvests(GameState state) {
    var current = state;
    var added = 0;
    for (var y = 1; y < current.gridSize; y++) {
      for (var x = 0; x < current.gridSize; x++) {
        if (current.actionQueue.length >= 16) break;
        final pos = GridPos(x, y);
        final tile = current.tileAt(pos);
        final ready =
            (tile.crop != null && tile.crop!.isRipe) ||
            (tile.animal != null && tile.animal!.readyCrates > 0) ||
            tile.producerCrates > 0 ||
            tile.droppedCrate != null;
        if (!ready) continue;
        final alreadyQueued = current.actionQueue.any((a) => a.target == pos);
        if (alreadyQueued) continue;

        final kind = tile.droppedCrate != null
            ? ActionKind.pickupCrate
            : ActionKind.harvest;
        current = current.copyWith(
          actionQueue: <QueuedAction>[
            ...current.actionQueue,
            QueuedAction(
              id: current.nextActionId,
              target: pos,
              kind: kind,
            ),
          ],
          nextActionId: current.nextActionId + 1,
        );
        added++;
      }
    }

    return SimulationStepResult(
      state: current,
      events: added == 0
          ? const <SimEvent>[
              SimEvent(
                type: SimEventType.statusHint,
                message: 'No ripe crops or ready crates to harvest right now!',
              ),
            ]
          : <SimEvent>[
              SimEvent(
                type: SimEventType.statusHint,
                message: 'Queued $added harvest task${added == 1 ? '' : 's'}!',
              ),
            ],
    );
  }

  /// Batch-queues watering on dry planted garden beds.
  SimulationStepResult queueAllThirstyPlots(GameState state) {
    var current = state;
    var added = 0;
    for (var y = 1; y < current.gridSize; y++) {
      for (var x = 0; x < current.gridSize; x++) {
        if (current.actionQueue.length >= 16) break;
        final pos = GridPos(x, y);
        final tile = current.tileAt(pos);
        if (tile.ground != GroundType.soil ||
            tile.crop == null ||
            tile.crop!.isRipe ||
            tile.moisture >= 0.65) {
          continue;
        }
        final alreadyQueued = current.actionQueue.any(
          (a) => a.target == pos && a.kind == ActionKind.water,
        );
        if (alreadyQueued) continue;

        current = current.copyWith(
          actionQueue: <QueuedAction>[
            ...current.actionQueue,
            QueuedAction(
              id: current.nextActionId,
              target: pos,
              kind: ActionKind.water,
            ),
          ],
          nextActionId: current.nextActionId + 1,
        );
        added++;
      }
    }

    return SimulationStepResult(
      state: current,
      events: added == 0
          ? const <SimEvent>[
              SimEvent(
                type: SimEventType.statusHint,
                message: 'All growing crops are well hydrated!',
              ),
            ]
          : <SimEvent>[
              SimEvent(
                type: SimEventType.statusHint,
                message: 'Queued watering for $added garden bed${added == 1 ? '' : 's'}!',
              ),
            ],
    );
  }

  /// Cancels any queued tasks targeting [pos] (Right-click on PC or badge tap).
  GameState cancelActionsAt(GameState state, GridPos pos) {
    final remaining = state.actionQueue
        .where((a) => a.target != pos)
        .toList();
    if (remaining.length == state.actionQueue.length) {
      return state;
    }
    final clearedFirst =
        state.actionQueue.isNotEmpty && state.actionQueue.first.target == pos;
    return state.copyWith(
      actionQueue: remaining,
      farmer: clearedFirst
          ? state.farmer.copyWith(activePath: const <GridPos>[])
          : state.farmer,
    );
  }

  /// Clears all pending queued actions.
  GameState clearQueue(GameState state) {
    return state.copyWith(
      actionQueue: const <QueuedAction>[],
      farmer: state.farmer.copyWith(activePath: const <GridPos>[]),
    );
  }

  GameState selectTool(GameState state, ToolMode tool) =>
      state.copyWith(activeTool: tool);

  GameState selectSeed(GameState state, ProductId seed) {
    if (!state.unlockedSeeds.contains(seed)) return state;
    return state.copyWith(selectedSeed: seed, activeTool: ToolMode.seed);
  }

  GameState selectBuildItem(GameState state, BuildItemType item) =>
      state.copyWith(selectedBuildItem: item, activeTool: ToolMode.build);

  GameState setPricingStance(GameState state, PricingStance stance) =>
      state.copyWith(market: state.market.copyWith(pricing: stance));

  /// Moves a crate directly from Barn storage onto the Market Stall display.
  SimulationStepResult moveBarnCrateToStall(
    GameState state,
    ProductId product,
  ) {
    final inBarn = state.barnStock[product] ?? 0;
    if (inBarn <= 0) return SimulationStepResult(state: state);
    if (state.market.stallCrates.length >= MarketState.maxStallSlots) {
      return SimulationStepResult(
        state: state,
        events: const <SimEvent>[
          SimEvent(
            type: SimEventType.statusHint,
            message: 'Market Stall display is full (8 crates)!',
          ),
        ],
      );
    }

    final updatedBarn = Map<ProductId, int>.from(state.barnStock);
    updatedBarn[product] = inBarn - 1;
    if (updatedBarn[product] == 0) updatedBarn.remove(product);

    final updatedStall = <ProductId>[...state.market.stallCrates, product];
    return SimulationStepResult(
      state: state.copyWith(
        barnStock: updatedBarn,
        market: state.market.copyWith(stallCrates: updatedStall),
      ),
    );
  }

  /// Unlocks a new crop seed license in the Town Shop.
  SimulationStepResult unlockSeedLicense(GameState state, ProductId cropId) {
    final def = SolvilleCatalog.crops[cropId];
    if (def == null || state.unlockedSeeds.contains(cropId)) {
      return SimulationStepResult(state: state);
    }
    if (state.coins < def.licenseCost) {
      return SimulationStepResult(
        state: state,
        events: const <SimEvent>[
          SimEvent(
            type: SimEventType.statusHint,
            message: 'Need more Sols for this seed license!',
          ),
        ],
      );
    }

    final unlocked = <ProductId>{...state.unlockedSeeds, cropId};
    return SimulationStepResult(
      state: state.copyWith(
        coins: state.coins - def.licenseCost,
        unlockedSeeds: unlocked,
        selectedSeed: cropId,
        activeTool: ToolMode.seed,
      ),
      events: <SimEvent>[
        SimEvent(
          type: SimEventType.shopPurchase,
          message: 'Unlocked ${def.name} seeds!',
        ),
      ],
    );
  }

  /// Purchases the next tier of a permanent character or farm upgrade.
  SimulationStepResult purchaseUpgrade(GameState state, UpgradeTrack track) {
    final nextTier = state.upgradeTier(track) + 1;
    UpgradeTierDef? upgradeDef;
    for (final candidate in SolvilleCatalog.upgrades) {
      if (candidate.track == track && candidate.tier == nextTier) {
        upgradeDef = candidate;
        break;
      }
    }
    if (upgradeDef == null) {
      return SimulationStepResult(state: state);
    }
    if (state.coins < upgradeDef.cost) {
      return SimulationStepResult(
        state: state,
        events: const <SimEvent>[
          SimEvent(
            type: SimEventType.statusHint,
            message: 'Not enough Sols for that upgrade yet!',
          ),
        ],
      );
    }

    final updatedTiers = Map<UpgradeTrack, int>.from(state.upgradeTiers)
      ..[track] = nextTier;
    var nextState = state.copyWith(
      coins: state.coins - upgradeDef.cost,
      upgradeTiers: updatedTiers,
    );

    if (track == UpgradeTrack.wateringCan) {
      nextState = nextState.copyWith(
        farmer: nextState.farmer.copyWith(
          waterCharges: SolvilleCatalog.maxWaterForTier(nextTier),
        ),
      );
    } else if (track == UpgradeTrack.farmExpansion) {
      nextState = _expandFarmGrid(
        nextState,
        SolvilleCatalog.gridSizeForExpansionTier(nextTier),
      );
    }

    final events = <SimEvent>[
      SimEvent(
        type: SimEventType.shopPurchase,
        message: 'Purchased ${upgradeDef.name}!',
      ),
    ];
    nextState = _evaluateTrophies(nextState, events);
    return SimulationStepResult(state: nextState, events: events);
  }

  /// Peaceful transition to the next morning with fresh Market Trends & weather.
  SimulationStepResult advanceToNextMorning(GameState state) {
    final nextDay = state.day + 1;
    final roll = _rng.nextDouble();
    final nextWeather = roll < 0.22
        ? WeatherType.gentleRain
        : (roll < 0.52 ? WeatherType.goldenBreeze : WeatherType.sunny);

    final extraAccessible = <ProductId>{};
    final updatedTiles = List<TileState>.from(state.tiles);
    for (var i = 0; i < updatedTiles.length; i++) {
      final t = updatedTiles[i];
      if (t.structure == StructureType.henhouse) {
        extraAccessible.add(ProductId.eggs);
      } else if (t.structure == StructureType.beehive) {
        extraAccessible.add(ProductId.honey);
      } else if (t.structure == StructureType.cowPaddock) {
        extraAccessible.add(ProductId.milk);
      } else if (t.structure == StructureType.lemonTree) {
        extraAccessible.add(ProductId.lemon);
      } else if (t.structure == StructureType.artisanPress) {
        extraAccessible.add(ProductId.preserves);
      }
      if (nextWeather == WeatherType.gentleRain &&
          t.ground == GroundType.soil) {
        updatedTiles[i] = t.copyWith(moisture: 1.0);
      }
    }

    final nextMarket = _generateMorningMarket(
      unlockedSeeds: state.unlockedSeeds,
      existingStallCrates: state.market.stallCrates,
      pricing: state.market.pricing,
      extraAccessible: extraAccessible.toList(),
    );

    final nextState = state.copyWith(
      day: nextDay,
      dayProgress: 0.08,
      weather: nextWeather,
      tiles: updatedTiles,
      market: nextMarket,
    );

    return SimulationStepResult(
      state: nextState,
      events: <SimEvent>[
        SimEvent(
          type: SimEventType.newDay,
          message: 'Day $nextDay dawned in Solville! (${nextWeather.label})',
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Internal Decision & Simulation Helpers
  // ---------------------------------------------------------------------------

  ({ActionKind kind, ProductId? seedId, BuildItemType? buildItem})?
  _decideQueuedAction(GameState state, GridPos pos) {
    final tile = state.tileAt(pos);
    if (pos.y == 0 && tile.structure != StructureType.marketStall) {
      return null;
    }

    // Landmark interactions always take priority regardless of selected tool.
    if (tile.structure == StructureType.well) {
      return (kind: ActionKind.refillWater, seedId: null, buildItem: null);
    }
    if (tile.structure == StructureType.marketStall) {
      return (kind: ActionKind.sellAtStall, seedId: null, buildItem: null);
    }
    if (tile.structure == StructureType.barn) {
      return (kind: ActionKind.storeInBarn, seedId: null, buildItem: null);
    }
    if (tile.structure == StructureType.farmhouse) {
      return null;
    }

    // Explicit non-smart tool modes
    switch (state.activeTool) {
      case ToolMode.dig:
        if (tile.structure == StructureType.none &&
            (tile.ground == GroundType.weeds ||
                tile.ground == GroundType.grass ||
                tile.crop != null ||
                tile.ground == GroundType.stonePath)) {
          return (kind: ActionKind.dig, seedId: null, buildItem: null);
        }
        return null;

      case ToolMode.seed:
        if (tile.structure != StructureType.none) return null;
        return (
          kind: ActionKind.plant,
          seedId: state.selectedSeed,
          buildItem: null,
        );

      case ToolMode.water:
        if (tile.ground == GroundType.soil ||
            state.actionQueue.any(
              (a) =>
                  a.target == pos &&
                  (a.kind == ActionKind.dig || a.kind == ActionKind.plant),
            )) {
          return (kind: ActionKind.water, seedId: null, buildItem: null);
        }
        return null;

      case ToolMode.compost:
        if (tile.ground == GroundType.soil && !tile.fertilized) {
          return (kind: ActionKind.compost, seedId: null, buildItem: null);
        }
        return null;

      case ToolMode.build:
        if (tile.structure == StructureType.none &&
            tile.crop == null &&
            tile.droppedCrate == null &&
            pos.y > 0) {
          return (
            kind: ActionKind.placeBuild,
            seedId: null,
            buildItem: state.selectedBuildItem,
          );
        }
        return null;

      case ToolMode.remove:
        if (tile.structure.isRemovable ||
            tile.ground == GroundType.stonePath ||
            tile.crop != null) {
          return (
            kind: ActionKind.removeStructure,
            seedId: null,
            buildItem: null,
          );
        }
        return null;

      case ToolMode.smart:
        break;
    }

    // Smart contextual mode + multi-tap combo inspection!
    final queuedOnPos = state.actionQueue
        .where((a) => a.target == pos)
        .toList();

    if (tile.droppedCrate != null &&
        !queuedOnPos.any((a) => a.kind == ActionKind.pickupCrate)) {
      return (kind: ActionKind.pickupCrate, seedId: null, buildItem: null);
    }

    // Orchard Lemon Tree & Artisan Kettle interactions
    if (tile.structure == StructureType.lemonTree) {
      if (tile.producerCrates > 0 &&
          !queuedOnPos.any((a) => a.kind == ActionKind.harvest)) {
        return (kind: ActionKind.harvest, seedId: null, buildItem: null);
      }
      return null;
    }
    if (tile.structure == StructureType.artisanPress) {
      if (tile.producerCrates > 0 &&
          !queuedOnPos.any((a) => a.kind == ActionKind.harvest)) {
        return (kind: ActionKind.harvest, seedId: null, buildItem: null);
      }
      if (!tile.producerActive &&
          state.farmer.carriedCrates.any((c) => c.canMakePreserves) &&
          !queuedOnPos.any((a) => a.kind == ActionKind.loadArtisan)) {
        return (kind: ActionKind.loadArtisan, seedId: null, buildItem: null);
      }
      return null;
    }

    if (tile.animal != null) {
      if (tile.animal!.readyCrates > 0 &&
          !queuedOnPos.any((a) => a.kind == ActionKind.harvest)) {
        return (kind: ActionKind.harvest, seedId: null, buildItem: null);
      }
      if (tile.animal!.type != AnimalType.bee &&
          tile.animal!.feedLevel < 0.80 &&
          !queuedOnPos.any((a) => a.kind == ActionKind.tendAnimal)) {
        return (kind: ActionKind.tendAnimal, seedId: null, buildItem: null);
      }
      return null;
    }

    if (tile.structure != StructureType.none &&
        tile.structure != StructureType.flowerArch) {
      return null;
    }

    if (tile.crop != null) {
      if (tile.crop!.isRipe &&
          !queuedOnPos.any((a) => a.kind == ActionKind.harvest)) {
        return (kind: ActionKind.harvest, seedId: null, buildItem: null);
      }
      if (tile.moisture < 0.85 &&
          !queuedOnPos.any((a) => a.kind == ActionKind.water)) {
        return (kind: ActionKind.water, seedId: null, buildItem: null);
      }
      return null;
    }

    // Multi-click combo on empty weeds / grass / soil!
    final hasQueuedDig = queuedOnPos.any((a) => a.kind == ActionKind.dig);
    final hasQueuedPlant = queuedOnPos.any((a) => a.kind == ActionKind.plant);
    final hasQueuedWater = queuedOnPos.any((a) => a.kind == ActionKind.water);

    if ((tile.ground == GroundType.weeds || tile.ground == GroundType.grass) &&
        !hasQueuedDig) {
      return (kind: ActionKind.dig, seedId: null, buildItem: null);
    }

    if ((tile.ground == GroundType.soil || hasQueuedDig) && !hasQueuedPlant) {
      return (
        kind: ActionKind.plant,
        seedId: state.selectedSeed,
        buildItem: null,
      );
    }

    if ((tile.ground == GroundType.soil || hasQueuedPlant) && !hasQueuedWater) {
      return (kind: ActionKind.water, seedId: null, buildItem: null);
    }

    return null;
  }

  GameState _tickTilesAndAutomation(
    GameState state,
    double dt,
    List<SimEvent> events,
  ) {
    final size = state.gridSize;
    final updated = List<TileState>.from(state.tiles);
    final updatedBarn = Map<ProductId, int>.from(state.barnStock);
    var barnChanged = false;
    final isRaining = state.weather == WeatherType.gentleRain;

    // First pass: trigger sprinklers
    final sprinklerTargets = <(int, int)>{};
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        final idx = y * size + x;
        final tile = updated[idx];
        final radius = switch (tile.structure) {
          StructureType.sprinklerRotary => 1,
          StructureType.sprinklerSolar => 2,
          _ => 0,
        };
        if (radius > 0) {
          final nextCd = tile.sprinklerCooldown - dt;
          if (nextCd <= 0.0) {
            updated[idx] = tile.copyWith(
              sprinklerCooldown: radius == 2 ? 4.5 : 5.5,
            );
            events.add(
              SimEvent(
                type: SimEventType.sprinklerPulse,
                tile: GridPos(x, y),
                radius: radius,
              ),
            );
            for (var dy = -radius; dy <= radius; dy++) {
              for (var dx = -radius; dx <= radius; dx++) {
                final nx = x + dx;
                final ny = y + dy;
                if (nx >= 0 && ny >= 0 && nx < size && ny < size) {
                  sprinklerTargets.add((nx, ny));
                }
              }
            }
          } else {
            updated[idx] = tile.copyWith(sprinklerCooldown: nextCd);
          }
        }
      }
    }

    // Second pass: crops, moisture, orchard trees, artisan kettles & animals
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        final idx = y * size + x;
        var tile = updated[idx];

        if (tile.ground == GroundType.soil) {
          var moisture = tile.moisture;
          if (isRaining || sprinklerTargets.contains((x, y))) {
            moisture = 1.0;
          } else {
            final cropDef = tile.crop != null
                ? SolvilleCatalog.crops[tile.crop!.cropId]
                : null;
            final baseDrain = cropDef?.waterDrainPerSec ?? 0.008;
            final drainFactor = tile.fertilized ? 0.70 : 1.0;
            moisture = (moisture - baseDrain * drainFactor * dt).clamp(
              0.0,
              1.0,
            );
          }

          var crop = tile.crop;
          if (crop != null && !crop.isRipe) {
            final def = SolvilleCatalog.crops[crop.cropId]!;
            if (moisture > 0.02) {
              final compostMult = tile.fertilized ? 1.35 : 1.0;
              final hydrationMult = moisture > 0.35 ? 1.0 : 0.65;
              final delta =
                  (dt / def.growthSeconds) * compostMult * hydrationMult;
              crop = crop.copyWith(
                growth: (crop.growth + delta).clamp(0.0, 1.0),
                thirstySeconds: 0.0,
              );
            } else {
              final trickle = (dt / def.growthSeconds) * 0.12;
              crop = crop.copyWith(
                growth: (crop.growth + trickle).clamp(0.0, 0.96),
                thirstySeconds: crop.thirstySeconds + dt,
              );
            }
          }
          tile = tile.copyWith(moisture: moisture, crop: crop);
        }

        // Sunburst Lemon Tree passive orchard cycle
        if (tile.structure == StructureType.lemonTree &&
            tile.producerCrates < 2) {
          final rainBonus = isRaining ? 1.25 : 1.0;
          var nextProg =
              tile.producerProgress +
              (dt / SolvilleCatalog.lemonTreeCycleSeconds) * rainBonus;
          var crates = tile.producerCrates;
          if (nextProg >= 1.0) {
            nextProg -= 1.0;
            crates = (crates + 1).clamp(0, 2);
          }
          tile = tile.copyWith(
            producerProgress: nextProg,
            producerCrates: crates,
          );
        }

        // Artisan Preserves Kettle cycle (auto-pulls raw produce from Barn if idle!)
        if (tile.structure == StructureType.artisanPress) {
          var active = tile.producerActive;
          var prog = tile.producerProgress;
          var crates = tile.producerCrates;

          if (!active && crates < 2) {
            for (final key in updatedBarn.keys.toList()) {
              if (key.canMakePreserves && (updatedBarn[key] ?? 0) > 0) {
                updatedBarn[key] = updatedBarn[key]! - 1;
                if (updatedBarn[key] == 0) updatedBarn.remove(key);
                barnChanged = true;
                active = true;
                prog = 0.0;
                break;
              }
            }
          }

          if (active) {
            prog += dt / SolvilleCatalog.artisanPressCycleSeconds;
            if (prog >= 1.0) {
              prog = 0.0;
              active = false;
              crates = (crates + 1).clamp(0, 2);
            }
          }

          tile = tile.copyWith(
            producerActive: active,
            producerProgress: prog,
            producerCrates: crates,
          );
        }

        if (tile.animal != null) {
          final animal = tile.animal!;
          final def = SolvilleCatalog.animals[animal.type]!;
          if (animal.readyCrates < 3) {
            final canProduce =
                animal.type == AnimalType.bee || animal.feedLevel > 0.02;
            if (canProduce) {
              var speedMult = 1.0;
              if (animal.type == AnimalType.bee) {
                speedMult += _computeBeeFlowerBonus(updated, size, x, y);
              }
              var nextProg =
                  animal.progress + (dt / def.cycleSeconds) * speedMult;
              var nextCrates = animal.readyCrates;
              var nextFeed = animal.feedLevel;
              if (animal.type != AnimalType.bee) {
                nextFeed = (nextFeed - (dt / (def.cycleSeconds * 2.2))).clamp(
                  0.0,
                  1.0,
                );
              }
              if (nextProg >= 1.0) {
                nextProg -= 1.0;
                nextCrates = (nextCrates + 1).clamp(0, 3);
              }
              tile = tile.copyWith(
                animal: animal.copyWith(
                  progress: nextProg,
                  readyCrates: nextCrates,
                  feedLevel: nextFeed,
                ),
              );
            }
          }
        }

        updated[idx] = tile;
      }
    }

    return state.copyWith(
      tiles: updated,
      barnStock: barnChanged ? updatedBarn : state.barnStock,
    );
  }

  double _computeBeeFlowerBonus(
    List<TileState> tiles,
    int size,
    int cx,
    int cy,
  ) {
    var bonus = 0.0;
    for (var dy = -2; dy <= 2; dy++) {
      for (var dx = -2; dx <= 2; dx++) {
        if (dx == 0 && dy == 0) continue;
        final nx = cx + dx;
        final ny = cy + dy;
        if (nx < 0 || ny < 0 || nx >= size || ny >= size) continue;
        final neighbor = tiles[ny * size + nx];
        final crop = neighbor.crop;
        if (crop != null && crop.growth >= 0.45) {
          bonus += crop.cropId == ProductId.lavender ? 0.35 : 0.10;
        } else if (neighbor.structure == StructureType.flowerArch ||
            neighbor.structure == StructureType.lemonTree) {
          bonus += 0.18;
        }
      }
    }
    return bonus.clamp(0.0, 1.05);
  }

  GameState _tickMarketStallSales(
    GameState state,
    double dt,
    List<SimEvent> events,
  ) {
    final market = state.market;
    if (market.stallCrates.isEmpty) {
      return state;
    }

    final nextCooldown = market.saleCooldown - dt;
    if (nextCooldown > 0.0) {
      return state.copyWith(
        market: market.copyWith(saleCooldown: nextCooldown),
      );
    }

    final soldProduct = market.stallCrates.first;
    final remainingCrates = market.stallCrates.sublist(1);
    final charm = state.charmBonus;
    final salePrice = market.unitPriceFor(soldProduct, charmBonus: charm);
    final isBoom = market.trendFor(soldProduct) == MarketTrend.boom;

    var earnedCoins = salePrice;
    var updatedRequest = market.dailyRequest;
    var completedRequests = state.requestsCompleted;

    if (updatedRequest != null &&
        !updatedRequest.isCompleted &&
        updatedRequest.product == soldProduct) {
      final nextDelivered = updatedRequest.deliveredCount + 1;
      updatedRequest = updatedRequest.copyWith(deliveredCount: nextDelivered);
      if (updatedRequest.isCompleted) {
        earnedCoins += updatedRequest.bonusReward;
        completedRequests += 1;
        events.add(
          SimEvent(
            type: SimEventType.coinsEarned,
            tile: marketStallPos,
            amount: updatedRequest.bonusReward,
            message:
                '${updatedRequest.villagerName}\'s order complete! +${updatedRequest.bonusReward}☀️',
          ),
        );
      }
    }

    events.add(
      SimEvent(
        type: SimEventType.coinsEarned,
        tile: marketStallPos,
        amount: salePrice,
        message:
            'Sold ${SolvilleCatalog.productEmoji(soldProduct)} +$salePrice☀️',
      ),
    );

    final baseInterval = 3.2 * market.pricing.saleIntervalFactor;
    return state.copyWith(
      coins: state.coins + earnedCoins,
      lifetimeCoinsEarned: state.lifetimeCoinsEarned + earnedCoins,
      boomCratesSold: state.boomCratesSold + (isBoom ? 1 : 0),
      requestsCompleted: completedRequests,
      market: market.copyWith(
        stallCrates: remainingCrates,
        saleCooldown: baseInterval,
        dailyRequest: updatedRequest,
      ),
    );
  }

  GameState _tickFarmerAndQueue(
    GameState state,
    double dt,
    List<SimEvent> events,
  ) {
    var farmer = state.farmer;

    if (farmer.workTimer > 0.0) {
      final remainingWork = (farmer.workTimer - dt).clamp(0.0, 10.0);
      return state.copyWith(
        farmer: farmer.copyWith(workTimer: remainingWork),
      );
    }

    if (state.actionQueue.isEmpty) {
      return state;
    }

    final currentAction = state.actionQueue.first;

    // Auto-refill detour: if next action is watering and watering can is empty,
    // prepend a trip to the Stone Well automatically!
    if (currentAction.kind == ActionKind.water && farmer.waterCharges <= 0) {
      final refillAction = QueuedAction(
        id: state.nextActionId,
        target: wellPos,
        kind: ActionKind.refillWater,
      );
      final updatedQueue = <QueuedAction>[refillAction, ...state.actionQueue];
      return state.copyWith(
        actionQueue: updatedQueue,
        nextActionId: state.nextActionId + 1,
        farmer: farmer.copyWith(activePath: const <GridPos>[]),
      );
    }

    if (_isInRangeForAction(state, farmer, currentAction.target)) {
      final dx = currentAction.target.x - farmer.x;
      final dy = currentAction.target.y - farmer.y;
      final stateFacing = state.copyWith(
        farmer: farmer.copyWith(
          facingX: dx == 0 && dy == 0 ? farmer.facingX : dx,
          facingY: dx == 0 && dy == 0 ? farmer.facingY : dy,
          activePath: const <GridPos>[],
        ),
      );
      return _executeFrontAction(stateFacing, currentAction, events);
    }

    var path = farmer.activePath;
    if (path.isEmpty) {
      final computed = pathfinder.findPath(
        start: farmer.currentTile,
        goal: currentAction.target,
        gridSize: state.gridSize,
        isWalkable: (p) => state.tileAt(p).isWalkable,
        stepCost: (_, to) => state.tileAt(to).walkCost,
      );
      if (computed.isEmpty) {
        events.add(
          const SimEvent(
            type: SimEventType.statusHint,
            message: 'Path blocked! Adjust garden layout.',
          ),
        );
        return state.copyWith(actionQueue: state.actionQueue.sublist(1));
      }
      path = computed.length > 1 &&
              (farmer.x - computed.first.x).abs() < 0.15 &&
              (farmer.y - computed.first.y).abs() < 0.15
          ? computed.sublist(1)
          : computed;
    }

    final currentGround = state.tileAt(farmer.currentTile).ground;
    final pathSpeedBonus =
        (currentGround == GroundType.stonePath ||
            currentGround == GroundType.cobbleLane)
        ? 1.40
        : 1.0;
    final moveSpeed = 3.8 * state.speedMultiplier * pathSpeedBonus;
    var stepBudget = moveSpeed * dt;
    var fx = farmer.x;
    var fy = farmer.y;
    var facingX = farmer.facingX;
    var facingY = farmer.facingY;
    final mutablePath = List<GridPos>.from(path);

    while (stepBudget > 0.0 && mutablePath.isNotEmpty) {
      final wp = mutablePath.first;
      final vx = wp.x - fx;
      final vy = wp.y - fy;
      final dist = math.sqrt(vx * vx + vy * vy);
      if (dist <= 0.001) {
        fx = wp.x.toDouble();
        fy = wp.y.toDouble();
        mutablePath.removeAt(0);
        continue;
      }
      facingX = vx / dist;
      facingY = vy / dist;
      if (stepBudget >= dist) {
        fx = wp.x.toDouble();
        fy = wp.y.toDouble();
        stepBudget -= dist;
        mutablePath.removeAt(0);
      } else {
        fx += facingX * stepBudget;
        fy += facingY * stepBudget;
        stepBudget = 0.0;
      }
    }

    return state.copyWith(
      farmer: farmer.copyWith(
        x: fx,
        y: fy,
        facingX: facingX,
        facingY: facingY,
        activePath: mutablePath,
        walkBobPhase: (farmer.walkBobPhase + dt * 11.0) % (math.pi * 2),
      ),
    );
  }

  bool _isInRangeForAction(
    GameState state,
    FarmerState farmer,
    GridPos target,
  ) {
    final targetTile = state.tileAt(target);
    final dx = (farmer.x - target.x).abs();
    final dy = (farmer.y - target.y).abs();
    if (targetTile.isWalkable) {
      return dx <= 0.32 && dy <= 0.32;
    }
    return dx <= 1.18 && dy <= 1.18 && (dx + dy) <= 1.45;
  }

  GameState _executeFrontAction(
    GameState state,
    QueuedAction action,
    List<SimEvent> events,
  ) {
    final remainingQueue = state.actionQueue.sublist(1);
    final pos = action.target;
    final tileIndex = pos.y * state.gridSize + pos.x;
    final tile = state.tiles[tileIndex];
    final updatedTiles = List<TileState>.from(state.tiles);
    final actionEmoji = switch (action.kind) {
      ActionKind.dig || ActionKind.removeStructure => '🪏',
      ActionKind.plant => '🌱',
      ActionKind.water || ActionKind.refillWater => '💧',
      ActionKind.compost => '✨',
      ActionKind.harvest || ActionKind.pickupCrate => '📦',
      ActionKind.tendAnimal => '🌾',
      ActionKind.loadArtisan => '🫙',
      ActionKind.placeBuild => '🔨',
      _ => '☀️',
    };
    var nextState = state.copyWith(
      actionQueue: remainingQueue,
      farmer: state.farmer.copyWith(
        workTimer: 0.24,
        lastActionEmoji: actionEmoji,
      ),
    );

    switch (action.kind) {
      case ActionKind.refillWater:
        nextState = nextState.copyWith(
          farmer: nextState.farmer.copyWith(
            waterCharges: nextState.maxWaterCharges,
          ),
        );
        events.add(
          SimEvent(
            type: SimEventType.refill,
            tile: pos,
            message: 'Watering can refilled!',
          ),
        );
        return nextState;

      case ActionKind.dig:
        if (tile.structure == StructureType.none) {
          final wasWeeds = tile.ground == GroundType.weeds;
          updatedTiles[tileIndex] = tile.copyWith(
            ground: GroundType.soil,
            crop: null,
            moisture: math.max(tile.moisture, 0.25),
          );
          nextState = nextState.copyWith(
            tiles: updatedTiles,
            coins: nextState.coins + (wasWeeds ? 1 : 0),
          );
          events.add(SimEvent(type: SimEventType.dig, tile: pos));
        }
        return nextState;

      case ActionKind.plant:
        final seed = action.seedId ?? nextState.selectedSeed;
        final def = SolvilleCatalog.crops[seed];
        if (def != null &&
            nextState.unlockedSeeds.contains(seed) &&
            tile.structure == StructureType.none &&
            tile.crop == null) {
          if (nextState.coins < def.seedCost) {
            events.add(
              SimEvent(
                type: SimEventType.statusHint,
                tile: pos,
                message: 'Need ${def.seedCost}☀️ for ${def.name} seeds!',
              ),
            );
            return nextState;
          }
          updatedTiles[tileIndex] = tile.copyWith(
            ground: GroundType.soil,
            moisture: math.max(tile.moisture, 0.35),
            crop: PlantedCrop(
              cropId: seed,
              growth: 0.04,
              harvestsLeft: def.maxHarvests,
            ),
          );
          nextState = nextState.copyWith(
            tiles: updatedTiles,
            coins: nextState.coins - def.seedCost,
          );
          events.add(SimEvent(type: SimEventType.plant, tile: pos));
        }
        return nextState;

      case ActionKind.water:
        if (tile.ground == GroundType.soil &&
            nextState.farmer.waterCharges > 0) {
          updatedTiles[tileIndex] = tile.copyWith(
            moisture: 1.0,
            crop: tile.crop?.copyWith(thirstySeconds: 0.0),
          );
          if (nextState.upgradeTier(UpgradeTrack.wateringCan) >= 2) {
            for (final adj in pos.cardinalNeighbors) {
              if (nextState.inBounds(adj)) {
                final adjIdx = adj.y * nextState.gridSize + adj.x;
                final adjTile = updatedTiles[adjIdx];
                if (adjTile.ground == GroundType.soil) {
                  updatedTiles[adjIdx] = adjTile.copyWith(
                    moisture: math.max(adjTile.moisture, 0.85),
                  );
                }
              }
            }
          }
          nextState = nextState.copyWith(
            tiles: updatedTiles,
            farmer: nextState.farmer.copyWith(
              waterCharges: nextState.farmer.waterCharges - 1,
            ),
          );
          events.add(SimEvent(type: SimEventType.water, tile: pos));
        }
        return nextState;

      case ActionKind.compost:
        if (tile.ground == GroundType.soil && !tile.fertilized) {
          if (nextState.coins < SolvilleCatalog.compostCost) {
            events.add(
              const SimEvent(
                type: SimEventType.statusHint,
                message:
                    'Need ${SolvilleCatalog.compostCost}☀️ for Rich Compost!',
              ),
            );
            return nextState;
          }
          updatedTiles[tileIndex] = tile.copyWith(fertilized: true);
          nextState = nextState.copyWith(
            tiles: updatedTiles,
            coins: nextState.coins - SolvilleCatalog.compostCost,
            compostedPlotsCount: nextState.compostedPlotsCount + 1,
          );
          events.add(SimEvent(type: SimEventType.compost, tile: pos));
        }
        return nextState;

      case ActionKind.harvest:
        ProductId? harvestedProduct;
        if (tile.crop != null && tile.crop!.isRipe) {
          final crop = tile.crop!;
          harvestedProduct = crop.cropId;
          final remainingHarvests = crop.harvestsLeft - 1;
          updatedTiles[tileIndex] = tile.copyWith(
            crop: remainingHarvests > 0
                ? crop.copyWith(growth: 0.35, harvestsLeft: remainingHarvests)
                : null,
          );
        } else if (tile.animal != null && tile.animal!.readyCrates > 0) {
          final animal = tile.animal!;
          harvestedProduct = SolvilleCatalog.animals[animal.type]!.product;
          updatedTiles[tileIndex] = tile.copyWith(
            animal: animal.copyWith(readyCrates: animal.readyCrates - 1),
          );
        } else if (tile.structure == StructureType.lemonTree &&
            tile.producerCrates > 0) {
          harvestedProduct = ProductId.lemon;
          updatedTiles[tileIndex] = tile.copyWith(
            producerCrates: tile.producerCrates - 1,
          );
        } else if (tile.structure == StructureType.artisanPress &&
            tile.producerCrates > 0) {
          harvestedProduct = ProductId.preserves;
          updatedTiles[tileIndex] = tile.copyWith(
            producerCrates: tile.producerCrates - 1,
          );
        }

        if (harvestedProduct != null) {
          nextState = nextState.copyWith(
            tiles: updatedTiles,
            totalCratesHarvested: nextState.totalCratesHarvested + 1,
          );
          nextState = _giveOrDropCrate(nextState, pos, harvestedProduct);
          events.add(SimEvent(type: SimEventType.harvest, tile: pos));
        }
        return nextState;

      case ActionKind.loadArtisan:
        if (tile.structure == StructureType.artisanPress &&
            !tile.producerActive &&
            tile.producerCrates < 2) {
          final carried = List<ProductId>.from(nextState.farmer.carriedCrates);
          final idx = carried.indexWhere((c) => c.canMakePreserves);
          if (idx >= 0) {
            carried.removeAt(idx);
            updatedTiles[tileIndex] = tile.copyWith(
              producerActive: true,
              producerProgress: 0.0,
            );
            nextState = nextState.copyWith(
              tiles: updatedTiles,
              farmer: nextState.farmer.copyWith(carriedCrates: carried),
            );
            events.add(
              SimEvent(
                type: SimEventType.compost,
                tile: pos,
                message: 'Simmering Gourmet Preserves! 🫙',
              ),
            );
          }
        }
        return nextState;

      case ActionKind.pickupCrate:
        final crate = tile.droppedCrate;
        if (crate != null) {
          if (nextState.farmer.carriedCrates.length <
              nextState.maxCarryCrates) {
            updatedTiles[tileIndex] = tile.copyWith(droppedCrate: null);
            nextState = nextState.copyWith(
              tiles: updatedTiles,
              farmer: nextState.farmer.copyWith(
                carriedCrates: <ProductId>[
                  ...nextState.farmer.carriedCrates,
                  crate,
                ],
              ),
            );
            events.add(SimEvent(type: SimEventType.harvest, tile: pos));
          } else {
            events.add(
              const SimEvent(
                type: SimEventType.statusHint,
                message: 'Hands full! Deliver crates or upgrade Crate Stacker.',
              ),
            );
          }
        }
        return nextState;

      case ActionKind.sellAtStall:
        final carried = List<ProductId>.from(nextState.farmer.carriedCrates);
        if (carried.isEmpty) {
          events.add(
            const SimEvent(
              type: SimEventType.statusHint,
              message:
                  'Harvest crops into crates first, then bring them here!',
            ),
          );
          return nextState;
        }
        final stall = List<ProductId>.from(nextState.market.stallCrates);
        while (carried.isNotEmpty && stall.length < MarketState.maxStallSlots) {
          stall.add(carried.removeAt(0));
        }
        final updatedBarn = Map<ProductId, int>.from(nextState.barnStock);
        while (carried.isNotEmpty) {
          final item = carried.removeAt(0);
          updatedBarn[item] = (updatedBarn[item] ?? 0) + 1;
        }
        return nextState.copyWith(
          farmer: nextState.farmer.copyWith(carriedCrates: carried),
          barnStock: updatedBarn,
          market: nextState.market.copyWith(stallCrates: stall),
        );

      case ActionKind.storeInBarn:
        final carried = List<ProductId>.from(nextState.farmer.carriedCrates);
        final updatedBarn = Map<ProductId, int>.from(nextState.barnStock);
        if (carried.isNotEmpty) {
          for (final item in carried) {
            updatedBarn[item] = (updatedBarn[item] ?? 0) + 1;
          }
          events.add(
            const SimEvent(
              type: SimEventType.statusHint,
              tile: barnPos,
              message: 'Crates stored safely in the Barn!',
            ),
          );
          return nextState.copyWith(
            barnStock: updatedBarn,
            farmer: nextState.farmer.copyWith(
              carriedCrates: const <ProductId>[],
            ),
          );
        } else if (updatedBarn.isNotEmpty &&
            nextState.farmer.carriedCrates.length < nextState.maxCarryCrates) {
          final sortedKeys = updatedBarn.keys.toList()
            ..sort(
              (a, b) => nextState.market
                  .unitPriceFor(b)
                  .compareTo(nextState.market.unitPriceFor(a)),
            );
          final picked = <ProductId>[];
          for (final key in sortedKeys) {
            while ((updatedBarn[key] ?? 0) > 0 &&
                picked.length < nextState.maxCarryCrates) {
              updatedBarn[key] = updatedBarn[key]! - 1;
              if (updatedBarn[key] == 0) updatedBarn.remove(key);
              picked.add(key);
            }
          }
          return nextState.copyWith(
            barnStock: updatedBarn,
            farmer: nextState.farmer.copyWith(carriedCrates: picked),
          );
        }
        return nextState;

      case ActionKind.tendAnimal:
        if (tile.animal != null) {
          final def = SolvilleCatalog.animals[tile.animal!.type]!;
          if (nextState.coins < def.tendCost) {
            events.add(
              SimEvent(
                type: SimEventType.statusHint,
                message: 'Need ${def.tendCost}☀️ for animal feed!',
              ),
            );
            return nextState;
          }
          updatedTiles[tileIndex] = tile.copyWith(
            animal: tile.animal!.copyWith(feedLevel: 1.0),
          );
          nextState = nextState.copyWith(
            tiles: updatedTiles,
            coins: nextState.coins - def.tendCost,
          );
          events.add(
            SimEvent(
              type: SimEventType.water,
              tile: pos,
              message: 'Fed ${def.name}!',
            ),
          );
        }
        return nextState;

      case ActionKind.placeBuild:
        final itemType = action.buildItem ?? nextState.selectedBuildItem;
        final def = SolvilleCatalog.buildItems[itemType]!;
        if (tile.structure != StructureType.none || tile.crop != null) {
          return nextState;
        }
        if (nextState.coins < def.cost) {
          events.add(
            SimEvent(
              type: SimEventType.statusHint,
              message: 'Need ${def.cost}☀️ for ${def.name}!',
            ),
          );
          return nextState;
        }

        if (itemType == BuildItemType.stonePath) {
          updatedTiles[tileIndex] = tile.copyWith(ground: GroundType.stonePath);
        } else {
          final structure = switch (itemType) {
            BuildItemType.sprinklerRotary => StructureType.sprinklerRotary,
            BuildItemType.sprinklerSolar => StructureType.sprinklerSolar,
            BuildItemType.lemonTree => StructureType.lemonTree,
            BuildItemType.artisanPress => StructureType.artisanPress,
            BuildItemType.henhouse => StructureType.henhouse,
            BuildItemType.beehive => StructureType.beehive,
            BuildItemType.cowPaddock => StructureType.cowPaddock,
            BuildItemType.lantern => StructureType.lantern,
            BuildItemType.flowerArch => StructureType.flowerArch,
            BuildItemType.stonePath => StructureType.none,
          };
          final animalState = switch (itemType) {
            BuildItemType.henhouse => const AnimalUnitState(
              type: AnimalType.chicken,
            ),
            BuildItemType.beehive => const AnimalUnitState(
              type: AnimalType.bee,
            ),
            BuildItemType.cowPaddock => const AnimalUnitState(
              type: AnimalType.cow,
            ),
            _ => null,
          };
          var updatedFarmer = nextState.farmer;
          if (!structure.isWalkable && updatedFarmer.currentTile == pos) {
            for (final adj in pos.cardinalNeighbors) {
              if (nextState.inBounds(adj) && nextState.tileAt(adj).isWalkable) {
                updatedFarmer = updatedFarmer.copyWith(
                  x: adj.x.toDouble(),
                  y: adj.y.toDouble(),
                );
                break;
              }
            }
          }
          updatedTiles[tileIndex] = tile.copyWith(
            ground: GroundType.grass,
            structure: structure,
            animal: animalState,
            sprinklerCooldown: 1.0,
            producerProgress: 0.0,
            producerCrates: 0,
            producerActive: false,
          );
          nextState = nextState.copyWith(farmer: updatedFarmer);
        }

        nextState = nextState.copyWith(
          tiles: updatedTiles,
          coins: nextState.coins - def.cost,
        );
        events.add(
          SimEvent(
            type: SimEventType.shopPurchase,
            tile: pos,
            message: 'Placed ${def.name}!',
          ),
        );
        return nextState;

      case ActionKind.removeStructure:
        if (tile.structure.isRemovable) {
          updatedTiles[tileIndex] = tile.copyWith(
            structure: StructureType.none,
            animal: null,
            producerProgress: 0.0,
            producerCrates: 0,
            producerActive: false,
          );
          nextState = nextState.copyWith(tiles: updatedTiles);
          events.add(SimEvent(type: SimEventType.dig, tile: pos));
        } else if (tile.crop != null || tile.ground == GroundType.stonePath) {
          updatedTiles[tileIndex] = tile.copyWith(
            ground: GroundType.grass,
            crop: null,
          );
          nextState = nextState.copyWith(tiles: updatedTiles);
          events.add(SimEvent(type: SimEventType.dig, tile: pos));
        }
        return nextState;

      case ActionKind.smart:
        return nextState;
    }
  }

  GameState _giveOrDropCrate(
    GameState state,
    GridPos sourcePos,
    ProductId product,
  ) {
    if (state.farmer.carriedCrates.length < state.maxCarryCrates) {
      return state.copyWith(
        farmer: state.farmer.copyWith(
          carriedCrates: <ProductId>[...state.farmer.carriedCrates, product],
        ),
      );
    }

    final candidates = <GridPos>[sourcePos, ...sourcePos.allNeighbors];
    final updatedTiles = List<TileState>.from(state.tiles);
    for (final candidate in candidates) {
      if (!state.inBounds(candidate) || candidate.y == 0) continue;
      final idx = candidate.y * state.gridSize + candidate.x;
      final t = updatedTiles[idx];
      if (t.isWalkable && t.droppedCrate == null) {
        updatedTiles[idx] = t.copyWith(droppedCrate: product);
        return state.copyWith(tiles: updatedTiles);
      }
    }

    final updatedBarn = Map<ProductId, int>.from(state.barnStock);
    updatedBarn[product] = (updatedBarn[product] ?? 0) + 1;
    return state.copyWith(barnStock: updatedBarn);
  }

  GameState _expandFarmGrid(GameState state, int newSize) {
    if (newSize <= state.gridSize) return state;
    final oldSize = state.gridSize;
    final newTiles = List<TileState>.generate(newSize * newSize, (index) {
      final x = index % newSize;
      final y = index ~/ newSize;
      if (x < oldSize && y < oldSize) {
        return state.tiles[y * oldSize + x];
      }
      if (y == 0) {
        return const TileState(ground: GroundType.cobbleLane);
      }
      final sprinkleWeeds = (x + y * 3) % 7 == 0;
      return TileState(
        ground: sprinkleWeeds ? GroundType.weeds : GroundType.grass,
      );
    });
    return state.copyWith(gridSize: newSize, tiles: newTiles);
  }

  MarketState _generateMorningMarket({
    required Set<ProductId> unlockedSeeds,
    required List<ProductId> existingStallCrates,
    required PricingStance pricing,
    required List<ProductId> extraAccessible,
  }) {
    final trends = <ProductId, MarketTrend>{};
    final allProducts = List<ProductId>.from(ProductId.values)..shuffle(_rng);

    for (var i = 0; i < allProducts.length; i++) {
      final p = allProducts[i];
      if (i < 2) {
        trends[p] = MarketTrend.boom;
      } else if (i < 5) {
        trends[p] = MarketTrend.high;
      } else if (i == allProducts.length - 1) {
        trends[p] = MarketTrend.surplus;
      } else {
        trends[p] = MarketTrend.steady;
      }
    }

    final accessible = <ProductId>{
      ...unlockedSeeds,
      ...extraAccessible,
    }.toList();
    if (accessible.isNotEmpty &&
        !accessible.any((p) => trends[p] == MarketTrend.boom)) {
      trends[accessible[_rng.nextInt(accessible.length)]] = MarketTrend.boom;
    }

    final reqProduct = accessible[_rng.nextInt(accessible.length)];
    final reqCount = 2 + _rng.nextInt(2);
    final villager = _villagerNames[_rng.nextInt(_villagerNames.length)];
    final baseVal = SolvilleCatalog.productBaseValues[reqProduct] ?? 20;
    final bonus = (baseVal * reqCount * 0.75).round() + 15;

    return MarketState(
      trends: trends,
      stallCrates: existingStallCrates,
      pricing: pricing,
      saleCooldown: 3.0,
      dailyRequest: VillageRequest(
        villagerName: villager,
        product: reqProduct,
        requiredCount: reqCount,
        deliveredCount: 0,
        bonusReward: bonus,
      ),
    );
  }

  GameState _ensureNoSoftLock(GameState state, List<SimEvent> events) {
    if (state.coins >= 6) return state;
    if (state.farmer.carriedCrates.isNotEmpty ||
        state.market.stallCrates.isNotEmpty ||
        state.totalBarnCrates > 0) {
      return state;
    }
    final hasAnyActiveFarmAsset = state.tiles.any(
      (t) =>
          t.crop != null ||
          t.droppedCrate != null ||
          t.animal != null ||
          t.structure == StructureType.lemonTree ||
          t.producerCrates > 0,
    );
    if (hasAnyActiveFarmAsset) return state;

    events.add(
      const SimEvent(
        type: SimEventType.coinsEarned,
        amount: 25,
        message: 'Mayor Sunny gifted a 25☀️ Village Seed Grant!',
      ),
    );
    return state.copyWith(coins: state.coins + 25);
  }

  GameState _evaluateTrophies(GameState state, List<SimEvent> events) {
    final unlocked = Set<String>.from(state.unlockedTrophies);
    var bonusCoins = 0;

    void check(String id, bool condition) {
      if (!condition || unlocked.contains(id)) return;
      unlocked.add(id);
      final def = SolvilleCatalog.trophies.firstWhere((t) => t.id == id);
      bonusCoins += def.rewardCoins;
      events.add(
        SimEvent(
          type: SimEventType.trophyUnlocked,
          trophyId: id,
          amount: def.rewardCoins,
          message: '🏆 Trophy: ${def.title} (+${def.rewardCoins}☀️)!',
        ),
      );
    }

    final hasSprinkler = state.tiles.any(
      (t) =>
          t.structure == StructureType.sprinklerRotary ||
          t.structure == StructureType.sprinklerSolar,
    );
    final harvestedTypes = <ProductId>{
      ...state.farmer.carriedCrates,
      ...state.barnStock.keys,
      ...state.market.stallCrates,
    };

    check('first_sprout', state.totalCratesHarvested >= 1);
    check('market_debut', state.lifetimeCoinsEarned >= 100);
    check('green_thumb', state.totalCratesHarvested >= 25);
    check('hydration_hero', hasSprinkler);
    check('stack_master', state.farmer.carriedCrates.length >= 2);
    check('feathered_friends', harvestedTypes.contains(ProductId.eggs));
    check('sweet_harmony', harvestedTypes.contains(ProductId.honey));
    check('dairy_delight', harvestedTypes.contains(ProductId.milk));
    check('savvy_trader', state.boomCratesSold >= 5);
    check('master_composter', state.compostedPlotsCount >= 8);
    check('village_darling', state.requestsCompleted >= 3);
    check(
      'golden_oasis',
      state.lifetimeCoinsEarned >= 2000 &&
          state.upgradeTier(UpgradeTrack.farmExpansion) >= 1,
    );

    if (bonusCoins == 0 && unlocked.length == state.unlockedTrophies.length) {
      return state;
    }

    return state.copyWith(
      unlockedTrophies: unlocked,
      coins: state.coins + bonusCoins,
      lifetimeCoinsEarned: state.lifetimeCoinsEarned + bonusCoins,
    );
  }
}
