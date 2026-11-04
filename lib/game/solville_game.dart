import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show KeyEventResult;

import '../domain/iso/iso_projection.dart';
import '../domain/models/game_state.dart';
import '../domain/models/grid_pos.dart';
import '../domain/models/tile_state.dart';
import '../domain/simulation/farm_simulation_engine.dart';
import '../ui/view_models/solville_controller.dart';
import 'painters/characters_and_fx_painter.dart';
import 'painters/iso_prism_painter.dart';
import 'painters/structures_and_crops_painter.dart';

/// Flame 2.5D Isometric Game hosting the Solville diorama world, responsive
/// PC/Steam + Android camera controls, Shift+Drag row painting, and atmosphere.
class SolvilleGame extends FlameGame with KeyboardEvents {
  SolvilleGame({required this.controller});

  final SolvilleController controller;
  final IsoProjection iso = const IsoProjection();

  late final IsometricDioramaWorldComponent _diorama;
  final Set<LogicalKeyboardKey> _heldKeys = <LogicalKeyboardKey>{};

  static const double minZoom = 0.58;
  static const double maxZoom = 2.05;
  double _pinchBaseZoom = 1.0;

  @override
  Color backgroundColor() {
    final p = controller.state.dayProgress;
    if (controller.state.weather == WeatherType.gentleRain) {
      return const Color(0xFF78909C);
    }
    if (p < 0.55) {
      return Color.lerp(
        const Color(0xFF81D4FA),
        const Color(0xFF4FC3F7),
        (p / 0.55).clamp(0.0, 1.0),
      )!;
    }
    return Color.lerp(
      const Color(0xFF4FC3F7),
      const Color(0xFF5C6BC0),
      ((p - 0.55) / 0.45).clamp(0.0, 1.0),
    )!;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _diorama = IsometricDioramaWorldComponent(
      controller: controller,
      iso: iso,
    );
    await world.add(_diorama);

    camera.viewfinder.anchor = Anchor.center;
    camera.viewfinder.zoom = 1.05;
    centerCameraOnFarm();

    controller.onVisualSimEvent = _diorama.handleSimEvent;
    controller.onRequestCenterCamera = centerCameraOnFarmer;
  }

  void centerCameraOnFarm() {
    final mid = (controller.state.gridSize - 1) * 0.46;
    final w = iso.gridToWorld(mid, mid);
    camera.viewfinder.position = Vector2(w.x, w.y);
  }

  void centerCameraOnFarmer() {
    final f = controller.state.farmer;
    final w = iso.gridToWorld(f.x, f.y);
    camera.viewfinder.position = Vector2(w.x, w.y - 12);
  }

  @override
  void update(double dt) {
    super.update(dt);
    controller.advanceFrame(dt);
    _updateKeyboardPan(dt);
  }

  void _updateKeyboardPan(double dt) {
    if (_heldKeys.isEmpty) return;
    var dx = 0.0;
    var dy = 0.0;
    if (_heldKeys.contains(LogicalKeyboardKey.keyA) ||
        _heldKeys.contains(LogicalKeyboardKey.arrowLeft)) {
      dx -= 1.0;
    }
    if (_heldKeys.contains(LogicalKeyboardKey.keyD) ||
        _heldKeys.contains(LogicalKeyboardKey.arrowRight)) {
      dx += 1.0;
    }
    if (_heldKeys.contains(LogicalKeyboardKey.keyW) ||
        _heldKeys.contains(LogicalKeyboardKey.arrowUp)) {
      dy -= 1.0;
    }
    if (_heldKeys.contains(LogicalKeyboardKey.keyS) ||
        _heldKeys.contains(LogicalKeyboardKey.arrowDown)) {
      dy += 1.0;
    }
    if (dx != 0.0 || dy != 0.0) {
      final speed = 440.0 / camera.viewfinder.zoom;
      camera.viewfinder.position += Vector2(dx, dy).normalized() * (speed * dt);
      _clampCamera();
    }
  }

