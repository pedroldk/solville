import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart' show Alignment, LinearGradient;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show KeyEventResult;

import '../domain/iso/iso_projection.dart';
import '../domain/models/game_state.dart';
import '../domain/models/grid_pos.dart';
import '../domain/simulation/farm_simulation_engine.dart';
import '../ui/view_models/solville_controller.dart';
import 'components/isometric_diorama_world.dart';
import 'painters/characters_and_fx_painter.dart';

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
  double? _cameraTargetX;
  double? _cameraTargetY;
  double? _zoomTarget;

  final ui.Paint _skyPaint = ui.Paint();
  double _cachedSkyWidth = -1;
  double _cachedSkyHeight = -1;
  int _cachedSkyStep = -1;
  WeatherType? _cachedSkyWeather;

  @override
  void render(ui.Canvas canvas) {
    _drawSkyGradient(canvas);
    super.render(canvas);
  }

  void _drawSkyGradient(ui.Canvas canvas) {
    final w = size.x;
    final h = size.y;
    if (w <= 0 || h <= 0) return;

    final p = controller.state.dayProgress;
    final weather = controller.state.weather;
    // Quantize dayProgress to 60 steps so the gradient shader is only rebuilt
    // when the sky visibly shifts or the viewport resizes.
    final skyStep = (p * 60.0).round();
    if (_skyPaint.shader == null ||
        _cachedSkyWidth != w ||
        _cachedSkyHeight != h ||
        _cachedSkyStep != skyStep ||
        _cachedSkyWeather != weather) {
      _cachedSkyWidth = w;
      _cachedSkyHeight = h;
      _cachedSkyStep = skyStep;
      _cachedSkyWeather = weather;

      final ({Color top, Color mid, Color horizon}) colors = _resolveSkyColors(
        p,
        weather,
      );
      _skyPaint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[colors.top, colors.mid, colors.horizon],
        stops: const <double>[0.0, 0.56, 1.0],
      ).createShader(ui.Rect.fromLTWH(0, 0, w, h));
    }

    canvas.drawRect(ui.Rect.fromLTWH(0, 0, w, h), _skyPaint);
  }

  ({Color top, Color mid, Color horizon}) _resolveSkyColors(
    double p,
    WeatherType weather,
  ) {
    if (weather == WeatherType.gentleRain) {
      return (
        top: const Color(0xFF546E7A),
        mid: const Color(0xFF78909C),
        horizon: const Color(0xFFB0BEC5),
      );
    }
    if (p < 0.25) {
      final t = (p / 0.25).clamp(0.0, 1.0);
      return (
        top: Color.lerp(
          const Color(0xFF4FC3F7),
          const Color(0xFF29B6F6),
          t,
        )!,
        mid: Color.lerp(
          const Color(0xFF81D4FA),
          const Color(0xFF81D4FA),
          t,
        )!,
        horizon: Color.lerp(
          const Color(0xFFFFE0B2),
          const Color(0xFFE1F5FE),
          t,
        )!,
      );
    }
    if (p < 0.60) {
      final t = ((p - 0.25) / 0.35).clamp(0.0, 1.0);
      return (
        top: Color.lerp(
          const Color(0xFF29B6F6),
          const Color(0xFF42A5F5),
          t,
        )!,
        mid: Color.lerp(
          const Color(0xFF81D4FA),
          const Color(0xFF90CAF9),
          t,
        )!,
        horizon: Color.lerp(
          const Color(0xFFE1F5FE),
          const Color(0xFFFFF3E0),
          t,
        )!,
      );
    }
    if (p < 0.85) {
      final t = ((p - 0.60) / 0.25).clamp(0.0, 1.0);
      return (
        top: Color.lerp(
          const Color(0xFF42A5F5),
          const Color(0xFF3949AB),
          t,
        )!,
        mid: Color.lerp(
          const Color(0xFF90CAF9),
          const Color(0xFFFF8A65),
          t,
        )!,
        horizon: Color.lerp(
          const Color(0xFFFFF3E0),
          const Color(0xFFFFCC80),
          t,
        )!,
      );
    }
    final t = ((p - 0.85) / 0.15).clamp(0.0, 1.0);
    return (
      top: Color.lerp(
        const Color(0xFF3949AB),
        const Color(0xFF1A237E),
        t,
      )!,
      mid: Color.lerp(
        const Color(0xFFFF8A65),
        const Color(0xFF3949AB),
        t,
      )!,
      horizon: Color.lerp(
        const Color(0xFFFFCC80),
        const Color(0xFF7986CB),
        t,
      )!,
    );
  }

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
    _cameraTargetX = null;
    _cameraTargetY = null;
    _setCameraPosition(w.x, w.y, clamp: false);
  }

  void centerCameraOnFarmer() {
    final f = controller.state.farmer;
    final w = iso.gridToWorld(f.x, f.y);
    final clamped = _clampCameraCoords(w.x, w.y - 12);
    _cameraTargetX = clamped.x;
    _cameraTargetY = clamped.y;
    // Apply an immediate initial step so responsiveness is instant and
    // synchronous callers observe progress on the same frame.
    final pos = camera.viewfinder.position;
    _setCameraPosition(
      pos.x + (clamped.x - pos.x) * 0.35,
      pos.y + (clamped.y - pos.y) * 0.35,
      clamp: false,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    controller.advanceFrame(dt);
    _updateKeyboardPan(dt);
    _updateSmoothCamera(dt);
  }

  void _updateSmoothCamera(double dt) {
    final lerpFactor = 1.0 - math.exp(-10.0 * dt);
    if (_cameraTargetX != null && _cameraTargetY != null) {
      final pos = camera.viewfinder.position;
      final dx = _cameraTargetX! - pos.x;
      final dy = _cameraTargetY! - pos.y;
      if (dx * dx + dy * dy < 0.5) {
        _setCameraPosition(_cameraTargetX!, _cameraTargetY!, clamp: false);
        _cameraTargetX = null;
        _cameraTargetY = null;
      } else {
        _setCameraPosition(
          pos.x + dx * lerpFactor,
          pos.y + dy * lerpFactor,
          clamp: false,
        );
      }
    }
    if (_zoomTarget != null) {
      final z = camera.viewfinder.zoom;
      final dz = _zoomTarget! - z;
      if (dz.abs() < 0.002) {
        camera.viewfinder.zoom = _zoomTarget!;
        _zoomTarget = null;
      } else {
        camera.viewfinder.zoom = z + dz * lerpFactor;
      }
    }
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
      _cameraTargetX = null;
      _cameraTargetY = null;
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
    _scratchScreenVec.setValues(localPosition.dx, localPosition.dy);
    final worldVec = camera.globalToLocal(
      _scratchScreenVec,
      output: _scratchWorldVec,
    );
    final wx = worldVec.x;
    final wy = worldVec.y;

    // 1. Check floating [🌿] quick-untill badge on the inspected tile
    final inspected = controller.inspectedTile;
    if (inspected != null && controller.state.inBounds(inspected)) {
      final tile = controller.state.tileAt(inspected);
      if (tile.canQuickUntill || tile.structure.isRemovable) {
        final tc = iso.tileCenterToWorld(inspected);
        final dx = wx - (tc.x + 26.0);
        final dy = wy - (tc.y - 34.0);
        if (dx * dx + dy * dy <= 19.0 * 19.0) {
          controller.untillTile(inspected);
          controller.clearInspectedTile();
          return;
        }
      }
    }

    // 2. Check floating [📈] Market Signpost badge above the Market Stall
    final stallCenter = iso.tileCenterToWorld(
      FarmSimulationEngine.marketStallPos,
    );
    final sdx = wx - (stallCenter.x - 26.0);
    final sdy = wy - (stallCenter.y - 52.0);
    if (sdx * sdx + sdy * sdy <= 18.0 * 18.0) {
      controller.openMarketModal();
      return;
    }

    // 3. Check fluttering daytime butterflies for +3☀️ boop bonus
    final state = controller.state;
    if (state.weather != WeatherType.gentleRain && state.dayProgress <= 0.60) {
      for (var b = 0; b < 3; b++) {
        final bPos = CharactersAndFxPainter.butterflyWorldPos(
          iso,
          b,
          _diorama.animTime,
        );
        final bdx = wx - bPos.dx;
        final bdy = wy - bPos.dy;
        if (bdx * bdx + bdy * bdy <= 20.0 * 20.0) {
          final tilePos = iso.worldToTile(bPos.dx, bPos.dy);
          controller.boopButterfly(
            state.inBounds(tilePos) ? tilePos : state.farmer.currentTile,
          );
          return;
        }
      }
    }

    final pos = iso.worldToTile(wx, wy);
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
    // Shift + Drag on PC or Sweep toggle on touch sweeps across tiles!
    if ((HardwareKeyboard.instance.isShiftPressed ||
            controller.paintSweepMode) &&
        (scale - 1.0).abs() < 0.01) {
      final pos = screenOffsetToTile(localFocalPoint);
      controller.handlePaintDragTile(pos);
      return;
    }

    if ((scale - 1.0).abs() > 0.005) {
      _zoomTarget = null;
      camera.viewfinder.zoom = (_pinchBaseZoom * scale).clamp(minZoom, maxZoom);
    }
    if (focalPointDelta != Offset.zero) {
      _cameraTargetX = null;
      _cameraTargetY = null;
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
    _zoomTarget = null;
    final factor = scrollDeltaY < 0 ? 1.10 : 0.91;
    camera.viewfinder.zoom = (camera.viewfinder.zoom * factor).clamp(
      minZoom,
      maxZoom,
    );
  }

  void adjustZoom(double factor) {
    final base = _zoomTarget ?? camera.viewfinder.zoom;
    _zoomTarget = (base * factor).clamp(minZoom, maxZoom);
  }

  ({double x, double y}) _clampCameraCoords(double x, double y) {
    final maxCoord = controller.state.gridSize.toDouble();
    final maxX = maxCoord * iso.tileWidth * 0.60;
    final maxY = maxCoord * iso.tileHeight * 1.15;
    return (x: x.clamp(-maxX, maxX), y: y.clamp(-80.0, maxY));
  }

  void _setCameraPosition(double x, double y, {bool clamp = true}) {
    if (clamp) {
      final clamped = _clampCameraCoords(x, y);
      x = clamped.x;
      y = clamped.y;
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
