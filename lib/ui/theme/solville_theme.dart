import 'package:flutter/material.dart';

/// Warm sunlit Mediterranean / cozy countryside theme for Solville.
abstract final class SolvilleTheme {
  static const Color parchment = Color(0xFFFFFDF6);
  static const Color warmCream = Color(0xFFFFF5DC);
  static const Color timberDark = Color(0xFF4E342E);
  static const Color timberBorder = Color(0xFF795548);
  static const Color sunGold = Color(0xFFFFB300);
  static const Color sunAmberLight = Color(0xFFFFECB3);
  static const Color meadowGreen = Color(0xFF43A047);
  static const Color skyWater = Color(0xFF0288D1);
  static const Color terracotta = Color(0xFFD84315);
  static const Color cedarOuter = Color(0xFF7A4E32);
  static const Color cedarDark = Color(0xFF4B2D1C);
  static const Color cedarHighlight = Color(0xFFB37B52);
  static const Color recessedWood = Color(0xFFEAD9BA);
  static const Color brassGold = Color(0xFFDDA128);
  static const Color brassLight = Color(0xFFFFE57F);

  static const Color _defaultPanelColor = Color(0xF5FFFDF6);
  static const Color _softBorderColor = Color(0x78795548);

  static const List<BoxShadow> _panelShadow = <BoxShadow>[
    BoxShadow(
      color: Color(0x283E2723),
      blurRadius: 12,
      offset: Offset(0, 3),
    ),
    BoxShadow(
      color: Color(0x14FFFFFF),
      blurRadius: 1,
      spreadRadius: 0.5,
      offset: Offset(0, -1),
    ),
  ];

  static const Border _defaultPanelBorder = Border.fromBorderSide(
    BorderSide(color: _softBorderColor, width: 1.5),
  );

  static const LinearGradient _defaultPanelGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[Color(0xFAFFFDF8), Color(0xF2FFF4DE)],
  );

  static const BoxDecoration _panelR16 = BoxDecoration(
    gradient: _defaultPanelGradient,
    borderRadius: BorderRadius.all(Radius.circular(16)),
    border: _defaultPanelBorder,
    boxShadow: _panelShadow,
  );

  static const BoxDecoration _panelR18 = BoxDecoration(
    gradient: _defaultPanelGradient,
    borderRadius: BorderRadius.all(Radius.circular(18)),
    border: _defaultPanelBorder,
    boxShadow: _panelShadow,
  );

  static const BoxDecoration _panelR22 = BoxDecoration(
    gradient: _defaultPanelGradient,
    borderRadius: BorderRadius.all(Radius.circular(22)),
    border: _defaultPanelBorder,
    boxShadow: _panelShadow,
  );

  static ThemeData buildTheme() {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'GoogleSansFlex',
      colorScheme: ColorScheme.fromSeed(
        seedColor: sunGold,
        surface: parchment,
        primary: const Color(0xFFE65100),
        secondary: meadowGreen,
      ),
      scaffoldBackgroundColor: const Color(0xFF81D4FA),
      cardTheme: CardThemeData(
        color: parchment,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: timberBorder, width: 2),
        ),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: terracotta,
        inactiveTrackColor: recessedWood,
        thumbColor: sunGold,
        overlayColor: Color(0x33FFB300),
        trackHeight: 6.0,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 9.0),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>(
          (states) => states.contains(WidgetState.selected)
              ? parchment
              : const Color(0xFFFFF8E1),
        ),
        trackColor: WidgetStateProperty.resolveWith<Color>(
          (states) => states.contains(WidgetState.selected)
              ? meadowGreen
              : const Color(0xFFD7C29E),
        ),
        trackOutlineColor: WidgetStateProperty.all<Color>(cedarOuter),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: parchment,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: timberBorder, width: 1.6),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: timberBorder, width: 1.6),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE65100), width: 2.0),
        ),
      ),
    );
  }

  /// Crafted cedar-bordered HUD container with cream-linen top sheen and 3D bottom lip.
  static BoxDecoration hudBarDecoration({double radius = 20}) {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: <double>[0.0, 0.14, 1.0],
        colors: <Color>[Color(0xFFFFFFFE), Color(0xFFFFFBF0), Color(0xFFFFF0CF)],
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: const Color(0xFF6D442B), width: 2.0),
      boxShadow: const <BoxShadow>[
        BoxShadow(
          color: cedarDark,
          offset: Offset(0, 3),
          blurRadius: 0,
        ),
        BoxShadow(
          color: Color(0x36261412),
          offset: Offset(0, 6),
          blurRadius: 14,
        ),
      ],
    );
  }

  /// Recessed timber-parchment slot decoration for tabs, stall trays & stats.
  static BoxDecoration recessedSlotDecoration({
    double radius = 12,
    Color? color,
  }) {
    final bot = color ?? const Color(0xFFF6EAD0);
    final top = Color.lerp(bot, const Color(0xFFD2B48C), 0.35)!;
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: const <double>[0.0, 0.25, 1.0],
        colors: <Color>[top, bot, Color.lerp(bot, Colors.white, 0.22)!],
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: const Color(0x786D4C41), width: 1.3),
    );
  }

  static BoxDecoration panelDecoration({
    Color color = _defaultPanelColor,
    Color borderColor = timberBorder,
    double radius = 18,
  }) {
    if (color == _defaultPanelColor && borderColor == timberBorder) {
      if (radius == 18) return _panelR18;
      if (radius == 22) return _panelR22;
      if (radius == 16) return _panelR16;
    }
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          Color.lerp(color, Colors.white, 0.25) ?? color,
          color,
        ],
      ),
      borderRadius: BorderRadius.circular(radius),
      border: borderColor == timberBorder
          ? _defaultPanelBorder
          : Border.all(color: borderColor, width: 1.5),
      boxShadow: _panelShadow,
    );
  }

  static BoxDecoration cardDecoration({
    Color color = warmCream,
    Color borderColor = _softBorderColor,
    double radius = 16,
    bool highlighted = false,
  }) {
    final topCol = Color.lerp(color, Colors.white, 0.35) ?? color;
    final botCol = Color.lerp(color, const Color(0xFFF3E2C7), 0.18) ?? color;
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[topCol, botCol],
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: highlighted ? sunGold : borderColor,
        width: highlighted ? 1.8 : 1.35,
      ),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: highlighted
              ? const Color(0x36FFB300)
              : const Color(0x143E2723),
          blurRadius: highlighted ? 10 : 6,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  static BoxDecoration goldAccentDecoration({double radius = 16}) {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[Color(0xFFFFF3C4), Color(0xFFFFD54F)],
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: const Color(0xFFE65100), width: 1.8),
      boxShadow: const <BoxShadow>[
        BoxShadow(
          color: Color(0x4DFFCA28),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    );
  }
}
