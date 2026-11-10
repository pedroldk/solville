import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show KeyEventResult;

import '../domain/iso/iso_projection.dart';
import '../domain/models/game_state.dart';
import '../domain/models/grid_pos.dart';
import '../ui/view_models/solville_controller.dart';
import 'components/isometric_diorama_world.dart';

/// Flame 2.5D Isometric Game hosting the Solville diorama world, responsive
/// PC/Steam + Android camera controls, Shift+Drag row painting, and atmosphere.
class SolvilleGame extends FlameGame with KeyboardEvents {
  SolvilleGame({required this.controller});

  final SolvilleController controller;
  final IsoProjection iso = const IsoProjection();

  late final IsometricDioramaWorldComponent _diorama;
  final Set<LogicalKeyboardKey> _heldKeys = <LogicalKeyboardKey>{};
  final Vector2 _scratchScreenVec = Vector2.zero();
  final Vector2 _scratchWorldVec = Vector2.zero();

  static const double minZoom = 0.28;
  static const double maxZoom = 2.05;
  double _pinchBaseZoom = 0.92;

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
    _diorama = IsometricDioramaWorldComponent(controller: controller, iso: iso);
    await world.add(_diorama);

    camera.viewfinder.anchor = Anchor.center;
    camera.viewfinder.zoom = 0.92;
    centerCameraOnFarm();

    controller.onVisualSimEvent = _diorama.handleSimEvent;
    controller.onRequestCenterCamera = centerCameraOnFarmer;
  }

  void centerCameraOnFarm() {
    final focus = math.min(6.0, (controller.state.gridSize - 1) * 0.45);
    final w = iso.gridToWorld(focus, focus);
    _setCameraPosition(w.x, w.y, clamp: false);
  }

  void centerCameraOnFarmer() {
    final f = controller.state.farmer;
    final w = iso.gridToWorld(f.x, f.y);
    _setCameraPosition(w.x, w.y - 12);
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
      final invLen = (dx != 0.0 && dy != 0.0) ? math.sqrt1_2 : 1.0;
      final step = (440.0 / camera.viewfinder.zoom) * dt * invLen;
      final pos = camera.viewfinder.position;
      _setCameraPosition(pos.x + dx * step, pos.y + dy * step);
    }
  }

  // ---------------------------------------------------------------------------
  // Unified Cross-Platform Input Bridge
  // ---------------------------------------------------------------------------

  GridPos screenOffsetToTile(Offset localPosition) {
    _scratchScreenVec.setValues(localPosition.dx, localPosition.dy);
    final worldVec = camera.globalToLocal(
      _scratchScreenVec,
      output: _scratchWorldVec,
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
    if (HardwareKeyboard.instance.isShiftPressed &&
        (scale - 1.0).abs() < 0.01) {
      final pos = screenOffsetToTile(localFocalPoint);
      controller.handlePaintDragTile(pos);
      return;
    }

    if ((scale - 1.0).abs() > 0.005) {
      camera.viewfinder.zoom = (_pinchBaseZoom * scale).clamp(minZoom, maxZoom);
    }
    if (focalPointDelta != Offset.zero) {
      final zoom = camera.viewfinder.zoom;
      final pos = camera.viewfinder.position;
      _setCameraPosition(
        pos.x - focalPointDelta.dx / zoom,
        pos.y - focalPointDelta.dy / zoom,
      );
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

  void _setCameraPosition(double x, double y, {bool clamp = true}) {
    if (clamp) {
      final maxCoord = controller.state.gridSize.toDouble();
      final maxX = maxCoord * iso.tileWidth * 0.60;
      final maxY = maxCoord * iso.tileHeight * 1.15;
      x = x.clamp(-maxX, maxX);
      y = y.clamp(-80.0, maxY);
    }
    camera.viewfinder.position = Vector2(x, y);
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
