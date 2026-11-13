import 'dart:math' as math;
import 'dart:ui';

import '../../domain/models/catalog.dart';
import '../../domain/models/grid_pos.dart';
import '../../domain/models/tile_state.dart';
import 'canvas_draw_helpers.dart';

/// Renders multi-stage growing crops, ripe sparkles, and thirst indicators
/// using pre-allocated [Paint] objects to avoid per-frame allocations.
class CropsPainter {
  const CropsPainter();

  static final Paint _stemPaint = Paint()..strokeCap = StrokeCap.round;
  static final Paint _foliagePaint = Paint();
  static final Paint _fruitPaint = Paint();
  static final Paint _stakePaint = Paint()
    ..color = const Color(0xFF8D6E63)
    ..strokeWidth = 2.4;
  static final Paint _cornStalkPaint = Paint()
    ..color = const Color(0xFF558B2F)
    ..strokeWidth = 3.4
    ..strokeCap = StrokeCap.round;
  static final Paint _lavenderStemPaint = Paint()
    ..color = const Color(0xFF66BB6A)
    ..strokeWidth = 2.0;
  static final Paint _ripeSparklePaint = Paint()
    ..color = const Color(0xEEFFEE58);
  static final Paint _thirstBgPaint = Paint()..color = const Color(0xDDFFFFFF);
  static final Paint _thirstDropPaint = Paint()
    ..color = const Color(0xFF29B6F6);
  static final Paint _cropShadowPaint = Paint()
    ..color = const Color(0x1E000000);
  static final Paint _goldenHaloPaint = Paint()
    ..color = const Color(0x55FFD54F);
  static final Paint _gaugeBgPaint = Paint()..color = const Color(0xDDFFFDF6);
  static final Paint _moistureFillPaint = Paint()
    ..color = const Color(0xFF29B6F6);

