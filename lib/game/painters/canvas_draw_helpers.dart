import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/painting.dart'
    show FontWeight, TextDirection, TextPainter, TextSpan, TextStyle;

import '../../domain/models/catalog.dart';
import '../../domain/models/tile_state.dart';

/// Shared low-level Canvas helpers for 2.5D crates, status bubbles, and centered text.
///
/// Uses a bounded LRU [TextPainter] cache and pre-allocated [Paint] objects to
/// eliminate per-frame paragraph layout and heap allocations in the render loop.
abstract final class CanvasDrawHelpers {
  static const int _maxTextCacheEntries = 256;
  static final LinkedHashMap<(String, TextStyle), TextPainter> _textCache =
      LinkedHashMap<(String, TextStyle), TextPainter>();

  static final Paint _pillFillPaint = Paint()..color = const Color(0xFFFFF8E1);
  static final Paint _pillStrokePaint = Paint()
    ..color = const Color(0xFFFFB300)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;
  static final Paint _hungryPillPaint = Paint()
    ..color = const Color(0xFFFFECB3);

  static final Paint _crateShadowPaint = Paint()
    ..color = const Color(0x38000000);
  static final Paint _crateBodyPaint = Paint()..color = const Color(0xFFD7995B);
  static final Paint _crateStrokePaint = Paint()
    ..color = const Color(0xFF6D4C41)
    ..style = PaintingStyle.stroke;
  static final Paint _cratePlankPaint = Paint()
    ..color = const Color(0xFF8D6E63);
  static final Paint _crateDotPaint = Paint();

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

  static void drawFloatingStatusPill(
    Canvas canvas,
    double x,
    double y,
    String text,
  ) {
    final r = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(x, y), width: 40, height: 20),
      const Radius.circular(10),
    );
    canvas.drawRRect(r, _pillFillPaint);
    canvas.drawRRect(r, _pillStrokePaint);
    drawCenteredText(canvas, text, Offset(x, y), _statusPillTextStyle);
  }

  static void drawAnimalStatusBubble(
    Canvas canvas,
    double x,
    double y,
    AnimalUnitState? state,
    String readyEmoji,
  ) {
    if (state == null) return;
    if (state.readyCrates > 0) {
      drawFloatingStatusPill(canvas, x, y, '$readyEmoji${state.readyCrates}');
    } else if (state.needsTending) {
      final r = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, y), width: 26, height: 19),
        const Radius.circular(9),
      );
      canvas.drawRRect(r, _hungryPillPaint);
      drawCenteredText(canvas, '🌾', Offset(x, y), _hungryEmojiTextStyle);
    }
  }

  static void drawWoodenCrate(
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
    canvas.drawRRect(rect.shift(Offset(0, 2 * scale)), _crateShadowPaint);
    canvas.drawRRect(rect, _crateBodyPaint);
    _crateStrokePaint.strokeWidth = 1.6 * scale;
    canvas.drawRRect(rect, _crateStrokePaint);
    _cratePlankPaint.strokeWidth = 1.2 * scale;
    canvas.drawLine(
      Offset(center.dx - w * 0.45, center.dy + 2 * scale),
      Offset(center.dx + w * 0.45, center.dy + 2 * scale),
      _cratePlankPaint,
    );

    _crateDotPaint.color = Color(SolvilleCatalog.productColorHex(product));
    canvas.drawCircle(
      Offset(center.dx - 4 * scale, center.dy - 3 * scale),
      4.2 * scale,
      _crateDotPaint,
    );
    canvas.drawCircle(
      Offset(center.dx + 4 * scale, center.dy - 3 * scale),
      4.2 * scale,
      _crateDotPaint,
    );
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
    _circleBgPaint.color = background;
    _circleBorderPaint.color = border;
    canvas.drawCircle(center, radius, _circleBgPaint);
    canvas.drawCircle(center, radius, _circleBorderPaint);
    drawCenteredText(canvas, emoji, center, _circleEmojiStyle);
  }
}
