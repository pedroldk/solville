import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/painting.dart' show Alignment, LinearGradient;

import '../../domain/iso/iso_projection.dart';
import '../../domain/models/catalog.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/grid_pos.dart';
import '../../domain/models/tile_state.dart';
import 'painterly_cache.dart';

/// Renders 2.5D painterly isometric terrain blocks from 2× supersampled offscreen
/// caches, auto-tiled organic soil borders, animated foliage accents, sculpted
/// floating sky-island cliffs with hanging vines, and rich hover/sprinkler overlays.
class IsoPrismPainter {
  IsoPrismPainter(this.iso, {PainterlyCache? cache})
      : _cache = cache ?? PainterlyCache(iso),
        _ownsCache = cache == null;

  final IsoProjection iso;
  final PainterlyCache _cache;
  final bool _ownsCache;

  final Path _leftFacePath = Path();
  final Path _rightFacePath = Path();
  final Path _topFacePath = Path();
  final Path _turfLipPath = Path();
  final Path _cliffStrataPath = Path();
  final Path _vinePath = Path();
  final Path _islandShadowPath = Path();

  final Paint _tileBlitPaint = Paint()..filterQuality = FilterQuality.medium;
  final Paint _soilBlendPaint = Paint()..filterQuality = FilterQuality.medium;
  final Paint _bevelPaint = Paint();
  final Paint _cliffDetailPaint = Paint();
  final Paint _cliffStrokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  final Paint _turfPaint = Paint();
  final Paint _turfRimPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  final Paint _sparklePaint = Paint()..color = const Color(0xFFFFE082);
  final Paint _weedLeafPaint = Paint()
    ..strokeWidth = 2.4
    ..strokeCap = StrokeCap.round;
  final Paint _dandelionPaint = Paint()..color = const Color(0xFFFFEE58);
  final Paint _dandelionCenterPaint = Paint()..color = const Color(0xFFFFA000);
  final Paint _grassBladePaint = Paint()
    ..strokeWidth = 1.6
    ..strokeCap = StrokeCap.round;
  final Paint _grassFlowerPaint = Paint()..color = const Color(0xFFFFF9C4);
  final Paint _moistureSheenPaint = Paint()
    ..color = const Color(0x28FFF8E1)
    ..strokeWidth = 1.3
    ..strokeCap = StrokeCap.round;

  final Paint _soilEdgeShadowPaint = Paint()
    ..color = const Color(0x663E2723)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.0
    ..strokeCap = StrokeCap.round;
  final Paint _soilEdgeRimPaint = Paint()
    ..color = const Color(0x448BC34A)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0
    ..strokeCap = StrokeCap.round;

  final Paint _fenceWoodPaint = Paint()
    ..color = const Color(0xFF9C724C)
    ..strokeCap = StrokeCap.round;
  final Paint _fenceShadePaint = Paint()
    ..color = const Color(0xFF6D4C41)
    ..strokeCap = StrokeCap.round;
  final Paint _fenceHighlightPaint = Paint()
    ..color = const Color(0x66FFE0B2)
    ..strokeWidth = 1.2
    ..strokeCap = StrokeCap.round;

  final Paint _sprinklerFillPaint = Paint()..color = const Color(0x3D29B6F6);
  final Paint _sprinklerStrokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0
    ..strokeCap = StrokeCap.round;

  final Paint _hoverFillPaint = Paint();
  final Paint _hoverStrokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.6
    ..strokeCap = StrokeCap.round;

  final Paint _islandShadowOuterPaint = Paint()..color = const Color(0x141A237E);
  final Paint _islandShadowMidPaint = Paint()..color = const Color(0x1C1A237E);
  final Paint _islandShadowInnerPaint = Paint()..color = const Color(0x241A237E);
  final Paint _mistReflectionPaint = Paint()..color = const Color(0x20FFFFFF);

  Shader? _leftCliffShader;
  Shader? _rightCliffShader;
  Shader? _hoverGlowValidShader;
  Shader? _hoverGlowInvalidShader;

  void _ensureCliffShaders() {
    _leftCliffShader ??= const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[
        Color(0xFFA97553),
        Color(0xFF8B583D),
        Color(0xFF694132),
      ],
      stops: <double>[0.0, 0.48, 1.0],
    ).createShader(const Rect.fromLTWH(-52, 0, 56, 104));

