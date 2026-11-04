import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:solville/data/services/cozy_sound_service.dart';
import 'package:solville/domain/models/catalog.dart';
import 'package:solville/domain/models/game_state.dart';
import 'package:solville/domain/models/grid_pos.dart';
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
        updatedTiles[lemonPos.y * state.gridSize + lemonPos.x] =
            const TileState(
              ground: GroundType.grass,
              structure: StructureType.lemonTree,
            );
        updatedTiles[pressPos.y * state.gridSize + pressPos.x] =
            const TileState(
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
      'purchases upgrades, expands farm grid, and round-trips JSON cleanly',
      () {
        state = state.copyWith(coins: 1000);
        state = engine.purchaseUpgrade(state, UpgradeTrack.crateStacker).state;
        state = engine.purchaseUpgrade(state, UpgradeTrack.farmExpansion).state;

        expect(state.maxCarryCrates, equals(2));
        expect(state.gridSize, equals(14));

        final jsonStr = jsonEncode(state.toJson());
        final restored = GameState.fromJson(
          jsonDecode(jsonStr) as Map<String, dynamic>,
        );
        expect(restored.gridSize, equals(14));
        expect(restored.maxCarryCrates, equals(2));
        expect(restored.coins, equals(state.coins));
      },
    );
  });

  group('CozySoundService seamless BGM synthesis', () {
    test('synthesizes valid click-free RIFF PCM WAV loops for all 3 tracks', () {
      final sound = CozySoundService(silentPlatformOutput: true);
      for (final track in const <BgmTrack>[
        BgmTrack.sunnyLullaby,
        BgmTrack.morningMeadow,
        BgmTrack.cozyRain,
      ]) {
        final wav = sound.synthesizeTrackWav(track);
        expect(wav.length, greaterThan(44 + 22050 * 16 * 2 - 10));
        // Verify RIFF....WAVE header
        expect(String.fromCharCodes(wav.sublist(0, 4)), equals('RIFF'));
        expect(String.fromCharCodes(wav.sublist(8, 12)), equals('WAVE'));

        // Verify seamless wrap-around continuity (first & last PCM sample diff is tiny)
        final bd = ByteData.sublistView(wav);
        final firstSample = bd.getInt16(44, Endian.little);
        final lastSample = bd.getInt16(wav.length - 2, Endian.little);
        expect((firstSample - lastSample).abs(), lessThan(600));
      }
    });
  });
}
