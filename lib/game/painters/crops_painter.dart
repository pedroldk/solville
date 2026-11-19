import 'dart:math' as math;
import 'dart:ui';

import '../../domain/models/catalog.dart';
import '../../domain/models/grid_pos.dart';
import '../../domain/models/tile_state.dart';
import 'canvas_draw_helpers.dart';

/// Renders lush, multi-stage botanical crops with 3D-shaded foliage, blossoms,
/// glossy fruit highlights, elastic pop-bounce scaling, golden mutation stars,
/// and crisp hover/inspect progress gauges.
class CropsPainter {
  const CropsPainter();

  static final Paint _stemPaint = Paint()..strokeCap = StrokeCap.round;
  static final Paint _foliagePaint = Paint();
  static final Paint _foliageShadePaint = Paint();
  static final Paint _fruitPaint = Paint();
  static final Paint _highlightPaint = Paint()
    ..color = const Color(0x99FFFFFF);
  static final Paint _stakePaint = Paint()
    ..color = const Color(0xFF8D6E63)
    ..strokeWidth = 2.4
    ..strokeCap = StrokeCap.round;
  static final Paint _cornStalkPaint = Paint()
    ..strokeWidth = 3.2
    ..strokeCap = StrokeCap.round;
  static final Paint _lavenderStemPaint = Paint()
    ..strokeWidth = 1.8
    ..strokeCap = StrokeCap.round;
  static final Paint _ripeSparklePaint = Paint()
    ..color = const Color(0xF5FFEE58);
  static final Paint _thirstBgPaint = Paint()..color = const Color(0xE6FFFDF6);
  static final Paint _thirstDropPaint = Paint()
    ..color = const Color(0xFF039BE5);
  static final Paint _leafContourPaint = Paint()
    ..color = const Color(0x441B3B1E)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.9
    ..strokeCap = StrokeCap.round;
  static final Paint _cropShadowPaint = Paint()
    ..color = const Color(0x28261412);
  static final Paint _goldenHaloPaint = Paint()
    ..color = const Color(0x55FFD54F);
  static final Paint _gaugeBgPaint = Paint()..color = const Color(0xEBFFFDF6);
  static final Paint _gaugeBorderPaint = Paint()
    ..color = const Color(0x665D4037)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.1;
  static final Paint _moistureFillPaint = Paint()
    ..color = const Color(0xFF039BE5);
  static final Path _leafPath = Path();

