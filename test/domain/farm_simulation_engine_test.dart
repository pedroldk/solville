import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:solville/data/services/cozy_sound_service.dart';
import 'package:solville/domain/models/catalog.dart';
import 'package:solville/domain/models/game_state.dart';
import 'package:solville/domain/models/grid_pos.dart';
import 'package:solville/domain/models/market_state.dart';
import 'package:solville/domain/models/tile_state.dart';
import 'package:solville/domain/simulation/farm_simulation_engine.dart';

void main() {
  group('FarmSimulationEngine', () {
    late FarmSimulationEngine engine;
    late GameState state;

    setUp(() {
      engine = FarmSimulationEngine(random: math.Random(42));
      state = engine.createNewGame();
    });

    test(
      'starts with an 11x11 starter isle and syncs grid size with expansion tier',
      () {
        expect(state.gridSize, equals(11));
        expect(state.tiles.length, equals(11 * 11));

        // Simulate an oversized 22x22 tier-0 save and verify it trims unused meadow back to 11x11
        final oversizedTiles = List<TileState>.generate(
          22 * 22,
          (i) => i < 22
              ? const TileState(ground: GroundType.cobbleLane)
              : const TileState(ground: GroundType.grass),
        );
        oversizedTiles[3 * 22 + 4] = const TileState(
          ground: GroundType.soil,
          moisture: 0.9,
          crop: PlantedCrop(
            cropId: ProductId.tomato,
            growth: 0.8,
            harvestsLeft: 3,
          ),
        );
        final oversizedState = state.copyWith(
          gridSize: 22,
          tiles: oversizedTiles,
        );
        final synced = engine.ensureMinimumIslandSize(oversizedState);

        expect(synced.gridSize, equals(11));
        expect(
          synced.tileAt(const GridPos(4, 3)).crop?.cropId,
          ProductId.tomato,
        );
        expect(
          synced.tileAt(const GridPos(10, 0)).ground,
          GroundType.cobbleLane,
        );
      },
    );

    test(
      'supports Alice Greenfingers 3-click combo queue (Dig -> Sow -> Water)',
      () {
        const target = GridPos(7, 4); // Starts as grass
        expect(state.tileAt(target).ground, equals(GroundType.grass));

        state = engine.enqueueTileTap(state, target).state;
        state = engine.enqueueTileTap(state, target).state;
        state = engine.enqueueTileTap(state, target).state;

        expect(state.actionQueue.length, equals(3));
        expect(state.actionQueue[0].kind, equals(ActionKind.dig));
        expect(state.actionQueue[1].kind, equals(ActionKind.plant));
        expect(state.actionQueue[2].kind, equals(ActionKind.water));

        // Simulate 8 seconds so Sol walks over and executes all 3 queued actions
        for (var i = 0; i < 80; i++) {
          state = engine.tick(state, 0.1).state;
        }

        expect(state.actionQueue, isEmpty);
        final updatedTile = state.tileAt(target);
        expect(updatedTile.ground, equals(GroundType.soil));
        expect(updatedTile.crop, isNotNull);
        expect(updatedTile.crop!.cropId, equals(ProductId.tomato));
        expect(updatedTile.moisture, greaterThan(0.80));
      },
    );

    test('untills empty or planted soil blocks cleanly back into grass', () {
      const emptySoil = GridPos(6, 3);
      const plantedSoil = GridPos(4, 3);

      // Enrich empty soil first to verify compost/moisture reset when untilled
      final enrichedTiles = List<TileState>.from(state.tiles);
      enrichedTiles[emptySoil.y * state.gridSize + emptySoil.x] = state
          .tileAt(emptySoil)
          .copyWith(fertilized: true, moisture: 0.9);
      state = state.copyWith(tiles: enrichedTiles, activeTool: ToolMode.remove);

      // Queue untilling via ToolMode.remove on empty soil + enqueueUntillAt on planted soil
      state = engine.enqueueTileTap(state, emptySoil).state;
      state = engine.enqueueUntillAt(state, plantedSoil).state;
      expect(state.actionQueue.length, equals(2));

      for (var i = 0; i < 80; i++) {
        state = engine.tick(state, 0.1).state;
      }

      expect(state.actionQueue, isEmpty);
      final restoredEmpty = state.tileAt(emptySoil);
      expect(restoredEmpty.ground, equals(GroundType.grass));
      expect(restoredEmpty.moisture, equals(0.0));
      expect(restoredEmpty.fertilized, isFalse);

      final restoredPlanted = state.tileAt(plantedSoil);
      expect(restoredPlanted.ground, equals(GroundType.grass));
      expect(restoredPlanted.crop, isNull);
    });

    test(
      'automatically detours to Stone Well when watering with empty can',
      () {
        const soilTarget = GridPos(6, 3);
        state = state.copyWith(
          activeTool: ToolMode.water,
          farmer: state.farmer.copyWith(waterCharges: 0),
        );
        state = engine.enqueueTileTap(state, soilTarget).state;

        // Run simulation until watering finishes
        for (var i = 0; i < 90; i++) {
          state = engine.tick(state, 0.1).state;
        }

        expect(state.actionQueue, isEmpty);
        expect(state.tileAt(soilTarget).moisture, greaterThan(0.85));
        expect(state.farmer.waterCharges, equals(state.maxWaterCharges - 1));
      },
    );

    test(
      'grows starter tomatoes, harvests crate, sells at Market Stall & unlocks trophy',
      () {
        const tomatoPlot = GridPos(4, 3);
        // Ripen starter tomato
        for (var i = 0; i < 60; i++) {
          state = engine.tick(state, 0.15).state;
        }
        expect(state.tileAt(tomatoPlot).crop!.isRipe, isTrue);

        // Queue harvest + sell at Market Stall
        state = engine.enqueueTileTap(state, tomatoPlot).state;
        state = engine
            .enqueueTileTap(state, FarmSimulationEngine.marketStallPos)
            .state;

        final coinsBeforeSale = state.coins;
        for (var i = 0; i < 120; i++) {
          state = engine.tick(state, 0.1).state;
        }

        expect(state.unlockedTrophies.contains('first_sprout'), isTrue);
        expect(state.coins, greaterThan(coinsBeforeSale));
      },
    );

    test(
      'passively ripens Sunburst Lemon Tree and simmers Artisan Preserves from Barn stock',
      () {
        const lemonPos = GridPos(8, 3);
        const pressPos = GridPos(8, 4);

        final updatedTiles = List<TileState>.from(state.tiles);
        updatedTiles[lemonPos.y * state.gridSize +
            lemonPos.x] = const TileState(
          ground: GroundType.grass,
          structure: StructureType.lemonTree,
        );
        updatedTiles[pressPos.y * state.gridSize +
            pressPos.x] = const TileState(
          ground: GroundType.stonePath,
          structure: StructureType.artisanPress,
        );

        state = state.copyWith(
          tiles: updatedTiles,
          barnStock: const <ProductId, int>{ProductId.strawberry: 1},
        );
        expect(state.charmBonus, closeTo(0.02, 0.0001));

        // Simulate 25 seconds (100 ticks * 0.25s) so both Lemon Tree (24s)
        // and Artisan Preserves Kettle (20s) complete a full cycle.
        for (var i = 0; i < 102; i++) {
          state = engine.tick(state, 0.25).state;
        }

        expect(state.tileAt(lemonPos).producerCrates, equals(1));
        expect(state.tileAt(pressPos).producerCrates, equals(1));
        expect(state.barnStock.containsKey(ProductId.strawberry), isFalse);

        // Batch-queue all ready harvests (ripened starter tomatoes + lemon + preserves)
        state = engine.queueAllReadyHarvests(state).state;
        expect(state.actionQueue.length, greaterThanOrEqualTo(3));
      },
    );

    test(
      'expands isle repeatedly with coins across multiple tiers and round-trips JSON',
      () {
        state = state.copyWith(coins: 5000);
        state = engine.purchaseUpgrade(state, UpgradeTrack.crateStacker).state;
        state = engine.purchaseUpgrade(state, UpgradeTrack.farmExpansion).state;
        expect(state.gridSize, equals(14));

        state = engine.purchaseUpgrade(state, UpgradeTrack.farmExpansion).state;
        expect(state.gridSize, equals(17));

        state = engine.purchaseUpgrade(state, UpgradeTrack.farmExpansion).state;
        expect(state.gridSize, equals(20));
        expect(state.maxCarryCrates, equals(2));

        final jsonStr = jsonEncode(state.toJson());
        final restored = GameState.fromJson(
          jsonDecode(jsonStr) as Map<String, dynamic>,
        );
        expect(restored.gridSize, equals(20));
        expect(restored.maxCarryCrates, equals(2));
        expect(restored.coins, equals(state.coins));
      },
    );

    test(
      'starts with ripe tomato, steps zero-text onboarding (0->1->2->3), and spotlights 90-Sol Gloves',
      () {
        expect(SolvilleCatalog.maxCratesForTier(0), equals(1));
        expect(state.maxCarryCrates, equals(1));
        expect(state.onboardingStep, equals(0));
        expect(state.isOnboardingActive, isTrue);
        expect(state.tileAt(const GridPos(4, 3)).crop?.isRipe, isTrue);
        expect(state.shouldSpotlightGloves, isFalse);

        // Step 0 -> 1: Harvest ripe starter tomato
        state = engine.enqueueTileTap(state, const GridPos(4, 3)).state;
        for (var i = 0; i < 60; i++) {
          state = engine.tick(state, 0.1).state;
        }
        expect(state.onboardingStep, equals(1));
        expect(state.totalCratesHarvested, equals(1));
        expect(state.shouldSpotlightGloves, isTrue);

        // Step 1 -> 2: Deposit crate at Market Stall
        state = engine
            .enqueueTileTap(state, FarmSimulationEngine.marketStallPos)
            .state;
        for (var i = 0; i < 60; i++) {
          state = engine.tick(state, 0.1).state;
        }
        expect(state.onboardingStep, equals(2));

        // Step 2 -> 3: Dig & plant a new plot
        const newPlot = GridPos(7, 4);
        state = engine.enqueueTileTap(state, newPlot).state;
        state = engine.enqueueTileTap(state, newPlot).state;
        for (var i = 0; i < 80; i++) {
          state = engine.tick(state, 0.1).state;
        }
        expect(state.onboardingStep, equals(3));
        expect(state.isOnboardingActive, isFalse);

        // Purchasing Gloves clears spotlight and raises carry capacity to 2
        state = engine.purchaseUpgrade(state, UpgradeTrack.crateStacker).state;
        expect(state.maxCarryCrates, equals(2));
        expect(state.shouldSpotlightGloves, isFalse);
      },
    );

    test(
      'rewards Golden harvest 2x Sols and increments rapid combo streak',
      () {
        final updatedTiles = List<TileState>.from(state.tiles);
        const plot1 = GridPos(4, 3);
        const plot2 = GridPos(5, 3);
        updatedTiles[plot1.y * state.gridSize + plot1.x] = state
            .tileAt(plot1)
            .copyWith(
              crop: const PlantedCrop(
                cropId: ProductId.tomato,
                growth: 1.0,
                harvestsLeft: 3,
                isGolden: true,
              ),
            );
        updatedTiles[plot2.y * state.gridSize + plot2.x] = state
            .tileAt(plot2)
            .copyWith(
              crop: const PlantedCrop(
                cropId: ProductId.tomato,
                growth: 1.0,
                harvestsLeft: 3,
              ),
            );
        state = engine.purchaseUpgrade(
          state.copyWith(
            tiles: updatedTiles,
            coins: 200,
            unlockedTrophies: const <String>{'first_sprout', 'stack_master'},
          ),
          UpgradeTrack.crateStacker,
        ).state;

        final coinsBefore = state.coins;
        final events = <SimEvent>[];
        var peakCombo = 0;
        state = engine.enqueueTileTap(state, plot1).state;
        state = engine.enqueueTileTap(state, plot2).state;
        for (var i = 0; i < 80 && state.actionQueue.isNotEmpty; i++) {
          final step = engine.tick(state, 0.1);
          state = step.state;
          events.addAll(step.events);
          peakCombo = math.max(peakCombo, state.comboStreak);
        }

        expect(
          events.any((e) => e.type == SimEventType.goldenHarvest),
          isTrue,
        );
        expect(peakCombo, equals(2));
        expect(state.comboStreak, equals(2));
        final expectedGoldenBonus =
            SolvilleCatalog.productBaseValues[ProductId.tomato]!;
        expect(state.coins, equals(coinsBefore + expectedGoldenBonus + 2));

        // Combo streak resets cleanly when timer runs out
        for (var i = 0; i < 40; i++) {
          state = engine.tick(state, 0.1).state;
        }
        expect(state.comboStreak, equals(0));
      },
    );

    test(
      'discovers Weed Treasure, plants free Trial Seeds, and boops butterflies',
      () {
        // Dig starter weeds until a Weed Treasure triggers (+5 coins, free compost, or trial seed)
        state = state.copyWith(totalCratesHarvested: 1);
        final weedEvents = <SimEvent>[];
        for (final weedPos in const <GridPos>[
          GridPos(5, 4),
          GridPos(6, 4),
          GridPos(7, 3),
          GridPos(4, 5),
          GridPos(7, 6),
          GridPos(8, 5),
        ]) {
          state = engine.enqueueTileTap(state, weedPos).state;
        }
        for (var i = 0; i < 200 && state.actionQueue.isNotEmpty; i++) {
          final step = engine.tick(state, 0.1);
          state = step.state;
          weedEvents.addAll(step.events);
        }
        expect(
          weedEvents.any((e) => e.type == SimEventType.weedTreasure),
          isTrue,
        );

        // Test free Trial Seed planting without Seed License or Sun Pass
        state = state.copyWith(
          selectedSeed: ProductId.pumpkin,
          trialSeeds: const <ProductId, int>{ProductId.pumpkin: 1},
          farmer: state.farmer.copyWith(x: 7, y: 4),
          activeTool: ToolMode.dig,
        );
        const target = GridPos(7, 4);
        final coinsBefore = state.coins;
        state = engine.enqueueTileTap(state, target).state;
        state = state.copyWith(activeTool: ToolMode.seed);
        state = engine.enqueueTileTap(state, target).state;
        for (var i = 0; i < 50 && state.actionQueue.isNotEmpty; i++) {
          state = engine.tick(state, 0.1).state;
        }
        expect(state.tileAt(target).crop?.cropId, equals(ProductId.pumpkin));
        expect(state.coins, equals(coinsBefore));
        expect(state.trialSeeds.containsKey(ProductId.pumpkin), isFalse);

        // Test Butterfly boop gives +3 coins & event
        final boopRes = engine.boopButterfly(state, const GridPos(3, 3));
        expect(boopRes.state.coins, equals(coinsBefore + 3));
        expect(
          boopRes.events.any((e) => e.type == SimEventType.butterflyBoop),
          isTrue,
        );
      },
    );

    test(
      'fulfills Express Flash Orders and cycles Artisan Kettle specialty recipes',
      () {
        const pressPos = GridPos(6, 5);
        final tiles = List<TileState>.from(state.tiles);
        tiles[pressPos.y * state.gridSize + pressPos.x] = const TileState(
          ground: GroundType.stonePath,
          structure: StructureType.artisanPress,
        );
        state = state.copyWith(
          tiles: tiles,
          barnStock: const <ProductId, int>{
            ProductId.strawberry: 1,
            ProductId.honey: 1,
          },
          market: state.market.copyWith(
            stallCrates: const <ProductId>[ProductId.strawberry],
            saleCooldown: 0.1,
            expressOrder: const ExpressOrder(
              villagerName: 'Baker Mateo',
              villagerVariant: 0,
              product: ProductId.strawberry,
              requiredCount: 1,
              deliveredCount: 0,
              remainingSeconds: 30,
              totalSeconds: 45,
              bonusCoins: 40,
              bonusTrialSeed: ProductId.corn,
            ),
          ),
        );

        // Toggle idle Kettle recipe to Berry Jam (Strawberry + Honey)
        state = engine.toggleKettleRecipe(state, pressPos).state;
        expect(
          state.tileAt(pressPos).kettleRecipe,
          equals(KettleRecipeId.berryJam),
        );

        final coinsBefore = state.coins;
        final events = <SimEvent>[];
        for (var i = 0; i < 120; i++) {
          final step = engine.tick(state, 0.25);
          state = step.state;
          events.addAll(step.events);
        }

        // Express Order fulfilled with bonus coins & corn trial seed
        expect(
          events.any((e) => e.type == SimEventType.expressOrderFulfilled),
          isTrue,
        );
        expect(state.market.expressOrder, isNull);
        expect(state.trialSeeds[ProductId.corn], equals(1));
        expect(state.coins, greaterThanOrEqualTo(coinsBefore + 40));

        // Kettle finished simmering Berry Jam crate
        expect(state.tileAt(pressPos).producerCrates, equals(1));
        expect(state.barnStock.containsKey(ProductId.strawberry), isFalse);
        expect(state.barnStock.containsKey(ProductId.honey), isFalse);
      },
    );

    test(
      'generates Expansion Landmarks and claims Treasure Cache rewards',
      () {
        state = state.copyWith(coins: 2000);
        state = engine.purchaseUpgrade(state, UpgradeTrack.farmExpansion).state;
        expect(state.gridSize, equals(14));

        // Cache landmark placed at (newSize - 2, 2) = (12, 2)
        const cachePos = GridPos(12, 2);
        expect(
          state.tileAt(cachePos).landmark,
          equals(LandmarkKind.treasureCache),
        );

        final coinsBefore = state.coins;
        state = engine.enqueueTileTap(state, cachePos).state;
        for (var i = 0; i < 160; i++) {
          state = engine.tick(state, 0.1).state;
        }

        expect(state.tileAt(cachePos).landmark, equals(LandmarkKind.none));
        expect(state.coins, equals(coinsBefore + 35));
      },
    );
  });

  group('CozySoundService seamless BGM synthesis', () {
    test(
      'synthesizes valid click-free RIFF PCM WAV loops for all 3 tracks',
      () {
        final sound = CozySoundService(silentPlatformOutput: true);
        for (final track in const <BgmTrack>[
          BgmTrack.sunnyLullaby,
          BgmTrack.morningMeadow,
          BgmTrack.cozyRain,
        ]) {
          final wav = sound.synthesizeTrackWav(track);
          expect(wav.length, greaterThan(44 + 22050 * 16 * 2 - 10));
          expect(String.fromCharCodes(wav.sublist(0, 4)), equals('RIFF'));
          expect(String.fromCharCodes(wav.sublist(8, 12)), equals('WAVE'));

          final bd = ByteData.sublistView(wav);
          final firstSample = bd.getInt16(44, Endian.little);
          final lastSample = bd.getInt16(wav.length - 2, Endian.little);
          expect((firstSample - lastSample).abs(), lessThan(600));
        }
      },
    );
  });
}
