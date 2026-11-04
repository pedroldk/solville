import 'dart:ui';

import '../../domain/iso/iso_projection.dart';
import '../../domain/models/catalog.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/grid_pos.dart';
import '../../domain/models/tile_state.dart';

/// Renders 2.5D bevelled isometric terrain blocks, soil furrows, paths, and
/// tile selection / sprinkler radius highlights.
class IsoPrismPainter {
  const IsoPrismPainter(this.iso);

  final IsoProjection iso;

  void drawTilePrism(
    Canvas canvas, {
    required GridPos pos,
    required TileState tile,
    required int gridSize,
    required bool isHovered,
    required bool isInSprinklerPreview,
    required double animTime,
  }) {
    final center = iso.tileCenterToWorld(pos);
    final hw = iso.tileWidth * 0.5;
    final hh = iso.tileHeight * 0.5;

    final isFrontEdge = pos.x == gridSize - 1 || pos.y == gridSize - 1;
    final depth = isFrontEdge ? 34.0 : 14.0;

    final topPt = Offset(center.x, center.y - hh);
    final rightPt = Offset(center.x + hw, center.y);
    final bottomPt = Offset(center.x, center.y + hh);
    final leftPt = Offset(center.x - hw, center.y);

    final colors = _resolveBlockColors(pos, tile);

    // Left bevel face (sunlit warm earth)
    if (isFrontEdge || tile.ground != GroundType.soil) {
      final leftFace = Path()
        ..moveTo(leftPt.dx, leftPt.dy)
        ..lineTo(bottomPt.dx, bottomPt.dy)
        ..lineTo(bottomPt.dx, bottomPt.dy + depth)
        ..lineTo(leftPt.dx, leftPt.dy + depth)
        ..close();
      canvas.drawPath(leftFace, Paint()..color = colors.leftBevel);

      // Right bevel face (deeper terracotta shadow)
      final rightFace = Path()
        ..moveTo(bottomPt.dx, bottomPt.dy)
        ..lineTo(rightPt.dx, rightPt.dy)
        ..lineTo(rightPt.dx, rightPt.dy + depth)
        ..lineTo(bottomPt.dx, bottomPt.dy + depth)
        ..close();
      canvas.drawPath(rightFace, Paint()..color = colors.rightBevel);
    } else {
      // Slightly recessed garden bed lip
      final leftFace = Path()
        ..moveTo(leftPt.dx, leftPt.dy)
        ..lineTo(bottomPt.dx, bottomPt.dy)
        ..lineTo(bottomPt.dx, bottomPt.dy + 12.0)
        ..lineTo(leftPt.dx, leftPt.dy + 12.0)
        ..close();
      canvas.drawPath(leftFace, Paint()..color = colors.leftBevel);

      final rightFace = Path()
        ..moveTo(bottomPt.dx, bottomPt.dy)
        ..lineTo(rightPt.dx, rightPt.dy)
        ..lineTo(rightPt.dx, rightPt.dy + 12.0)
        ..lineTo(bottomPt.dx, bottomPt.dy + 12.0)
        ..close();
      canvas.drawPath(rightFace, Paint()..color = colors.rightBevel);
    }

    // Top diamond face
    final topFace = Path()
      ..moveTo(topPt.dx, topPt.dy)
      ..lineTo(rightPt.dx, rightPt.dy)
      ..lineTo(bottomPt.dx, bottomPt.dy)
      ..lineTo(leftPt.dx, leftPt.dy)
      ..close();
    canvas.drawPath(topFace, Paint()..color = colors.top);

    // Subtle crisp tile border
    canvas.drawPath(
      topFace,
      Paint()
        ..color = const Color(0x22000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Surface texture details
    switch (tile.ground) {
      case GroundType.soil:
        _drawSoilDetails(canvas, center.x, center.y, tile);
      case GroundType.stonePath:
        _drawStonePathDetails(canvas, center.x, center.y);
      case GroundType.cobbleLane:
        _drawCobbleDetails(canvas, center.x, center.y);
      case GroundType.weeds:
        _drawWeedDetails(canvas, center.x, center.y, pos);
      case GroundType.grass:
        _drawGrassAccent(canvas, center.x, center.y, pos);
    }

    // Sprinkler coverage preview overlay
    if (isInSprinklerPreview) {
      canvas.drawPath(
        topFace,
        Paint()..color = const Color(0x4429B6F6),
      );
      canvas.drawPath(
        topFace,
        Paint()
          ..color = const Color(0xAA0288D1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
    }

    // Hover highlight diamond
    if (isHovered) {
      canvas.drawPath(
        topFace,
        Paint()..color = const Color(0x28FFF59D),
      );
      canvas.drawPath(
        topFace,
        Paint()
          ..color = const Color(0xFFFFF176)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6,
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

  void _drawSoilDetails(
    Canvas canvas,
    double cx,
    double cy,
    TileState tile,
  ) {
    final furrowColor = Color.lerp(
      const Color(0xFF8A5A3B),
      const Color(0xFF3E2516),
      tile.moisture.clamp(0.0, 1.0),
    )!;
    final furrowPaint = Paint()
      ..color = furrowColor
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    for (final offset in const <double>[-10.0, 0.0, 10.0]) {
      canvas.drawLine(
        Offset(cx - 18.0 + offset * 0.6, cy - 5.0 + offset * 0.5),
        Offset(cx + 12.0 + offset * 0.6, cy + 9.0 + offset * 0.5),
        furrowPaint,
      );
    }

    if (tile.fertilized) {
      final sparklePaint = Paint()..color = const Color(0xFFFFD54F);
      canvas.drawCircle(Offset(cx - 14, cy - 2), 2.1, sparklePaint);
      canvas.drawCircle(Offset(cx + 11, cy + 4), 2.1, sparklePaint);
      canvas.drawCircle(Offset(cx + 2, cy - 8), 1.8, sparklePaint);
      canvas.drawCircle(Offset(cx - 4, cy + 9), 1.8, sparklePaint);
    }
  }

  void _drawStonePathDetails(Canvas canvas, double cx, double cy) {
    final stonePaint = Paint()..color = const Color(0xFFF3E2C7);
    final outline = Paint()
      ..color = const Color(0xFFB59A78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final stones = <RRect>[
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx - 11, cy - 3), width: 15, height: 8),
        const Radius.circular(4),
      ),
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx + 9, cy - 5), width: 14, height: 7),
        const Radius.circular(4),
      ),
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx + 2, cy + 5), width: 17, height: 8),
        const Radius.circular(4),
      ),
    ];
    for (final s in stones) {
      canvas.drawRRect(s, stonePaint);
      canvas.drawRRect(s, outline);
    }
  }

  void _drawCobbleDetails(Canvas canvas, double cx, double cy) {
    final cobblePaint = Paint()..color = const Color(0xFFBCAAA4);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - 12, cy), width: 12, height: 6),
      cobblePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + 10, cy - 3), width: 13, height: 6),
      cobblePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + 2, cy + 6), width: 11, height: 5),
      cobblePaint,
    );
  }

  void _drawWeedDetails(Canvas canvas, double cx, double cy, GridPos pos) {
    final leafPaint = Paint()
      ..color = const Color(0xFF33691E)
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;

    final clusters = <Offset>[
      Offset(cx - 10, cy + 2),
      Offset(cx + 9, cy - 3),
      Offset(cx - 1, cy + 7),
    ];
    for (final base in clusters) {
      canvas.drawLine(base, base + const Offset(-6, -9), leafPaint);
      canvas.drawLine(base, base + const Offset(0, -11), leafPaint);
      canvas.drawLine(base, base + const Offset(6, -8), leafPaint);
    }
    // Wild yellow dandelion dot
    canvas.drawCircle(
      Offset(cx + 9, cy - 14),
      3.0,
      Paint()..color = const Color(0xFFFFEE58),
    );
  }

  void _drawGrassAccent(Canvas canvas, double cx, double cy, GridPos pos) {
    if ((pos.x * 7 + pos.y * 13) % 4 != 0) return;
    final bladePaint = Paint()
      ..color = const Color(0xFF689F38)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx - 4, cy + 2), Offset(cx - 6, cy - 4), bladePaint);
    canvas.drawLine(Offset(cx - 1, cy + 2), Offset(cx + 1, cy - 5), bladePaint);
    if ((pos.x + pos.y) % 3 == 0) {
      canvas.drawCircle(
        Offset(cx + 8, cy + 3),
        2.0,
        Paint()..color = const Color(0xFFFFF9C4),
      );
    }
  }

  /// Helper computing whether [pos] falls inside the sprinkler preview when
  /// placing a sprinkler in `ToolMode.build`.
  bool isInSprinklerPreview(GameState state, GridPos? hovered, GridPos pos) {
    if (hovered == null || state.activeTool != ToolMode.build) return false;
    final item = SolvilleCatalog.buildItems[state.selectedBuildItem];
    if (item == null || item.sprinklerRadius <= 0) return false;
    return hovered.chebyshevDistanceTo(pos) <= item.sprinklerRadius;
  }
}
