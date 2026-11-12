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

  static const Color _defaultPanelColor = Color(0xF2FFFDF6);

  static const List<BoxShadow> _panelShadow = <BoxShadow>[
    BoxShadow(color: Color(0x29000000), blurRadius: 10, offset: Offset(0, 4)),
  ];

  static const Border _defaultPanelBorder = Border.fromBorderSide(
    BorderSide(color: timberBorder, width: 2.2),
  );

  static const BoxDecoration _panelR16 = BoxDecoration(
    color: _defaultPanelColor,
    borderRadius: BorderRadius.all(Radius.circular(16)),
    border: _defaultPanelBorder,
    boxShadow: _panelShadow,
  );

  static const BoxDecoration _panelR18 = BoxDecoration(
    color: _defaultPanelColor,
    borderRadius: BorderRadius.all(Radius.circular(18)),
    border: _defaultPanelBorder,
    boxShadow: _panelShadow,
  );

  static const BoxDecoration _panelR22 = BoxDecoration(
    color: _defaultPanelColor,
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
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: borderColor == timberBorder
          ? _defaultPanelBorder
          : Border.all(color: borderColor, width: 2.2),
      boxShadow: _panelShadow,
    );
  }
}
