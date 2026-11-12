import 'dart:math' as math;
import 'dart:ui';

import '../../domain/iso/iso_projection.dart';
import '../../domain/models/catalog.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/grid_pos.dart';
import '../../domain/models/tile_state.dart';

/// Renders 2.5D bevelled isometric terrain blocks, soil furrows, paths, and
/// tile selection / sprinkler radius highlights.
///
/// Reuses [Path] and [Paint] instances across all tiles to avoid per-frame
/// object allocations on large (`35×35`) grids.
class IsoPrismPainter {
  IsoPrismPainter(this.iso);

  final IsoProjection iso;

  final Path _leftFacePath = Path();
  final Path _rightFacePath = Path();
  final Path _topFacePath = Path();

  final Paint _leftBevelPaint = Paint();
  final Paint _rightBevelPaint = Paint();
  final Paint _topFacePaint = Paint();
  final Paint _topBorderPaint = Paint()
    ..color = const Color(0x22000000)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;

  final Paint _furrowPaint = Paint()
    ..strokeWidth = 2.4
    ..strokeCap = StrokeCap.round;
  final Paint _sparklePaint = Paint()..color = const Color(0xFFFFD54F);

  final Paint _stoneFillPaint = Paint()..color = const Color(0xFFF3E2C7);
  final Paint _stoneOutlinePaint = Paint()
    ..color = const Color(0xFFB59A78)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2;

  final Paint _cobblePaint = Paint()..color = const Color(0xFFBCAAA4);

  final Paint _weedLeafPaint = Paint()
    ..color = const Color(0xFF33691E)
    ..strokeWidth = 2.6
    ..strokeCap = StrokeCap.round;
  final Paint _dandelionPaint = Paint()..color = const Color(0xFFFFEE58);

  final Paint _grassBladePaint = Paint()
    ..color = const Color(0xFF689F38)
    ..strokeWidth = 1.8
    ..strokeCap = StrokeCap.round;
  final Paint _grassFlowerPaint = Paint()..color = const Color(0xFFFFF9C4);
  final Paint _moistureSheenPaint = Paint()
    ..color = const Color(0x1EFFFFFF)
    ..strokeWidth = 1.2
    ..strokeCap = StrokeCap.round;
  final Paint _pebblePaint = Paint()..color = const Color(0x285D4037);

  final Paint _sprinklerFillPaint = Paint()..color = const Color(0x4429B6F6);
  final Paint _sprinklerStrokePaint = Paint()
    ..color = const Color(0xAA0288D1)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;

  final Paint _hoverFillPaint = Paint()..color = const Color(0x28FFF59D);
  final Paint _hoverStrokePaint = Paint()
    ..color = const Color(0xFFFFF176)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.6;
  final Paint _hoverInvalidFillPaint = Paint()..color = const Color(0x2AEF5350);
  final Paint _hoverInvalidStrokePaint = Paint()
    ..color = const Color(0xFFE53935)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.6;

  final Path _islandShadowPath = Path();
  final Paint _islandShadowOuterPaint = Paint()..color = const Color(0x161A237E);
  final Paint _islandShadowInnerPaint = Paint()..color = const Color(0x241A237E);

  /// Draws a soft two-layered floating-island drop shadow beneath the entire
  /// isometric grid, subtly shifting with the sun angle across the day.
  void drawIslandDropShadow(
    Canvas canvas,
    int gridSize,
    double dayProgress,
  ) {
    final hw = iso.tileWidth * 0.5;
    final hh = iso.tileHeight * 0.5;
    final sunOffsetX = (dayProgress - 0.45) * 16.0;

    final topX = sunOffsetX;
    final topY = -hh + 42.0;
    final rightX = gridSize * hw + sunOffsetX;
    final rightY = (gridSize - 1) * hh + 42.0;
    final bottomX = sunOffsetX;
    final bottomY = (2 * gridSize - 1) * hh + 48.0;
    final leftX = -gridSize * hw + sunOffsetX;
    final leftY = (gridSize - 1) * hh + 42.0;

    _islandShadowPath
      ..reset()
      ..moveTo(topX, topY - 10.0)
      ..lineTo(rightX + 20.0, rightY + 4.0)
      ..lineTo(bottomX, bottomY + 18.0)
      ..lineTo(leftX - 20.0, leftY + 4.0)
      ..close();
    canvas.drawPath(_islandShadowPath, _islandShadowOuterPaint);

    _islandShadowPath
      ..reset()
      ..moveTo(topX, topY - 2.0)
      ..lineTo(rightX + 8.0, rightY + 2.0)
      ..lineTo(bottomX, bottomY + 6.0)
      ..lineTo(leftX - 8.0, leftY + 2.0)
      ..close();
    canvas.drawPath(_islandShadowPath, _islandShadowInnerPaint);
  }