  // ---------------------------------------------------------------------------
  // Unified Cross-Platform Input Bridge
  // ---------------------------------------------------------------------------

  GridPos screenOffsetToTile(Offset localPosition) {
    final worldVec = camera.globalToLocal(
      Vector2(localPosition.dx, localPosition.dy),
    );
    return iso.worldToTile(worldVec.x, worldVec.y);
  }

  void handlePointerHover(Offset localPosition) {
    final pos = screenOffsetToTile(localPosition);
    controller.setHoveredTile(controller.state.inBounds(pos) ? pos : null);
  }

  void handlePrimaryTap(Offset localPosition) {
    final pos = screenOffsetToTile(localPosition);
    if (controller.state.inBounds(pos)) {
      controller.handleTileTap(pos);
    }
  }

  void handleSecondaryTap(Offset localPosition) {
    final pos = screenOffsetToTile(localPosition);
    if (controller.state.inBounds(pos)) {
      controller.handleTileSecondaryTap(pos);
    }
  }

  void handleScaleStart() {
    _pinchBaseZoom = camera.viewfinder.zoom;
    controller.resetPaintDrag();
    controller.notifyUserGestureForAudio();
  }

  void handleScaleUpdate({
    required Offset localFocalPoint,
    required Offset focalPointDelta,
    required double scale,
  }) {
    // Shift + Drag on PC sweeps across tiles to row-queue chores!
    if (HardwareKeyboard.instance.isShiftPressed && (scale - 1.0).abs() < 0.01) {
      final pos = screenOffsetToTile(localFocalPoint);
      controller.handlePaintDragTile(pos);
      return;
    }

    if ((scale - 1.0).abs() > 0.005) {
      camera.viewfinder.zoom = (_pinchBaseZoom * scale).clamp(minZoom, maxZoom);
    }
    if (focalPointDelta != Offset.zero) {
      final zoom = camera.viewfinder.zoom;
      camera.viewfinder.position -= Vector2(
        focalPointDelta.dx / zoom,
        focalPointDelta.dy / zoom,
      );
      _clampCamera();
    }
  }

  void handleMouseScroll(double scrollDeltaY) {
    controller.notifyUserGestureForAudio();
    final factor = scrollDeltaY < 0 ? 1.10 : 0.91;
    camera.viewfinder.zoom = (camera.viewfinder.zoom * factor).clamp(
      minZoom,
      maxZoom,
    );
  }

  void adjustZoom(double factor) {
    camera.viewfinder.zoom = (camera.viewfinder.zoom * factor).clamp(
      minZoom,
      maxZoom,
    );
  }

