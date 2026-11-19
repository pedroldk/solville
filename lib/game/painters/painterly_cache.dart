import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart' show Alignment, Color, LinearGradient, Offset, Rect;

import '../../domain/iso/iso_projection.dart';

/// Lazily bakes 2× supersampled painterly isometric tile-top `ui.Image`s once
/// and caches them for blazing-fast `drawImageRect` terrain blitting.
class PainterlyCache {
  PainterlyCache(this.iso);

  final IsoProjection iso;

  static const double oversample = 2.0;
  static const double pad = 2.0;

  final List<ui.Image> grassVariants = <ui.Image>[];
  final List<ui.Image> soilVariants = <ui.Image>[];
  final List<ui.Image> stonePathVariants = <ui.Image>[];
  final List<ui.Image> cobbleLaneVariants = <ui.Image>[];
  final List<ui.Image> weedsVariants = <ui.Image>[];

  bool _built = false;
  bool _disposed = false;

  double get logicalWidth => iso.tileWidth + pad * 2.0;
  double get logicalHeight => iso.tileHeight + pad * 2.0;

  void ensureBuilt() {
    if (_built || _disposed) return;
    _built = true;

    for (var i = 0; i < 4; i++) {
      grassVariants.add(_bakeTile((canvas, hw, hh) {
        _paintGrassVariant(canvas, hw, hh, i);
      }));
    }
    for (var tier = 0; tier < 3; tier++) {
      soilVariants.add(_bakeTile((canvas, hw, hh) {
        _paintSoilTier(canvas, hw, hh, tier);
      }));
    }
    for (var i = 0; i < 2; i++) {
      stonePathVariants.add(_bakeTile((canvas, hw, hh) {
        _paintStonePathVariant(canvas, hw, hh, i);
      }));
    }
    for (var i = 0; i < 2; i++) {
      cobbleLaneVariants.add(_bakeTile((canvas, hw, hh) {
        _paintCobbleLaneVariant(canvas, hw, hh, i);
      }));
    }
    for (var i = 0; i < 2; i++) {
      weedsVariants.add(_bakeTile((canvas, hw, hh) {
        _paintWeedsVariant(canvas, hw, hh, i);
      }));
    }
  }

  ui.Image _bakeTile(
    void Function(ui.Canvas canvas, double hw, double hh) drawer,
  ) {
    final lw = logicalWidth;
    final lh = logicalHeight;
    final imgW = (lw * oversample).round();
    final imgH = (lh * oversample).round();

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, Rect.fromLTWH(0, 0, imgW.toDouble(), imgH.toDouble()));
    canvas.scale(oversample, oversample);
    canvas.translate(lw * 0.5, lh * 0.5);

    final hw = iso.tileWidth * 0.5;
    final hh = iso.tileHeight * 0.5;
    drawer(canvas, hw, hh);