  void drawTilePrism(
    Canvas canvas, {
    required GridPos pos,
    required TileState tile,
    required int gridSize,
    required bool isHovered,
    required bool isInSprinklerPreview,
    required double animTime,
    bool hoverValid = true,
  }) {
    final center = iso.tileCenterToWorld(pos);
    final cx = center.x;
    final cy = center.y;
    final hw = iso.tileWidth * 0.5;
    final hh = iso.tileHeight * 0.5;

    final isFrontEdge = pos.x == gridSize - 1 || pos.y == gridSize - 1;
    final bevelDepth = (isFrontEdge || tile.ground != GroundType.soil)
        ? (isFrontEdge ? 34.0 : 14.0)
        : 12.0;

    final topX = cx;
    final topY = cy - hh;
    final rightX = cx + hw;
    final rightY = cy;
    final bottomX = cx;
    final bottomY = cy + hh;
    final leftX = cx - hw;
    final leftY = cy;

    final colors = _resolveBlockColors(pos, tile);

    // Left bevel face (sunlit warm earth)
    _leftFacePath
      ..reset()
      ..moveTo(leftX, leftY)
      ..lineTo(bottomX, bottomY)
      ..lineTo(bottomX, bottomY + bevelDepth)
      ..lineTo(leftX, leftY + bevelDepth)
      ..close();
    _leftBevelPaint.color = colors.leftBevel;
    canvas.drawPath(_leftFacePath, _leftBevelPaint);

    // Right bevel face (deeper terracotta shadow)
    _rightFacePath
      ..reset()
      ..moveTo(bottomX, bottomY)
      ..lineTo(rightX, rightY)
      ..lineTo(rightX, rightY + bevelDepth)
      ..lineTo(bottomX, bottomY + bevelDepth)
      ..close();
    _rightBevelPaint.color = colors.rightBevel;
    canvas.drawPath(_rightFacePath, _rightBevelPaint);

    // Top diamond face
    _topFacePath
      ..reset()
      ..moveTo(topX, topY)
      ..lineTo(rightX, rightY)
      ..lineTo(bottomX, bottomY)
      ..lineTo(leftX, leftY)
      ..close();
    _topFacePaint.color = colors.top;
    canvas.drawPath(_topFacePath, _topFacePaint);

    // Subtle crisp tile border
    canvas.drawPath(_topFacePath, _topBorderPaint);

    // Surface texture details
    switch (tile.ground) {
      case GroundType.soil:
        _drawSoilDetails(canvas, cx, cy, tile);
      case GroundType.stonePath:
        _drawStonePathDetails(canvas, cx, cy);
      case GroundType.cobbleLane:
        _drawCobbleDetails(canvas, cx, cy);
      case GroundType.weeds:
        _drawWeedDetails(canvas, cx, cy);
      case GroundType.grass:
        _drawGrassAccent(canvas, cx, cy, pos, animTime);
    }

    // Sprinkler coverage preview overlay
    if (isInSprinklerPreview) {
      canvas.drawPath(_topFacePath, _sprinklerFillPaint);
      canvas.drawPath(_topFacePath, _sprinklerStrokePaint);
    }

    // Hover highlight diamond
    if (isHovered) {
      canvas.drawPath(
        _topFacePath,
        hoverValid ? _hoverFillPaint : _hoverInvalidFillPaint,
      );
      canvas.drawPath(
        _topFacePath,
        hoverValid ? _hoverStrokePaint : _hoverInvalidStrokePaint,
      );
    }
  }

  ({Color top, Color leftBevel, Color rightBevel}) _resolveBlockColors(
    GridPos pos,
    TileState tile,
  ) {
    final checker = (pos.x + pos.y).isEven;
    switch (tile.ground) {
      case GroundType.grass:
        return (
          top: checker ? const Color(0xFF7CB342) : const Color(0xFF86BC4B),
          leftBevel: const Color(0xFF8D6E63),
          rightBevel: const Color(0xFF6D4C41),
        );
      case GroundType.weeds:
        return (
          top: checker ? const Color(0xFF689F38) : const Color(0xFF71A840),
          leftBevel: const Color(0xFF8D6E63),
          rightBevel: const Color(0xFF6D4C41),
        );
      case GroundType.soil:
        // Interpolate dry warm loam -> deep hydrated espresso brown
        final m = tile.moisture.clamp(0.0, 1.0);
        final top = Color.lerp(
          const Color(0xFFA9744F),
          const Color(0xFF5D3A24),
          m,
        )!;
        return (
          top: top,
          leftBevel: const Color(0xFF795548),
          rightBevel: const Color(0xFF5D4037),
        );
      case GroundType.stonePath:
        return (
          top: checker ? const Color(0xFFE6CEAC) : const Color(0xFFDEC39D),
          leftBevel: const Color(0xFF9E866B),
          rightBevel: const Color(0xFF7D6850),
        );
      case GroundType.cobbleLane:
        return (
          top: checker ? const Color(0xFFD7CCC8) : const Color(0xFFCBC0BC),
          leftBevel: const Color(0xFF8D827E),
          rightBevel: const Color(0xFF6E6562),
        );
    }
  }

