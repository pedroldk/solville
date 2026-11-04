import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/painting.dart'
    show FontWeight, TextDirection, TextPainter, TextSpan, TextStyle;

import '../../domain/iso/iso_projection.dart';
import '../../domain/models/catalog.dart';
import '../../domain/models/grid_pos.dart';
import '../../domain/models/market_state.dart';
import '../../domain/models/tile_state.dart';

/// Renders 2.5D farm landmarks, multi-stage crops, sprinklers, orchard trees,
/// artisan kettles, animal pens, wooden crates, and Action Queue markers.
class StructuresAndCropsPainter {
  const StructuresAndCropsPainter(this.iso);

  final IsoProjection iso;

  void drawTileContents(
    Canvas canvas, {
    required GridPos pos,
    required TileState tile,
    required MarketState market,
    required int totalBarnCrates,
    required double dayProgress,
    required double animTime,
  }) {
    final center = iso.tileCenterToWorld(pos);
    final cx = center.x;
    final cy = center.y;

    // Scenic cypress bushes & fence posts along the northern village lane
    if (pos.y == 0 && tile.structure == StructureType.none) {
      _drawLaneScenery(canvas, cx, cy, pos, animTime);
    }

    switch (tile.structure) {
      case StructureType.farmhouse:
        _drawFarmhouse(canvas, cx, cy, dayProgress, animTime);
      case StructureType.well:
        _drawStoneWell(canvas, cx, cy, animTime);
      case StructureType.barn:
        _drawBarn(canvas, cx, cy, totalBarnCrates);
      case StructureType.marketStall:
        _drawMarketStall(canvas, cx, cy, market.stallCrates, animTime);
      case StructureType.sprinklerRotary:
        _drawRotarySprinkler(canvas, cx, cy, animTime);
      case StructureType.sprinklerSolar:
        _drawSolarSprinkler(canvas, cx, cy, animTime);
      case StructureType.lemonTree:
        _drawLemonTree(canvas, cx, cy, pos, tile, animTime);
      case StructureType.artisanPress:
        _drawArtisanPress(canvas, cx, cy, tile, animTime);
      case StructureType.henhouse:
        _drawHenhouse(canvas, cx, cy, tile.animal, animTime);
      case StructureType.beehive:
        _drawBeehive(canvas, cx, cy, tile.animal, animTime);
      case StructureType.cowPaddock:
        _drawCowPaddock(canvas, cx, cy, tile.animal, animTime);
      case StructureType.lantern:
        _drawSolarLantern(canvas, cx, cy, dayProgress, animTime);
      case StructureType.flowerArch:
        _drawFlowerArch(canvas, cx, cy, animTime);
      case StructureType.none:
        break;
    }

    if (tile.crop != null) {
      _drawPlantedCrop(
        canvas,
        cx,
        cy,
        pos,
        tile.crop!,
        tile.moisture,
        animTime,
      );
    }

    if (tile.droppedCrate != null) {
      drawWoodenCrate(
        canvas,
        Offset(cx + 10, cy + 4),
        tile.droppedCrate!,
        scale: 0.95,
      );
    }
  }