  void drawPlantedCrop(
    Canvas canvas,
    double cx,
    double cy,
    GridPos pos,
    PlantedCrop crop,
    double moisture,
    double animTime, {
    bool showDetailedMeters = false,
  }) {
    final def = SolvilleCatalog.crops[crop.cropId]!;
    final sway =
        math.sin(animTime * 2.8 + pos.x * 0.9 + pos.y * 0.7) *
        (2.0 + crop.growth * 2.5);
    final stemColor = crop.isDrooping
        ? const Color(0xFF9E9D24)
        : const Color(0xFF2E7D32);

    if (crop.growth < 0.30) {
      final h = 6.0 + crop.growth * 22.0;
      _stemPaint
        ..color = stemColor
        ..strokeWidth = 2.6;
      for (final ox in const <double>[-8.0, 0.0, 8.0]) {
        canvas.drawLine(
          Offset(cx + ox, cy + 2),
          Offset(cx + ox + sway * 0.4, cy + 2 - h),
          _stemPaint,
        );
      }
    } else {
      final scale = (0.55 + crop.growth * 0.45).clamp(0.55, 1.0);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, cy + 3),
          width: 20.0 * scale,
          height: 9.0 * scale,
        ),
        _cropShadowPaint,
      );
      _foliagePaint.color = stemColor;
      final primary = Color(def.primaryColorHex);
      final accent = Color(def.accentColorHex);

      switch (crop.cropId) {
        case ProductId.tomato:
          canvas.drawLine(
            Offset(cx, cy + 2),
            Offset(cx, cy - 26 * scale),
            _stakePaint,
          );
          canvas.drawCircle(
            Offset(cx + sway * 0.5, cy - 13 * scale),
            12 * scale,
            _foliagePaint,
          );
          if (crop.growth >= 0.70) {
            final r = crop.isRipe ? 4.4 : 2.8;
            _fruitPaint.color = crop.isRipe ? primary : accent;
            canvas.drawCircle(
              Offset(cx - 5 + sway * 0.5, cy - 14),
              r,
              _fruitPaint,
            );
            canvas.drawCircle(
              Offset(cx + 6 + sway * 0.5, cy - 11),
              r,
              _fruitPaint,
            );
            canvas.drawCircle(
              Offset(cx + 1 + sway * 0.5, cy - 19),
              r,
              _fruitPaint,
            );
          }

        case ProductId.carrot:
          _stemPaint
            ..color = stemColor
            ..strokeWidth = 2.3;
          _fruitPaint.color = primary;
          for (final ox in const <double>[-9.0, 0.0, 9.0]) {
            if (crop.growth >= 0.65) {
              canvas.drawCircle(
                Offset(cx + ox, cy + 1),
                crop.isRipe ? 4.6 : 3.0,
                _fruitPaint,
              );
            }
            canvas.drawLine(
              Offset(cx + ox, cy - 1),
              Offset(cx + ox - 3 + sway * 0.5, cy - 15 * scale),
              _stemPaint,
            );
            canvas.drawLine(
              Offset(cx + ox, cy - 1),
              Offset(cx + ox + 3 + sway * 0.5, cy - 16 * scale),
              _stemPaint,
            );
          }

        case ProductId.strawberry:
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(cx + sway * 0.4, cy - 8 * scale),
              width: 28 * scale,
              height: 17 * scale,
            ),
            _foliagePaint,
          );
          if (crop.growth >= 0.65) {
            _fruitPaint.color = crop.isRipe ? primary : const Color(0xFFFFF9C4);
            final r = crop.isRipe ? 3.8 : 2.5;
            canvas.drawCircle(Offset(cx - 7, cy - 8), r, _fruitPaint);
            canvas.drawCircle(Offset(cx + 6, cy - 6), r, _fruitPaint);
            canvas.drawCircle(Offset(cx, cy - 12), r, _fruitPaint);
          }

        case ProductId.corn:
          _fruitPaint.color = crop.isRipe ? primary : accent;
          for (final ox in const <double>[-7.0, 2.0, 9.0]) {
            final topY = cy - 34 * scale;
            canvas.drawLine(
              Offset(cx + ox, cy + 2),
              Offset(cx + ox + sway, topY),
              _cornStalkPaint,
            );
            if (crop.growth >= 0.72) {
              canvas.drawOval(
                Rect.fromCenter(
                  center: Offset(cx + ox + sway * 0.6 + 2, cy - 17 * scale),
                  width: 5.5,
                  height: 10.0,
                ),
                _fruitPaint,
              );
            }
          }

        case ProductId.lavender:
          _fruitPaint.color = crop.isRipe ? primary : accent;
          for (final ox in const <double>[-9.0, -3.0, 3.0, 9.0]) {
            canvas.drawLine(
              Offset(cx + ox, cy + 2),
              Offset(cx + ox + sway * 0.7, cy - 22 * scale),
              _lavenderStemPaint,
            );
            if (crop.growth >= 0.55) {
              canvas.drawOval(
                Rect.fromCenter(
                  center: Offset(cx + ox + sway * 0.7, cy - 20 * scale),
                  width: 5.0,
                  height: 11.0 * scale,
                ),
                _fruitPaint,
              );
            }
          }

        case ProductId.pumpkin:
          canvas.drawOval(
            Rect.fromCenter(center: Offset(cx, cy - 2), width: 32, height: 15),
            _foliagePaint,
          );
          final pr = 6.0 + crop.growth * 9.0;
          _fruitPaint.color = crop.isRipe ? primary : const Color(0xFF81C784);
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(cx, cy - pr * 0.65),
              width: pr * 2.1,
              height: pr * 1.45,
            ),
            _fruitPaint,
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

    if (crop.isGolden) {
      final shimmer = 0.75 + 0.25 * math.sin(animTime * 6.5 + pos.x);
      _goldenHaloPaint.color = Color.fromRGBO(255, 213, 79, 0.42 * shimmer);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy - 6), width: 38, height: 22),
        _goldenHaloPaint,
      );
      CanvasDrawHelpers.drawFloatingStatusPill(canvas, cx, cy - 34, '✨2×');
    } else if (crop.isRipe) {
      final pulse = (math.sin(animTime * 5.0 + pos.x) + 1.0) * 0.5;
      canvas.drawCircle(
        Offset(cx, cy - 28 - pulse * 4.0),
        3.6 + pulse * 1.6,
        _ripeSparklePaint,
      );
    } else if (moisture < 0.18) {
      canvas.drawCircle(Offset(cx + 12, cy - 22), 6.5, _thirstBgPaint);
      canvas.drawCircle(Offset(cx + 12, cy - 22), 3.6, _thirstDropPaint);
    }

    // Pure on-canvas hover/inspect growth ring + moisture bar (no top HUD text)
    if (showDetailedMeters && !crop.isRipe) {
      final ringCenter = Offset(cx - 14, cy - 24);
      canvas.drawCircle(ringCenter, 8.5, _gaugeBgPaint);
      CanvasDrawHelpers.drawProgressArc(
        canvas,
        ringCenter,
        6.5,
        crop.growth,
        const Color(0xFF43A047),
        trackColor: const Color(0x336D4C41),
        strokeWidth: 2.6,
      );
      final barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + 8, cy - 30, 5.5, 16.0),
        const Radius.circular(3),
      );
      canvas.drawRRect(barRect, _gaugeBgPaint);
      final fillH = (moisture.clamp(0.0, 1.0)) * 13.0;
      if (fillH > 0.5) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(cx + 9.2, cy - 15.5 - fillH, 3.1, fillH),
            const Radius.circular(2),
          ),
          _moistureFillPaint,
        );
      }
    }
  }
}
