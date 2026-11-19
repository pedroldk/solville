import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solville/data/repositories/save_game_repository.dart';
import 'package:solville/data/services/cozy_sound_service.dart';
import 'package:solville/domain/iso/iso_projection.dart';
import 'package:solville/domain/models/catalog.dart';
import 'package:solville/domain/models/game_state.dart';
import 'package:solville/domain/models/grid_pos.dart';
import 'package:solville/domain/models/tile_state.dart';
import 'package:solville/domain/simulation/farm_simulation_engine.dart';
import 'package:solville/game/painters/painterly_cache.dart';
import 'package:solville/game/solville_game.dart';
import 'package:solville/main.dart';
import 'package:solville/ui/view_models/solville_controller.dart';
import 'package:solville/ui/widgets/solville_buttons.dart';
import 'package:solville/ui/widgets/solville_icons.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('PainterlyCache bakes all terrain variants cleanly and disposes', () {
    final cache = PainterlyCache(const IsoProjection());
    cache.ensureBuilt();
    expect(cache.grassVariants.length, equals(4));
    expect(cache.soilVariants.length, equals(3));
    expect(cache.stonePathVariants.length, equals(2));
    expect(cache.cobbleLaneVariants.length, equals(2));
    expect(cache.weedsVariants.length, equals(2));
    cache.dispose();
  });

  testWidgets('All SolvilleIconKind variants render cleanly', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Wrap(
            children: <Widget>[
              for (final kind in SolvilleIconKind.values)
                SolvilleIcon(kind: kind, size: 20),
            ],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Solville diorama renders all structures, crops, animals, landmarks across day, sunset, night & rain',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var state = FarmSimulationEngine().createNewGame();
      final size = state.gridSize;
      final tiles = List<TileState>.from(state.tiles);

      void setAt(int x, int y, TileState t) {
        tiles[y * size + x] = t;
      }

      // Populate full showcase of crops, buildings, animals, and landmarks
      setAt(
        3,
        4,
        const TileState(
          ground: GroundType.soil,
          moisture: 0.95,
          fertilized: true,
          crop: PlantedCrop(
            cropId: ProductId.strawberry,
            growth: 1.0,
            harvestsLeft: 3,
            isGolden: true,
          ),
        ),
      );
      setAt(
        4,
        5,
        const TileState(
          ground: GroundType.soil,
          moisture: 0.70,
          crop: PlantedCrop(
            cropId: ProductId.carrot,
            growth: 0.9,
            harvestsLeft: 1,
          ),
        ),
      );
      setAt(
        5,
        5,
        const TileState(
          ground: GroundType.soil,
          moisture: 0.85,
          crop: PlantedCrop(
            cropId: ProductId.corn,
            growth: 1.0,
            harvestsLeft: 1,
          ),
        ),
      );
      setAt(
        6,
        5,
        const TileState(
          ground: GroundType.soil,
          moisture: 0.55,
          crop: PlantedCrop(
            cropId: ProductId.lavender,
            growth: 1.0,
            harvestsLeft: 2,
          ),
        ),
      );
      setAt(
        7,
        5,
        const TileState(
          ground: GroundType.soil,
          moisture: 0.80,
          crop: PlantedCrop(
            cropId: ProductId.pumpkin,
            growth: 1.0,
            harvestsLeft: 1,
          ),
        ),
      );
      setAt(
        3,
        6,
        const TileState(
          ground: GroundType.grass,
          structure: StructureType.lemonTree,
          producerCrates: 2,
        ),
      );
      setAt(
        4,
        6,
        const TileState(
          ground: GroundType.stonePath,
          structure: StructureType.artisanPress,
          producerActive: true,
          producerProgress: 0.65,
        ),
      );
      setAt(
        5,
        6,
        const TileState(
          ground: GroundType.grass,
          structure: StructureType.henhouse,
          animal: AnimalUnitState(type: AnimalType.chicken, readyCrates: 1),
        ),
      );
      setAt(
        6,
        6,
        const TileState(
          ground: GroundType.grass,
          structure: StructureType.beehive,
          animal: AnimalUnitState(type: AnimalType.bee, readyCrates: 1),
        ),
      );
      setAt(
        7,
        6,
        const TileState(
          ground: GroundType.grass,
          structure: StructureType.cowPaddock,
          animal: AnimalUnitState(type: AnimalType.cow, readyCrates: 1),
        ),
      );
      setAt(
        8,
        3,
        const TileState(
          ground: GroundType.grass,
          structure: StructureType.sprinklerRotary,
        ),
      );
      setAt(
        8,
        4,
        const TileState(
          ground: GroundType.grass,
          structure: StructureType.sprinklerSolar,
        ),
      );
      setAt(
        3,
        2,
        const TileState(
          ground: GroundType.stonePath,
          structure: StructureType.lantern,
        ),
      );
      setAt(
        4,
        2,
        const TileState(
          ground: GroundType.stonePath,
          structure: StructureType.flowerArch,
        ),
      );
      setAt(
        9,
        2,
        const TileState(
          ground: GroundType.grass,
          landmark: LandmarkKind.treasureCache,
        ),
      );
      setAt(
        2,
        9,
        const TileState(
          ground: GroundType.grass,
          landmark: LandmarkKind.oasisFountain,
        ),
      );
      setAt(
        9,
        8,
        const TileState(
          ground: GroundType.grass,
          landmark: LandmarkKind.wildflowerShrine,
        ),
      );
      setAt(
        5,
        2,
        const TileState(
          ground: GroundType.stonePath,
          droppedCrate: ProductId.honey,
        ),
      );
      setAt(
        2,
        4,
        const TileState(
          ground: GroundType.soil,
          moisture: 0.0,
          crop: PlantedCrop(
            cropId: ProductId.tomato,
            growth: 0.55,
            harvestsLeft: 2,
            thirstySeconds: 16.0,
          ),
        ),
      );

      state = state.copyWith(
        tiles: tiles,
        onboardingStep: 3,
        claimedQuestsCount: 3,
        farmer: state.farmer.copyWith(
          carriedCrates: <ProductId>[ProductId.tomato, ProductId.strawberry],
          workTimer: 0.35,
          lastActionEmoji: '💧',
        ),
        actionQueue: <QueuedAction>[
          const QueuedAction(
            id: 1,
            target: GridPos(6, 3),
            kind: ActionKind.plant,
            seedId: ProductId.carrot,
          ),
          const QueuedAction(
            id: 2,
            target: GridPos(6, 3),
            kind: ActionKind.water,
          ),
        ],
      );
      // Test daytime, golden sunset, twilight, and gentle rain renders
      for (final (dayP, weather) in <(double, WeatherType)>[
        (0.30, WeatherType.sunny),
        (0.74, WeatherType.goldenBreeze),
        (0.92, WeatherType.sunny),
        (0.42, WeatherType.gentleRain),
      ]) {
        await SaveGameRepository().saveGame(
          state.copyWith(dayProgress: dayP, weather: weather),
        );
        final controller = SolvilleController(
          soundService: CozySoundService(silentPlatformOutput: true),
        );
        await controller.initialize();
        controller.setHoveredTile(const GridPos(6, 6));
        controller.inspectTile(const GridPos(4, 6));

        await tester.pumpWidget(SolvilleApp(controller: controller));
        await tester.pump(const Duration(milliseconds: 80));

        final gameWidget = tester.widget<GameWidget<SolvilleGame>>(
          find.byType(GameWidget<SolvilleGame>),
        );
        final game = gameWidget.game!;
        game.update(0.12);
        await tester.pump(const Duration(milliseconds: 50));
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        controller.dispose();
      }
    },
  );

  testWidgets(
    'AAA 3D UI kit components (buttons, icon buttons, chips, segmented tabs, cards) render and interact cleanly',
    (tester) async {
      var tapCount = 0;
      var chipSelected = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return DefaultTabController(
                  length: 3,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const SolvilleSegmentedTabs(
                          labels: <String>['Upgrades', 'Seeds', 'Build'],
                        ),
                        const SizedBox(height: 10),
                        SolvilleMenuCard(
                          highlighted: true,
                          child: Row(
                            children: <Widget>[
                              const SolvilleIconMedallion(
                                highlighted: true,
                                child: SolvilleIcon(
                                  kind: SolvilleIconKind.trophy,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: SolvilleBadge(label: 'Spotlight'),
                              ),
                              SolvilleIconButton(
                                icon: Icons.close_rounded,
                                tone: SolvilleButtonTone.coral,
                                onPressed: () => setState(() => tapCount++),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            for (final tone in SolvilleButtonTone.values)
                              SolvilleButton(
                                label: tone.name,
                                tone: tone,
                                onPressed: () => setState(() => tapCount++),
                              ),
                            const SolvilleButton(
                              label: 'disabled',
                              onPressed: null,
                            ),
                            SolvilleChip(
                              label: 'Toggle Chip',
                              selected: chipSelected,
                              onTap: () =>
                                  setState(() => chipSelected = !chipSelected),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const SizedBox(
                          height: 40,
                          child: TabBarView(
                            children: <Widget>[
                              Text('Tab 1'),
                              Text('Tab 2'),
                              Text('Tab 3'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Verify tap interaction & segmented tab switch
      await tester.tap(find.text('primary'));
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.tap(find.text('Toggle Chip'));
      await tester.tap(find.text('Seeds'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(tapCount, equals(2));
      expect(chipSelected, isTrue);
      expect(find.text('Tab 2'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
