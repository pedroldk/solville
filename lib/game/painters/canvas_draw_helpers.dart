import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/painting.dart'
    show FontWeight, TextDirection, TextPainter, TextSpan, TextStyle;

import '../../domain/models/catalog.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/tile_state.dart';

/// Shared low-level Canvas helpers for 2.5D slatted crates with produce,
/// status bubbles, 4-point star sparkles, vector action icons, and cached text.
///
/// Uses a bounded LRU [TextPainter] cache and pre-allocated [Paint]/[Path]
/// objects to eliminate per-frame allocations in the render loop.
abstract final class CanvasDrawHelpers {
  static const int _maxTextCacheEntries = 256;
  static final LinkedHashMap<(String, TextStyle), TextPainter> _textCache =
      LinkedHashMap<(String, TextStyle), TextPainter>();

  static final Paint _pillShadowPaint = Paint()
    ..color = const Color(0x333E2723);
  static final Paint _pillFillPaint = Paint()..color = const Color(0xFFFFFBF0);
  static final Paint _pillInnerHighlight = Paint()
    ..color = const Color(0x99FFFFFF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;
  static final Paint _pillStrokePaint = Paint()
    ..color = const Color(0xFFE69A00)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.8;
  static final Paint _hungryPillPaint = Paint()
    ..color = const Color(0xFFFFECB3);
  static final Paint _zenHaloPaint = Paint()..color = const Color(0x4DFFCA28);
  static final Paint _zenDotPaint = Paint()..color = const Color(0xF5FFEE58);
  static final Paint _zenTendingDotPaint = Paint()
    ..color = const Color(0xAAFFB300);

  static final Paint _crateShadowPaint = Paint()
    ..color = const Color(0x3D261412);
  static final Paint _crateLeftPaint = Paint()..color = const Color(0xFFD99B58);
  static final Paint _crateRightPaint = Paint()..color = const Color(0xFFB57A3E);
  static final Paint _crateTopRimPaint = Paint()..color = const Color(0xFFEAC086);
  static final Paint _crateInteriorPaint = Paint()
    ..color = const Color(0xFF5D3A22);
  static final Paint _crateStrokePaint = Paint()
    ..color = const Color(0xFF5D4037)
    ..style = PaintingStyle.stroke
    ..strokeJoin = StrokeJoin.round;
  static final Paint _crateItemPaint = Paint();
  static final Paint _crateDetailPaint = Paint();
  static final Path _cratePathA = Path();
  static final Path _cratePathB = Path();

  static final Path _starPath = Path();
  static final Path _iconPath = Path();
  static final Paint _iconFillPaint = Paint();
  static final Paint _iconStrokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  static const TextStyle _statusPillTextStyle = TextStyle(
    color: Color(0xFF3E2723),
    fontSize: 10.5,
    fontWeight: FontWeight.w800,
  );
  static const TextStyle _hungryEmojiTextStyle = TextStyle(fontSize: 11);

  static void drawCenteredText(
    Canvas canvas,
    String text,
    Offset center,
    TextStyle style,
  ) {
    final key = (text, style);
    var tp = _textCache.remove(key);
    if (tp == null) {
      tp = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      if (_textCache.length >= _maxTextCacheEntries) {
        _textCache.remove(_textCache.keys.first);
      }
    }
    _textCache[key] = tp;
    tp.paint(
      canvas,
      Offset(center.dx - tp.width * 0.5, center.dy - tp.height * 0.5),
    );
  }

  /// Draws a crisp 4-point storybook diamond sparkle star.
  static void drawStar4(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint, {
    double rotation = 0.0,
  }) {
    final inner = radius * 0.30;
    _starPath.reset();
    for (var i = 0; i < 8; i++) {
      final r = i.isEven ? radius : inner;
      final a = rotation + i * (math.pi * 0.25);
      final px = center.dx + math.cos(a) * r;
      final py = center.dy + math.sin(a) * r;
      if (i == 0) {
        _starPath.moveTo(px, py);
      } else {
        _starPath.lineTo(px, py);
      }
    }
    _starPath.close();
    canvas.drawPath(_starPath, paint);
  }

  static void drawFloatingStatusPill(
    Canvas canvas,
    double x,
    double y,
    String text,
  ) {
    final width = math.max(42.0, text.length * 6.8 + 16.0);
    final r = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(x, y), width: width, height: 21),
      const Radius.circular(10.5),
    );
    canvas.drawRRect(r.shift(const Offset(0, 1.8)), _pillShadowPaint);
    canvas.drawRRect(r, _pillFillPaint);
    canvas.drawRRect(r.deflate(1.2), _pillInnerHighlight);
    canvas.drawRRect(r, _pillStrokePaint);
    drawCenteredText(canvas, text, Offset(x, y), _statusPillTextStyle);
  }

  static void drawAnimalStatusBubble(
    Canvas canvas,
    double x,
    double y,
    AnimalUnitState? state,
    String readyEmoji, {
    bool showDetailedMeters = false,
    double animTime = 0.0,
  }) {
    if (state == null) return;
    if (showDetailedMeters) {
      if (state.readyCrates > 0) {
        drawFloatingStatusPill(canvas, x, y, '$readyEmoji${state.readyCrates}');
      } else if (state.needsTending) {
        final r = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, y), width: 26, height: 19),
          const Radius.circular(9),
        );
        canvas.drawRRect(r.shift(const Offset(0, 1.5)), _pillShadowPaint);
        canvas.drawRRect(r, _hungryPillPaint);
        canvas.drawRRect(r, _pillStrokePaint);
        drawCenteredText(canvas, '🌾', Offset(x, y), _hungryEmojiTextStyle);
      }
      return;
    }

    if (state.readyCrates > 0) {
      final bob = math.sin(animTime * 4.2 + x * 0.1).abs() * 2.5;
      final dotCenter = Offset(x, y + 6 - bob);
      canvas.drawCircle(dotCenter, 9.5, _zenHaloPaint);
      canvas.drawCircle(dotCenter, 4.2, _zenDotPaint);
      drawStar4(canvas, dotCenter, 6.2, _zenDotPaint, rotation: animTime * 0.8);
    } else if (state.needsTending) {
      canvas.drawCircle(Offset(x, y + 8), 3.0, _zenTendingDotPaint);
    }
  }

  /// Draws a 2.5D isometric slatted wooden crate brimming with illustrated produce.
  static void drawWoodenCrate(
    Canvas canvas,
    Offset center,
    ProductId product, {
    double scale = 1.0,
  }) {
    final s = scale;
    final cx = center.dx;
    final cy = center.dy;

    // Soft ground shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + 0.8 * s, cy + 7.0 * s),
        width: 24.0 * s,
        height: 11.0 * s,
      ),
      _crateShadowPaint,
    );

    // 2.5D Isometric crate faces
    final hw = 10.5 * s;
    final hh = 5.2 * s;
    final depth = 9.0 * s;

    // Left sunlit timber face
    _cratePathA
      ..reset()
      ..moveTo(cx - hw, cy - depth * 0.5)
      ..lineTo(cx, cy + hh - depth * 0.5)
      ..lineTo(cx, cy + hh + depth * 0.5)
      ..lineTo(cx - hw, cy + depth * 0.5)
      ..close();
    canvas.drawPath(_cratePathA, _crateLeftPaint);

    // Right shaded timber face
    _cratePathB
      ..reset()
      ..moveTo(cx, cy + hh - depth * 0.5)
      ..lineTo(cx + hw, cy - depth * 0.5)
      ..lineTo(cx + hw, cy + depth * 0.5)
      ..lineTo(cx, cy + hh + depth * 0.5)
      ..close();
    canvas.drawPath(_cratePathB, _crateRightPaint);

    // Top open crate rim & recessed dark interior
    _cratePathA
      ..reset()
      ..moveTo(cx, cy - hh - depth * 0.5)
      ..lineTo(cx + hw, cy - depth * 0.5)
      ..lineTo(cx, cy + hh - depth * 0.5)
      ..lineTo(cx - hw, cy - depth * 0.5)
      ..close();
    canvas.drawPath(_cratePathA, _crateTopRimPaint);

    _cratePathB
      ..reset()
      ..moveTo(cx, cy - hh * 0.72 - depth * 0.5)
      ..lineTo(cx + hw * 0.72, cy - depth * 0.5)
      ..lineTo(cx, cy + hh * 0.72 - depth * 0.5)
      ..lineTo(cx - hw * 0.72, cy - depth * 0.5)
      ..close();
    canvas.drawPath(_cratePathB, _crateInteriorPaint);

    // Miniature illustrated produce nested inside the crate
    _drawCrateContents(canvas, cx, cy - depth * 0.52, s, product);

    // Front wood slat & crisp chestnut outline
    _crateStrokePaint.strokeWidth = 1.25 * s;
    canvas.drawLine(
      Offset(cx - hw, cy),
      Offset(cx, cy + hh),
      _crateStrokePaint,
    );
    canvas.drawLine(
      Offset(cx, cy + hh),
      Offset(cx + hw, cy),
      _crateStrokePaint,
    );
    canvas.drawLine(
      Offset(cx, cy + hh - depth * 0.5),
      Offset(cx, cy + hh + depth * 0.5),
      _crateStrokePaint,
    );
    _cratePathA
      ..reset()
      ..moveTo(cx, cy - hh - depth * 0.5)
      ..lineTo(cx + hw, cy - depth * 0.5)
      ..lineTo(cx + hw, cy + depth * 0.5)
      ..lineTo(cx, cy + hh + depth * 0.5)
      ..lineTo(cx - hw, cy + depth * 0.5)
      ..lineTo(cx - hw, cy - depth * 0.5)
      ..close();
    canvas.drawPath(_cratePathA, _crateStrokePaint);
  }

  static void _drawCrateContents(
    Canvas canvas,
    double cx,
    double cy,
    double s,
    ProductId product,
  ) {
    final mainColor = Color(SolvilleCatalog.productColorHex(product));
    switch (product) {
      case ProductId.tomato:
      case ProductId.lemon:
        _crateItemPaint.color = mainColor;
        for (final o in const <(double, double)>[
          (-3.6, 0.2),
          (3.4, 0.0),
          (0.0, -2.0),
        ]) {
          final p = Offset(cx + o.$1 * s, cy + o.$2 * s);
          canvas.drawCircle(p, 3.1 * s, _crateItemPaint);
          _crateDetailPaint.color = const Color(0x88FFFFFF);
          canvas.drawCircle(Offset(p.dx - 0.9 * s, p.dy - 1.0 * s), 0.9 * s, _crateDetailPaint);
          _crateDetailPaint.color = const Color(0xFF388E3C);
          canvas.drawCircle(Offset(p.dx, p.dy - 2.3 * s), 0.9 * s, _crateDetailPaint);
        }
      case ProductId.carrot:
        _crateItemPaint.color = const Color(0xFFFB8C00);
        for (final dx in const <double>[-3.5, 0.2, 3.8]) {
          canvas.drawOval(
            Rect.fromCenter(center: Offset(cx + dx * s, cy - 0.3 * s), width: 3.6 * s, height: 5.5 * s),
            _crateItemPaint,
          );
          _crateDetailPaint.color = const Color(0xFF43A047);
          canvas.drawCircle(Offset(cx + dx * s, cy - 3.3 * s), 1.4 * s, _crateDetailPaint);
        }
      case ProductId.strawberry:
        _crateItemPaint.color = const Color(0xFFE91E63);
        for (final o in const <(double, double)>[(-3.2, 0.2), (3.2, 0.1), (0.0, -1.8)]) {
          canvas.drawCircle(Offset(cx + o.$1 * s, cy + o.$2 * s), 2.8 * s, _crateItemPaint);
          _crateDetailPaint.color = const Color(0xFFFFF59D);
          canvas.drawCircle(Offset(cx + (o.$1 - 0.6) * s, cy + o.$2 * s), 0.55 * s, _crateDetailPaint);
          _crateDetailPaint.color = const Color(0xFF43A047);
          canvas.drawCircle(Offset(cx + o.$1 * s, cy + (o.$2 - 2.2) * s), 0.9 * s, _crateDetailPaint);
        }
      case ProductId.corn:
        _crateItemPaint.color = const Color(0xFFFDD835);
        for (final dx in const <double>[-3.2, 0.4, 3.6]) {
          canvas.drawOval(
            Rect.fromCenter(center: Offset(cx + dx * s, cy - 1.0 * s), width: 3.3 * s, height: 6.4 * s),
            _crateItemPaint,
          );
        }
        _crateDetailPaint.color = const Color(0xFF66BB6A);
        canvas.drawOval(
          Rect.fromCenter(center: Offset(cx, cy + 1.2 * s), width: 10.0 * s, height: 3.2 * s),
          _crateDetailPaint,
        );
      case ProductId.lavender:
        _crateDetailPaint.color = const Color(0xFF66BB6A);
        canvas.drawOval(
          Rect.fromCenter(center: Offset(cx, cy + 0.5 * s), width: 9.0 * s, height: 3.5 * s),
          _crateDetailPaint,
        );
        _crateItemPaint.color = const Color(0xFF9C27B0);
        for (final dx in const <double>[-3.5, 0.0, 3.5]) {
          canvas.drawOval(
            Rect.fromCenter(center: Offset(cx + dx * s, cy - 1.8 * s), width: 2.8 * s, height: 5.5 * s),
            _crateItemPaint,
          );
        }
      case ProductId.pumpkin:
        _crateItemPaint.color = const Color(0xFFF4511E);
        canvas.drawOval(
          Rect.fromCenter(center: Offset(cx, cy - 1.2 * s), width: 10.2 * s, height: 7.4 * s),
          _crateItemPaint,
        );
        _crateDetailPaint.color = const Color(0xFFFF8A65);
        canvas.drawOval(
          Rect.fromCenter(center: Offset(cx, cy - 1.2 * s), width: 4.5 * s, height: 7.2 * s),
          _crateDetailPaint,
        );
        _crateDetailPaint.color = const Color(0xFF558B2F);
        canvas.drawCircle(Offset(cx, cy - 5.0 * s), 1.3 * s, _crateDetailPaint);
      case ProductId.eggs:
        _crateItemPaint.color = const Color(0xFFFFF8E1);
        for (final o in const <(double, double)>[(-3.2, 0.1), (3.2, 0.1), (0.0, -1.7)]) {
          canvas.drawOval(
            Rect.fromCenter(center: Offset(cx + o.$1 * s, cy + o.$2 * s), width: 4.0 * s, height: 5.2 * s),
            _crateItemPaint,
          );
        }
      case ProductId.milk:
        _crateItemPaint.color = const Color(0xFFF5FBFF);
        for (final dx in const <double>[-3.0, 2.8]) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(cx + dx * s, cy - 1.8 * s), width: 4.2 * s, height: 7.5 * s),
              Radius.circular(1.5 * s),
            ),
            _crateItemPaint,
          );
          _crateDetailPaint.color = const Color(0xFF4FC3F7);
          canvas.drawCircle(Offset(cx + dx * s, cy - 5.6 * s), 1.3 * s, _crateDetailPaint);
        }
      case ProductId.honey:
      case ProductId.preserves:
      case ProductId.berryJam:
      case ProductId.villageSalsa:
      case ProductId.autumnLatte:
        _crateItemPaint.color = mainColor;
        for (final dx in const <double>[-2.8, 2.8]) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(cx + dx * s, cy - 1.5 * s), width: 4.6 * s, height: 6.4 * s),
              Radius.circular(1.6 * s),
            ),
            _crateItemPaint,
          );
          _crateDetailPaint.color = const Color(0xFFFFE082);
          canvas.drawRect(
            Rect.fromCenter(center: Offset(cx + dx * s, cy - 4.7 * s), width: 4.0 * s, height: 1.6 * s),
            _crateDetailPaint,
          );
        }
    }
  }

  static final Paint _arcTrackPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  static final Paint _arcFillPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  static final Paint _circleBgPaint = Paint();
  static final Paint _circleBorderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.8;
  static const TextStyle _circleEmojiStyle = TextStyle(fontSize: 13);

  /// Draws a compact circular progress arc clockwise from 12 o'clock.
  static void drawProgressArc(
    Canvas canvas,
    Offset center,
    double radius,
    double progress,
    Color color, {
    Color trackColor = const Color(0x66FFFFFF),
    double strokeWidth = 3.2,
  }) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    _arcTrackPaint
      ..color = trackColor
      ..strokeWidth = strokeWidth;
    canvas.drawArc(rect, 0, math.pi * 2, false, _arcTrackPaint);

    final sweep = progress.clamp(0.0, 1.0) * math.pi * 2;
    if (sweep > 0.01) {
      _arcFillPaint
        ..color = color
        ..strokeWidth = strokeWidth;
      canvas.drawArc(rect, -math.pi * 0.5, sweep, false, _arcFillPaint);
    }
  }

  /// Draws a crisp interactive circular action icon badge in world space.
  static void drawActionCircleBadge(
    Canvas canvas,
    Offset center,
    String emoji, {
    Color background = const Color(0xF5FFFDF6),
    Color border = const Color(0xFFFFB300),
    double radius = 12.5,
  }) {
    canvas.drawCircle(center.translate(0, 1.6), radius, _pillShadowPaint);
    _circleBgPaint.color = background;
    _circleBorderPaint.color = border;
    canvas.drawCircle(center, radius, _circleBgPaint);
    canvas.drawCircle(center, radius, _circleBorderPaint);
    drawCenteredText(canvas, emoji, center, _circleEmojiStyle);
  }

  /// Draws crisp vector mini-icons on world-space Action Queue badges so
  /// glyphs never turn into missing-font tofu boxes across platforms.
  static void drawCanvasActionIcon(
    Canvas canvas,
    ActionKind kind,
    Offset center,
    double size,
  ) {
    final r = size * 0.48;
    final cx = center.dx;
    final cy = center.dy;
    switch (kind) {
      case ActionKind.dig:
        // Wooden handle + silver spade blade
        _iconStrokePaint
          ..color = const Color(0xFF6D4C41)
          ..strokeWidth = 2.0;
        canvas.drawLine(Offset(cx - r * 0.6, cy + r * 0.6), Offset(cx + r * 0.25, cy - r * 0.25), _iconStrokePaint);
        _iconPath
          ..reset()
          ..moveTo(cx, cy - r * 0.4)
          ..lineTo(cx + r * 0.75, cy - r * 0.75)
          ..lineTo(cx + r * 0.4, cy)
          ..close();
        _iconFillPaint.color = const Color(0xFF78909C);
        canvas.drawPath(_iconPath, _iconFillPaint);
      case ActionKind.plant:
      case ActionKind.removeStructure:
        // Twin fresh emerald sprout leaves
        _iconStrokePaint
          ..color = const Color(0xFF2E7D32)
          ..strokeWidth = 1.8;
        canvas.drawLine(Offset(cx, cy + r * 0.7), Offset(cx, cy - r * 0.1), _iconStrokePaint);
        _iconFillPaint.color = const Color(0xFF43A047);
        canvas.drawOval(Rect.fromCenter(center: Offset(cx - r * 0.42, cy - r * 0.25), width: r * 0.85, height: r * 0.55), _iconFillPaint);
        canvas.drawOval(Rect.fromCenter(center: Offset(cx + r * 0.42, cy - r * 0.42), width: r * 0.85, height: r * 0.55), _iconFillPaint);
      case ActionKind.water:
      case ActionKind.refillWater:
        // Glossy cerulean water droplet
        _iconPath
          ..reset()
          ..moveTo(cx, cy - r * 0.85)
          ..quadraticBezierTo(cx + r * 0.85, cy + r * 0.15, cx, cy + r * 0.78)
          ..quadraticBezierTo(cx - r * 0.85, cy + r * 0.15, cx, cy - r * 0.85)
          ..close();
        _iconFillPaint.color = const Color(0xFF039BE5);
        canvas.drawPath(_iconPath, _iconFillPaint);
        _iconFillPaint.color = const Color(0x99FFFFFF);
        canvas.drawCircle(Offset(cx - r * 0.2, cy + r * 0.1), r * 0.18, _iconFillPaint);
      case ActionKind.compost:
        // Golden 4-point sparkle
        _iconFillPaint.color = const Color(0xFFFF8F00);
        drawStar4(canvas, center, r * 0.92, _iconFillPaint);
      case ActionKind.harvest:
      case ActionKind.pickupCrate:
        // Mini warm timber crate
        _iconFillPaint.color = const Color(0xFFD7995B);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: center, width: r * 1.45, height: r * 1.15),
            const Radius.circular(2.0),
          ),
          _iconFillPaint,
        );
        _iconStrokePaint
          ..color = const Color(0xFF5D4037)
          ..strokeWidth = 1.4;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: center, width: r * 1.45, height: r * 1.15),
            const Radius.circular(2.0),
          ),
          _iconStrokePaint,
        );
      case ActionKind.sellAtStall:
        // Sunlit gold coin
        _iconFillPaint.color = const Color(0xFFFFB300);
        canvas.drawCircle(center, r * 0.75, _iconFillPaint);
        _iconStrokePaint
          ..color = const Color(0xFFE65100)
          ..strokeWidth = 1.3;
        canvas.drawCircle(center, r * 0.75, _iconStrokePaint);
      case ActionKind.storeInBarn:
        // Mini red barn roof
        _iconPath
          ..reset()
          ..moveTo(cx - r * 0.75, cy + r * 0.05)
          ..lineTo(cx, cy - r * 0.72)
          ..lineTo(cx + r * 0.75, cy + r * 0.05)
          ..lineTo(cx + r * 0.58, cy + r * 0.72)
          ..lineTo(cx - r * 0.58, cy + r * 0.72)
          ..close();
        _iconFillPaint.color = const Color(0xFFC62828);
        canvas.drawPath(_iconPath, _iconFillPaint);
      case ActionKind.tendAnimal:
        // Golden wheat tuft
        _iconFillPaint.color = const Color(0xFFFBC02D);
        canvas.drawOval(Rect.fromCenter(center: center, width: r * 0.7, height: r * 1.4), _iconFillPaint);
      case ActionKind.loadArtisan:
        // Copper kettle jar
        _iconFillPaint.color = const Color(0xFFAD1457);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, cy + r * 0.1), width: r * 1.1, height: r * 1.2),
            const Radius.circular(2.5),
          ),
          _iconFillPaint,
        );
      case ActionKind.placeBuild:
        // Mini hammer
        _iconStrokePaint
          ..color = const Color(0xFF5D4037)
          ..strokeWidth = 2.0;
        canvas.drawLine(Offset(cx - r * 0.55, cy + r * 0.55), Offset(cx + r * 0.25, cy - r * 0.25), _iconStrokePaint);
        _iconFillPaint.color = const Color(0xFF607D8B);
        canvas.drawRect(Rect.fromCenter(center: Offset(cx + r * 0.35, cy - r * 0.35), width: r * 0.9, height: r * 0.45), _iconFillPaint);
      case ActionKind.claimLandmark:
        // Sparkling sapphire gem
        _iconPath
          ..reset()
          ..moveTo(cx, cy - r * 0.78)
          ..lineTo(cx + r * 0.68, cy)
          ..lineTo(cx, cy + r * 0.78)
          ..lineTo(cx - r * 0.68, cy)
          ..close();
        _iconFillPaint.color = const Color(0xFF29B6F6);
        canvas.drawPath(_iconPath, _iconFillPaint);
      case ActionKind.smart:
        _iconFillPaint.color = const Color(0xFF5D4037);
        canvas.drawCircle(center, r * 0.4, _iconFillPaint);
    }
  }
}