  void drawPlantedCrop(
    Canvas canvas,
    double cx,
    double cy,
    GridPos pos,
    PlantedCrop crop,
    double moisture,
    double animTime, {
    bool showDetailedMeters = false,
    double popScale = 1.0,
  }) {
    final def = SolvilleCatalog.crops[crop.cropId]!;
    final sway =
        math.sin(animTime * 1.55 + pos.x * 0.9 + pos.y * 0.7) *
        (1.3 + crop.growth * 1.8);
    final isDrooping = crop.isDrooping;
    final stemDark = isDrooping
        ? const Color(0xFF827717)
        : const Color(0xFF1F6623);
    final stemMid = isDrooping
        ? const Color(0xFF9E9D24)
        : const Color(0xFF2E7D32);
    final stemLit = isDrooping
        ? const Color(0xFFC0CA33)
        : const Color(0xFF558B2F);

    canvas.save();
    if ((popScale - 1.0).abs() > 0.002) {
      canvas.translate(cx, cy + 2);
      canvas.scale(popScale, popScale);
      canvas.translate(-cx, -(cy + 2));
    }

    if (crop.growth < 0.25) {
      // Stage 1: Tender sprouting shoots with twin curved cotyledon leaves
      final h = 6.0 + crop.growth * 24.0;
      _stemPaint
        ..color = stemMid
        ..strokeWidth = 2.2;
      _foliagePaint.color = stemLit;
      for (final ox in const <double>[-9.0, 0.0, 9.0]) {
        final topX = cx + ox + sway * 0.35;
        final topY = cy + 2 - h;
        canvas.drawLine(Offset(cx + ox, cy + 2), Offset(topX, topY), _stemPaint);
        canvas.drawOval(
          Rect.fromCenter(center: Offset(topX - 2.6, topY + 0.5), width: 5.2, height: 3.0),
          _foliagePaint,
        );
        canvas.drawOval(
          Rect.fromCenter(center: Offset(topX + 2.6, topY - 0.5), width: 5.2, height: 3.0),
          _foliagePaint,
        );
      }
    } else {
      final scale = (0.52 + crop.growth * 0.48).clamp(0.52, 1.0);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, cy + 3.5),
          width: 24.0 * scale,
          height: 11.0 * scale,
        ),
        _cropShadowPaint,
      );

      final primary = Color(def.primaryColorHex);
      final accent = Color(def.accentColorHex);

      switch (crop.cropId) {
        case ProductId.tomato:
          _drawTomatoPlant(
            canvas,
            cx,
            cy,
            scale,
            sway,
            crop,
            stemDark,
            stemMid,
            stemLit,
            primary,
            accent,
          );
        case ProductId.carrot:
          _drawCarrotPlant(
            canvas,
            cx,
            cy,
            scale,
            sway,
            crop,
            stemDark,
            stemMid,
            stemLit,
            primary,
          );
        case ProductId.strawberry:
          _drawStrawberryPlant(
            canvas,
            cx,
            cy,
            scale,
            sway,
            crop,
            stemDark,
            stemMid,
            stemLit,
            primary,
          );
        case ProductId.corn:
          _drawCornPlant(
            canvas,
            cx,
            cy,
            scale,
            sway,
            crop,
            stemDark,
            stemMid,
            stemLit,
            primary,
            accent,
          );
        case ProductId.lavender:
          _drawLavenderPlant(
            canvas,
            cx,
            cy,
            scale,
            sway,
            crop,
            stemMid,
            stemLit,
            primary,
            accent,
          );
        case ProductId.pumpkin:
          _drawPumpkinPlant(
            canvas,
            cx,
            cy,
            scale,
            sway,
            crop,
            stemDark,
            stemMid,
            stemLit,
            primary,
          );
        case ProductId.lemon:
        case ProductId.eggs:
        case ProductId.honey:
        case ProductId.milk:
        case ProductId.preserves:
        case ProductId.berryJam:
        case ProductId.villageSalsa:
        case ProductId.autumnLatte:
          break;
      }
    }

    canvas.restore();

    if (crop.isGolden) {
      final shimmer = 0.72 + 0.28 * math.sin(animTime * 3.8 + pos.x);
      _goldenHaloPaint.color = Color.fromRGBO(255, 213, 79, 0.44 * shimmer);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy - 6), width: 40, height: 22),
        _goldenHaloPaint,
      );
      _ripeSparklePaint.color = Color.fromRGBO(255, 241, 118, shimmer);
      CanvasDrawHelpers.drawStar4(
        canvas,
        Offset(cx - 10, cy - 26 - shimmer * 3),
        4.5,
        _ripeSparklePaint,
        rotation: animTime * 1.4,
      );
      CanvasDrawHelpers.drawStar4(
        canvas,
        Offset(cx + 9, cy - 22 + shimmer * 2),
        3.8,
        _ripeSparklePaint,
        rotation: -animTime * 1.2,
      );
      if (showDetailedMeters) {
        CanvasDrawHelpers.drawFloatingStatusPill(canvas, cx, cy - 36, '✨2×');
      }
    } else if (crop.isRipe) {
      final pulse = (math.sin(animTime * 3.2 + pos.x) + 1.0) * 0.5;
      _goldenHaloPaint.color = Color.fromRGBO(
        255,
        238,
        88,
        0.16 + 0.16 * pulse,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy - 2), width: 34, height: 18),
        _goldenHaloPaint,
      );
      _ripeSparklePaint.color = Color.fromRGBO(
        255,
        245,
        157,
        0.75 + 0.25 * pulse,
      );
      CanvasDrawHelpers.drawStar4(
        canvas,
        Offset(cx, cy - 30 - pulse * 4.0),
        4.6 + pulse * 1.6,
        _ripeSparklePaint,
        rotation: animTime * 0.9,
      );
    } else if (!crop.isRipe && (crop.isDrooping || (showDetailedMeters && moisture < 0.18))) {
      final dropBob = crop.isDrooping ? math.sin(animTime * 4.2 + pos.x) * 1.8 : 0.0;
      final dc = Offset(cx + 12, cy - 23 + dropBob);
      canvas.drawCircle(dc, 5.4, _thirstBgPaint);
      canvas.drawCircle(dc, 5.4, _gaugeBorderPaint);
      _leafPath
        ..reset()
        ..moveTo(dc.dx, dc.dy - 3.3)
        ..quadraticBezierTo(dc.dx + 3.0, dc.dy + 0.5, dc.dx, dc.dy + 3.1)
        ..quadraticBezierTo(dc.dx - 3.0, dc.dy + 0.5, dc.dx, dc.dy - 3.3)
        ..close();
      canvas.drawPath(_leafPath, _thirstDropPaint);
      canvas.drawCircle(dc.translate(-0.7, 0.5), 0.75, _highlightPaint);
    }

    // Pure on-canvas hover/inspect growth ring + moisture bar
    if (showDetailedMeters && !crop.isRipe) {
      final ringCenter = Offset(cx - 14, cy - 24);
      canvas.drawCircle(ringCenter, 8.8, _gaugeBgPaint);
      canvas.drawCircle(ringCenter, 8.8, _gaugeBorderPaint);
      CanvasDrawHelpers.drawProgressArc(
        canvas,
        ringCenter,
        6.4,
        crop.growth,
        const Color(0xFF43A047),
        trackColor: const Color(0x336D4C41),
        strokeWidth: 2.6,
      );
      final barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + 8, cy - 30, 5.8, 16.0),
        const Radius.circular(3),
      );
      canvas.drawRRect(barRect, _gaugeBgPaint);
      canvas.drawRRect(barRect, _gaugeBorderPaint);
      final fillH = (moisture.clamp(0.0, 1.0)) * 13.0;
      if (fillH > 0.5) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(cx + 9.3, cy - 15.5 - fillH, 3.2, fillH),
            const Radius.circular(2),
          ),
          _moistureFillPaint,
        );
      }
    }
  }

  void _drawTomatoPlant(
    Canvas canvas,
    double cx,
    double cy,
    double scale,
    double sway,
    PlantedCrop crop,
    Color stemDark,
    Color stemMid,
    Color stemLit,
    Color primary,
    Color accent,
  ) {
    // Rustic bamboo stake trellis + horizontal tie
    canvas.drawLine(
      Offset(cx, cy + 2),
      Offset(cx, cy - 29 * scale),
      _stakePaint,
    );
    canvas.drawLine(
      Offset(cx - 7 * scale, cy - 18 * scale),
      Offset(cx + 7 * scale, cy - 18 * scale),
      _stakePaint,
    );

    // Layered botanical bush canopy
    _foliageShadePaint.color = stemDark;
    canvas.drawCircle(Offset(cx - 5 + sway * 0.4, cy - 10 * scale), 9.5 * scale, _foliageShadePaint);
    canvas.drawCircle(Offset(cx + 6 + sway * 0.4, cy - 11 * scale), 9.0 * scale, _foliageShadePaint);

    _foliagePaint.color = stemMid;
    canvas.drawCircle(Offset(cx + sway * 0.5, cy - 15 * scale), 11.5 * scale, _foliagePaint);
    _foliagePaint.color = stemLit;
    canvas.drawCircle(Offset(cx - 2 + sway * 0.6, cy - 20 * scale), 7.5 * scale, _foliagePaint);
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx + sway * 0.5, cy - 15 * scale), width: 21 * scale, height: 21 * scale),
      math.pi * 1.05,
      math.pi * 0.75,
      false,
      _leafContourPaint,
    );

    // Tiny yellow blossoms during mid-growth
    if (crop.growth >= 0.45 && crop.growth < 0.72) {
      _fruitPaint.color = const Color(0xFFFFEE58);
      canvas.drawCircle(Offset(cx - 5 + sway * 0.5, cy - 15 * scale), 2.1, _fruitPaint);
      canvas.drawCircle(Offset(cx + 6 + sway * 0.5, cy - 18 * scale), 2.0, _fruitPaint);
    }

    // Glossy scarlet tomatoes with green star calyces & white shine
    if (crop.growth >= 0.68) {
      final r = crop.isRipe ? 4.4 : 2.9;
      _fruitPaint.color = crop.isRipe ? primary : accent;
      for (final o in const <(double, double)>[
        (-6, -13),
        (6, -11),
        (0, -19),
        (-2, -7),
        (5, -18),
      ]) {
        final tc = Offset(cx + o.$1 * scale + sway * 0.5, cy + o.$2 * scale);
        canvas.drawCircle(tc, r, _fruitPaint);
        canvas.drawCircle(tc.translate(-r * 0.3, -r * 0.3), r * 0.28, _highlightPaint);
        _foliageShadePaint.color = stemDark;
        CanvasDrawHelpers.drawStar4(
          canvas,
          tc.translate(0, -r * 0.68),
          r * 0.45,
          _foliageShadePaint,
          rotation: 0.4,
        );
      }
    }
  }

  void _drawCarrotPlant(
    Canvas canvas,
    double cx,
    double cy,
    double scale,
    double sway,
    PlantedCrop crop,
    Color stemDark,
    Color stemMid,
    Color stemLit,
    Color primary,
  ) {
    _stemPaint
      ..color = stemMid
      ..strokeWidth = 2.0;

    for (final ox in const <double>[-10.0, 0.0, 10.0]) {
      // Mounded soil collar
      _foliageShadePaint.color = const Color(0x553E2723);
      canvas.drawOval(Rect.fromCenter(center: Offset(cx + ox, cy + 2), width: 9.5, height: 4.5), _foliageShadePaint);

      if (crop.growth >= 0.62) {
        final cr = crop.isRipe ? 4.6 : 3.1;
        _fruitPaint.color = primary;
        canvas.drawOval(
          Rect.fromCenter(center: Offset(cx + ox, cy + 0.5), width: cr * 2.1, height: cr * 1.5),
          _fruitPaint,
        );
        canvas.drawCircle(Offset(cx + ox - 1.2, cy - 0.5), 1.0, _highlightPaint);
      }

      // Multi-frond feathery carrot fern leaves
      _stemPaint.color = stemDark;
      canvas.drawLine(Offset(cx + ox, cy - 1), Offset(cx + ox - 4 + sway * 0.5, cy - 15 * scale), _stemPaint);
      _stemPaint.color = stemMid;
      canvas.drawLine(Offset(cx + ox, cy - 1), Offset(cx + ox + sway * 0.6, cy - 18 * scale), _stemPaint);
      _stemPaint.color = stemLit;
      canvas.drawLine(Offset(cx + ox, cy - 1), Offset(cx + ox + 4.5 + sway * 0.5, cy - 14 * scale), _stemPaint);
    }
  }

  void _drawStrawberryPlant(
    Canvas canvas,
    double cx,
    double cy,
    double scale,
    double sway,
    PlantedCrop crop,
    Color stemDark,
    Color stemMid,
    Color stemLit,
    Color primary,
  ) {
    // Low mounded lush tri-leaf clusters
    _foliageShadePaint.color = stemDark;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + sway * 0.3, cy - 5 * scale), width: 30 * scale, height: 15 * scale),
      _foliageShadePaint,
    );
    _foliagePaint.color = stemMid;
    canvas.drawCircle(Offset(cx - 8 * scale + sway * 0.4, cy - 9 * scale), 7.5 * scale, _foliagePaint);
    canvas.drawCircle(Offset(cx + 8 * scale + sway * 0.4, cy - 9 * scale), 7.5 * scale, _foliagePaint);
    _foliagePaint.color = stemLit;
    canvas.drawCircle(Offset(cx + sway * 0.5, cy - 12 * scale), 8.2 * scale, _foliagePaint);
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx + sway * 0.5, cy - 12 * scale), width: 15 * scale, height: 15 * scale),
      math.pi * 1.1,
      math.pi * 0.7,
      false,
      _leafContourPaint,
    );

    // Crisp white 5-petal berry blossoms
    if (crop.growth >= 0.40 && crop.growth < 0.78) {
      for (final o in const <(double, double)>[(-6, -12), (7, -10)]) {
        final fc = Offset(cx + o.$1 * scale + sway * 0.4, cy + o.$2 * scale);
        _fruitPaint.color = const Color(0xFFFFFFFF);
        canvas.drawCircle(fc, 2.8, _fruitPaint);
        _fruitPaint.color = const Color(0xFFFFCA28);
        canvas.drawCircle(fc, 1.1, _fruitPaint);
      }
    }

    // Glossy heart-shaped ruby strawberries with green star calyces & golden seeds
    if (crop.growth >= 0.62) {
      _fruitPaint.color = crop.isRipe ? primary : const Color(0xFFF48FB1);
      final r = crop.isRipe ? 3.8 : 2.5;
      for (final o in const <(double, double)>[(-8, -7), (7, -6), (0, -11), (-2, -3)]) {
        final sc = Offset(cx + o.$1 * scale + sway * 0.35, cy + o.$2 * scale);
        canvas.drawOval(Rect.fromCenter(center: sc, width: r * 1.9, height: r * 2.1), _fruitPaint);
        canvas.drawCircle(sc.translate(-0.9, -0.8), 0.9, _highlightPaint);
        _foliageShadePaint.color = stemDark;
        CanvasDrawHelpers.drawStar4(
          canvas,
          sc.translate(0, -r * 0.9),
          r * 0.44,
          _foliageShadePaint,
        );
        _foliageShadePaint.color = const Color(0xFFFFF59D);
        canvas.drawCircle(sc.translate(0.7, 0.5), 0.55, _foliageShadePaint);
        canvas.drawCircle(sc.translate(-0.6, 1.1), 0.50, _foliageShadePaint);
      }
    }
  }

  void _drawCornPlant(
    Canvas canvas,
    double cx,
    double cy,
    double scale,
    double sway,
    PlantedCrop crop,
    Color stemDark,
    Color stemMid,
    Color stemLit,
    Color primary,
    Color accent,
  ) {
    for (final ox in const <double>[-8.0, 1.0, 9.5]) {
      final topY = cy - 35 * scale;
      final topX = cx + ox + sway;
      _cornStalkPaint.color = stemMid;
      canvas.drawLine(Offset(cx + ox, cy + 2), Offset(topX, topY), _cornStalkPaint);

      // Sweeping arching corn leaves
      _leafPath
        ..reset()
        ..moveTo(cx + ox + sway * 0.4, cy - 14 * scale)
        ..quadraticBezierTo(cx + ox - 8 * scale + sway * 0.3, cy - 20 * scale, cx + ox - 10 * scale, cy - 11 * scale);
      _stemPaint
        ..color = stemLit
        ..strokeWidth = 2.0;
      canvas.drawPath(_leafPath, _stemPaint);

      // Feathering drooping corn silk pollen tassels at stalk apex
      if (crop.growth >= 0.60) {
        _stemPaint
          ..color = const Color(0xFFFFD54F)
          ..strokeWidth = 1.3;
        canvas.drawLine(Offset(topX, topY), Offset(topX - 3.2, topY - 4.0), _stemPaint);
        canvas.drawLine(Offset(topX, topY), Offset(topX + 3.2, topY - 3.8), _stemPaint);
        canvas.drawLine(Offset(topX, topY), Offset(topX + 0.4, topY - 5.2), _stemPaint);
        _fruitPaint.color = const Color(0xFFFFEE58);
        canvas.drawCircle(Offset(topX, topY - 2.2), 1.6, _fruitPaint);
      }

      // Plump golden corn ear with peeling husk & silk tip
      if (crop.growth >= 0.70) {
        final earCenter = Offset(cx + ox + sway * 0.55 + 2.5, cy - 17 * scale);
        _fruitPaint.color = crop.isRipe ? primary : accent;
        canvas.drawOval(Rect.fromCenter(center: earCenter, width: 5.8, height: 10.5), _fruitPaint);
        _stemPaint
          ..color = const Color(0xFFFFB74D)
          ..strokeWidth = 1.1;
        canvas.drawLine(earCenter.translate(0, -5.0), earCenter.translate(1.5, -7.8), _stemPaint);
        _foliagePaint.color = stemDark;
        canvas.drawOval(
          Rect.fromCenter(center: earCenter.translate(0, 3.0), width: 6.4, height: 4.5),
          _foliagePaint,
        );
      }
    }
  }

  void _drawLavenderPlant(
    Canvas canvas,
    double cx,
    double cy,
    double scale,
    double sway,
    PlantedCrop crop,
    Color stemMid,
    Color stemLit,
    Color primary,
    Color accent,
  ) {
    // Low silver-sage foliage cushion
    _foliagePaint.color = stemLit;
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + 1), width: 22 * scale, height: 9 * scale), _foliagePaint);
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, cy + 1), width: 21 * scale, height: 8.5 * scale),
      math.pi * 1.1,
      math.pi * 0.8,
      false,
      _leafContourPaint,
    );

    _lavenderStemPaint.color = stemMid;
    for (final ox in const <double>[-10.0, -5.0, 0.0, 5.0, 10.0]) {
      final tipX = cx + ox + sway * 0.75;
      final tipY = cy - 23 * scale;
      canvas.drawLine(Offset(cx + ox * 0.7, cy + 2), Offset(tipX, tipY), _lavenderStemPaint);

      if (crop.growth >= 0.50) {
        final spikeCenter = Offset(tipX, cy - 20 * scale);
        _fruitPaint.color = crop.isRipe ? primary : accent;
        canvas.drawOval(
          Rect.fromCenter(center: spikeCenter, width: 5.2, height: 11.5 * scale),
          _fruitPaint,
        );
        _foliagePaint.color = accent;
        canvas.drawCircle(spikeCenter.translate(-0.5, -3.5 * scale), 1.6, _foliagePaint);
      }
    }
  }

  void _drawPumpkinPlant(
    Canvas canvas,
    double cx,
    double cy,
    double scale,
    double sway,
    PlantedCrop crop,
    Color stemDark,
    Color stemMid,
    Color stemLit,
    Color primary,
  ) {
    // Curling vine tendrils & broad scalloped leaves
    _leafPath
      ..reset()
      ..moveTo(cx - 12, cy + 1)
      ..quadraticBezierTo(cx - 19, cy - 3, cx - 17, cy + 4 + sway * 0.2)
      ..moveTo(cx + 12, cy + 1)
      ..quadraticBezierTo(cx + 19, cy - 2, cx + 17, cy + 5 - sway * 0.2);
    _stemPaint
      ..color = stemMid
      ..strokeWidth = 1.4;
    canvas.drawPath(_leafPath, _stemPaint);

    _foliageShadePaint.color = stemDark;
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - 8, cy + 1), width: 20, height: 11), _foliageShadePaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + 9, cy + 1), width: 19, height: 10), _foliageShadePaint);
    _foliagePaint.color = stemLit;
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + 4), width: 28, height: 12), _foliagePaint);
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, cy + 4), width: 27, height: 11),
      0.2,
      math.pi * 0.7,
      false,
      _leafContourPaint,
    );

    final pr = 4.8 + crop.growth * 7.6;
    final pc = Offset(cx, cy - pr * 0.62);
    final baseCol = crop.isRipe ? primary : const Color(0xFF81C784);
    final sideCol = crop.isRipe ? const Color(0xFFD84315) : const Color(0xFF558B2F);
    final centerLobeCol = crop.isRipe ? const Color(0xFFFF7043) : const Color(0xFFA5D6A7);

    // 3D-shaded ribbed pumpkin lobes
    _fruitPaint.color = sideCol;
    canvas.drawOval(Rect.fromCenter(center: pc, width: pr * 2.25, height: pr * 1.48), _fruitPaint);
    _fruitPaint.color = baseCol;
    canvas.drawOval(Rect.fromCenter(center: pc.translate(0, -0.5), width: pr * 1.55, height: pr * 1.48), _fruitPaint);
    _fruitPaint.color = centerLobeCol;
    canvas.drawOval(Rect.fromCenter(center: pc.translate(-0.8, -0.8), width: pr * 0.85, height: pr * 1.45), _fruitPaint);

    // Specular shine + curly green pumpkin stem
    canvas.drawOval(
      Rect.fromCenter(center: pc.translate(-pr * 0.35, -pr * 0.35), width: pr * 0.45, height: pr * 0.28),
      _highlightPaint,
    );
    _stemPaint
      ..color = stemMid
      ..strokeWidth = 2.6;
    canvas.drawLine(pc.translate(0, -pr * 0.68), pc.translate(2.2 + sway * 0.3, -pr * 1.05), _stemPaint);
  }
}
