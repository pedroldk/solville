import '../models/catalog.dart';
import '../models/game_state.dart';
import '../models/grid_pos.dart';
import '../models/tile_state.dart';

/// Generates starter island terrain, core landmarks, and frontier grid expansions.
abstract final class FarmMapGenerator {
  static const GridPos farmhousePos = GridPos(1, 1);
  static const GridPos wellPos = GridPos(2, 3);
  static const GridPos barnPos = GridPos(1, 5);
  static const GridPos marketStallPos = GridPos(5, 1);

  /// Creates the initial `11×11` Solville island layout with landmarks,
  /// starter garden beds, sunstone paths, and wildflower weeds.
  static List<TileState> createStarterTiles(int gridSize) {
    final tiles = List<TileState>.generate(gridSize * gridSize, (index) {
      final x = index % gridSize;
      final y = index ~/ gridSize;
      if (y == 0) {
        return const TileState(ground: GroundType.cobbleLane);
      }
      if ((x >= 10 || y >= 8) && (x * 5 + y * 11) % 17 == 0) {
        return const TileState(ground: GroundType.weeds);
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

    // Starter garden beds: 1 ripe tomato ready immediately, 1 nearly ripe tomato, 2 tilled beds
    setTile(
      4,
      3,
      const TileState(
        ground: GroundType.soil,
        moisture: 0.90,
        crop: PlantedCrop(
          cropId: ProductId.tomato,
          growth: 1.0,
          harvestsLeft: 3,
        ),
      ),
    );
    setTile(
      5,
      3,
      const TileState(
        ground: GroundType.soil,
        moisture: 0.72,
        crop: PlantedCrop(
          cropId: ProductId.tomato,
          growth: 0.65,
          harvestsLeft: 3,
        ),
      ),
    );
    setTile(6, 3, const TileState(ground: GroundType.soil, moisture: 0.45));
    setTile(4, 4, const TileState(ground: GroundType.soil, moisture: 0.45));

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

    return tiles;
  }

  /// Expands [state]'s square tile grid to [newSize] while preserving all
  /// existing farm tiles and extending the northern cobble lane.
  static GameState expandFarmGrid(GameState state, int newSize) {
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

    // Discoverable Expansion Landmarks on newly unlocked frontier rings
    final cachePos = GridPos(newSize - 2, 2);
    if (cachePos.x >= oldSize || cachePos.y >= oldSize) {
      newTiles[cachePos.y * newSize + cachePos.x] = const TileState(
        ground: GroundType.grass,
        landmark: LandmarkKind.treasureCache,
      );
    }
    final secondaryPos = GridPos(2, newSize - 2);
    if (secondaryPos.x >= oldSize || secondaryPos.y >= oldSize) {
      final isEvenTier = ((newSize - SolvilleCatalog.starterGridSize) ~/
              SolvilleCatalog.expansionStepSize)
          .isEven;
      newTiles[secondaryPos.y * newSize + secondaryPos.x] = TileState(
        ground: isEvenTier ? GroundType.stonePath : GroundType.grass,
        landmark: isEvenTier
            ? LandmarkKind.oasisFountain
            : LandmarkKind.wildflowerShrine,
      );
    }

    return state.copyWith(gridSize: newSize, tiles: newTiles);
  }

  /// Synchronizes [state]'s grid size with [targetSize] for its current
  /// expansion tier, expanding if smaller or trimming unused outer meadow if
  /// a previous build had a larger default grid size.
  static GameState syncFarmGridToSize(GameState state, int targetSize) {
    if (state.gridSize == targetSize) return state;
    if (state.gridSize < targetSize) {
      return expandFarmGrid(state, targetSize);
    }

    final oldSize = state.gridSize;
    var requiredSize = targetSize;
    for (var y = 0; y < oldSize; y++) {
      for (var x = 0; x < oldSize; x++) {
        if (x < requiredSize && y < requiredSize) continue;
        final t = state.tiles[y * oldSize + x];
        final hasPlayerContent =
            t.structure != StructureType.none ||
            t.landmark != LandmarkKind.none ||
            t.crop != null ||
            t.animal != null ||
            t.droppedCrate != null ||
            t.ground == GroundType.soil ||
            t.ground == GroundType.stonePath;
        if (hasPlayerContent) {
          if (x + 1 > requiredSize) requiredSize = x + 1;
          if (y + 1 > requiredSize) requiredSize = y + 1;
        }
      }
    }

    if (requiredSize >= oldSize) return state;

    final newTiles = List<TileState>.generate(requiredSize * requiredSize, (i) {
      final x = i % requiredSize;
      final y = i ~/ requiredSize;
      return state.tiles[y * oldSize + x];
    });
    final maxCoord = (requiredSize - 1).toDouble();
    final clampedFarmer = state.farmer.copyWith(
      x: state.farmer.x.clamp(0.0, maxCoord),
      y: state.farmer.y.clamp(0.0, maxCoord),
      activePath: const <GridPos>[],
    );
    final validQueue = state.actionQueue
        .where(
          (a) =>
              a.target.x >= 0 &&
              a.target.y >= 0 &&
              a.target.x < requiredSize &&
              a.target.y < requiredSize,
        )
        .toList();

    return state.copyWith(
      gridSize: requiredSize,
      tiles: newTiles,
      farmer: clampedFarmer,
      actionQueue: validQueue,
    );
  }
}