    final picture = recorder.endRecording();
    final image = picture.toImageSync(imgW, imgH);
    picture.dispose();
    return image;
  }

  ui.Path _diamondPath(double hw, double hh, {double bleed = 0.45}) {
    final ew = hw + bleed;
    final eh = hh + bleed * 0.5;
    return ui.Path()
      ..moveTo(0, -eh)
      ..lineTo(ew, 0)
      ..lineTo(0, eh)
      ..lineTo(-ew, 0)
      ..close();
  }

  void _paintSunlitRim(ui.Canvas canvas, double hw, double hh, Color nwHighlight, Color seShadow) {
    final stroke = ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = ui.StrokeCap.round;
    stroke.color = nwHighlight;
    canvas.drawLine(Offset(-hw + 1, 0), Offset(0, -hh + 0.5), stroke);
    canvas.drawLine(Offset(0, -hh + 0.5), Offset(hw - 1, 0), stroke);

    stroke.color = seShadow;
    canvas.drawLine(Offset(-hw + 1, 0), Offset(0, hh - 0.5), stroke);
    canvas.drawLine(Offset(0, hh - 0.5), Offset(hw - 1, 0), stroke);
  }

  void _paintGrassVariant(ui.Canvas canvas, double hw, double hh, int variant) {
    final path = _diamondPath(hw, hh);

    // Seamless edge-matching lush meadow green so adjacent tiles flow cleanly
    // into one continuous painted lawn with asymmetric interior brushstrokes.
    const baseMeadow = Color(0xFF74B93D);
    final bgPaint = ui.Paint()..color = baseMeadow;

    canvas.save();
    canvas.clipPath(path);
    canvas.drawPath(path, bgPaint);

    // Broad, subtly feathered meadow tones spread across the full diamond so
    // adjacent grass tiles blend into one continuous velvety lawn without grid clustering.
    final rng = math.Random(101 + variant * 43);
    final patchPaint = ui.Paint();
    for (var i = 0; i < 5; i++) {
      final px = (rng.nextDouble() - 0.5) * hw * 1.35;
      final py = (rng.nextDouble() - 0.5) * hh * 1.25;
      final pw = 22.0 + rng.nextDouble() * 22.0;
      final ph = pw * 0.50;
      patchPaint.color = i.isEven
          ? const Color(0x0EFFE082)
          : const Color(0x0C2E7D32);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(px, py), width: pw, height: ph),
        patchPaint,
      );
    }

    // Light sparse grass blade tufts distributed naturally (only 3-5 per variant)
    final bladePaint = ui.Paint()
      ..strokeWidth = 1.15
      ..strokeCap = ui.StrokeCap.round;
    final bladeCount = 3 + (variant % 3);
    for (var i = 0; i < bladeCount; i++) {
      final bx = (rng.nextDouble() - 0.5) * hw * 1.15;
      final by = (rng.nextDouble() - 0.5) * hh * 1.05;
      bladePaint.color = i.isEven
          ? const Color(0x40437A22)
          : const Color(0x3CAED581);
      canvas.drawLine(Offset(bx, by), Offset(bx - 1.8, by - 3.2), bladePaint);
      canvas.drawLine(Offset(bx + 1.4, by), Offset(bx + 2.8, by - 2.8), bladePaint);
    }

    // Delicate buttercup / daisy specks on select variants
    if (variant == 1 || variant == 2) {
      final flowerCount = variant == 1 ? 2 : 3;
      for (var i = 0; i < flowerCount; i++) {
        final fx = (rng.nextDouble() - 0.5) * hw * 0.76;
        final fy = (rng.nextDouble() - 0.5) * hh * 0.70;
        patchPaint.color = i == 0
            ? const Color(0xDDFFF9C4)
            : const Color(0xCCFFFFFF);
        canvas.drawCircle(Offset(fx, fy), 1.6, patchPaint);
        patchPaint.color = const Color(0xEEFFB300);
        canvas.drawCircle(Offset(fx, fy), 0.7, patchPaint);
      }
    }

    canvas.restore();
  }

  void _paintSoilTier(ui.Canvas canvas, double hw, double hh, int tier) {
    final path = _diamondPath(hw, hh);
    final rect = Rect.fromCenter(center: Offset.zero, width: hw * 2, height: hh * 2);

    // 0: Dry sunlit loam, 1: Moist rich cocoa, 2: Deep hydrated espresso
    final Color baseNW = switch (tier) {
      0 => const Color(0xFFC58A5C),
      1 => const Color(0xFF965F3E),
      _ => const Color(0xFF663D26),
    };
    final Color baseSE = switch (tier) {
      0 => const Color(0xFFA06A43),
      1 => const Color(0xFF714328),
      _ => const Color(0xFF452616),
    };

    final bgPaint = ui.Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[baseNW, baseSE],
      ).createShader(rect);

    canvas.save();
    canvas.clipPath(path);
    canvas.drawPath(path, bgPaint);

    // Sculpted 3D isometric furrow ridges running parallel to NW-SE axis
    final troughColor = switch (tier) {
      0 => const Color(0xFF704224),
      1 => const Color(0xFF492714),
      _ => const Color(0xFF2B150A),
    };
    final ridgeHighlight = switch (tier) {
      0 => const Color(0x6CECB789),
      1 => const Color(0x55C48B63),
      _ => const Color(0x449B6A4E),
    };

    final troughPaint = ui.Paint()
      ..color = troughColor
      ..strokeWidth = 3.4
      ..strokeCap = ui.StrokeCap.round;
    final crestPaint = ui.Paint()
      ..color = ridgeHighlight
      ..strokeWidth = 1.8
      ..strokeCap = ui.StrokeCap.round;

    for (final offset in const <double>[-13.0, -4.3, 4.3, 13.0]) {
      final p0 = Offset(-20.0 + offset * 0.56, -6.5 + offset * 0.52);
      final p1 = Offset(14.0 + offset * 0.56, 10.5 + offset * 0.52);
      canvas.drawLine(p0, p1, troughPaint);
      canvas.drawLine(
        Offset(p0.dx + 0.8, p0.dy - 1.6),
        Offset(p1.dx + 0.8, p1.dy - 1.6),
        crestPaint,
      );
    }

    // Organic crumb & tiny pebble texture
    final rng = math.Random(404 + tier * 19);
    final speckPaint = ui.Paint();
    for (var i = 0; i < 16; i++) {
      final sx = (rng.nextDouble() - 0.5) * hw * 1.25;
      final sy = (rng.nextDouble() - 0.5) * hh * 1.15;
      speckPaint.color = i.isEven
          ? const Color(0x333E2723)
          : const Color(0x28FFE0B2);
      canvas.drawCircle(Offset(sx, sy), 0.9 + rng.nextDouble() * 0.8, speckPaint);
    }

    // Soft glossy moisture glint on wet soil
    if (tier == 2) {
      final sheenPaint = ui.Paint()
        ..color = const Color(0x2AFFF8E1)
        ..strokeWidth = 1.3
        ..strokeCap = ui.StrokeCap.round;
      canvas.drawLine(const Offset(-13, -7), const Offset(7, 3), sheenPaint);
      canvas.drawLine(const Offset(-6, 1), const Offset(13, 10), sheenPaint);
      canvas.drawLine(const Offset(-16, 0), const Offset(-2, 7), sheenPaint);
    }

    _paintSunlitRim(
      canvas,
      hw,
      hh,
      const Color(0x1CFFE0B2),
      const Color(0x2A3E2723),
    );
    canvas.restore();
  }

  void _paintStonePathVariant(ui.Canvas canvas, double hw, double hh, int variant) {
    final path = _diamondPath(hw, hh);

    // Grass-embedded natural sunstone stepping path (outer edges match grass #74B93D)
    final meadowBasePaint = ui.Paint()..color = const Color(0xFF74B93D);
    final sandBedPaint = ui.Paint()
      ..shader = ui.Gradient.radial(
        Offset.zero,
        hw * 0.78,
        const <Color>[Color(0xFFCBB18B), Color(0xAAAE936D), Color(0x0074B93D)],
        const <double>[0.0, 0.55, 1.0],
      );

    canvas.save();
    canvas.clipPath(path);
    canvas.drawPath(path, meadowBasePaint);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: hw * 1.55, height: hh * 1.55),
      sandBedPaint,
    );

    // Subtle emerald moss flecks nestled between stepping stones
    final mossPaint = ui.Paint()..color = const Color(0x66558B2F);
    canvas.drawOval(Rect.fromCenter(center: const Offset(-13, 4), width: 7, height: 3.5), mossPaint);
    canvas.drawOval(Rect.fromCenter(center: const Offset(14, -3), width: 6, height: 3), mossPaint);
    canvas.drawOval(Rect.fromCenter(center: const Offset(2, -9), width: 5, height: 2.5), mossPaint);

    final stones = variant == 0
        ? const <({double x, double y, double w, double h, int tone})>[
            (x: -16, y: -2, w: 17, h: 9.5, tone: 0),
            (x: 2, y: -8, w: 18, h: 9.5, tone: 1),
            (x: 18, y: 0, w: 15, h: 8.5, tone: 2),
            (x: -4, y: 6, w: 19, h: 10.0, tone: 1),
            (x: 12, y: 8, w: 14, h: 7.5, tone: 0),
          ]
        : const <({double x, double y, double w, double h, int tone})>[
            (x: -13, y: -6, w: 16, h: 8.8, tone: 1),
            (x: 8, y: -6, w: 17, h: 9.5, tone: 0),
            (x: -18, y: 3, w: 14, h: 7.8, tone: 2),
            (x: 0, y: 2, w: 19, h: 9.5, tone: 0),
            (x: 16, y: 4, w: 15, h: 8.5, tone: 1),
          ];

    final fillPaint = ui.Paint();
    final outlinePaint = ui.Paint()
      ..color = const Color(0x996D523A)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.1;
    final highlightPaint = ui.Paint()
      ..color = const Color(0x75FFFDF6)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.15;
    final shadowPaint = ui.Paint()..color = const Color(0x2E4E342E);

    for (final st in stones) {
      final stoneRect = Rect.fromCenter(
        center: Offset(st.x, st.y),
        width: st.w,
        height: st.h,
      );
      final rr = ui.RRect.fromRectAndRadius(stoneRect, const ui.Radius.circular(4.2));
      canvas.drawRRect(rr.shift(const Offset(0.8, 1.4)), shadowPaint);

      final Color topCol = switch (st.tone) {
        0 => const Color(0xFFF7E9D2),
        1 => const Color(0xFFEED8B8),
        _ => const Color(0xFFE5C9A1),
      };
      final Color botCol = switch (st.tone) {
        0 => const Color(0xFFE2CA9F),
        1 => const Color(0xFFD6B98E),
        _ => const Color(0xFFCBA87C),
      };
      fillPaint.shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[topCol, botCol],
      ).createShader(stoneRect);
      canvas.drawRRect(rr, fillPaint);
      canvas.drawRRect(rr, outlinePaint);

      canvas.drawLine(
        Offset(st.x - st.w * 0.30, st.y - st.h * 0.36),
        Offset(st.x + st.w * 0.25, st.y - st.h * 0.36),
        highlightPaint,
      );
    }

    canvas.restore();
  }

  void _paintCobbleLaneVariant(ui.Canvas canvas, double hw, double hh, int variant) {
    final path = _diamondPath(hw, hh);
    final rect = Rect.fromCenter(center: Offset.zero, width: hw * 2, height: hh * 2);

    final bedPaint = ui.Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[Color(0xFFB3A49B), Color(0xFF8C7E76)],
      ).createShader(rect);

    canvas.save();
    canvas.clipPath(path);
    canvas.drawPath(path, bedPaint);

    final fillPaint = ui.Paint();
    final strokePaint = ui.Paint()
      ..color = const Color(0x665D4037)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 0.95;

    final cobbles = <({double x, double y, double w, double h, int tone})>[
      (x: -22, y: -1, w: 12, h: 6.5, tone: 0),
      (x: -9, y: -6, w: 13, h: 7, tone: 1),
      (x: 6, y: -9, w: 12, h: 6.5, tone: 2),
      (x: -11, y: 5, w: 14, h: 7.2, tone: 2),
      (x: 4, y: 0, w: 15, h: 7.5, tone: 0),
      (x: 19, y: -2, w: 12, h: 6.5, tone: 1),
      (x: 1, y: 10, w: 14, h: 6.8, tone: 1),
      (x: 16, y: 6, w: 13, h: 6.5, tone: 0),
      if (variant == 1) (x: -2, y: -14, w: 11, h: 5.5, tone: 0),
    ];

    for (final c in cobbles) {
      final r = Rect.fromCenter(center: Offset(c.x, c.y), width: c.w, height: c.h);
      final col = switch (c.tone) {
        0 => const Color(0xFFE6DDD8),
        1 => const Color(0xFFDAD0CA),
        _ => const Color(0xFFCEC2BC),
      };
      fillPaint.color = col;
      canvas.drawOval(r, fillPaint);
      canvas.drawOval(r, strokePaint);
      fillPaint.color = const Color(0x40FFFFFF);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(c.x - 1.2, c.y - 1.3),
          width: c.w * 0.55,
          height: c.h * 0.35,
        ),
        fillPaint,
      );
    }

    // Subtle sandstone lane curb highlight along lower edge
    final curbPaint = ui.Paint()
      ..color = const Color(0x55FFF3E0)
      ..strokeWidth = 2.0
      ..strokeCap = ui.StrokeCap.round;
    canvas.drawLine(Offset(-hw + 3, 1), Offset(0, hh - 1), curbPaint);

    _paintSunlitRim(
      canvas,
      hw,
      hh,
      const Color(0x28FFFFFF),
      const Color(0x245D4037),
    );
    canvas.restore();
  }

  void _paintWeedsVariant(ui.Canvas canvas, double hw, double hh, int variant) {
    final path = _diamondPath(hw, hh);

    // Match seamless grass edge base so weed tiles nest naturally in the meadow
    final bgPaint = ui.Paint()..color = const Color(0xFF74B93D);
    final mossyShadePaint = ui.Paint()
      ..shader = ui.Gradient.radial(
        Offset.zero,
        hw * 0.72,
        const <Color>[Color(0xFF558B2F), Color(0x0074B93D)],
        const <double>[0.0, 1.0],
      );

    canvas.save();
    canvas.clipPath(path);
    canvas.drawPath(path, bgPaint);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: hw * 1.45, height: hh * 1.45),
      mossyShadePaint,
    );

    final shadePaint = ui.Paint()..color = const Color(0x2E1B5E20);
    canvas.drawOval(Rect.fromCenter(center: const Offset(-10, 4), width: 16, height: 8), shadePaint);
    canvas.drawOval(Rect.fromCenter(center: const Offset(10, -2), width: 15, height: 8), shadePaint);
    canvas.drawOval(Rect.fromCenter(center: const Offset(0, 8), width: 17, height: 8), shadePaint);

    // Clover clusters on ground
    final cloverPaint = ui.Paint()..color = const Color(0xFF43A047);
    final rng = math.Random(707 + variant * 29);
    for (var i = 0; i < 8; i++) {
      final cx = (rng.nextDouble() - 0.5) * hw * 0.85;
      final cy = (rng.nextDouble() - 0.5) * hh * 0.75;
      canvas.drawCircle(Offset(cx, cy), 2.1, cloverPaint);
      canvas.drawCircle(Offset(cx + 2.1, cy + 0.8), 1.9, cloverPaint);
    }

    canvas.restore();
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final img in grassVariants) {
      img.dispose();
    }
    for (final img in soilVariants) {
      img.dispose();
    }
    for (final img in stonePathVariants) {
      img.dispose();
    }
    for (final img in cobbleLaneVariants) {
      img.dispose();
    }
    for (final img in weedsVariants) {
      img.dispose();
    }
    grassVariants.clear();
    soilVariants.clear();
    stonePathVariants.clear();
    cobbleLaneVariants.clear();
    weedsVariants.clear();
  }
}