  void drawQueueMarkers(
    Canvas canvas,
    GridPos pos,
    List<int> stepNumbers,
    double animTime,
  ) {
    if (stepNumbers.isEmpty) return;
    final center = iso.tileCenterToWorld(pos);
    final bob = math.sin(animTime * 4.5 + pos.x) * 3.0;
    final label = stepNumbers.join(',');
    final badgeCenter = Offset(center.x, center.y - 34.0 + bob);

    canvas.drawLine(
      Offset(center.x, center.y - 8),
      Offset(badgeCenter.dx, badgeCenter.dy + 10),
      Paint()
        ..color = const Color(0xCCFFF8E1)
        ..strokeWidth = 2.0,
    );

    final badgeWidth = label.length > 2 ? 32.0 : 24.0;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: badgeCenter, width: badgeWidth, height: 22),
      const Radius.circular(11),
    );
    canvas.drawRRect(
      rrect.shift(const Offset(0, 2)),
      Paint()..color = const Color(0x44000000),
    );
    canvas.drawRRect(rrect, Paint()..color = const Color(0xFFFFCA28));
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = const Color(0xFF5D4037)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    _drawCenteredText(
      canvas,
      label,
      badgeCenter,
      const TextStyle(
        color: Color(0xFF3E2723),
        fontSize: 11.5,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  void drawWoodenCrate(
    Canvas canvas,
    Offset center,
    ProductId product, {
    double scale = 1.0,
  }) {
    final w = 22.0 * scale;
    final h = 16.0 * scale;
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: w, height: h),
      Radius.circular(3.5 * scale),
    );
    canvas.drawRRect(
      rect.shift(Offset(0, 2 * scale)),
      Paint()..color = const Color(0x38000000),
    );
    canvas.drawRRect(rect, Paint()..color = const Color(0xFFD7995B));
    canvas.drawRRect(
      rect,
      Paint()
        ..color = const Color(0xFF6D4C41)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6 * scale,
    );
    canvas.drawLine(
      Offset(center.dx - w * 0.45, center.dy + 2 * scale),
      Offset(center.dx + w * 0.45, center.dy + 2 * scale),
      Paint()
        ..color = const Color(0xFF8D6E63)
        ..strokeWidth = 1.2 * scale,
    );

    final dotColor = _productColor(product);
    canvas.drawCircle(
      Offset(center.dx - 4 * scale, center.dy - 3 * scale),
      4.2 * scale,
      Paint()..color = dotColor,
    );
    canvas.drawCircle(
      Offset(center.dx + 4 * scale, center.dy - 3 * scale),
      4.2 * scale,
      Paint()..color = dotColor,
    );
  }

  // ---------------------------------------------------------------------------
  // Village Lane Scenery & Landmarks
  // ---------------------------------------------------------------------------

  void _drawLaneScenery(
    Canvas canvas,
    double cx,
    double cy,
    GridPos pos,
    double animTime,
  ) {
    // Low split-rail wooden post along back edge of cobble road
    if (pos.x.isEven && pos.x != 4 && pos.x != 6) {
      final sway = math.sin(animTime * 1.8 + pos.x) * 1.5;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx + 14, cy - 11), width: 18, height: 9),
        Paint()..color = const Color(0x28000000),
      );
      // Mediterranean mini cypress shrub
      final cypress = Path()
        ..moveTo(cx + 7, cy - 11)
        ..quadraticBezierTo(cx + 14 + sway, cy - 38, cx + 14 + sway, cy - 40)
        ..quadraticBezierTo(cx + 21 + sway, cy - 24, cx + 21, cy - 11)
        ..close();
      canvas.drawPath(cypress, Paint()..color = const Color(0xFF2E7D32));
    }
  }

  void _drawFarmhouse(
    Canvas canvas,
    double cx,
    double cy,
    double dayProgress,
    double animTime,
  ) {
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 4), width: 76, height: 36),
      Paint()..color = const Color(0x33000000),
    );

    final leftWall = Path()
      ..moveTo(cx - 30, cy - 4)
      ..lineTo(cx, cy + 12)
      ..lineTo(cx, cy - 26)
      ..lineTo(cx - 30, cy - 42)
      ..close();
    canvas.drawPath(leftWall, Paint()..color = const Color(0xFFFFF3E0));

    final rightWall = Path()
      ..moveTo(cx, cy + 12)
      ..lineTo(cx + 30, cy - 4)
      ..lineTo(cx + 30, cy - 42)
      ..lineTo(cx, cy - 26)
      ..close();
    canvas.drawPath(rightWall, Paint()..color = const Color(0xFFFFE0B2));

    final door = RRect.fromRectAndCorners(
      Rect.fromLTWH(cx + 9, cy - 18, 11, 20),
      topLeft: const Radius.circular(6),
      topRight: const Radius.circular(6),
    );
    canvas.drawRRect(door, Paint()..color = const Color(0xFF795548));

    final isEvening = dayProgress > 0.60;
    if (isEvening) {
      canvas.drawCircle(
        Offset(cx - 15, cy - 18),
        16,
        Paint()..color = const Color(0x38FFD54F),
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx - 15, cy - 18),
          width: 11,
          height: 11,
        ),
        const Radius.circular(3),
      ),
      Paint()
        ..color = isEvening
            ? const Color(0xFFFFD54F)
            : const Color(0xFF81D4FA),
    );

    canvas.drawRect(
      Rect.fromLTWH(cx - 20, cy - 64, 9, 18),
      Paint()..color = const Color(0xFFA1887F),
    );
    final puffPhase = (animTime * 0.7) % 1.0;
    canvas.drawCircle(
      Offset(cx - 15 + puffPhase * 6, cy - 68 - puffPhase * 16),
      4.5 * (1.0 - puffPhase * 0.4),
      Paint()..color = Color.fromRGBO(255, 255, 255, (1.0 - puffPhase) * 0.65),
    );

    final roofLeft = Path()
      ..moveTo(cx - 35, cy - 39)
      ..lineTo(cx, cy - 22)
      ..lineTo(cx, cy - 56)
      ..close();
    canvas.drawPath(roofLeft, Paint()..color = const Color(0xFFD84315));

    final roofRight = Path()
      ..moveTo(cx, cy - 22)
      ..lineTo(cx + 35, cy - 39)
      ..lineTo(cx, cy - 56)
      ..close();
    canvas.drawPath(roofRight, Paint()..color = const Color(0xFFBF360C));
  }

  void _drawStoneWell(Canvas canvas, double cx, double cy, double animTime) {
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 4), width: 52, height: 26),
      Paint()..color = const Color(0x33000000),
    );

    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy - 4), width: 42, height: 22),
      const Radius.circular(10),
    );
    canvas.drawRRect(body, Paint()..color = const Color(0xFF90A4AE));
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy - 13), width: 42, height: 18),
      Paint()..color = const Color(0xFFB0BEC5),
    );

    final shimmer = (math.sin(animTime * 3.2) + 1.0) * 0.5;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy - 13), width: 30, height: 12),
      Paint()
        ..color = Color.lerp(
          const Color(0xFF0288D1),
          const Color(0xFF4FC3F7),
          shimmer,
        )!,
    );

    final postPaint = Paint()
      ..color = const Color(0xFF6D4C41)
      ..strokeWidth = 3.5;
    canvas.drawLine(
      Offset(cx - 15, cy - 14),
      Offset(cx - 15, cy - 40),
      postPaint,
    );
    canvas.drawLine(
      Offset(cx + 15, cy - 14),
      Offset(cx + 15, cy - 40),
      postPaint,
    );

    final roof = Path()
      ..moveTo(cx - 24, cy - 36)
      ..lineTo(cx, cy - 50)
      ..lineTo(cx + 24, cy - 36)
      ..close();
    canvas.drawPath(roof, Paint()..color = const Color(0xFF8D6E63));
  }

  void _drawBarn(Canvas canvas, double cx, double cy, int totalBarnCrates) {
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 5), width: 74, height: 34),
      Paint()..color = const Color(0x33000000),
    );

    final leftWall = Path()
      ..moveTo(cx - 28, cy - 3)
      ..lineTo(cx, cy + 12)
      ..lineTo(cx, cy - 26)
      ..lineTo(cx - 28, cy - 40)
      ..close();
    canvas.drawPath(leftWall, Paint()..color = const Color(0xFFC62828));

    final rightWall = Path()
      ..moveTo(cx, cy + 12)
      ..lineTo(cx + 28, cy - 3)
      ..lineTo(cx + 28, cy - 40)
      ..lineTo(cx, cy - 26)
      ..close();
    canvas.drawPath(rightWall, Paint()..color = const Color(0xFFA31D1D));

    final trim = Paint()
      ..color = const Color(0xFFFFF8E1)
      ..strokeWidth = 2.4;
    canvas.drawRect(
      Rect.fromLTWH(cx + 6, cy - 20, 16, 22),
      Paint()
        ..color = const Color(0xFFFFF8E1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
    canvas.drawLine(Offset(cx + 6, cy - 20), Offset(cx + 22, cy + 2), trim);
    canvas.drawLine(Offset(cx + 22, cy - 20), Offset(cx + 6, cy + 2), trim);

    final roof = Path()
      ..moveTo(cx - 33, cy - 38)
      ..lineTo(cx, cy - 58)
      ..lineTo(cx + 33, cy - 38)
      ..lineTo(cx, cy - 23)
      ..close();
    canvas.drawPath(roof, Paint()..color = const Color(0xFF5D4037));

    if (totalBarnCrates > 0) {
      _drawFloatingStatusPill(canvas, cx, cy - 66, '📦 $totalBarnCrates');
    }
  }

  void _drawMarketStall(
    Canvas canvas,
    double cx,
    double cy,
    List<ProductId> stallCrates,
    double animTime,
  ) {
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 5), width: 78, height: 34),
      Paint()..color = const Color(0x33000000),
    );

    final counter = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy - 4), width: 58, height: 22),
      const Radius.circular(6),
    );
    canvas.drawRRect(counter, Paint()..color = const Color(0xFFA1693A));
    canvas.drawRRect(
      counter,
      Paint()
        ..color = const Color(0xFF5D4037)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    for (var i = 0; i < stallCrates.length && i < 6; i++) {
      final row = i ~/ 3;
      final col = i % 3;
      drawWoodenCrate(
        canvas,
        Offset(cx - 16 + col * 16.0, cy - 14 - row * 9.0),
        stallCrates[i],
        scale: 0.66,
      );
    }

    final polePaint = Paint()
      ..color = const Color(0xFF6D4C41)
      ..strokeWidth = 3.2;
    canvas.drawLine(
      Offset(cx - 25, cy - 12),
      Offset(cx - 25, cy - 44),
      polePaint,
    );
    canvas.drawLine(
      Offset(cx + 25, cy - 12),
      Offset(cx + 25, cy - 44),
      polePaint,
    );

    const stripeCount = 5;
    const totalW = 60.0;
    const stripeW = totalW / stripeCount;
    for (var i = 0; i < stripeCount; i++) {
      final sx = cx - totalW * 0.5 + i * stripeW;
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(sx, cy - 52, stripeW + 0.5, 15),
          bottomLeft: const Radius.circular(4),
          bottomRight: const Radius.circular(4),
        ),
        Paint()
          ..color = i.isEven
              ? const Color(0xFFE53935)
              : const Color(0xFFFFF8E1),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Orchard Lemon Tree, Artisan Kettle, Automation & Animals
  // ---------------------------------------------------------------------------

  void _drawLemonTree(
    Canvas canvas,
    double cx,
    double cy,
    GridPos pos,
    TileState tile,
    double time,
  ) {
    final sway = math.sin(time * 2.1 + pos.x) * 2.4;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 4), width: 46, height: 22),
      Paint()..color = const Color(0x33000000),
    );
    // Terracotta orchard border ring
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 1), width: 32, height: 15),
      Paint()
        ..color = const Color(0xFFD84315)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6,
    );
    // Trunk
    canvas.drawLine(
      Offset(cx, cy + 1),
      Offset(cx + sway * 0.25, cy - 22),
      Paint()
        ..color = const Color(0xFF6D4C41)
        ..strokeWidth = 6.0
        ..strokeCap = StrokeCap.round,
    );

    // Lush layered Mediterranean canopy
    canvas.drawCircle(
      Offset(cx - 9 + sway, cy - 28),
      13.5,
      Paint()..color = const Color(0xFF388E3C),
    );
    canvas.drawCircle(
      Offset(cx + 9 + sway, cy - 27),
      13.5,
      Paint()..color = const Color(0xFF2E7D32),
    );
    canvas.drawCircle(
      Offset(cx + sway, cy - 35),
      15.5,
      Paint()..color = const Color(0xFF43A047),
    );

    // Bright yellow lemons when maturing or ready!
    if (tile.producerCrates > 0 || tile.producerProgress > 0.45) {
      final r = tile.producerCrates > 0 ? 3.8 : 2.6;
      final lemonPaint = Paint()..color = const Color(0xFFFFEE58);
      canvas.drawCircle(Offset(cx - 8 + sway, cy - 28), r, lemonPaint);
      canvas.drawCircle(Offset(cx + 7 + sway, cy - 30), r, lemonPaint);
      canvas.drawCircle(Offset(cx + 1 + sway, cy - 39), r, lemonPaint);
      canvas.drawCircle(Offset(cx + 9 + sway, cy - 22), r, lemonPaint);
    }

    if (tile.producerCrates > 0) {
      _drawFloatingStatusPill(
        canvas,
        cx,
        cy - 58,
        '🍋 ${tile.producerCrates}',
      );
    }
  }

  void _drawArtisanPress(
    Canvas canvas,
    double cx,
    double cy,
    TileState tile,
    double time,
  ) {
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 4), width: 52, height: 24),
      Paint()..color = const Color(0x36000000),
    );

    // Warm stone hearth base
    final hearth = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy - 4), width: 38, height: 18),
      const Radius.circular(7),
    );
    canvas.drawRRect(hearth, Paint()..color = const Color(0xFF8D6E63));

    if (tile.producerActive) {
      final glow = (math.sin(time * 6.0) + 1.0) * 0.5;
      canvas.drawCircle(
        Offset(cx, cy + 1),
        6.0 + glow * 2.0,
        Paint()..color = const Color(0xCCFF7043),
      );
    }

    // Gleaming copper preserves kettle
    final kettle = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy - 17), width: 30, height: 20),
      const Radius.circular(9),
    );
    canvas.drawRRect(kettle, Paint()..color = const Color(0xFFD87A3B));
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy - 25), width: 26, height: 10),
      Paint()
        ..color = tile.producerActive
            ? const Color(0xFFC2185B)
            : const Color(0xFF5D4037),
    );

    // Rising fragrant steam bubbles while simmering!
    if (tile.producerActive) {
      for (var s = 0; s < 2; s++) {
        final phase = ((time * 0.9 + s * 0.5) % 1.0);
        canvas.drawCircle(
          Offset(cx - 4 + s * 8.0, cy - 30 - phase * 18.0),
          3.6 * (1.0 - phase * 0.35),
          Paint()..color = Color.fromRGBO(255, 248, 225, (1.0 - phase) * 0.75),
        );
      }
    }

    if (tile.producerCrates > 0) {
      _drawFloatingStatusPill(
        canvas,
        cx,
        cy - 46,
        '🫙 ${tile.producerCrates}',
      );
    }
  }

  void _drawRotarySprinkler(Canvas canvas, double cx, double cy, double time) {
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 2), width: 24, height: 12),
      Paint()..color = const Color(0x33000000),
    );
    canvas.drawCircle(
      Offset(cx, cy),
      9,
      Paint()..color = const Color(0xFF546E7A),
    );
    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx, cy - 13),
      Paint()
        ..color = const Color(0xFFCFD8DC)
        ..strokeWidth = 4.0,
    );
    final angle = time * 4.5;
    final dx = math.cos(angle) * 11.0;
    final dy = math.sin(angle) * 5.5;
    canvas.drawLine(
      Offset(cx - dx, cy - 13 - dy),
      Offset(cx + dx, cy - 13 + dy),
      Paint()
        ..color = const Color(0xFF29B6F6)
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawSolarSprinkler(Canvas canvas, double cx, double cy, double time) {
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 2), width: 30, height: 15),
      Paint()..color = const Color(0x38000000),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy - 11), width: 12, height: 24),
        const Radius.circular(5),
      ),
      Paint()..color = const Color(0xFFFFB300),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy - 25), width: 24, height: 11),
      Paint()..color = const Color(0xFF1565C0),
    );
    final pulse = (math.sin(time * 3.8) + 1) * 0.5;
    canvas.drawCircle(
      Offset(cx, cy - 16),
      5.0 + pulse * 3.0,
      Paint()..color = const Color(0x664FC3F7),
    );
  }

  void _drawHenhouse(
    Canvas canvas,
    double cx,
    double cy,
    AnimalUnitState? state,
    double time,
  ) {
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 4), width: 56, height: 26),
      Paint()..color = const Color(0x30000000),
    );
    final coop = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx - 6, cy - 12), width: 32, height: 22),
      const Radius.circular(5),
    );
    canvas.drawRRect(coop, Paint()..color = const Color(0xFFD7A86E));
    final roof = Path()
      ..moveTo(cx - 26, cy - 21)
      ..lineTo(cx - 6, cy - 35)
      ..lineTo(cx + 14, cy - 21)
      ..close();
    canvas.drawPath(roof, Paint()..color = const Color(0xFFE65100));

    final peck = math.sin(time * 5.0).abs() * 3.0;
    for (final (ox, oy, col) in <(double, double, Color)>[
      (12.0, 2.0, const Color(0xFFFFFFFF)),
      (2.0, 8.0, const Color(0xFFFFCC80)),
    ]) {
      canvas.drawCircle(Offset(cx + ox, cy + oy), 5.5, Paint()..color = col);
      canvas.drawCircle(
        Offset(cx + ox + 4, cy + oy - 3 + peck),
        3.2,
        Paint()..color = col,
      );
      canvas.drawCircle(
        Offset(cx + ox + 4, cy + oy - 6 + peck),
        1.8,
        Paint()..color = const Color(0xFFE53935),
      );
    }

    _drawAnimalStatusBubble(canvas, cx, cy - 44, state, '🥚');
  }

  void _drawBeehive(
    Canvas canvas,
    double cx,
    double cy,
    AnimalUnitState? state,
    double time,
  ) {
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 3), width: 42, height: 20),
      Paint()..color = const Color(0x30000000),
    );
    for (var i = 0; i < 3; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(cx, cy - 5 - i * 8.0),
            width: 28 - i * 4.0,
            height: 9,
          ),
          const Radius.circular(5),
        ),
        Paint()
          ..color = i.isEven
              ? const Color(0xFFFFCA28)
              : const Color(0xFFFFB300),
      );
    }
    canvas.drawCircle(
      Offset(cx, cy - 6),
      3.2,
      Paint()..color = const Color(0xFF3E2723),
    );

    for (var b = 0; b < 3; b++) {
      final a = time * 3.6 + b * 2.1;
      final bx = cx + math.cos(a) * 18.0;
      final by = cy - 16.0 + math.sin(a * 1.5) * 7.0;
      canvas.drawCircle(
        Offset(bx, by),
        2.5,
        Paint()..color = const Color(0xFFFFEE58),
      );
    }

    _drawAnimalStatusBubble(canvas, cx, cy - 40, state, '🍯');
  }

  void _drawCowPaddock(
    Canvas canvas,
    double cx,
    double cy,
    AnimalUnitState? state,
    double time,
  ) {
    final fencePaint = Paint()
      ..color = const Color(0xFF8D6E63)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy - 2), width: 64, height: 30),
      fencePaint,
    );

    final sway = math.sin(time * 2.2) * 2.0;
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx - 2 + sway, cy - 10),
        width: 26,
        height: 15,
      ),
      const Radius.circular(7),
    );
    canvas.drawRRect(bodyRect, Paint()..color = const Color(0xFFFAFAFA));
    canvas.drawCircle(
      Offset(cx - 5 + sway, cy - 11),
      4.2,
      Paint()..color = const Color(0xFF3E2723),
    );
    canvas.drawCircle(
      Offset(cx + 4 + sway, cy - 8),
      3.2,
      Paint()..color = const Color(0xFF3E2723),
    );
    canvas.drawCircle(
      Offset(cx + 12 + sway, cy - 14),
      6.0,
      Paint()..color = const Color(0xFFFAFAFA),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + 14 + sway, cy - 12),
        width: 7,
        height: 4.5,
      ),
      Paint()..color = const Color(0xFFF48FB1),
    );

    _drawAnimalStatusBubble(canvas, cx, cy - 38, state, '🥛');
  }

  void _drawFloatingStatusPill(
    Canvas canvas,
    double x,
    double y,
    String text,
  ) {
    final r = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(x, y), width: 40, height: 20),
      const Radius.circular(10),
    );
    canvas.drawRRect(r, Paint()..color = const Color(0xFFFFF8E1));
    canvas.drawRRect(
      r,
      Paint()
        ..color = const Color(0xFFFFB300)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
    _drawCenteredText(
      canvas,
      text,
      Offset(x, y),
      const TextStyle(
        color: Color(0xFF3E2723),
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  void _drawAnimalStatusBubble(
    Canvas canvas,
    double x,
    double y,
    AnimalUnitState? state,
    String readyEmoji,
  ) {
    if (state == null) return;
    if (state.readyCrates > 0) {
      _drawFloatingStatusPill(
        canvas,
        x,
        y,
        '$readyEmoji${state.readyCrates}',
      );
    } else if (state.needsTending) {
      final r = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, y), width: 26, height: 19),
        const Radius.circular(9),
      );
      canvas.drawRRect(r, Paint()..color = const Color(0xFFFFECB3));
      _drawCenteredText(
        canvas,
        '🌾',
        Offset(x, y),
        const TextStyle(fontSize: 11),
      );
    }
  }

  void _drawSolarLantern(
    Canvas canvas,
    double cx,
    double cy,
    double dayProgress,
    double time,
  ) {
    final isDusk = dayProgress > 0.55;
    final glowStrength = isDusk ? 0.52 : 0.16;
    canvas.drawCircle(
      Offset(cx, cy - 20),
      (isDusk ? 26.0 : 16.0) + math.sin(time * 3.0) * 2.5,
      Paint()..color = Color.fromRGBO(255, 213, 79, glowStrength),
    );
    canvas.drawLine(
      Offset(cx, cy + 2),
      Offset(cx, cy - 18),
      Paint()
        ..color = const Color(0xFF4E342E)
        ..strokeWidth = 3.2,
    );
    canvas.drawCircle(
      Offset(cx, cy - 21),
      6.5,
      Paint()..color = const Color(0xFFFFEE58),
    );
    canvas.drawPath(
      Path()
        ..moveTo(cx - 9, cy - 25)
        ..lineTo(cx, cy - 32)
        ..lineTo(cx + 9, cy - 25)
        ..close(),
      Paint()..color = const Color(0xFF5D4037),
    );
  }

  void _drawFlowerArch(Canvas canvas, double cx, double cy, double time) {
    final archPaint = Paint()
      ..color = const Color(0xFF6D4C41)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, cy - 8), width: 44, height: 56),
      math.pi,
      math.pi,
      false,
      archPaint,
    );
    for (var i = 0; i <= 6; i++) {
      final a = math.pi + (math.pi * i / 6.0);
      final fx = cx + math.cos(a) * 22.0;
      final fy = cy - 8 + math.sin(a) * 28.0;
      canvas.drawCircle(
        Offset(fx, fy),
        5.2,
        Paint()..color = const Color(0xFF43A047),
      );
      canvas.drawCircle(
        Offset(fx, fy - 1),
        3.4,
        Paint()
          ..color = i.isEven
              ? const Color(0xFFEC407A)
              : const Color(0xFFFF80AB),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Multi-Stage Crops
  // ---------------------------------------------------------------------------

  void _drawPlantedCrop(
    Canvas canvas,
    double cx,
    double cy,
    GridPos pos,
    PlantedCrop crop,
    double moisture,
    double animTime,
  ) {
    final def = SolvilleCatalog.crops[crop.cropId]!;
    final sway =
        math.sin(animTime * 2.8 + pos.x * 0.9 + pos.y * 0.7) *
        (2.0 + crop.growth * 2.5);
    final stemColor = crop.isDrooping
        ? const Color(0xFF9E9D24)
        : const Color(0xFF2E7D32);

    if (crop.growth < 0.30) {
      final h = 6.0 + crop.growth * 22.0;
      final p = Paint()
        ..color = stemColor
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round;
      for (final ox in const <double>[-8.0, 0.0, 8.0]) {
        canvas.drawLine(
          Offset(cx + ox, cy + 2),
          Offset(cx + ox + sway * 0.4, cy + 2 - h),
          p,
        );
      }
    } else {
      final scale = (0.55 + crop.growth * 0.45).clamp(0.55, 1.0);
      final foliagePaint = Paint()..color = stemColor;
      final primary = Color(def.primaryColorHex);
      final accent = Color(def.accentColorHex);

      switch (crop.cropId) {
        case ProductId.tomato:
          canvas.drawLine(
            Offset(cx, cy + 2),
            Offset(cx, cy - 26 * scale),
            Paint()
              ..color = const Color(0xFF8D6E63)
              ..strokeWidth = 2.4,
          );
          canvas.drawCircle(
            Offset(cx + sway * 0.5, cy - 13 * scale),
            12 * scale,
            foliagePaint,
          );
          if (crop.growth >= 0.70) {
            final r = crop.isRipe ? 4.4 : 2.8;
            final c = crop.isRipe ? primary : accent;
            canvas.drawCircle(
              Offset(cx - 5 + sway * 0.5, cy - 14),
              r,
              Paint()..color = c,
            );
            canvas.drawCircle(
              Offset(cx + 6 + sway * 0.5, cy - 11),
              r,
              Paint()..color = c,
            );
            canvas.drawCircle(
              Offset(cx + 1 + sway * 0.5, cy - 19),
              r,
              Paint()..color = c,
            );
          }

        case ProductId.carrot:
          for (final ox in const <double>[-9.0, 0.0, 9.0]) {
            if (crop.growth >= 0.65) {
              canvas.drawCircle(
                Offset(cx + ox, cy + 1),
                crop.isRipe ? 4.6 : 3.0,
                Paint()..color = primary,
              );
            }
            canvas.drawLine(
              Offset(cx + ox, cy - 1),
              Offset(cx + ox - 3 + sway * 0.5, cy - 15 * scale),
              Paint()
                ..color = stemColor
                ..strokeWidth = 2.3,
            );
            canvas.drawLine(
              Offset(cx + ox, cy - 1),
              Offset(cx + ox + 3 + sway * 0.5, cy - 16 * scale),
              Paint()
                ..color = stemColor
                ..strokeWidth = 2.3,
            );
          }

        case ProductId.strawberry:
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(cx + sway * 0.4, cy - 8 * scale),
              width: 28 * scale,
              height: 17 * scale,
            ),
            foliagePaint,
          );
          if (crop.growth >= 0.65) {
            final c = crop.isRipe ? primary : const Color(0xFFFFF9C4);
            final r = crop.isRipe ? 3.8 : 2.5;
            canvas.drawCircle(Offset(cx - 7, cy - 8), r, Paint()..color = c);
            canvas.drawCircle(Offset(cx + 6, cy - 6), r, Paint()..color = c);
            canvas.drawCircle(Offset(cx, cy - 12), r, Paint()..color = c);
          }

        case ProductId.corn:
          for (final ox in const <double>[-7.0, 2.0, 9.0]) {
            final topY = cy - 34 * scale;
            canvas.drawLine(
              Offset(cx + ox, cy + 2),
              Offset(cx + ox + sway, topY),
              Paint()
                ..color = const Color(0xFF558B2F)
                ..strokeWidth = 3.4
                ..strokeCap = StrokeCap.round,
            );
            if (crop.growth >= 0.72) {
              canvas.drawOval(
                Rect.fromCenter(
                  center: Offset(cx + ox + sway * 0.6 + 2, cy - 17 * scale),
                  width: 5.5,
                  height: 10.0,
                ),
                Paint()..color = crop.isRipe ? primary : accent,
              );
            }
          }

        case ProductId.lavender:
          for (final ox in const <double>[-9.0, -3.0, 3.0, 9.0]) {
            canvas.drawLine(
              Offset(cx + ox, cy + 2),
              Offset(cx + ox + sway * 0.7, cy - 22 * scale),
              Paint()
                ..color = const Color(0xFF66BB6A)
                ..strokeWidth = 2.0,
            );
            if (crop.growth >= 0.55) {
              canvas.drawOval(
                Rect.fromCenter(
                  center: Offset(cx + ox + sway * 0.7, cy - 20 * scale),
                  width: 5.0,
                  height: 11.0 * scale,
                ),
                Paint()..color = crop.isRipe ? primary : accent,
              );
            }
          }

        case ProductId.pumpkin:
          canvas.drawOval(
            Rect.fromCenter(center: Offset(cx, cy - 2), width: 32, height: 15),
            foliagePaint,
          );
          final pr = 6.0 + crop.growth * 9.0;
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(cx, cy - pr * 0.65),
              width: pr * 2.1,
              height: pr * 1.45,
            ),
            Paint()..color = crop.isRipe ? primary : const Color(0xFF81C784),
          );

        case ProductId.lemon:
        case ProductId.eggs:
        case ProductId.honey:
        case ProductId.milk:
        case ProductId.preserves:
          break;
      }
    }

    if (crop.isRipe) {
      final pulse = (math.sin(animTime * 5.0 + pos.x) + 1.0) * 0.5;
      canvas.drawCircle(
        Offset(cx, cy - 28 - pulse * 4.0),
        3.6 + pulse * 1.6,
        Paint()..color = const Color(0xEEFFEE58),
      );
    } else if (moisture < 0.18) {
      canvas.drawCircle(
        Offset(cx + 12, cy - 22),
        6.5,
        Paint()..color = const Color(0xDDFFFFFF),
      );
      canvas.drawCircle(
        Offset(cx + 12, cy - 22),
        3.6,
        Paint()..color = const Color(0xFF29B6F6),
      );
    }
  }

  Color _productColor(ProductId id) => switch (id) {
    ProductId.tomato => const Color(0xFFE53935),
    ProductId.carrot => const Color(0xFFFB8C00),
    ProductId.strawberry => const Color(0xFFD81B60),
    ProductId.corn => const Color(0xFFFDD835),
    ProductId.lavender => const Color(0xFF8E24AA),
    ProductId.pumpkin => const Color(0xFFF4511E),
    ProductId.lemon => const Color(0xFFFFEE58),
    ProductId.eggs => const Color(0xFFFFF8E1),
    ProductId.honey => const Color(0xFFFFB300),
    ProductId.milk => const Color(0xFFE1F5FE),
    ProductId.preserves => const Color(0xFFAD1457),
  };

  void _drawCenteredText(
    Canvas canvas,
    String text,
    Offset center,
    TextStyle style,
  ) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(center.dx - tp.width * 0.5, center.dy - tp.height * 0.5),
    );
  }
}
