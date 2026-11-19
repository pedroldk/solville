import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart'
    show Alignment, Color, LinearGradient, Offset, Rect, Size;

import '../../domain/iso/iso_projection.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/grid_pos.dart';
import '../../domain/models/tile_state.dart';

/// Renders Solville's custom GLSL sky dome, arcing sun/moon, multi-layer
/// parallax clouds, additive evening lantern/window light pools, volumetric
/// sunbeams, and subtle day/twilight color grading.
class AtmospherePainter {
  ui.FragmentProgram? _skyProgram;
  ui.FragmentShader? _skyShader;
  ui.FragmentProgram? _atmoProgram;
  ui.FragmentShader? _atmoShader;
  bool _shadersAttempted = false;

  final ui.Paint _shaderPaint = ui.Paint();
  final ui.Paint _fallbackSkyPaint = ui.Paint();
  final ui.Paint _cloudLitPaint = ui.Paint();
  final ui.Paint _cloudMidPaint = ui.Paint();
  final ui.Paint _cloudShadePaint = ui.Paint();
  final ui.Paint _cloudRimPaint = ui.Paint();
  final ui.Paint _cloudShadowPaint = ui.Paint()
    ..color = const Color(0x0E1A3B5C);
  final ui.Paint _archipelagoPaint = ui.Paint();
  final ui.Paint _birdStrokePaint = ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeCap = ui.StrokeCap.round;
  final ui.Paint _lightPoolPaint = ui.Paint()..blendMode = ui.BlendMode.plus;
  final ui.Paint _beamPaint = ui.Paint();
  final ui.Paint _fxPaint = ui.Paint();
  final ui.Path _beamPath = ui.Path();
  final ui.Path _moonPath = ui.Path();
  final ui.Path _isletPath = ui.Path();
  final ui.Path _islandClipPath = ui.Path();
  final ui.Path _birdPath = ui.Path();

  double _cachedSkyW = -1;
  double _cachedSkyH = -1;
  int _cachedSkyStep = -1;
  WeatherType? _cachedSkyWeather;

  ui.Shader? _warmPoolShader;
  ui.Shader? _firePoolShader;
  ui.Shader? _sunCoronaShader;

  Future<void> loadShaders() async {
    if (_shadersAttempted) return;
    _shadersAttempted = true;
    try {
      _skyProgram = await ui.FragmentProgram.fromAsset(
        'shaders/solville_sky.frag',
      );
      _skyShader = _skyProgram!.fragmentShader();
    } catch (_) {
      _skyProgram = null;
      _skyShader = null;
    }
    try {
      _atmoProgram = await ui.FragmentProgram.fromAsset(
        'shaders/solville_atmosphere.frag',
      );
      _atmoShader = _atmoProgram!.fragmentShader();
    } catch (_) {
      _atmoProgram = null;
      _atmoShader = null;
    }
  }

  void _ensureCachedOriginShaders() {
    _warmPoolShader ??= ui.Gradient.radial(
      Offset.zero,
      72.0,
      const <Color>[
        Color(0x58FFE082),
        Color(0x28FFB300),
        Color(0x00FF8F00),
      ],
      const <double>[0.0, 0.45, 1.0],
    );
    _firePoolShader ??= ui.Gradient.radial(
      Offset.zero,
      58.0,
      const <Color>[
        Color(0x55FF8A65),
        Color(0x24FF7043),
        Color(0x00D84315),
      ],
      const <double>[0.0, 0.48, 1.0],
    );
    _sunCoronaShader ??= ui.Gradient.radial(
      Offset.zero,
      110.0,
      const <Color>[
        Color(0xEEFFFDE7),
        Color(0x66FFE082),
        Color(0x18FFCA28),
        Color(0x00FFCA28),
      ],
      const <double>[0.0, 0.22, 0.56, 1.0],
    );
  }

  void drawSkyDome(
    ui.Canvas canvas,
    Size size,
    double dayProgress,
    WeatherType weather,
    double animTime,
  ) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;

