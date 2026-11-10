import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../../domain/iso/iso_projection.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/grid_pos.dart';
import '../../domain/models/tile_state.dart';
import '../../domain/simulation/farm_simulation_engine.dart';
import '../../ui/view_models/solville_controller.dart';
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

        final pos = GridPos(x, y);
        final tile = tiles[y * size + x];
        final isHovered = hovered != null && hovered.x == x && hovered.y == y;
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
          _fxPainter.drawVillager(canvas, v0, boom0, _animTime);
        } else if (bestId == 1) {
          v1Drawn = true;
          _fxPainter.drawVillager(canvas, v1, boom1, _animTime);
        } else {
          farmerDrawn = true;
          _fxPainter.drawFarmer(canvas, farmer, _animTime);
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
              pos: GridPos(x, y),
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
}