    _rightCliffShader ??= const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[
        Color(0xFF7D503C),
        Color(0xFF613B2F),
        Color(0xFF472A27),
      ],
      stops: <double>[0.0, 0.50, 1.0],
    ).createShader(const Rect.fromLTWH(-2, 0, 56, 104));

    _hoverGlowValidShader ??= Gradient.radial(
      Offset.zero,
      46.0,
      const <Color>[Color(0x55FFF59D), Color(0x18FFCA28), Color(0x00FFCA28)],
      const <double>[0.0, 0.58, 1.0],
    );
    _hoverGlowInvalidShader ??= Gradient.radial(
      Offset.zero,
      46.0,
      const <Color>[Color(0x48EF9A9A), Color(0x18E53935), Color(0x00E53935)],
      const <double>[0.0, 0.58, 1.0],
    );
  }

  /// Draws a soft feathered cloud-cushion & atmospheric shadow beneath the
  /// floating sky-island, shifting subtly with the sun angle.
  void drawIslandDropShadow(
    Canvas canvas,
    int gridSize,
    double dayProgress,
  ) {
    final hw = iso.tileWidth * 0.5;
    final hh = iso.tileHeight * 0.5;
    final sunOffsetX = (dayProgress - 0.45) * 20.0;
    const dropY = 76.0;

    final topX = sunOffsetX;
    final topY = -hh + dropY;
    final rightX = gridSize * hw + sunOffsetX;
    final rightY = (gridSize - 1) * hh + dropY;
    final bottomX = sunOffsetX;
    final bottomY = (2 * gridSize - 1) * hh + dropY + 12.0;
    final leftX = -gridSize * hw + sunOffsetX;
    final leftY = (gridSize - 1) * hh + dropY;

    final midCenterY = (topY + bottomY) * 0.5;
    final spanW = (rightX - leftX);
    final spanH = (bottomY - topY);

    // Feathered elliptical sky-shadow cushion (no harsh sharp corners)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(sunOffsetX, midCenterY + 12.0),
        width: spanW * 1.04,
        height: spanH * 0.96,
      ),
      _islandShadowOuterPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(sunOffsetX, midCenterY + 6.0),
        width: spanW * 0.94,
        height: spanH * 0.88,
      ),
      _islandShadowMidPaint,
    );

    _islandShadowPath
      ..reset()
      ..moveTo(topX, topY + 4.0)
      ..lineTo(rightX + 4.0, rightY + 2.0)
      ..lineTo(bottomX, bottomY + 4.0)
      ..lineTo(leftX - 4.0, leftY + 2.0)
      ..close();
    canvas.drawPath(_islandShadowPath, _islandShadowInnerPaint);

    // Sunlit mist cloud cushion tucked under the front cliff underside
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(bottomX - hw * 1.1, bottomY - 12.0),
        width: 130,
        height: 28,
      ),
      _mistReflectionPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(bottomX + hw * 1.1, bottomY - 15.0),
        width: 118,
        height: 25,
      ),
      _mistReflectionPaint,
    );
  }

  double _leftCliffDepthAtCorner(int cornerX, int gridSize) {
    if (cornerX <= 0) return 32.0;
    if (cornerX >= gridSize) return 64.0;
    final t = cornerX / gridSize;
    return 36.0 + t * 25.0 + math.sin(cornerX * 1.85 + 0.4) * 5.0;
  }

  double _rightCliffDepthAtCorner(int cornerY, int gridSize) {
    if (cornerY <= 0) return 32.0;
    if (cornerY >= gridSize) return 64.0;
    final t = cornerY / gridSize;
    return 36.0 + t * 25.0 + math.cos(cornerY * 2.05 + 0.7) * 5.0;
  }

  void drawTilePrism(
    Canvas canvas, {
    required GridPos pos,
    required TileState tile,
    required int gridSize,
    required bool isHovered,
    required bool isInSprinklerPreview,
    required double animTime,
    List<TileState>? tiles,
    double dayProgress = 0.35,
    bool hoverValid = true,
  }) {
    _cache.ensureBuilt();
    _ensureCliffShaders();

    final center = iso.tileCenterToWorld(pos);
    final cx = center.x;
    final cy = center.y;
    final hw = iso.tileWidth * 0.5;
    final hh = iso.tileHeight * 0.5;

    final drawLeftCliff = pos.y == gridSize - 1;
    final drawRightCliff = pos.x == gridSize - 1;

    final topX = cx;
    final topY = cy - hh;
    final rightX = cx + hw;
    final rightY = cy;
    final bottomX = cx;
    final bottomY = cy + hh;
    final leftX = cx - hw;
    final leftY = cy;

    // 1. Draw side bevels or sculpted floating sky-island cliff skirts
    if (drawLeftCliff) {
      final d0 = _leftCliffDepthAtCorner(pos.x, gridSize);
      final d1 = _leftCliffDepthAtCorner(pos.x + 1, gridSize);
      _drawSculptedLeftCliff(
        canvas,
        cx: cx,
        cy: cy,
        leftX: leftX,
        leftY: leftY,
        bottomX: bottomX,
        bottomY: bottomY,
        d0: d0,
        d1: d1,
        pos: pos,
        tile: tile,
        animTime: animTime,
      );
    } else {
      const innerDepth = 12.0;
      _leftFacePath
        ..reset()
        ..moveTo(leftX, leftY)
        ..lineTo(bottomX, bottomY)
        ..lineTo(bottomX, bottomY + innerDepth)
        ..lineTo(leftX, leftY + innerDepth)
        ..close();
      _bevelPaint
        ..shader = null
        ..color = _innerLeftBevelColor(tile.ground);
      canvas.drawPath(_leftFacePath, _bevelPaint);
    }

    if (drawRightCliff) {
      final d0 = _rightCliffDepthAtCorner(pos.y, gridSize);
      final d1 = _rightCliffDepthAtCorner(pos.y + 1, gridSize);
      _drawSculptedRightCliff(
        canvas,
        cx: cx,
        cy: cy,
        bottomX: bottomX,
        bottomY: bottomY,
        rightX: rightX,
        rightY: rightY,
        d0: d0,
        d1: d1,
        pos: pos,
        tile: tile,
        animTime: animTime,
      );
    } else {
      const innerDepth = 12.0;
      _rightFacePath
        ..reset()
        ..moveTo(bottomX, bottomY)
        ..lineTo(rightX, rightY)
        ..lineTo(rightX, rightY + innerDepth)
        ..lineTo(bottomX, bottomY + innerDepth)
        ..close();
      _bevelPaint
        ..shader = null
        ..color = _innerRightBevelColor(tile.ground);
      canvas.drawPath(_rightFacePath, _bevelPaint);
    }

    // 2. Blit cached 2× supersampled painterly top diamond
    _blitTileSurface(canvas, cx, cy, pos, tile);

    // 2.5 Gentle macro sunlit swath undulation across grass + bridging stepping stones
    if (tile.ground == GroundType.grass) {
      final wave = math.sin(pos.x * 0.55 + pos.y * 0.42);
      if (wave.abs() > 0.14) {
        _bevelPaint
          ..shader = null
          ..color = wave > 0
              ? Color.fromRGBO(255, 245, 157, wave * 0.036)
              : Color.fromRGBO(27, 94, 32, (-wave) * 0.028);
        canvas.drawOval(
          Rect.fromCenter(center: Offset(cx, cy), width: 78, height: 39),
          _bevelPaint,
        );
      }
    } else if (tile.ground == GroundType.stonePath && tiles != null) {
      _drawStonePathBridges(
        canvas,
        pos: pos,
        tiles: tiles,
        gridSize: gridSize,
        rightX: rightX,
        rightY: rightY,
        bottomX: bottomX,
        bottomY: bottomY,
        leftX: leftX,
        leftY: leftY,
      );
    }

    // 3. Auto-tiled organic soil border lip against grass / path / weeds
    if (tile.ground == GroundType.soil && tiles != null) {
      _drawAutoTiledSoilBorders(
        canvas,
        pos: pos,
        tiles: tiles,
        gridSize: gridSize,
        topX: topX,
        topY: topY,
        rightX: rightX,
        rightY: rightY,
        bottomX: bottomX,
        bottomY: bottomY,
        leftX: leftX,
        leftY: leftY,
      );
    }

    // 4. Dynamic animated surface details (swaying grass, moisture glint, weeds, compost)
    switch (tile.ground) {
      case GroundType.soil:
        _drawDynamicSoilDetails(canvas, cx, cy, pos, tile, animTime);
      case GroundType.weeds:
        _drawDynamicWeedDetails(canvas, cx, cy, pos, animTime);
      case GroundType.grass:
        _drawDynamicGrassAccent(canvas, cx, cy, pos, animTime);
      case GroundType.stonePath:
      case GroundType.cobbleLane:
        break;
    }

    // 5. Charming low rustic rail fence along NW meadow rim & lane entrance post
    if (pos.x == 0 && pos.y > 0 && tile.structure == StructureType.none) {
      _drawNorthwestRimFence(canvas, leftX, leftY, topX, topY, pos);
    } else if (pos.x == 0 && pos.y == 0) {
      _drawLaneWelcomePost(canvas, leftX, leftY);
    }

    // 5.5 Overflowing corner foliage/flowers & floating cliff pebbles on island tips
    if ((pos.x == 0 && pos.y == gridSize - 1) ||
        (pos.x == gridSize - 1 && pos.y == gridSize - 1) ||
        (pos.x == gridSize - 1 && pos.y == 0)) {
      _drawIslandCornerFoliage(
        canvas,
        pos: pos,
        gridSize: gridSize,
        leftX: leftX,
        leftY: leftY,
        bottomX: bottomX,
        bottomY: bottomY,
        rightX: rightX,
        rightY: rightY,
        animTime: animTime,
      );
    }

    // 6. Sprinkler coverage preview & Hover highlight
    if (isInSprinklerPreview || isHovered) {
      _topFacePath
        ..reset()
        ..moveTo(topX, topY)
        ..lineTo(rightX, rightY)
        ..lineTo(bottomX, bottomY)
        ..lineTo(leftX, leftY)
        ..close();
    }

    if (isInSprinklerPreview) {
      canvas.drawPath(_topFacePath, _sprinklerFillPaint);
      final pulse = 0.65 + 0.35 * math.sin(animTime * 4.5);
      _sprinklerStrokePaint.color = Color.fromRGBO(
        2,
        136,
        209,
        0.72 * pulse,
      );
      canvas.drawPath(_topFacePath, _sprinklerStrokePaint);
    }

    if (isHovered) {
      canvas.save();
      canvas.translate(cx, cy);
      _hoverFillPaint.shader = hoverValid
          ? _hoverGlowValidShader
          : _hoverGlowInvalidShader;
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 78, height: 39),
        _hoverFillPaint,
      );
      canvas.restore();

      final pulse = 0.72 + 0.28 * math.sin(animTime * 5.2);
      _hoverStrokePaint.color = hoverValid
          ? Color.fromRGBO(255, 241, 118, 0.92 * pulse)
          : Color.fromRGBO(229, 57, 53, 0.92 * pulse);
      canvas.drawPath(_topFacePath, _hoverStrokePaint);
    }
  }

  void _blitTileSurface(
    Canvas canvas,
    double cx,
    double cy,
    GridPos pos,
    TileState tile,
  ) {
    final hash = (pos.x * 31 + pos.y * 17).abs();
    final lw = _cache.logicalWidth;
    final lh = _cache.logicalHeight;
    final src = Rect.fromLTWH(
      0,
      0,
      lw * PainterlyCache.oversample,
      lh * PainterlyCache.oversample,
    );
    final dst = Rect.fromCenter(
      center: Offset(cx, cy),
      width: lw,
      height: lh,
    );

    switch (tile.ground) {
      case GroundType.grass:
        final img = _cache.grassVariants[hash % _cache.grassVariants.length];
        canvas.drawImageRect(img, src, dst, _tileBlitPaint);
      case GroundType.weeds:
        final img = _cache.weedsVariants[hash % _cache.weedsVariants.length];
        canvas.drawImageRect(img, src, dst, _tileBlitPaint);
      case GroundType.stonePath:
        final img =
            _cache.stonePathVariants[hash % _cache.stonePathVariants.length];
        canvas.drawImageRect(img, src, dst, _tileBlitPaint);
      case GroundType.cobbleLane:
        final img =
            _cache.cobbleLaneVariants[hash % _cache.cobbleLaneVariants.length];
        canvas.drawImageRect(img, src, dst, _tileBlitPaint);
      case GroundType.soil:
        final m = tile.moisture.clamp(0.0, 1.0);
        if (m < 0.5) {
          final t = (m * 2.0).clamp(0.0, 1.0);
          canvas.drawImageRect(_cache.soilVariants[0], src, dst, _tileBlitPaint);
          if (t > 0.04) {
            _soilBlendPaint.color = Color.fromRGBO(255, 255, 255, t);
            canvas.drawImageRect(
              _cache.soilVariants[1],
              src,
              dst,
              _soilBlendPaint,
            );
          }
        } else {
          final t = ((m - 0.5) * 2.0).clamp(0.0, 1.0);
          canvas.drawImageRect(_cache.soilVariants[1], src, dst, _tileBlitPaint);
          if (t > 0.04) {
            _soilBlendPaint.color = Color.fromRGBO(255, 255, 255, t);
            canvas.drawImageRect(
              _cache.soilVariants[2],
              src,
              dst,
              _soilBlendPaint,
            );
          }
        }
    }
  }

  void _drawAutoTiledSoilBorders(
    Canvas canvas, {
    required GridPos pos,
    required List<TileState> tiles,
    required int gridSize,
    required double topX,
    required double topY,
    required double rightX,
    required double rightY,
    required double bottomX,
    required double bottomY,
    required double leftX,
    required double leftY,
  }) {
    bool isSoil(int x, int y) {
      if (x < 0 || y < 0 || x >= gridSize || y >= gridSize) return false;
      return tiles[y * gridSize + x].ground == GroundType.soil;
    }

    bool isGrass(int x, int y) {
      if (x < 0 || y < 0 || x >= gridSize || y >= gridSize) return false;
      final g = tiles[y * gridSize + x].ground;
      return g == GroundType.grass || g == GroundType.weeds;
    }

    // NW edge borders neighbor (x - 1, y)
    if (!isSoil(pos.x - 1, pos.y)) {
      canvas.drawLine(
        Offset(leftX + 2, leftY - 1),
        Offset(topX - 2, topY + 1),
        _soilEdgeShadowPaint,
      );
    }
    // NE edge borders neighbor (x, y - 1)
    if (!isSoil(pos.x, pos.y - 1)) {
      canvas.drawLine(
        Offset(topX + 2, topY + 1),
        Offset(rightX - 2, rightY - 1),
        _soilEdgeShadowPaint,
      );
    }
    // SE edge borders neighbor (x + 1, y)
    if (!isSoil(pos.x + 1, pos.y)) {
      canvas.drawLine(
        Offset(rightX - 2, rightY + 1),
        Offset(bottomX + 2, bottomY - 1),
        _soilEdgeRimPaint,
      );
      if (isGrass(pos.x + 1, pos.y)) {
        final mx = (rightX + bottomX) * 0.5;
        final my = (rightY + bottomY) * 0.5;
        _grassBladePaint.color = const Color(0xFF5D9E2E);
        canvas.drawLine(Offset(mx, my), Offset(mx - 2, my - 3.5), _grassBladePaint);
      }
    }
    // SW edge borders neighbor (x, y + 1)
    if (!isSoil(pos.x, pos.y + 1)) {
      canvas.drawLine(
        Offset(bottomX - 2, bottomY - 1),
        Offset(leftX + 2, leftY + 1),
        _soilEdgeRimPaint,
      );
      if (isGrass(pos.x, pos.y + 1)) {
        final mx = (bottomX + leftX) * 0.5;
        final my = (bottomY + leftY) * 0.5;
        _grassBladePaint.color = const Color(0xFF689F38);
        canvas.drawLine(Offset(mx, my), Offset(mx + 2, my - 3.5), _grassBladePaint);
      }
    }
  }

  void _drawStonePathBridges(
    Canvas canvas, {
    required GridPos pos,
    required List<TileState> tiles,
    required int gridSize,
    required double rightX,
    required double rightY,
    required double bottomX,
    required double bottomY,
    required double leftX,
    required double leftY,
  }) {
    bool isPath(int x, int y) {
      if (x < 0 || y < 0 || x >= gridSize || y >= gridSize) return false;
      final g = tiles[y * gridSize + x].ground;
      return g == GroundType.stonePath || g == GroundType.cobbleLane;
    }

    void drawBridgeSeam(Offset pA, Offset pB) {
      final mid = Offset((pA.dx + pB.dx) * 0.5, (pA.dy + pB.dy) * 0.5);
      // Warm footpath sand cushion joining adjacent stone path diamonds
      _cliffDetailPaint.color = const Color(0x88BEA47E);
      canvas.drawOval(
        Rect.fromCenter(center: mid, width: 28, height: 14),
        _cliffDetailPaint,
      );

      for (final o in const <({double dx, double dy, double w, double h, int c})>[
        (dx: -5.5, dy: -2.0, w: 12.5, h: 7.2, c: 0xFFF0DCB8),
        (dx: 5.5, dy: 2.2, w: 11.0, h: 6.5, c: 0xFFE3C89E),
      ]) {
        final rr = RRect.fromRectAndRadius(
          Rect.fromCenter(center: mid.translate(o.dx, o.dy), width: o.w, height: o.h),
          const Radius.circular(3.5),
        );
        _cliffDetailPaint.color = const Color(0x284E342E);
        canvas.drawRRect(rr.shift(const Offset(0.6, 1.1)), _cliffDetailPaint);
        _cliffDetailPaint.color = Color(o.c);
        canvas.drawRRect(rr, _cliffDetailPaint);
        _cliffStrokePaint
          ..color = const Color(0x886D523A)
          ..strokeWidth = 0.95;
        canvas.drawRRect(rr, _cliffStrokePaint);
      }
    }

    if (isPath(pos.x + 1, pos.y)) {
      drawBridgeSeam(Offset(rightX, rightY), Offset(bottomX, bottomY));
    }
    if (isPath(pos.x, pos.y + 1)) {
      drawBridgeSeam(Offset(bottomX, bottomY), Offset(leftX, leftY));
    }
  }

  void _drawLaneWelcomePost(Canvas canvas, double leftX, double leftY) {
    final px = leftX + 7;
    final py = leftY - 2;
    _fenceShadePaint
      ..color = const Color(0xFF5D4037)
      ..strokeWidth = 4.2;
    canvas.drawLine(Offset(px, py + 1), Offset(px, py - 19), _fenceShadePaint);
    _fenceWoodPaint.strokeWidth = 2.8;
    canvas.drawLine(Offset(px, py - 16), Offset(px + 9, py - 19), _fenceWoodPaint);
    _turfPaint.color = const Color(0xFFFFCA28);
    canvas.drawCircle(Offset(px + 8, py - 14), 3.0, _turfPaint);
    _turfPaint.color = const Color(0xFFEC407A);
    canvas.drawCircle(Offset(px + 6.5, py - 15), 1.6, _turfPaint);
  }

  void _drawIslandCornerFoliage(
    Canvas canvas, {
    required GridPos pos,
    required int gridSize,
    required double leftX,
    required double leftY,
    required double bottomX,
    required double bottomY,
    required double rightX,
    required double rightY,
    required double animTime,
  }) {
    final sway = math.sin(animTime * 1.4 + pos.x + pos.y) * 1.2;
    if (pos.x == 0 && pos.y == gridSize - 1) {
      // West island corner wildflower & shrub spill
      _turfPaint.color = const Color(0xFF2E7D32);
      canvas.drawCircle(Offset(leftX + 5, leftY + 2), 6.2, _turfPaint);
      _turfPaint.color = const Color(0xFF66BB6A);
      canvas.drawCircle(Offset(leftX + 3, leftY - 1), 4.8, _turfPaint);
      _turfPaint.color = const Color(0xFFFF80AB);
      canvas.drawCircle(Offset(leftX + 2 + sway * 0.4, leftY - 2), 2.3, _turfPaint);
      _turfPaint.color = const Color(0xFFFFF59D);
      canvas.drawCircle(Offset(leftX + 6, leftY + 1), 1.8, _turfPaint);
    } else if (pos.x == gridSize - 1 && pos.y == 0) {
      // East island corner shrub spill
      _turfPaint.color = const Color(0xFF2E7D32);
      canvas.drawCircle(Offset(rightX - 4, rightY + 2), 5.8, _turfPaint);
      _turfPaint.color = const Color(0xFF66BB6A);
      canvas.drawCircle(Offset(rightX - 2, rightY - 1), 4.2, _turfPaint);
      _turfPaint.color = const Color(0xFFFFEE58);
      canvas.drawCircle(Offset(rightX - 2 + sway * 0.3, rightY - 2), 2.0, _turfPaint);
    } else if (pos.x == gridSize - 1 && pos.y == gridSize - 1) {
      // South front tip corner bush + 3 gently bobbing floating rock pebbles below cliff
      _turfPaint.color = const Color(0xFF2E7D32);
      canvas.drawCircle(Offset(bottomX, bottomY + 3), 5.6, _turfPaint);
      _turfPaint.color = const Color(0xFF66BB6A);
      canvas.drawCircle(Offset(bottomX - 1, bottomY + 1), 4.2, _turfPaint);
      _turfPaint.color = const Color(0xFFFF8A80);
      canvas.drawCircle(Offset(bottomX + sway * 0.3, bottomY), 2.2, _turfPaint);

      final tipBottomY = bottomY + 64.0;
      for (var i = 0; i < 3; i++) {
        final bob = math.sin(animTime * 1.4 + i * 2.1) * 2.2;
        final rx = bottomX + (i - 1) * 14.0;
        final ry = tipBottomY + 10.0 + (i == 1 ? 6.0 : 0.0) + bob;
        _cliffDetailPaint.color = i.isEven
            ? const Color(0xFF7D503C)
            : const Color(0xFF613B2F);
        canvas.drawOval(
          Rect.fromCenter(center: Offset(rx, ry), width: 7.5 - i * 1.0, height: 5.0 - i * 0.6),
          _cliffDetailPaint,
        );
      }
    }
  }

  void _drawSculptedLeftCliff(
    Canvas canvas, {
    required double cx,
    required double cy,
    required double leftX,
    required double leftY,
    required double bottomX,
    required double bottomY,
    required double d0,
    required double d1,
    required GridPos pos,
    required TileState tile,
    required double animTime,
  }) {
    final hash = pos.x * 23 + pos.y * 19;
    final midX1 = leftX + (bottomX - leftX) * 0.34;
    final midY1 = leftY + (bottomY - leftY) * 0.34;
    final midX2 = leftX + (bottomX - leftX) * 0.68;
    final midY2 = leftY + (bottomY - leftY) * 0.68;
    final jag1 = ((hash % 5) - 2) * 2.2;
    final jag2 = (((hash + 2) % 5) - 2) * 2.4;

    _leftFacePath
      ..reset()
      ..moveTo(leftX, leftY)
      ..lineTo(bottomX, bottomY)
      ..lineTo(bottomX, bottomY + d1)
      ..lineTo(midX2, midY2 + (d0 * 0.32 + d1 * 0.68) + jag2)
      ..lineTo(midX1, midY1 + (d0 * 0.66 + d1 * 0.34) + jag1)
      ..lineTo(leftX, leftY + d0)
      ..close();

    canvas.save();
    canvas.translate(cx, cy);
    canvas.clipPath(_leftFacePath.shift(Offset(-cx, -cy)));
    _bevelPaint
      ..shader = _leftCliffShader
      ..color = const Color(0xFFFFFFFF);
    canvas.drawRect(const Rect.fromLTWH(-52, 0, 56, 104), _bevelPaint);
    _bevelPaint.shader = null;

    // Geological horizontal-sloped rock strata bands
    _cliffStrataPath
      ..reset()
      ..moveTo(-50, 14)
      ..lineTo(2, 38)
      ..lineTo(2, 52)
      ..lineTo(-50, 28)
      ..close();
    _cliffDetailPaint.color = const Color(0x2AFFE0B2);
    canvas.drawPath(_cliffStrataPath, _cliffDetailPaint);

    _cliffStrataPath
      ..reset()
      ..moveTo(-50, 30)
      ..lineTo(2, 54)
      ..lineTo(2, 82)
      ..lineTo(-50, 62)
      ..close();
    _cliffDetailPaint.color = const Color(0x363E2723);
    canvas.drawPath(_cliffStrataPath, _cliffDetailPaint);

    // Embedded cliff stones & chiseled rock crevices
    _cliffDetailPaint.color = const Color(0x445D4037);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-28 + (hash % 7).toDouble(), 24 + (hash % 5).toDouble()),
        width: 14,
        height: 8,
      ),
      _cliffDetailPaint,
    );
    _cliffDetailPaint.color = const Color(0x30FFE0B2);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-29 + (hash % 7).toDouble(), 22.5 + (hash % 5).toDouble()),
        width: 11,
        height: 4,
      ),
      _cliffDetailPaint,
    );
    _cliffStrokePaint
      ..color = const Color(0x443E2723)
      ..strokeWidth = 1.4;
    canvas.drawLine(
      Offset(-16, 18),
      Offset(-12 + (hash % 4).toDouble(), 39),
      _cliffStrokePaint,
    );

    canvas.restore();

    // Only draw vertical cliff corner crease at the front-most island tip
    if (pos.x == pos.y) {
      _cliffStrokePaint
        ..color = const Color(0x4D3E2723)
        ..strokeWidth = 1.3;
      canvas.drawLine(
        Offset(bottomX, bottomY),
        Offset(bottomX, bottomY + d1),
        _cliffStrokePaint,
      );
    }

    // Overhanging lush turf lip (on grass, weeds, and path edges)
    if (tile.ground != GroundType.soil) {
      _drawLeftTurfOverhang(
        canvas,
        leftX: leftX,
        leftY: leftY,
        bottomX: bottomX,
        bottomY: bottomY,
        seed: hash,
        animTime: animTime,
      );
    }
  }

  void _drawSculptedRightCliff(
    Canvas canvas, {
    required double cx,
    required double cy,
    required double bottomX,
    required double bottomY,
    required double rightX,
    required double rightY,
    required double d0,
    required double d1,
    required GridPos pos,
    required TileState tile,
    required double animTime,
  }) {
    final hash = pos.x * 17 + pos.y * 29;
    final midX1 = bottomX + (rightX - bottomX) * 0.34;
    final midY1 = bottomY + (rightY - bottomY) * 0.34;
    final midX2 = bottomX + (rightX - bottomX) * 0.68;
    final midY2 = bottomY + (rightY - bottomY) * 0.68;
    final jag1 = ((hash % 5) - 2) * 2.2;
    final jag2 = (((hash + 3) % 5) - 2) * 2.4;

    _rightFacePath
      ..reset()
      ..moveTo(bottomX, bottomY)
      ..lineTo(rightX, rightY)
      ..lineTo(rightX, rightY + d0)
      ..lineTo(midX2, midY2 + (d0 * 0.68 + d1 * 0.32) + jag2)
      ..lineTo(midX1, midY1 + (d0 * 0.34 + d1 * 0.66) + jag1)
      ..lineTo(bottomX, bottomY + d1)
      ..close();

    canvas.save();
    canvas.translate(cx, cy);
    canvas.clipPath(_rightFacePath.shift(Offset(-cx, -cy)));
    _bevelPaint
      ..shader = _rightCliffShader
      ..color = const Color(0xFFFFFFFF);
    canvas.drawRect(const Rect.fromLTWH(-2, 0, 56, 104), _bevelPaint);
    _bevelPaint.shader = null;

    // Cooler indigo-plum deep rock strata on shaded SE face
    _cliffStrataPath
      ..reset()
      ..moveTo(-2, 36)
      ..lineTo(50, 12)
      ..lineTo(50, 26)
      ..lineTo(-2, 50)
      ..close();
    _cliffDetailPaint.color = const Color(0x22D7CCC8);
    canvas.drawPath(_cliffStrataPath, _cliffDetailPaint);

    _cliffDetailPaint.color = const Color(0x3D261412);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(24 - (hash % 6).toDouble(), 28 + (hash % 5).toDouble()),
        width: 14,
        height: 8,
      ),
      _cliffDetailPaint,
    );
    _cliffStrokePaint
      ..color = const Color(0x4D261412)
      ..strokeWidth = 1.4;
    canvas.drawLine(
      Offset(15, 22),
      Offset(19 - (hash % 4).toDouble(), 44),
      _cliffStrokePaint,
    );

    canvas.restore();

    if (tile.ground != GroundType.soil) {
      _drawRightTurfOverhang(
        canvas,
        bottomX: bottomX,
        bottomY: bottomY,
        rightX: rightX,
        rightY: rightY,
        seed: hash,
        animTime: animTime,
      );
    }
  }

  void _drawLeftTurfOverhang(
    Canvas canvas, {
    required double leftX,
    required double leftY,
    required double bottomX,
    required double bottomY,
    required int seed,
    required double animTime,
  }) {
    final dx = bottomX - leftX;
    final dy = bottomY - leftY;
    final p1x = leftX + dx * 0.25;
    final p1y = leftY + dy * 0.25;
    final p2x = leftX + dx * 0.52;
    final p2y = leftY + dy * 0.52;
    final p3x = leftX + dx * 0.78;
    final p3y = leftY + dy * 0.78;

    // Soft cast shadow beneath overhanging grass
    _turfLipPath
      ..reset()
      ..moveTo(leftX, leftY + 1.5)
      ..lineTo(bottomX, bottomY + 1.5)
      ..lineTo(bottomX, bottomY + 10.5)
      ..quadraticBezierTo(p3x, p3y + 15.5, p2x, p2y + 11.5)
      ..quadraticBezierTo(p1x, p1y + 15.0, leftX, leftY + 10.5)
      ..close();
    _turfPaint.color = const Color(0x4D261412);
    canvas.drawPath(_turfLipPath, _turfPaint);

    // Rich green turf lip
    _turfLipPath
      ..reset()
      ..moveTo(leftX, leftY)
      ..lineTo(bottomX, bottomY)
      ..lineTo(bottomX, bottomY + 8.0)
      ..quadraticBezierTo(p3x, p3y + 12.8, p2x, p2y + 8.8)
      ..quadraticBezierTo(p1x, p1y + 12.8, leftX, leftY + 8.0)
      ..close();
    _turfPaint.color = const Color(0xFF60A330);
    canvas.drawPath(_turfLipPath, _turfPaint);

    // Sunlit lime highlight crest along top edge
    _turfRimPaint
      ..color = const Color(0xB3B2EB6E)
      ..strokeWidth = 1.8;
    canvas.drawLine(Offset(leftX + 1, leftY + 0.5), Offset(bottomX - 1, bottomY + 0.5), _turfRimPaint);

    // Swaying hanging ivy vine & cliff blossoms
    if (seed % 2 == 0) {
      final vx = p2x - 2;
      final vy = p2y + 8.5;
      final len = 16.0 + (seed % 4) * 3.5;
      final sway = math.sin(animTime * 1.45 + seed * 0.7) * 2.5;
      _vinePath
        ..reset()
        ..moveTo(vx, vy)
        ..quadraticBezierTo(vx + sway * 0.6, vy + len * 0.55, vx + sway, vy + len);
      _turfRimPaint
        ..color = const Color(0xFF33691E)
        ..strokeWidth = 1.9;
      canvas.drawPath(_vinePath, _turfRimPaint);

      _turfPaint.color = const Color(0xFF7CB342);
      canvas.drawCircle(Offset(vx - 2.6 + sway * 0.35, vy + len * 0.36), 2.6, _turfPaint);
      canvas.drawCircle(Offset(vx + 2.6 + sway * 0.7, vy + len * 0.66), 2.5, _turfPaint);
      canvas.drawCircle(Offset(vx + sway, vy + len), 2.7, _turfPaint);

      if (seed % 4 == 0) {
        _turfPaint.color = const Color(0xFFFF80AB);
        canvas.drawCircle(Offset(p1x, p1y + 7.2), 2.8, _turfPaint);
        _turfPaint.color = const Color(0xFFFFF59D);
        canvas.drawCircle(Offset(p1x, p1y + 7.2), 1.2, _turfPaint);
      }
    }
  }

  void _drawRightTurfOverhang(
    Canvas canvas, {
    required double bottomX,
    required double bottomY,
    required double rightX,
    required double rightY,
    required int seed,
    required double animTime,
  }) {
    final dx = rightX - bottomX;
    final dy = rightY - bottomY;
    final p1x = bottomX + dx * 0.25;
    final p1y = bottomY + dy * 0.25;
    final p2x = bottomX + dx * 0.52;
    final p2y = bottomY + dy * 0.52;
    final p3x = bottomX + dx * 0.78;
    final p3y = bottomY + dy * 0.78;

    _turfLipPath
      ..reset()
      ..moveTo(bottomX, bottomY + 1.5)
      ..lineTo(rightX, rightY + 1.5)
      ..lineTo(rightX, rightY + 8.5)
      ..quadraticBezierTo(p3x, p3y + 12.0, p2x, p2y + 9.0)
      ..quadraticBezierTo(p1x, p1y + 12.5, bottomX, bottomY + 9.0)
      ..close();
    _turfPaint.color = const Color(0x441B0E0C);
    canvas.drawPath(_turfLipPath, _turfPaint);

    _turfLipPath
      ..reset()
      ..moveTo(bottomX, bottomY)
      ..lineTo(rightX, rightY)
      ..lineTo(rightX, rightY + 6.0)
      ..quadraticBezierTo(p3x, p3y + 9.5, p2x, p2y + 6.5)
      ..quadraticBezierTo(p1x, p1y + 10.0, bottomX, bottomY + 6.5)
      ..close();
    _turfPaint.color = const Color(0xFF447B23);
    canvas.drawPath(_turfLipPath, _turfPaint);

    if (seed % 2 == 1) {
      final vx = p2x;
      final vy = p2y + 7.0;
      final len = 12.0 + (seed % 3) * 3.5;
      final sway = math.sin(animTime * 1.35 + seed * 0.9) * 2.2;
      _vinePath
        ..reset()
        ..moveTo(vx, vy)
        ..quadraticBezierTo(vx + sway * 0.6, vy + len * 0.5, vx + sway, vy + len);
      _turfRimPaint
        ..color = const Color(0xFF285517)
        ..strokeWidth = 1.6;
      canvas.drawPath(_vinePath, _turfRimPaint);

      _turfPaint.color = const Color(0xFF4F8929);
      canvas.drawCircle(Offset(vx + 2.0 + sway * 0.4, vy + len * 0.4), 2.0, _turfPaint);
      canvas.drawCircle(Offset(vx - 1.8 + sway * 0.75, vy + len * 0.72), 1.9, _turfPaint);

      if (seed % 3 == 0) {
        _turfPaint.color = const Color(0xFFF48FB1);
        canvas.drawCircle(Offset(p3x, p3y + 5.5), 2.2, _turfPaint);
      }
    }
  }

  void _drawNorthwestRimFence(
    Canvas canvas,
    double leftX,
    double leftY,
    double topX,
    double topY,
    GridPos pos,
  ) {
    final mx = (leftX + topX) * 0.5;
    final my = (leftY + topY) * 0.5;

    // Subtle fence shadow on grass
    _fenceShadePaint.strokeWidth = 3.0;
    canvas.drawLine(
      Offset(leftX + 3, leftY + 1),
      Offset(topX + 3, topY + 1),
      _fenceShadePaint..color = const Color(0x22000000),
    );

    // Rail bars
    _fenceWoodPaint.strokeWidth = 2.4;
    canvas.drawLine(Offset(leftX + 1, leftY - 4.5), Offset(topX - 1, topY - 4.5), _fenceWoodPaint);
    canvas.drawLine(Offset(leftX + 1, leftY - 9.0), Offset(topX - 1, topY - 9.0), _fenceWoodPaint);
    canvas.drawLine(Offset(leftX + 1, leftY - 9.6), Offset(topX - 1, topY - 9.6), _fenceHighlightPaint);

    // Fence posts
    _fenceShadePaint
      ..color = const Color(0xFF6D4C41)
      ..strokeWidth = 3.6;
    canvas.drawLine(Offset(leftX + 2, leftY + 0.5), Offset(leftX + 2, leftY - 12.5), _fenceShadePaint);
    canvas.drawLine(Offset(mx, my + 0.5), Offset(mx, my - 12.5), _fenceShadePaint);
    _fenceWoodPaint.strokeWidth = 2.6;
    canvas.drawLine(Offset(leftX + 1.5, leftY), Offset(leftX + 1.5, leftY - 12.5), _fenceWoodPaint);
    canvas.drawLine(Offset(mx - 0.5, my), Offset(mx - 0.5, my - 12.5), _fenceWoodPaint);
  }

  void _drawDynamicSoilDetails(
    Canvas canvas,
    double cx,
    double cy,
    GridPos pos,
    TileState tile,
    double animTime,
  ) {
    if (tile.moisture > 0.45) {
      final shimmer = 0.5 + 0.5 * math.sin(animTime * 2.2 + pos.x + pos.y);
      _moistureSheenPaint.color = Color.fromRGBO(
        255,
        248,
        225,
        0.10 + 0.14 * shimmer,
      );
      canvas.drawLine(
        Offset(cx - 11.0, cy - 6.0),
        Offset(cx + 8.0, cy + 3.0),
        _moistureSheenPaint,
      );
    }

    if (tile.fertilized) {
      final glint = 0.65 + 0.35 * math.sin(animTime * 3.4 + pos.x * 1.3 + pos.y);
      _sparklePaint.color = Color.fromRGBO(255, 224, 130, glint);
      canvas.drawCircle(Offset(cx - 14, cy - 2), 2.1, _sparklePaint);
      canvas.drawCircle(Offset(cx + 12, cy + 4), 2.1, _sparklePaint);
      canvas.drawCircle(Offset(cx + 2, cy - 8), 1.8, _sparklePaint);
      canvas.drawCircle(Offset(cx - 5, cy + 9), 1.8, _sparklePaint);
    }
  }

  void _drawDynamicWeedDetails(
    Canvas canvas,
    double cx,
    double cy,
    GridPos pos,
    double animTime,
  ) {
    final sway = math.sin(animTime * 1.6 + pos.x * 0.9 + pos.y * 0.7) * 1.8;
    void drawFern(double bx, double by, double scale) {
      _weedLeafPaint.color = const Color(0xFF2E6B1E);
      canvas.drawLine(Offset(bx, by), Offset(bx - 6 * scale + sway * 0.6, by - 9 * scale), _weedLeafPaint);
      canvas.drawLine(Offset(bx, by), Offset(bx + 6 * scale + sway * 0.6, by - 8 * scale), _weedLeafPaint);
      _weedLeafPaint.color = const Color(0xFF558B2F);
      canvas.drawLine(Offset(bx, by), Offset(bx + sway, by - 12 * scale), _weedLeafPaint);
    }

    drawFern(cx - 11, cy + 2, 1.0);
    drawFern(cx + 10, cy - 3, 0.92);
    drawFern(cx - 1, cy + 7, 1.05);

    // Cheerful golden wildflower / dandelion puff
    canvas.drawCircle(Offset(cx + 10 + sway * 0.5, cy - 13), 3.3, _dandelionPaint);
    canvas.drawCircle(Offset(cx + 10 + sway * 0.5, cy - 13), 1.3, _dandelionCenterPaint);
  }

  void _drawDynamicGrassAccent(
    Canvas canvas,
    double cx,
    double cy,
    GridPos pos,
    double animTime,
  ) {
    final hash = pos.x * 7 + pos.y * 13;
    if (hash % 3 != 0) return;
    final sway = math.sin(animTime * 1.4 + pos.x * 0.8 + pos.y * 0.6) * 1.7;
    _grassBladePaint.color = const Color(0xFF558B2F);
    canvas.drawLine(
      Offset(cx - 4, cy + 2),
      Offset(cx - 6.5 + sway, cy - 4.5),
      _grassBladePaint,
    );
    _grassBladePaint.color = const Color(0xFF7CB342);
    canvas.drawLine(
      Offset(cx - 1, cy + 2),
      Offset(cx + 1.5 + sway, cy - 5.5),
      _grassBladePaint,
    );
    if ((pos.x + pos.y) % 4 == 0) {
      canvas.drawCircle(
        Offset(cx + 8 + sway * 0.4, cy + 3),
        2.1,
        _grassFlowerPaint,
      );
    }
  }

  Color _innerLeftBevelColor(GroundType ground) => switch (ground) {
        GroundType.soil => const Color(0xFF78513E),
        GroundType.cobbleLane => const Color(0xFF8C7E76),
        GroundType.grass ||
        GroundType.weeds ||
        GroundType.stonePath => const Color(0xFF6B9E38),
      };

  Color _innerRightBevelColor(GroundType ground) => switch (ground) {
        GroundType.soil => const Color(0xFF593B2C),
        GroundType.cobbleLane => const Color(0xFF6D615B),
        GroundType.grass ||
        GroundType.weeds ||
        GroundType.stonePath => const Color(0xFF528029),
      };

  /// Active sprinkler radius (`0`, `1`, or `2`) when placing a sprinkler in
  /// `ToolMode.build`.
  int sprinklerPreviewRadius(GameState state) {
    if (state.activeTool != ToolMode.build) return 0;
    return SolvilleCatalog
            .buildItems[state.selectedBuildItem]
            ?.sprinklerRadius ??
        0;
  }

  /// Helper computing whether [pos] falls inside the sprinkler preview when
  /// placing a sprinkler in `ToolMode.build`.
  bool isInSprinklerPreview(GameState state, GridPos? hovered, GridPos pos) {
    if (hovered == null) return false;
    final radius = sprinklerPreviewRadius(state);
    if (radius <= 0) return false;
    return hovered.chebyshevDistanceTo(pos) <= radius;
  }

  void dispose() {
    if (_ownsCache) {
      _cache.dispose();
    }
  }
}
