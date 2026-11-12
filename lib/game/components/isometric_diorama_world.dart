import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show TextStyle;

import '../../domain/iso/iso_projection.dart';
import '../../domain/models/catalog.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/grid_pos.dart';
import '../../domain/models/tile_state.dart';
import '../../domain/simulation/farm_simulation_engine.dart';
import '../../ui/view_models/solville_controller.dart';
import '../painters/canvas_draw_helpers.dart';
import '../painters/characters_and_fx_painter.dart';
import '../painters/iso_prism_painter.dart';
import '../painters/landmarks_and_structures_painter.dart';
import '../solville_game.dart';

/// Depth-sorted Painter's-algorithm renderer for the entire 2.5D Solville island.
///
/// Optimized for zero closure/list allocations per frame by traversing isometric
/// diagonals directly and interleaving dynamic entities in-place.
class IsometricDioramaWorldComponent extends Component
    with HasGameReference<SolvilleGame> {
  IsometricDioramaWorldComponent({
    required this.controller,
    required this.iso,
  }) {
    _prismPainter = IsoPrismPainter(iso);
    _structuresPainter = LandmarksAndStructuresPainter(iso);
    _fxPainter = CharactersAndFxPainter(iso);
  }

  final SolvilleController controller;
  final IsoProjection iso;

  late final IsoPrismPainter _prismPainter;
  late final LandmarksAndStructuresPainter _structuresPainter;
  late final CharactersAndFxPainter _fxPainter;

  final math.Random _rng = math.Random();
  final List<FloatingVfx> _vfx = <FloatingVfx>[];
  final Map<GridPos, List<int>> _queueStepsByPos = <GridPos, List<int>>{};
  final Paint _ghostBadgePaint = Paint();
  List<GridPos> _cachedGridPos = const <GridPos>[];
  int _cachedGridSize = -1;

  late final List<StrollingVillager> _villagers = <StrollingVillager>[
    StrollingVillager(
      gx: 1.5,
      speed: 0.75,
      tunicColor: const Color(0xFF26A69A),
      hairColor: const Color(0xFF4E342E),
    ),
    StrollingVillager(
      gx: 8.2,
      speed: -0.65,
      tunicColor: const Color(0xFFAB47BC),
      hairColor: const Color(0xFFFFB300),
    ),
  ];

  double _animTime = 0.0;

  void handleSimEvent(SimEvent event) {
    _fxPainter.spawnForSimEvent(_vfx, event, _rng);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (controller.isPaused) return;
    _animTime += dt;

    final maxGx = (controller.state.gridSize - 1).toDouble();
    final hasStallGoods = controller.state.market.stallCrates.isNotEmpty;
    for (final v in _villagers) {
      if (v.pauseTimer > 0) {
        v.pauseTimer -= dt;
        continue;
      }
      final prevGx = v.gx;
      v.gx += v.speed * dt;
      final stallX = FarmSimulationEngine.marketStallPos.x.toDouble();
      if (hasStallGoods &&
          (prevGx - stallX).sign != (v.gx - stallX).sign &&
          (v.gx - stallX).abs() < 0.5) {
        v.pauseTimer = 1.6;
      }
      if (v.gx > maxGx) {
        v.gx = maxGx;
        v.speed = -v.speed.abs();
      } else if (v.gx < 0.2) {
        v.gx = 0.2;
        v.speed = v.speed.abs();
      }
    }

    for (var i = _vfx.length - 1; i >= 0; i--) {
      final p = _vfx[i];
      p.life -= dt;
      if (p.life <= 0) {
        _vfx.removeAt(i);
      } else {
        p.x += p.vx * dt;
        p.y += p.vy * dt;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final state = controller.state;
    final size = state.gridSize;
    if (_cachedGridSize != size) {
      _cachedGridSize = size;
      _cachedGridPos = List<GridPos>.generate(
        size * size,
        (i) => GridPos(i % size, i ~/ size),
        growable: false,
      );
    }
    final tiles = state.tiles;
    final hovered = controller.hoveredTile;
    final totalBarn = state.totalBarnCrates;
    final booms = state.market.boomProducts;

    final visibleRect = game.camera.visibleWorldRect.inflate(220.0);
    final minVisX = visibleRect.left;
    final maxVisX = visibleRect.right;
    final minVisY = visibleRect.top;
    final maxVisY = visibleRect.bottom;
    final halfTileW = iso.tileWidth * 0.5;
    final halfTileH = iso.tileHeight * 0.5;

    // Pass 0: Soft drifting sky clouds behind floating island
    _fxPainter.drawSkyClouds(canvas, size, state.dayProgress, _animTime);

    // Pass 0.5: Floating island drop shadow
    _prismPainter.drawIslandDropShadow(canvas, size, state.dayProgress);

    final previewRadius = hovered != null
        ? _prismPainter.sprinklerPreviewRadius(state)
        : 0;
    final maxSum = (size - 1) * 2;

    // Pass 1: Isometric terrain prisms back-to-front (with primitive frustum culling)
    for (var sum = 0; sum <= maxSum; sum++) {
      final cy = sum * halfTileH;
      if (cy < minVisY || cy > maxVisY) continue;
      final minX = math.max(0, sum - (size - 1));
      final maxX = math.min(size - 1, sum);
      for (var x = minX; x <= maxX; x++) {
        final y = sum - x;
        final cx = (x - y) * halfTileW;
        if (cx < minVisX || cx > maxVisX) continue;

        final idx = y * size + x;
        final pos = _cachedGridPos[idx];
        final tile = tiles[idx];
        final isHovered = hovered != null && hovered.x == x && hovered.y == y;
        final hoverValid = isHovered
            ? _isPlacementValid(state, tile)
            : true;
        final inSprinklerPreview =
            previewRadius > 0 &&
            hovered != null &&
            (hovered.x - x).abs() <= previewRadius &&
            (hovered.y - y).abs() <= previewRadius;

        _prismPainter.drawTilePrism(
          canvas,
          pos: pos,
          tile: tile,
          gridSize: size,
          isHovered: isHovered,
          isInSprinklerPreview: inSprinklerPreview,
          animTime: _animTime,
          hoverValid: hoverValid,
        );
      }
    }

    // Pass 1.5: A* stepping-stone route dots on ground
    _fxPainter.drawActivePathDots(canvas, state.farmer, _animTime);

    // Pass 2: Depth-sorted 2.5D entities in diagonal order (zero closure allocations)
    final v0 = _villagers[0];
    final v1 = _villagers[1];
    final v0Depth = v0.gx + 0.05;
    final v1Depth = v1.gx + 0.05;
    final farmer = state.farmer;
    final farmerDepth = farmer.x + farmer.y + 0.08;
    final boom0 = booms.isNotEmpty ? booms[0] : null;
    final boom1 = booms.isNotEmpty ? booms[1 % booms.length] : null;

    var v0Drawn = false;
    var v1Drawn = false;
    var farmerDrawn = false;

    void drawDynamicInBand(double maxBandDepth) {
      // At most 3 dynamic characters exist (2 villagers + Sol); draw any not yet
      // drawn whose depth <= maxBandDepth in ascending depth order.
      while (true) {
        var bestId = -1;
        var bestDepth = double.infinity;
        if (!v0Drawn && v0Depth <= maxBandDepth && v0Depth < bestDepth) {
          bestDepth = v0Depth;
          bestId = 0;
        }
        if (!v1Drawn && v1Depth <= maxBandDepth && v1Depth < bestDepth) {
          bestDepth = v1Depth;
          bestId = 1;
        }
        if (!farmerDrawn &&
            farmerDepth <= maxBandDepth &&
            farmerDepth < bestDepth) {
          bestDepth = farmerDepth;
          bestId = 2;
        }
        if (bestId == -1) break;
        if (bestId == 0) {
          v0Drawn = true;
          _fxPainter.drawVillager(
            canvas,
            v0,
            boom0,
            _animTime,
            dayProgress: state.dayProgress,
          );
        } else if (bestId == 1) {
          v1Drawn = true;
          _fxPainter.drawVillager(
            canvas,
            v1,
            boom1,
            _animTime,
            dayProgress: state.dayProgress,
          );
        } else {
          farmerDrawn = true;
          _fxPainter.drawFarmer(
            canvas,
            farmer,
            _animTime,
            dayProgress: state.dayProgress,
          );
        }
      }
    }

    for (var sum = 0; sum <= maxSum; sum++) {
      // Draw any character strictly behind this diagonal
      drawDynamicInBand(sum.toDouble() - 0.0001);

      final cy = sum * halfTileH;
      if (cy >= minVisY && cy <= maxVisY) {
        final minX = math.max(0, sum - (size - 1));
        final maxX = math.min(size - 1, sum);
        for (var x = minX; x <= maxX; x++) {
          final y = sum - x;
          final tile = tiles[y * size + x];
          if (y == 0 ||
              tile.structure != StructureType.none ||
              tile.crop != null ||
              tile.droppedCrate != null) {
            final cx = (x - y) * halfTileW;
            if (cx < minVisX || cx > maxVisX) continue;
            _structuresPainter.drawTileContents(
              canvas,
              pos: _cachedGridPos[y * size + x],
              tile: tile,
              market: state.market,
              totalBarnCrates: totalBarn,
              dayProgress: state.dayProgress,
              animTime: _animTime,
            );
          }
        }
      }

      // Draw characters residing within diagonal band `[sum, sum + 1)`
      drawDynamicInBand(sum + 0.9999);
    }

    // Ensure any character beyond maxSum is drawn
    drawDynamicInBand(double.infinity);

    // Pass 3: Action Queue numbered badges
    if (state.actionQueue.isNotEmpty) {
      _queueStepsByPos.clear();
      for (var i = 0; i < state.actionQueue.length; i++) {
        final pos = state.actionQueue[i].target;
        (_queueStepsByPos[pos] ??= <int>[]).add(i + 1);
      }
      for (final entry in _queueStepsByPos.entries) {
        _structuresPainter.drawQueueMarkers(
          canvas,
          entry.key,
          entry.value,
          _animTime,
        );
      }
    }

    // Pass 3.5: Ghost placement preview on hovered tile in Seed / Build mode
    if (hovered != null &&
        (state.activeTool == ToolMode.seed ||
            state.activeTool == ToolMode.build)) {
      _drawGhostPreview(canvas, state, hovered);
    }

    // Pass 4: Butterflies / twilight fireflies / rain & floating coin popups
    _fxPainter.drawAmbientButterfliesFirefliesAndRain(
      canvas,
      gridSize: size,
      weather: state.weather,
      dayProgress: state.dayProgress,
      animTime: _animTime,
    );
    _fxPainter.drawFloatingVfx(canvas, _vfx);
  }

  static const TextStyle _ghostEmojiStyle = TextStyle(fontSize: 18);

  bool _isPlacementValid(GameState state, TileState tile) {
    switch (state.activeTool) {
      case ToolMode.seed:
        final crop = SolvilleCatalog.crops[state.selectedSeed];
        return tile.ground == GroundType.soil &&
            tile.crop == null &&
            tile.structure == StructureType.none &&
            (crop == null || state.coins >= crop.seedCost);
      case ToolMode.build:
        final def = SolvilleCatalog.buildItems[state.selectedBuildItem];
        return (tile.ground == GroundType.grass ||
                tile.ground == GroundType.stonePath) &&
            tile.structure == StructureType.none &&
            tile.crop == null &&
            (def == null || state.coins >= def.cost);
      default:
        return true;
    }
  }

  void _drawGhostPreview(Canvas canvas, GameState state, GridPos hovered) {
    final tile = state.tileAt(hovered);
    final valid = _isPlacementValid(state, tile);
    final emoji = state.activeTool == ToolMode.seed
        ? SolvilleCatalog.crops[state.selectedSeed]?.emoji
        : SolvilleCatalog.buildItems[state.selectedBuildItem]?.emoji;
    if (emoji == null) return;

    final center = iso.tileCenterToWorld(hovered);
    final bob = math.sin(_animTime * 5.0) * 2.5;
    final badgeCenter = Offset(center.x, center.y - 18.0 + bob);
    _ghostBadgePaint.color = valid
        ? const Color(0xBBFFFDF6)
        : const Color(0xBBFFCDD2);
    canvas.drawCircle(badgeCenter, 14.0, _ghostBadgePaint);
    CanvasDrawHelpers.drawCenteredText(
      canvas,
      emoji,
      badgeCenter,
      _ghostEmojiStyle,
    );
  }
}