    final shader = _skyShader;
    if (shader != null) {
      shader.setFloat(0, w);
      shader.setFloat(1, h);
      shader.setFloat(2, dayProgress.clamp(0.0, 1.0));
      shader.setFloat(3, animTime);
      shader.setFloat(4, weather == WeatherType.gentleRain ? 1.0 : 0.0);
      _shaderPaint.shader = shader;
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), _shaderPaint);
      return;
    }

    _drawFallbackSkyDome(canvas, w, h, dayProgress, weather, animTime);
  }

  void _drawFallbackSkyDome(
    ui.Canvas canvas,
    double w,
    double h,
    double p,
    WeatherType weather,
    double animTime,
  ) {
    final skyStep = (p * 60.0).round();
    if (_fallbackSkyPaint.shader == null ||
        _cachedSkyW != w ||
        _cachedSkyH != h ||
        _cachedSkyStep != skyStep ||
        _cachedSkyWeather != weather) {
      _cachedSkyW = w;
      _cachedSkyH = h;
      _cachedSkyStep = skyStep;
      _cachedSkyWeather = weather;

      final colors = _resolveSkyPalette(p, weather);
      _fallbackSkyPaint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[colors.top, colors.mid, colors.horizon],
        stops: const <double>[0.0, 0.56, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    }
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), _fallbackSkyPaint);

    _ensureCachedOriginShaders();
    final isRain = weather == WeatherType.gentleRain;

    // Fallback Sun corona + disc (sets cleanly before crescent moon rises)
    final minDim = math.min(w, h);
    if (p < 0.81 && !isRain) {
      final sunFade = (1.0 - ((p - 0.70) / 0.11).clamp(0.0, 1.0));
      final sunArc = (p / 0.82).clamp(0.0, 1.0);
      final sx = w * (0.18 + sunArc * 0.64);
      final sy = h * (0.14 + 0.18 * math.pow((sunArc - 0.35) * 1.35, 2));

      canvas.save();
      canvas.translate(sx, sy);
      final coronaScale = (minDim / 720.0).clamp(0.55, 1.15);
      canvas.scale(coronaScale, coronaScale);
      _fxPaint
        ..shader = _sunCoronaShader
        ..color = Color.fromRGBO(255, 255, 255, sunFade);
      canvas.drawCircle(Offset.zero, 96.0, _fxPaint);
      _fxPaint.shader = null;
      _fxPaint.color = Color.fromRGBO(255, 250, 224, sunFade);
      canvas.drawCircle(Offset.zero, 20.0, _fxPaint);
      canvas.restore();
    }

    // Fallback twilight stars & crescent moon rising after sunset
    if (p > 0.72 && !isRain) {
      final starAlpha = ((p - 0.72) / 0.20).clamp(0.0, 1.0);
      for (var i = 0; i < 18; i++) {
        final sx = w * (((i * 73 + 19) % 97) / 97.0);
        final sy = h * (0.06 + ((i * 41 + 7) % 52) / 100.0);
        final twinkle = 0.55 + 0.45 * math.sin(animTime * 2.1 + i * 1.3);
        _fxPaint.color = Color.fromRGBO(
          255,
          248,
          225,
          0.72 * twinkle * starAlpha,
        );
        canvas.drawCircle(Offset(sx, sy), (i % 3 == 0) ? 1.8 : 1.1, _fxPaint);
      }

      if (p > 0.81) {
        final moonAlpha = ((p - 0.81) / 0.13).clamp(0.0, 1.0);
        final mx = w * 0.78;
        final my = h * 0.18;
        _fxPaint.color = Color.fromRGBO(220, 232, 255, 0.22 * moonAlpha);
        canvas.drawCircle(Offset(mx, my), 30.0, _fxPaint);
        _moonPath
          ..reset()
          ..addOval(Rect.fromCircle(center: Offset(mx, my), radius: 13.0));
        _fxPaint.color = Color.fromRGBO(240, 246, 255, 0.90 * moonAlpha);
        canvas.drawPath(_moonPath, _fxPaint);
      }
    }
  }

  ({Color top, Color mid, Color horizon}) _resolveSkyPalette(
    double p,
    WeatherType weather,
  ) {
    if (weather == WeatherType.gentleRain) {
      return (
        top: const Color(0xFF526D7A),
        mid: const Color(0xFF78909C),
        horizon: const Color(0xFFB5C5CD),
      );
    }
    if (p < 0.25) {
      final t = (p / 0.25).clamp(0.0, 1.0);
      return (
        top: Color.lerp(const Color(0xFF2FA8F6), const Color(0xFF1F92EC), t)!,
        mid: Color.lerp(const Color(0xFF7AD6FC), const Color(0xFF66CEFA), t)!,
        horizon: Color.lerp(
          const Color(0xFFFFE3B8),
          const Color(0xFFE3F7FF),
          t,
        )!,
      );
    }
    if (p < 0.60) {
      final t = ((p - 0.25) / 0.35).clamp(0.0, 1.0);
      return (
        top: Color.lerp(const Color(0xFF1F92EC), const Color(0xFF3A7BE0), t)!,
        mid: Color.lerp(const Color(0xFF66CEFA), const Color(0xFF8CC5FA), t)!,
        horizon: Color.lerp(
          const Color(0xFFE3F7FF),
          const Color(0xFFFFF3DD),
          t,
        )!,
      );
    }
    if (p < 0.82) {
      final t = ((p - 0.60) / 0.22).clamp(0.0, 1.0);
      return (
        top: Color.lerp(const Color(0xFF3A7BE0), const Color(0xFF3B4DAE), t)!,
        mid: Color.lerp(const Color(0xFF8CC5FA), const Color(0xFFFA8E68), t)!,
        horizon: Color.lerp(
          const Color(0xFFFFF3DD),
          const Color(0xFFFFD685),
          t,
        )!,
      );
    }
    final t = ((p - 0.82) / 0.18).clamp(0.0, 1.0);
    return (
      top: Color.lerp(const Color(0xFF3B4DAE), const Color(0xFF141E57), t)!,
      mid: Color.lerp(const Color(0xFFFA8E68), const Color(0xFF304494), t)!,
      horizon: Color.lerp(const Color(0xFFFFD685), const Color(0xFF737BC2), t)!,
    );
  }

  /// Renders distant hazy floating sky-islets and soaring Mediterranean swallow
  /// silhouettes in screen space with subtle camera parallax so the main island
  /// feels part of a sunlit sky archipelago.
  void drawSkyArchipelago(
    ui.Canvas canvas,
    Size size,
    double cameraX,
    double cameraY,
    double dayProgress,
    WeatherType weather,
    double animTime,
  ) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;

    final isRain = weather == WeatherType.gentleRain;
    final isSunset = dayProgress >= 0.58 && dayProgress < 0.84;
    final isNight = dayProgress >= 0.84;

    final Color turfCol;
    final Color rockCol;
    final Color mistCol;
    final Color accentCol;
    if (isRain) {
      turfCol = const Color(0x44607D8B);
      rockCol = const Color(0x44455A64);
      mistCol = const Color(0x38CFD8DC);
      accentCol = const Color(0x4478909C);
    } else if (isNight) {
      turfCol = const Color(0x3D3949AB);
      rockCol = const Color(0x3D283593);
      mistCol = const Color(0x285C6BC0);
      accentCol = const Color(0x66FFD54F);
    } else if (isSunset) {
      turfCol = const Color(0x588E6C88);
      rockCol = const Color(0x526D4C6D);
      mistCol = const Color(0x44FFE0B2);
      accentCol = const Color(0x66FFB74D);
    } else {
      turfCol = const Color(0x5265A894);
      rockCol = const Color(0x48587C8C);
      mistCol = const Color(0x4DFFFFFF);
      accentCol = const Color(0x55D86C4A);
    }

    final islets = <({double fx, double fy, double scale, bool hasCottage})>[
      (fx: 0.11, fy: 0.30, scale: 0.88, hasCottage: true),
      (fx: 0.89, fy: 0.36, scale: 1.02, hasCottage: true),
      (fx: 0.15, fy: 0.72, scale: 0.65, hasCottage: false),
    ];

    for (var i = 0; i < islets.length; i++) {
      final d = islets[i];
      final px =
          w * d.fx -
          cameraX * (0.04 + i * 0.015) +
          math.sin(animTime * 0.3 + i) * 3.0;
      final py =
          h * d.fy -
          cameraY * (0.04 + i * 0.015) +
          math.cos(animTime * 0.55 + i * 1.4) * 3.5;
      final s = d.scale * (math.min(w, h) / 720.0).clamp(0.65, 1.15);

      // Soft misty collar beneath distant islet
      _archipelagoPaint.color = mistCol;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(px, py + 15 * s),
          width: 78 * s,
          height: 16 * s,
        ),
        _archipelagoPaint,
      );

      // Tapered floating rock underside
      _isletPath
        ..reset()
        ..moveTo(px - 28 * s, py + 2 * s)
        ..lineTo(px + 28 * s, py + 2 * s)
        ..lineTo(px + 12 * s, py + 18 * s)
        ..lineTo(px - 2 * s, py + 23 * s)
        ..lineTo(px - 18 * s, py + 14 * s)
        ..close();
      _archipelagoPaint.color = rockCol;
      canvas.drawPath(_isletPath, _archipelagoPaint);

      // Rolling sunlit turf cap
      _archipelagoPaint.color = turfCol;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(px, py), width: 60 * s, height: 15 * s),
        _archipelagoPaint,
      );

      // Miniature distant cypress silhouettes & cottage speck
      _isletPath
        ..reset()
        ..moveTo(px - 18 * s, py - 2 * s)
        ..lineTo(px - 14 * s, py - 15 * s)
        ..lineTo(px - 10 * s, py - 2 * s)
        ..close();
      canvas.drawPath(_isletPath, _archipelagoPaint);
      _isletPath
        ..reset()
        ..moveTo(px + 11 * s, py - 2 * s)
        ..lineTo(px + 15 * s, py - 13 * s)
        ..lineTo(px + 19 * s, py - 2 * s)
        ..close();
      canvas.drawPath(_isletPath, _archipelagoPaint);

      if (d.hasCottage) {
        _archipelagoPaint.color = accentCol;
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(px, py - 6 * s),
            width: 8 * s,
            height: 6 * s,
          ),
          _archipelagoPaint,
        );
      }
    }

    // Soaring distant swallow silhouettes during sunny / golden-breeze daylight
    if (!isRain && dayProgress < 0.80) {
      final birdAlpha = (1.0 - ((dayProgress - 0.65) / 0.15).clamp(0.0, 1.0));
      _birdStrokePaint
        ..color = Color.fromRGBO(55, 71, 79, 0.42 * birdAlpha)
        ..strokeWidth = 1.6;
      for (var flock = 0; flock < 2; flock++) {
        final fx =
            ((w * (0.22 + flock * 0.42) + animTime * (12.0 + flock * 4.0)) %
                (w + 120.0)) -
            60.0;
        final fy =
            h * (0.20 + flock * 0.10) +
            math.sin(animTime * 0.7 + flock * 2.0) * 10.0;
        for (var b = 0; b < 3; b++) {
          final bx = fx - b * 14.0;
          final by = fy + (b == 1 ? -5.0 : b * 4.5);
          final flap = math.sin(animTime * 5.8 + b * 1.1 + flock) * 3.0;
          _birdPath
            ..reset()
            ..moveTo(bx - 5.5, by - flap)
            ..quadraticBezierTo(bx - 2.2, by - 2.5, bx, by)
            ..quadraticBezierTo(bx + 2.2, by - 2.5, bx + 5.5, by - flap);
          canvas.drawPath(_birdPath, _birdStrokePaint);
        }
      }
    }
  }

  /// Renders multi-depth 3-tone sculptural cumulus clouds (plus soft lower
  /// cloud banks below the island) with sunlit ivory tops and shaded undersides.
  void drawParallaxClouds(
    ui.Canvas canvas,
    IsoProjection iso,
    int gridSize,
    double dayProgress,
    WeatherType weather,
    double animTime,
  ) {
    final isRain = weather == WeatherType.gentleRain;
    final isSunset = dayProgress >= 0.58 && dayProgress < 0.84;
    final isNight = dayProgress >= 0.84;

    final Color litColor;
    final Color midColor;
    final Color shadeColor;
    if (isRain) {
      litColor = const Color(0x70CFD8DC);
      midColor = const Color(0x66B0BEC5);
      shadeColor = const Color(0x5278909C);
    } else if (isNight) {
      litColor = const Color(0x42B0BEC5);
      midColor = const Color(0x3890A4AE);
      shadeColor = const Color(0x365C6BC0);
    } else if (isSunset) {
      litColor = const Color(0x7CFFE0B2);
      midColor = const Color(0x6CFFCCBC);
      shadeColor = const Color(0x56D9889B);
    } else {
      litColor = const Color(0x88FFFFFF);
      midColor = const Color(0x6EEAF6FF);
      shadeColor = const Color(0x4DAACFEB);
    }

    final halfSpanX = gridSize * iso.tileWidth * 0.68;
    final spanX = halfSpanX * 2.0;
    final cloudCount = (gridSize ~/ 3).clamp(5, 11) + 2;

    for (var c = 0; c < cloudCount; c++) {
      final isLowHorizon = c >= cloudCount - 2;
      final isFar = c.isEven;
      final speed = isLowHorizon
          ? (4.2 + c * 0.3)
          : (isFar ? (3.2 + c * 0.45) : (6.8 + c * 0.75));
      final scale = isLowHorizon ? 1.25 : (isFar ? 0.82 : 1.06);
      final baseX = -halfSpanX + ((animTime * speed + c * 280.0) % spanX);
      final baseY = isLowHorizon
          ? (gridSize * iso.tileHeight * 0.86 + (c % 2) * 34.0)
          : (-150.0 + c * (gridSize * iso.tileHeight * 0.115));

      _cloudShadePaint.color = shadeColor;
      _cloudMidPaint.color = midColor;
      _cloudLitPaint.color = litColor;
      _cloudRimPaint.color = litColor.withValues(
        alpha: (litColor.a * 0.62).clamp(0.0, 1.0),
      );

      // Soft shaded cloud underside
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(baseX + 3 * scale, baseY + 7 * scale),
          width: 150 * scale,
          height: 31 * scale,
        ),
        _cloudShadePaint,
      );

      // Warm mid-tone body puff
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(baseX, baseY + 2 * scale),
          width: 140 * scale,
          height: 30 * scale,
        ),
        _cloudMidPaint,
      );

      // Sculpted sunlit multi-puff cumulus crown
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(baseX - 30 * scale, baseY - 9 * scale),
          width: 74 * scale,
          height: 31 * scale,
        ),
        _cloudLitPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(baseX + 26 * scale, baseY - 7 * scale),
          width: 70 * scale,
          height: 28 * scale,
        ),
        _cloudLitPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(baseX - 4 * scale, baseY - 15 * scale),
          width: 62 * scale,
          height: 28 * scale,
        ),
        _cloudRimPaint,
      );
    }
  }

  /// Renders soft drifting cloud shadows moving slowly across the sunlit
  /// island diamond during sunny / golden-breeze daylight.
  void drawCloudShadows(
    ui.Canvas canvas,
    IsoProjection iso,
    int gridSize,
    double dayProgress,
    WeatherType weather,
    double animTime,
  ) {
    if (weather == WeatherType.gentleRain || dayProgress >= 0.80) return;

    final hw = iso.tileWidth * 0.5;
    final hh = iso.tileHeight * 0.5;
    final top = Offset(0, -hh);
    final right = Offset(gridSize * hw, (gridSize - 1) * hh);
    final bottom = Offset(0, (2 * gridSize - 1) * hh);
    final left = Offset(-gridSize * hw, (gridSize - 1) * hh);

    _islandClipPath
      ..reset()
      ..moveTo(top.dx, top.dy)
      ..lineTo(right.dx, right.dy)
      ..lineTo(bottom.dx, bottom.dy)
      ..lineTo(left.dx, left.dy)
      ..close();

    final fade = 1.0 - ((dayProgress - 0.65) / 0.15).clamp(0.0, 1.0);
    _cloudShadowPaint.color = Color.fromRGBO(24, 52, 82, 0.065 * fade);

    final spanW = right.dx - left.dx + 320.0;
    canvas.save();
    canvas.clipPath(_islandClipPath);
    for (var i = 0; i < 3; i++) {
      final sx =
          left.dx -
          160.0 +
          ((animTime * (12.0 + i * 2.5) + i * 380.0) % spanW);
      final sy = top.dy + (bottom.dy - top.dy) * (0.24 + i * 0.27);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(sx, sy),
          width: 220.0 + i * 35.0,
          height: 92.0 + i * 14.0,
        ),
        _cloudShadowPaint,
      );
    }
    canvas.restore();
  }

  /// Renders soft additive warm golden light pools around lanterns, farmhouse
  /// windows, market stall lamps, and simmering artisan hearths at dusk AND
  /// cozy rainy weather.
  void drawDuskLightPools(
    ui.Canvas canvas,
    IsoProjection iso,
    GameState state,
    double animTime, {
    required Rect visibleRect,
  }) {
    final isRain = state.weather == WeatherType.gentleRain;
    if (state.dayProgress <= 0.52 && !isRain) return;
    _ensureCachedOriginShaders();

    final duskT = ((state.dayProgress - 0.52) / 0.30).clamp(0.0, 1.0);
    final lightStrength = math.max(duskT, isRain ? 0.55 : 0.0);
    final size = state.gridSize;
    final tiles = state.tiles;
    final minX = visibleRect.left;
    final maxX = visibleRect.right;
    final minY = visibleRect.top;
    final maxY = visibleRect.bottom;

    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        final tile = tiles[y * size + x];
        final s = tile.structure;
        if (s != StructureType.lantern &&
            s != StructureType.farmhouse &&
            s != StructureType.marketStall &&
            !(s == StructureType.artisanPress && tile.producerActive)) {
          continue;
        }
        final center = iso.tileCenterToWorld(GridPos(x, y));
        if (center.x < minX ||
            center.x > maxX ||
            center.y < minY ||
            center.y > maxY) {
          continue;
        }

        final flicker = 0.90 + 0.10 * math.sin(animTime * 4.2 + x * 1.7 + y);
        final isFire = s == StructureType.artisanPress;
        final double radius = switch (s) {
          StructureType.farmhouse => 78.0,
          StructureType.lantern => 72.0,
          StructureType.marketStall => 62.0,
          _ => 56.0,
        };
        final double oy = switch (s) {
          StructureType.farmhouse => -16.0,
          StructureType.lantern => -14.0,
          StructureType.marketStall => -24.0,
          _ => -6.0,
        };

        canvas.save();
        canvas.translate(center.x, center.y + oy);
        _lightPoolPaint
          ..shader = isFire ? _firePoolShader : _warmPoolShader
          ..color = Color.fromRGBO(255, 255, 255, lightStrength * flicker * 0.95);
        canvas.drawCircle(Offset.zero, radius, _lightPoolPaint);
        canvas.restore();
      }
    }
    _lightPoolPaint.shader = null;
  }

  /// Applies screen-space volumetric sunbeams, golden-hour wash, twilight
  /// grading, and gentle storybook vignette.
  void drawAtmosphericOverlay(
    ui.Canvas canvas,
    Size size,
    double dayProgress,
    WeatherType weather,
    double animTime,
  ) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;

    final shader = _atmoShader;
    if (shader != null) {
      shader.setFloat(0, w);
      shader.setFloat(1, h);
      shader.setFloat(2, dayProgress.clamp(0.0, 1.0));
      shader.setFloat(3, animTime);
      shader.setFloat(4, weather == WeatherType.gentleRain ? 1.0 : 0.0);
      _shaderPaint.shader = shader;
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), _shaderPaint);
      return;
    }

    _drawFallbackAtmosphericOverlay(canvas, w, h, dayProgress, weather, animTime);
  }

  void _drawFallbackAtmosphericOverlay(
    ui.Canvas canvas,
    double w,
    double h,
    double p,
    WeatherType weather,
    double animTime,
  ) {
    final isRain = weather == WeatherType.gentleRain;

    // Gentle sunlit diagonal god-rays from top-left
    if (!isRain && p < 0.84) {
      final rayStrength = (1.0 - ((p - 0.68) / 0.16).clamp(0.0, 1.0));
      final pulse = 0.85 + 0.15 * math.sin(animTime * 0.7);
      _beamPaint.color = Color.fromRGBO(
        255,
        245,
        204,
        0.065 * rayStrength * pulse,
      );
      for (var i = 0; i < 3; i++) {
        final sx = w * (0.04 + i * 0.22);
        final bw = w * (0.12 + i * 0.03);
        _beamPath
          ..reset()
          ..moveTo(sx, 0)
          ..lineTo(sx + bw, 0)
          ..lineTo(sx + bw + h * 0.65, h)
          ..lineTo(sx + h * 0.55, h)
          ..close();
        canvas.drawPath(_beamPath, _beamPaint);
      }
    }

    // Golden-hour / twilight / rain color grading wash
    if (isRain) {
      _fxPaint.color = const Color(0x16607D8B);
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), _fxPaint);
    } else if (p >= 0.58 && p < 0.84) {
      final t = math.sin(((p - 0.58) / 0.26).clamp(0.0, 1.0) * math.pi);
      _fxPaint.color = Color.fromRGBO(255, 183, 77, 0.075 * t);
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), _fxPaint);
    } else if (p >= 0.84) {
      final t = ((p - 0.84) / 0.16).clamp(0.0, 1.0);
      _fxPaint.color = Color.fromRGBO(26, 35, 126, 0.16 * t);
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), _fxPaint);
    }
  }
}
