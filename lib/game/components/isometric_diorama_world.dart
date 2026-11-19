import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show TextStyle;

import '../../domain/iso/iso_projection.dart';
import '../../domain/models/catalog.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/grid_pos.dart';
import '../../domain/models/solville_toast.dart';
import '../../domain/models/tile_state.dart';
import '../../domain/simulation/farm_simulation_engine.dart';
import '../../ui/view_models/solville_controller.dart';
import '../painters/atmosphere_painter.dart';
import '../painters/canvas_draw_helpers.dart';
import '../painters/characters_and_fx_painter.dart';
import '../painters/iso_prism_painter.dart';
import '../painters/landmarks_and_structures_painter.dart';
import '../painters/painterly_cache.dart';
import '../solville_game.dart';

/// Depth-sorted Painter's-algorithm renderer for the entire 2.5D Solville island.
///
/// Optimized for zero closure/list allocations per frame by traversing isometric
/// diagonals directly, blitting cached 2× painterly terrain tiles, and
/// interleaving dynamic entities, elastic pop animations, and atmospheric lighting.
class IsometricDioramaWorldComponent extends Component
    with HasGameReference<SolvilleGame> {
  IsometricDioramaWorldComponent({
    required this.controller,
    required this.iso,
    AtmospherePainter? atmospherePainter,
  }) : _atmospherePainter = atmospherePainter ?? AtmospherePainter() {
    _painterlyCache = PainterlyCache(iso);
    _prismPainter = IsoPrismPainter(iso, cache: _painterlyCache);
    _structuresPainter = LandmarksAndStructuresPainter(iso);
    _fxPainter = CharactersAndFxPainter(iso);
  }

  final SolvilleController controller;
  final IsoProjection iso;
  final AtmospherePainter _atmospherePainter;

  late final PainterlyCache _painterlyCache;
  late final IsoPrismPainter _prismPainter;
  late final LandmarksAndStructuresPainter _structuresPainter;
  late final CharactersAndFxPainter _fxPainter;

  final math.Random _rng = math.Random();
  final List<FloatingVfx> _vfx = <FloatingVfx>[];
  final Map<GridPos, List<({int step, ActionKind kind})>> _queueStepsByPos =
      <GridPos, List<({int step, ActionKind kind})>>{};
  final Map<GridPos, double> _tilePopTimes = <GridPos, double>{};
  final List<GridPos> _expiredPops = <GridPos>[];
  final List<bool> _villagersDrawn = List<bool>.filled(5, false);
  final Paint _ghostBadgePaint = Paint();
  final Paint _ghostBorderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.8;

  List<GridPos> _cachedGridPos = const <GridPos>[];
  int _cachedGridSize = -1;
  double _stepDustCooldown = 0.0;

  static const double _popDuration = 0.34;

  late final List<StrollingVillager> _villagers = <StrollingVillager>[
    StrollingVillager(
      name: 'Baker Mateo',
      variant: 0,
      gx: 1.5,
      speed: 0.42,
      tunicColor: const Color(0xFF26A69A),
      hairColor: const Color(0xFF4E342E),
    ),
    StrollingVillager(
      name: 'Chef Clara',
      variant: 1,
      gx: 8.2,
      speed: -0.38,
      tunicColor: const Color(0xFFAB47BC),
      hairColor: const Color(0xFFFFB300),
    ),
    StrollingVillager(
      name: 'Florist Mina',
      variant: 2,
      gx: 4.5,
      speed: 0.35,
      tunicColor: const Color(0xFFEC407A),
      hairColor: const Color(0xFF3E2723),
    ),
    StrollingVillager(
      name: 'Grandpa Leo',
      variant: 3,
      gx: 9.4,
      speed: -0.30,
      tunicColor: const Color(0xFF8D6E63),
      hairColor: const Color(0xFFECEFF1),
    ),
    StrollingVillager(
      name: 'Mayor Sunny',
      variant: 4,
      gx: 2.8,
      speed: 0.45,
      tunicColor: const Color(0xFFFFA726),
      hairColor: const Color(0xFF5D4037),
    ),
  ];

  double _animTime = 0.0;
  double get animTime => _animTime;

  @override
  void onRemove() {
    _painterlyCache.dispose();
    super.onRemove();
  }

  void handleSimEvent(SimEvent event) {
    _fxPainter.spawnForSimEvent(_vfx, event, _rng);
    if (event.tile != null &&
        (event.type == SimEventType.dig ||
            event.type == SimEventType.plant ||
            event.type == SimEventType.water ||
            event.type == SimEventType.compost ||
            event.type == SimEventType.harvest ||
            event.type == SimEventType.goldenHarvest)) {
      _tilePopTimes[event.tile!] = _popDuration;
    }

    if ((event.type == SimEventType.coinsEarned ||
            event.type == SimEventType.expressOrderFulfilled) &&
        event.tile == FarmSimulationEngine.marketStallPos) {
      final stallX = FarmSimulationEngine.marketStallPos.x.toDouble();
      StrollingVillager? closest;
      var bestDist = double.infinity;
      final activeCount = controller.state.market.isRushActive ? 5 : 3;
      for (var i = 0; i < activeCount; i++) {
        final v = _villagers[i];
        final d = (v.gx - stallX).abs();
        if (d < bestDist) {
          bestDist = d;
          closest = v;
        }
      }
      if (closest != null) {
        closest.heartTimer = 3.0;
        closest.pauseTimer = math.max(closest.pauseTimer, 2.0);
        if (event.toast?.kind == SolvilleToastKind.soldCrate &&
            event.toast?.product != null) {
          closest.purchaseBubbleText =
              '💛 ${SolvilleCatalog.productEmoji(event.toast!.product!)} +${event.amount}☀️';
        } else {
          closest.purchaseBubbleText = null;
        }
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (controller.isPaused) return;
    _animTime += dt;

    final state = controller.state;
    final maxGx = (state.gridSize - 1).toDouble();
    final market = state.market;
    final hasStallGoods = market.stallCrates.isNotEmpty;
    final activeCount = market.isRushActive ? 5 : 3;
    final speedMult = market.isRushActive ? 1.15 : 1.0;

    for (var i = 0; i < activeCount; i++) {
      final v = _villagers[i];
      if (v.heartTimer > 0) {
        v.heartTimer = math.max(0.0, v.heartTimer - dt);
        if (v.heartTimer == 0.0) {
          v.purchaseBubbleText = null;
        }
      }
      if (v.pauseTimer > 0) {
        v.pauseTimer -= dt;
        continue;
      }
      final prevGx = v.gx;
      v.gx += v.speed * speedMult * dt;
      final stallX = FarmSimulationEngine.marketStallPos.x.toDouble();
      if (hasStallGoods &&
          (prevGx - stallX).sign != (v.gx - stallX).sign &&
          (v.gx - stallX).abs() < 0.6) {
        v.pauseTimer = market.isRushActive ? 1.8 : 2.6;
      }
      if (v.gx > maxGx) {
        v.gx = maxGx;
        v.speed = -v.speed.abs();
      } else if (v.gx < 0.2) {
        v.gx = 0.2;
        v.speed = v.speed.abs();
      }
    }

    // Subtle footstep meadow dust puffs behind Sol while walking
    if (state.farmer.activePath.isNotEmpty) {
      _stepDustCooldown -= dt;
      if (_stepDustCooldown <= 0.0) {
        _stepDustCooldown = 0.18;
        final fw = iso.gridToWorld(state.farmer.x, state.farmer.y);
        _fxPainter.spawnFootstepDust(_vfx, fw.x, fw.y, _rng);
      }
    } else {
      _stepDustCooldown = 0.0;
    }

    // Elastic tile pop-bounce decay
    if (_tilePopTimes.isNotEmpty) {
      _expiredPops.clear();
      _tilePopTimes.updateAll((pos, rem) {
        final next = rem - dt;
        if (next <= 0.0) _expiredPops.add(pos);
        return next;
      });
      for (var i = 0; i < _expiredPops.length; i++) {
        _tilePopTimes.remove(_expiredPops[i]);
      }
    }

    // Update particle physics (gravity, drag, spin)
    for (var i = _vfx.length - 1; i >= 0; i--) {
      final p = _vfx[i];
      p.life -= dt;
      if (p.life <= 0) {
        _vfx.removeAt(i);
      } else {
        p.vy += p.ay * dt;
        p.x += p.vx * dt;
        p.y += p.vy * dt;
        p.angle += p.angularVelocity * dt;
      }
    }
    if (_vfx.length > 180) {
      _vfx.removeRange(0, _vfx.length - 180);
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

    final visibleRect = game.camera.visibleWorldRect.inflate(230.0);
    final minVisX = visibleRect.left;
    final maxVisX = visibleRect.right;
    final minVisY = visibleRect.top;
    final maxVisY = visibleRect.bottom;
    final halfTileW = iso.tileWidth * 0.5;
    final halfTileH = iso.tileHeight * 0.5;

    // Pass 0: Multi-layer parallax cumulus clouds behind floating island
    _atmospherePainter.drawParallaxClouds(
      canvas,
      iso,
      size,
      state.dayProgress,
      state.weather,
      _animTime,
    );

    // Pass 0.5: Feathered multi-layered floating island drop shadow
    _prismPainter.drawIslandDropShadow(canvas, size, state.dayProgress);

    final previewRadius = hovered != null
        ? _prismPainter.sprinklerPreviewRadius(state)
        : 0;
    final maxSum = (size - 1) * 2;

    // Pass 1: Isometric painterly terrain prisms & sculpted sky-island cliffs
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
          tiles: tiles,
          gridSize: size,
          isHovered: isHovered,
          isInSprinklerPreview: inSprinklerPreview,
          animTime: _animTime,
          dayProgress: state.dayProgress,
          hoverValid: hoverValid,
        );
      }
    }

    // Pass 1.2: Soft drifting cloud shadows sweeping across sunlit island
    _atmospherePainter.drawCloudShadows(
      canvas,
      iso,
      size,
      state.dayProgress,
      state.weather,
      _animTime,
    );

    // Pass 1.5: Glowing A* stepping-stone route dots on ground
    _fxPainter.drawActivePathDots(canvas, state.farmer, _animTime);

    // Pass 2: Depth-sorted 2.5D entities in diagonal order
    final activeVillagerCount = state.market.isRushActive ? 5 : 3;
    _villagersDrawn.fillRange(0, activeVillagerCount, false);
    final farmer = state.farmer;
    final farmerDepth = farmer.x + farmer.y + 0.08;
    var farmerDrawn = false;
    final inspected = controller.inspectedTile;
    final sunPassActive = controller.isSunPassActive;

    void drawDynamicInBand(double maxBandDepth) {
      while (true) {
        var bestId = -1;
        var bestDepth = double.infinity;
        for (var i = 0; i < activeVillagerCount; i++) {
          if (_villagersDrawn[i]) continue;
          final d = _villagers[i].gx + 0.05;
          if (d <= maxBandDepth && d < bestDepth) {
            bestDepth = d;
            bestId = i;
          }
        }
        if (!farmerDrawn &&
            farmerDepth <= maxBandDepth &&
            farmerDepth < bestDepth) {
          bestDepth = farmerDepth;
          bestId = 99;
        }
        if (bestId == -1) break;
        if (bestId == 99) {
          farmerDrawn = true;
          _fxPainter.drawFarmer(
            canvas,
            farmer,
            _animTime,
            dayProgress: state.dayProgress,
          );
        } else {
          _villagersDrawn[bestId] = true;
          final boomHighlight = booms.isNotEmpty
              ? booms[bestId % booms.length]
              : null;
          _fxPainter.drawVillager(
            canvas,
            _villagers[bestId],
            boomHighlight,
            _animTime,
            dayProgress: state.dayProgress,
          );
        }
      }
    }

    for (var sum = 0; sum <= maxSum; sum++) {
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
              tile.landmark != LandmarkKind.none ||
              tile.crop != null ||
              tile.droppedCrate != null) {
            final cx = (x - y) * halfTileW;
            if (cx < minVisX || cx > maxVisX) continue;
            final pos = _cachedGridPos[y * size + x];
            final showMeters = pos == hovered || pos == inspected;
            final popRem = _tilePopTimes[pos];
            final popScale = popRem != null
                ? 1.0 + math.sin((popRem / _popDuration) * math.pi) * 0.22
                : 1.0;

            _structuresPainter.drawTileContents(
              canvas,
              pos: pos,
              tile: tile,
              market: state.market,
              totalBarnCrates: totalBarn,
              dayProgress: state.dayProgress,
              animTime: _animTime,
              weather: state.weather,
              isSunPassActive: sunPassActive,
              showDetailedMeters: showMeters,
              popScale: popScale,
              homesteadLabel: controller.landmarkHomesteadLabel,
              refillLabel: controller.landmarkRefillLabel,
              barnLabel: controller.landmarkBarnLabel,
            );
          }
        }
      }

      drawDynamicInBand(sum + 0.9999);
    }

    drawDynamicInBand(double.infinity);

    // Pass 2.5: Additive warm lantern, window & hearth light pools at dusk
    _atmospherePainter.drawDuskLightPools(
      canvas,
      iso,
      state,
      _animTime,
      visibleRect: visibleRect,
    );

    // Pass 3: Action Queue numbered badges with crisp vector action icons
    if (state.actionQueue.isNotEmpty) {
      _queueStepsByPos.clear();
      for (var i = 0; i < state.actionQueue.length; i++) {
        final action = state.actionQueue[i];
        (_queueStepsByPos[action.target] ??= <({int step, ActionKind kind})>[])
            .add((step: i + 1, kind: action.kind));
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

    // Pass 3.2: Pure on-canvas Bee Synergy links & quick Untill badge
    final inspectTarget = hovered ?? inspected;
    if (inspectTarget != null && state.inBounds(inspectTarget)) {
      final t = state.tileAt(inspectTarget);
      if (t.structure == StructureType.beehive) {
        _structuresPainter.drawBeeSynergyLinks(
          canvas,
          state,
          inspectTarget,
          controller.beeFlowerBonusAt(inspectTarget),
          _animTime,
        );
      }
    }
    if (inspected != null && state.inBounds(inspected)) {
      final inspectedTile = state.tileAt(inspected);
      if (inspectedTile.canQuickUntill || inspectedTile.structure.isRemovable) {
        _structuresPainter.drawInspectedActionPill(
          canvas,
          inspected,
          _animTime,
        );
      }
    }

    // Pass 3.4: Zero-text 3-Step Visual Onboarding Spotlight & Contextual Guidance
    if (state.onboardingStep < 3) {
      _drawOnboardingCue(canvas, state);
    } else {
      _drawContextualGuidanceCue(canvas, state);
    }

    // Pass 3.5: Ghost placement preview on hovered tile in Seed / Build mode
    if (hovered != null &&
        (state.activeTool == ToolMode.seed ||
            state.activeTool == ToolMode.build)) {
      _drawGhostPreview(canvas, state, hovered);
    }

    // Pass 4: Butterflies / blossom petals / twilight fireflies / rain & VFX
    _fxPainter.drawAmbientButterfliesFirefliesAndRain(
      canvas,
      gridSize: size,
      weather: state.weather,
      dayProgress: state.dayProgress,
      animTime: _animTime,
    );
    _fxPainter.drawFloatingVfx(canvas, _vfx);
  }

  void _drawOnboardingCue(Canvas canvas, GameState state) {
    if (state.onboardingStep == 0) {
      GridPos target = const GridPos(4, 3);
      for (var y = 1; y < state.gridSize; y++) {
        for (var x = 0; x < state.gridSize; x++) {
          final p = GridPos(x, y);
          final c = state.tileAt(p).crop;
          if (c != null && c.isRipe) {
            target = p;
            x = state.gridSize;
            y = state.gridSize;
          }
        }
      }
      _fxPainter.drawOnboardingSpotlight(
        canvas,
        target,
        controller.spotlightHarvestLabel,
        _animTime,
      );
    } else if (state.onboardingStep == 1) {
      _fxPainter.drawOnboardingSpotlight(
        canvas,
        FarmSimulationEngine.marketStallPos,
        controller.spotlightSellLabel,
        _animTime,
      );
    } else if (state.onboardingStep == 2) {
      GridPos? target;
      for (final action in state.actionQueue) {
        if (action.kind == ActionKind.dig ||
            action.kind == ActionKind.plant ||
            action.kind == ActionKind.water) {
          target = action.target;
          break;
        }
      }
      if (target == null) {
        const starterWeeds = GridPos(5, 4);
        if (state.inBounds(starterWeeds)) {
          final starterTile = state.tileAt(starterWeeds);
          if (starterTile.structure == StructureType.none &&
              starterTile.landmark == LandmarkKind.none &&
              starterTile.crop == null &&
              (starterTile.ground == GroundType.weeds ||
                  starterTile.ground == GroundType.soil)) {
            target = starterWeeds;
          }
        }
      }
      if (target == null) {
        for (var y = 1; y < state.gridSize; y++) {
          for (var x = 0; x < state.gridSize; x++) {
            final p = GridPos(x, y);
            final t = state.tileAt(p);
            if (t.structure == StructureType.none &&
                t.crop == null &&
                (t.ground == GroundType.weeds ||
                    t.ground == GroundType.soil)) {
              target = p;
              x = state.gridSize;
              y = state.gridSize;
            }
          }
        }
      }
      final resolvedTarget = target ?? const GridPos(6, 3);
      final t = state.tileAt(resolvedTarget);
      final hasDigQueued = state.actionQueue.any(
        (a) => a.target == resolvedTarget && a.kind == ActionKind.dig,
      );
      final hasPlantQueued = state.actionQueue.any(
        (a) => a.target == resolvedTarget && a.kind == ActionKind.plant,
      );
      final String stepLabel;
      if (t.ground != GroundType.soil && !hasDigQueued) {
        stepLabel = controller.spotlightStepDigLabel;
      } else if (t.crop == null && !hasPlantQueued) {
        stepLabel = controller.spotlightStepPlantLabel;
      } else {
        stepLabel = controller.spotlightStepWaterLabel;
      }
      _fxPainter.drawOnboardingSpotlight(
        canvas,
        resolvedTarget,
        stepLabel,
        _animTime,
      );
    }
  }

  void _drawContextualGuidanceCue(Canvas canvas, GameState state) {
    if (state.farmer.carriedCrates.length >= state.maxCarryCrates &&
        !state.actionQueue.any(
          (a) =>
              a.kind == ActionKind.sellAtStall ||
              a.kind == ActionKind.storeInBarn,
        )) {
      _fxPainter.drawOnboardingSpotlight(
        canvas,
        FarmSimulationEngine.marketStallPos,
        controller.spotlightSellLabel,
        _animTime,
      );
      return;
    }

    if (state.farmer.waterCharges <= 0 &&
        !state.actionQueue.any((a) => a.kind == ActionKind.refillWater)) {
      _fxPainter.drawOnboardingSpotlight(
        canvas,
        FarmSimulationEngine.wellPos,
        controller.landmarkRefillLabel,
        _animTime,
      );
      return;
    }

    if (state.claimedQuestsCount < 3 &&
        state.farmer.waterCharges > 0 &&
        !state.actionQueue.any((a) => a.kind == ActionKind.water)) {
      for (var y = 1; y < state.gridSize; y++) {
        for (var x = 0; x < state.gridSize; x++) {
          final p = GridPos(x, y);
          if (state.tileAt(p).isThirstyPlot) {
            _fxPainter.drawOnboardingSpotlight(
              canvas,
              p,
              controller.spotlightStepWaterLabel,
              _animTime,
            );
            return;
          }
        }
      }
    }
  }

  static const TextStyle _ghostEmojiStyle = TextStyle(fontSize: 18);

  bool _isPlacementValid(GameState state, TileState tile) {
    switch (state.activeTool) {
      case ToolMode.seed:
        final crop = SolvilleCatalog.crops[state.selectedSeed];
        final isFreeTrial =
            !state.unlockedSeeds.contains(state.selectedSeed) &&
            (state.trialSeeds[state.selectedSeed] ?? 0) > 0;
        return tile.crop == null &&
            tile.structure == StructureType.none &&
            tile.landmark == LandmarkKind.none &&
            (crop == null || isFreeTrial || state.coins >= crop.seedCost);
      case ToolMode.build:
        final def = SolvilleCatalog.buildItems[state.selectedBuildItem];
        return (tile.ground == GroundType.grass ||
                tile.ground == GroundType.stonePath) &&
            tile.structure == StructureType.none &&
            tile.landmark == LandmarkKind.none &&
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
    final bob = math.sin(_animTime * 2.8) * 2.0;
    final badgeCenter = Offset(center.x, center.y - 18.0 + bob);
    _ghostBadgePaint.color = valid
        ? const Color(0xDCFFFDF6)
        : const Color(0xDCFFCDD2);
    _ghostBorderPaint.color = valid
        ? const Color(0xFFFFB300)
        : const Color(0xFFE53935);
    canvas.drawCircle(badgeCenter, 14.5, _ghostBadgePaint);
    canvas.drawCircle(badgeCenter, 14.5, _ghostBorderPaint);
    CanvasDrawHelpers.drawCenteredText(
      canvas,
      emoji,
      badgeCenter,
      _ghostEmojiStyle,
    );
  }
}