  void _clampCamera() {
    final maxCoord = controller.state.gridSize.toDouble();
    final maxX = maxCoord * iso.tileWidth * 0.60;
    final maxY = maxCoord * iso.tileHeight * 1.15;
    final pos = camera.viewfinder.position;
    pos.x = pos.x.clamp(-maxX, maxX);
    pos.y = pos.y.clamp(-80.0, maxY);
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    _heldKeys
      ..clear()
      ..addAll(keysPressed);

    if (event is KeyDownEvent) {
      controller.notifyUserGestureForAudio();
      final key = event.logicalKey;
      if (key == LogicalKeyboardKey.digit1) {
        controller.selectTool(ToolMode.smart);
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.digit2) {
        controller.selectTool(ToolMode.dig);
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.digit3) {
        controller.selectTool(ToolMode.seed);
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.digit4) {
        controller.selectTool(ToolMode.water);
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.digit5) {
        controller.selectTool(ToolMode.compost);
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.digit6) {
        controller.selectTool(ToolMode.build);
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.digit7) {
        controller.selectTool(ToolMode.remove);
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.keyH) {
        controller.queueAllReadyHarvests();
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.keyM) {
        controller.cycleBgmTrack();
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.escape ||
          key == LogicalKeyboardKey.keyX) {
        controller.clearActionQueue();
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.space ||
          key == LogicalKeyboardKey.keyC) {
        centerCameraOnFarmer();
        return KeyEventResult.handled;
      } else if (key == LogicalKeyboardKey.keyP) {
        controller.togglePause();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }
}

/// Depth-sorted Painter's-algorithm renderer for the entire 2.5D Solville island.
class IsometricDioramaWorldComponent extends Component {
  IsometricDioramaWorldComponent({
    required this.controller,
    required this.iso,
  }) {
    _prismPainter = IsoPrismPainter(iso);
    _structuresPainter = StructuresAndCropsPainter(iso);
    _fxPainter = CharactersAndFxPainter(iso, _structuresPainter);
  }

  final SolvilleController controller;
  final IsoProjection iso;

  late final IsoPrismPainter _prismPainter;
  late final StructuresAndCropsPainter _structuresPainter;
  late final CharactersAndFxPainter _fxPainter;

  final math.Random _rng = math.Random();
  final List<FloatingVfx> _vfx = <FloatingVfx>[];
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
    final hovered = controller.hoveredTile;
    final totalBarn = state.totalBarnCrates;
    final booms = state.market.boomProducts;

    // Pass 0: Soft drifting sky clouds behind floating island
    _fxPainter.drawSkyClouds(canvas, state.dayProgress, _animTime);

    final queueStepsByPos = <GridPos, List<int>>{};
    for (var i = 0; i < state.actionQueue.length; i++) {
      final pos = state.actionQueue[i].target;
      (queueStepsByPos[pos] ??= <int>[]).add(i + 1);
    }

    // Pass 1: Isometric terrain prisms back-to-front
    for (var sum = 0; sum <= (size - 1) * 2; sum++) {
      final minX = math.max(0, sum - (size - 1));
      final maxX = math.min(size - 1, sum);
      for (var x = minX; x <= maxX; x++) {
        final y = sum - x;
        final pos = GridPos(x, y);
        final tile = state.tileAt(pos);
        _prismPainter.drawTilePrism(
          canvas,
          pos: pos,
          tile: tile,
          gridSize: size,
          isHovered: hovered == pos,
          isInSprinklerPreview: _prismPainter.isInSprinklerPreview(
            state,
            hovered,
            pos,
          ),
          animTime: _animTime,
        );
      }
    }

    // Pass 1.5: A* stepping-stone route dots on ground
    _fxPainter.drawActivePathDots(canvas, state.farmer, _animTime);

    // Pass 2: Depth-sorted 2.5D entities
    final drawItems = <({double depth, void Function() draw})>[];

    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        final pos = GridPos(x, y);
        final tile = state.tileAt(pos);
        if (y == 0 ||
            tile.structure != StructureType.none ||
            tile.crop != null ||
            tile.droppedCrate != null) {
          drawItems.add((
            depth: (x + y).toDouble(),
            draw: () => _structuresPainter.drawTileContents(
              canvas,
              pos: pos,
              tile: tile,
              market: state.market,
              totalBarnCrates: totalBarn,
              dayProgress: state.dayProgress,
              animTime: _animTime,
            ),
          ));
        }
      }
    }

    for (var i = 0; i < _villagers.length; i++) {
      final v = _villagers[i];
      final boomHint = booms.isNotEmpty ? booms[i % booms.length] : null;
      drawItems.add((
        depth: v.gx + 0.05,
        draw: () => _fxPainter.drawVillager(canvas, v, boomHint, _animTime),
      ));
    }

    drawItems.add((
      depth: state.farmer.x + state.farmer.y + 0.08,
      draw: () => _fxPainter.drawFarmer(canvas, state.farmer, _animTime),
    ));

    drawItems.sort((a, b) => a.depth.compareTo(b.depth));
    for (final item in drawItems) {
      item.draw();
    }

    // Pass 3: Action Queue numbered badges
    for (final entry in queueStepsByPos.entries) {
      _structuresPainter.drawQueueMarkers(
        canvas,
        entry.key,
        entry.value,
        _animTime,
      );
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