  void _drawSoilDetails(Canvas canvas, double cx, double cy, TileState tile) {
    _furrowPaint.color = Color.lerp(
      const Color(0xFF8A5A3B),
      const Color(0xFF3E2516),
      tile.moisture.clamp(0.0, 1.0),
    )!;

    for (final offset in const <double>[-10.0, 0.0, 10.0]) {
      canvas.drawLine(
        Offset(cx - 18.0 + offset * 0.6, cy - 5.0 + offset * 0.5),
        Offset(cx + 12.0 + offset * 0.6, cy + 9.0 + offset * 0.5),
        _furrowPaint,
      );
    }

    if (tile.moisture > 0.35) {
      canvas.drawLine(
        Offset(cx - 12.0, cy - 6.0),
        Offset(cx + 8.0, cy + 3.5),
        _moistureSheenPaint,
      );
      canvas.drawLine(
        Offset(cx - 6.0, cy + 1.0),
        Offset(cx + 12.0, cy + 9.5),
        _moistureSheenPaint,
      );
    }

    if (tile.fertilized) {
      canvas.drawCircle(Offset(cx - 14, cy - 2), 2.1, _sparklePaint);
      canvas.drawCircle(Offset(cx + 11, cy + 4), 2.1, _sparklePaint);
      canvas.drawCircle(Offset(cx + 2, cy - 8), 1.8, _sparklePaint);
      canvas.drawCircle(Offset(cx - 4, cy + 9), 1.8, _sparklePaint);
    }
  }

  void _drawStonePathDetails(Canvas canvas, double cx, double cy) {
    const r = Radius.circular(4);
    final s1 = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx - 11, cy - 3), width: 15, height: 8),
      r,
    );
    final s2 = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx + 9, cy - 5), width: 14, height: 7),
      r,
    );
    final s3 = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx + 2, cy + 5), width: 17, height: 8),
      r,
    );

    canvas.drawRRect(s1, _stoneFillPaint);
    canvas.drawRRect(s1, _stoneOutlinePaint);
    canvas.drawRRect(s2, _stoneFillPaint);
    canvas.drawRRect(s2, _stoneOutlinePaint);
    canvas.drawRRect(s3, _stoneFillPaint);
    canvas.drawRRect(s3, _stoneOutlinePaint);
  }

  void _drawCobbleDetails(Canvas canvas, double cx, double cy) {
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - 12, cy), width: 12, height: 6),
      _cobblePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + 10, cy - 3), width: 13, height: 6),
      _cobblePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + 2, cy + 6), width: 11, height: 5),
      _cobblePaint,
    );
  }

  void _drawWeedDetails(Canvas canvas, double cx, double cy) {
    void drawCluster(double bx, double by) {
      final base = Offset(bx, by);
      canvas.drawLine(base, Offset(bx - 6, by - 9), _weedLeafPaint);
      canvas.drawLine(base, Offset(bx, by - 11), _weedLeafPaint);
      canvas.drawLine(base, Offset(bx + 6, by - 8), _weedLeafPaint);
    }

    drawCluster(cx - 10, cy + 2);
    drawCluster(cx + 9, cy - 3);
    drawCluster(cx - 1, cy + 7);

    // Wild yellow dandelion dot
    canvas.drawCircle(Offset(cx + 9, cy - 14), 3.0, _dandelionPaint);
  }

  void _drawGrassAccent(
    Canvas canvas,
    double cx,
    double cy,
    GridPos pos,
    double animTime,
  ) {
    final hash = pos.x * 7 + pos.y * 13;
    if (hash % 7 == 0) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx - 10, cy + 4), width: 4.5, height: 2.5),
        _pebblePaint,
      );
    }
    if (hash % 4 != 0) return;
    final sway = math.sin(animTime * 2.2 + pos.x * 0.8 + pos.y * 0.6) * 1.5;
    canvas.drawLine(
      Offset(cx - 4, cy + 2),
      Offset(cx - 6 + sway, cy - 4),
      _grassBladePaint,
    );
    canvas.drawLine(
      Offset(cx - 1, cy + 2),
      Offset(cx + 1 + sway, cy - 5),
      _grassBladePaint,
    );
    if ((pos.x + pos.y) % 3 == 0) {
      canvas.drawCircle(
        Offset(cx + 8 + sway * 0.4, cy + 3),
        2.0,
        _grassFlowerPaint,
      );
    }
  }

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
}
