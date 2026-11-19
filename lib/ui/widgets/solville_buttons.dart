import 'package:flutter/material.dart';

import '../theme/solville_theme.dart';

/// Color themes for tactile 3D storybook buttons in Solville.
enum SolvilleButtonTone { primary, emerald, amber, cream, coral, sky }

class _TonePalette {
  const _TonePalette({
    required this.top,
    required this.bottom,
    required this.lip,
    required this.border,
    required this.foreground,
    required this.hasTextShadow,
    required this.glow,
  });

  final Color top;
  final Color bottom;
  final Color lip;
  final Color border;
  final Color foreground;
  final bool hasTextShadow;
  final Color glow;
}

_TonePalette _paletteFor(SolvilleButtonTone tone, {required bool enabled}) {
  if (!enabled) {
    return const _TonePalette(
      top: Color(0xFFEFE8D8),
      bottom: Color(0xFFDDD2BC),
      lip: Color(0xFFB8AC94),
      border: Color(0xFF8C7E6A),
      foreground: Color(0xFF8A7C68),
      hasTextShadow: false,
      glow: Color(0x00000000),
    );
  }
  return switch (tone) {
    SolvilleButtonTone.primary => const _TonePalette(
      top: Color(0xFFFFB74D),
      bottom: Color(0xFFF57C00),
      lip: Color(0xFFB34700),
      border: Color(0xFF5A2605),
      foreground: Colors.white,
      hasTextShadow: true,
      glow: Color(0x4DFF9800),
    ),
    SolvilleButtonTone.emerald => const _TonePalette(
      top: Color(0xFF66BB6A),
      bottom: Color(0xFF2E7D32),
      lip: Color(0xFF1B5E20),
      border: Color(0xFF144418),
      foreground: Colors.white,
      hasTextShadow: true,
      glow: Color(0x4543A047),
    ),
    SolvilleButtonTone.amber => const _TonePalette(
      top: Color(0xFFFFE57F),
      bottom: Color(0xFFFFB300),
      lip: Color(0xFFC47B00),
      border: Color(0xFF5E3A00),
      foreground: SolvilleTheme.timberDark,
      hasTextShadow: false,
      glow: Color(0x55FFCA28),
    ),
    SolvilleButtonTone.cream => const _TonePalette(
      top: Color(0xFFFFFFFB),
      bottom: Color(0xFFF6E6C5),
      lip: Color(0xFFC4AA80),
      border: Color(0xFF6D4C41),
      foreground: SolvilleTheme.timberDark,
      hasTextShadow: false,
      glow: Color(0x28795548),
    ),
    SolvilleButtonTone.coral => const _TonePalette(
      top: Color(0xFFFF8A65),
      bottom: Color(0xFFE64A19),
      lip: Color(0xFFA52708),
      border: Color(0xFF5D1B09),
      foreground: Colors.white,
      hasTextShadow: true,
      glow: Color(0x45FF5722),
    ),
    SolvilleButtonTone.sky => const _TonePalette(
      top: Color(0xFF4FC3F7),
      bottom: Color(0xFF0288D1),
      lip: Color(0xFF01579B),
      border: Color(0xFF0A3B66),
      foreground: Colors.white,
      hasTextShadow: true,
      glow: Color(0x45039BE5),
    ),
  };
}

/// Tactile 3D storybook push-button with glossy top specular sheen, dark
/// outline, physical bottom bevel lip, hover lift, and press depression.
class SolvilleButton extends StatefulWidget {
  const SolvilleButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.tone = SolvilleButtonTone.primary,
    this.icon,
    this.leading,
    this.padding,
    this.borderRadius = 13.0,
    this.fontSize = 13.0,
    this.compact = false,
    this.expand = false,
    this.tooltip,
  });

  final String label;
  final VoidCallback? onPressed;
  final SolvilleButtonTone tone;
  final IconData? icon;
  final Widget? leading;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double fontSize;
  final bool compact;
  final bool expand;
  final String? tooltip;

  @override
  State<SolvilleButton> createState() => _SolvilleButtonState();
}

class _SolvilleButtonState extends State<SolvilleButton> {
  bool _pressed = false;
  bool _hovered = false;

  void _setPressed(bool value) {
    if (_pressed != value && mounted) {
      setState(() => _pressed = value);
    }
  }

  void _setHovered(bool value) {
    if (_hovered != value && mounted) {
      setState(() => _hovered = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final palette = _paletteFor(widget.tone, enabled: enabled);
    final maxLip = widget.compact ? 2.5 : 3.5;
    final isDown = enabled && _pressed;
    final currentLip = isDown ? 1.0 : maxLip;
    final topPad = isDown ? maxLip - 1.0 : 0.0;
    final hoverOffset = (enabled && _hovered && !isDown) ? -0.9 : 0.0;

    final effectivePadding =
        widget.padding ??
        (widget.compact
            ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6)
            : const EdgeInsets.symmetric(horizontal: 14, vertical: 8));

    final topSheen = Color.lerp(palette.top, Colors.white, 0.45)!;
    final midTint = Color.lerp(palette.top, palette.bottom, 0.22)!;

    final textShadow = palette.hasTextShadow
        ? const <Shadow>[
            Shadow(
              color: Color(0x55261412),
              offset: Offset(0, 1),
              blurRadius: 1.5,
            ),
          ]
        : null;

    Widget contentRow = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (widget.leading != null) ...<Widget>[
          widget.leading!,
          if (widget.label.isNotEmpty) SizedBox(width: widget.compact ? 5 : 6),
        ] else if (widget.icon != null) ...<Widget>[
          Icon(
            widget.icon,
            size: widget.compact ? 15 : 17,
            color: palette.foreground,
            shadows: textShadow,
          ),
          if (widget.label.isNotEmpty) SizedBox(width: widget.compact ? 5 : 6),
        ],
        if (widget.label.isNotEmpty)
          Flexible(
            child: Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: palette.foreground,
                fontWeight: FontWeight.w900,
                fontSize: widget.fontSize,
                height: 1.15,
                shadows: textShadow,
              ),
            ),
          ),
      ],
    );

    Widget buttonBody = Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => _setHovered(true),
        onExit: (_) {
          _setHovered(false);
          _setPressed(false);
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => _setPressed(true) : null,
          onTapUp: enabled ? (_) => _setPressed(false) : null,
          onTapCancel: enabled ? () => _setPressed(false) : null,
          onTap: widget.onPressed,
          child: Transform.translate(
            offset: Offset(0, hoverOffset),
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 70),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(top: topPad, bottom: currentLip),
              child: Container(
                width: widget.expand ? double.infinity : null,
                padding: effectivePadding,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const <double>[0.0, 0.16, 0.22, 1.0],
                    colors: <Color>[topSheen, palette.top, midTint, palette.bottom],
                  ),
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  border: Border.all(
                    color: palette.border,
                    width: widget.compact ? 1.4 : 1.6,
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: palette.lip,
                      offset: Offset(0, currentLip),
                      blurRadius: 0,
                    ),
                    if (enabled)
                      BoxShadow(
                        color: (_hovered && !isDown)
                            ? palette.glow
                            : const Color(0x28261412),
                        offset: Offset(0, currentLip + 2),
                        blurRadius: (_hovered && !isDown) ? 8 : 4,
                      ),
                  ],
                ),
                child: contentRow,
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip != null && widget.tooltip!.isNotEmpty) {
      buttonBody = Tooltip(message: widget.tooltip!, child: buttonBody);
    }
    return buttonBody;
  }
}

/// Square or circular tactile 3D icon button used across HUD controls & dialog closes.
class SolvilleIconButton extends StatefulWidget {
  const SolvilleIconButton({
    super.key,
    required this.onPressed,
    this.icon,
    this.child,
    this.tone = SolvilleButtonTone.cream,
    this.size = 34.0,
    this.iconSize = 17.0,
    this.borderRadius,
    this.tooltip,
  });

  final VoidCallback? onPressed;
  final IconData? icon;
  final Widget? child;
  final SolvilleButtonTone tone;
  final double size;
  final double iconSize;
  final double? borderRadius;
  final String? tooltip;

  @override
  State<SolvilleIconButton> createState() => _SolvilleIconButtonState();
}

class _SolvilleIconButtonState extends State<SolvilleIconButton> {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final palette = _paletteFor(widget.tone, enabled: enabled);
    const maxLip = 2.5;
    final isDown = enabled && _pressed;
    final currentLip = isDown ? 1.0 : maxLip;
    final topPad = isDown ? maxLip - 1.0 : 0.0;
    final hoverOffset = (enabled && _hovered && !isDown) ? -0.7 : 0.0;
    final radius = widget.borderRadius ?? 11.0;

    final topSheen = Color.lerp(palette.top, Colors.white, 0.45)!;
    final midTint = Color.lerp(palette.top, palette.bottom, 0.22)!;

    Widget iconContent =
        widget.child ??
        Icon(
          widget.icon,
          size: widget.iconSize,
          color: palette.foreground,
          shadows: palette.hasTextShadow
              ? const <Shadow>[
                  Shadow(
                    color: Color(0x55261412),
                    offset: Offset(0, 1),
                    blurRadius: 1.5,
                  ),
                ]
              : null,
        );

    Widget result = Semantics(
      button: true,
      enabled: enabled,
      label: widget.tooltip,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() {
          _hovered = false;
          _pressed = false;
        }),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
          onTap: widget.onPressed,
          child: Transform.translate(
            offset: Offset(0, hoverOffset),
            child: Padding(
              padding: EdgeInsets.only(top: topPad, bottom: currentLip),
              child: Container(
                width: widget.size,
                height: widget.size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const <double>[0.0, 0.16, 0.24, 1.0],
                    colors: <Color>[topSheen, palette.top, midTint, palette.bottom],
                  ),
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(color: palette.border, width: 1.4),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: palette.lip,
                      offset: Offset(0, currentLip),
                      blurRadius: 0,
                    ),
                    if (enabled)
                      BoxShadow(
                        color: (_hovered && !isDown)
                            ? palette.glow
                            : const Color(0x22261412),
                        offset: Offset(0, currentLip + 1.5),
                        blurRadius: (_hovered && !isDown) ? 6 : 3,
                      ),
                  ],
                ),
                child: iconContent,
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip != null && widget.tooltip!.isNotEmpty) {
      result = Tooltip(message: widget.tooltip!, child: result);
    }
    return result;
  }
}

/// Tactile 3D selector chip with bevel lip and hover/press feedback, replacing
/// flat Material ChoiceChip / ActionChip across dock trays & modal pickers.
class SolvilleChip extends StatefulWidget {
  const SolvilleChip({
    super.key,
    required this.label,
    required this.onTap,
    this.leading,
    this.selected = false,
    this.selectedTone = SolvilleButtonTone.amber,
    this.unselectedTone = SolvilleButtonTone.cream,
    this.backgroundColor,
    this.borderRadius = 12.0,
    this.fontSize = 12.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  });

  final String label;
  final Widget? leading;
  final bool selected;
  final VoidCallback? onTap;
  final SolvilleButtonTone selectedTone;
  final SolvilleButtonTone unselectedTone;
  final Color? backgroundColor;
  final double borderRadius;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  @override
  State<SolvilleChip> createState() => _SolvilleChipState();
}

class _SolvilleChipState extends State<SolvilleChip> {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final basePalette = _paletteFor(
      widget.selected ? widget.selectedTone : widget.unselectedTone,
      enabled: enabled,
    );

    final topColor = (!widget.selected && widget.backgroundColor != null && enabled)
        ? Color.lerp(widget.backgroundColor!, Colors.white, 0.42)!
        : basePalette.top;
    final bottomColor = (!widget.selected && widget.backgroundColor != null && enabled)
        ? widget.backgroundColor!
        : basePalette.bottom;
    final lipColor = (!widget.selected && widget.backgroundColor != null && enabled)
        ? Color.lerp(widget.backgroundColor!, const Color(0xFF4E342E), 0.34)!
        : basePalette.lip;

    const maxLip = 2.5;
    final isDown = enabled && _pressed;
    final currentLip = isDown ? 1.0 : maxLip;
    final topPad = isDown ? maxLip - 1.0 : 0.0;
    final hoverOffset = (enabled && _hovered && !isDown) ? -0.7 : 0.0;
    final topSheen = Color.lerp(topColor, Colors.white, 0.50)!;

    return Semantics(
      button: true,
      selected: widget.selected,
      enabled: enabled,
      label: widget.label,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() {
          _hovered = false;
          _pressed = false;
        }),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
          onTap: widget.onTap,
          child: Transform.translate(
            offset: Offset(0, hoverOffset),
            child: Padding(
              padding: EdgeInsets.only(top: topPad, bottom: currentLip),
              child: Container(
                padding: widget.padding,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const <double>[0.0, 0.16, 0.24, 1.0],
                    colors: <Color>[
                      topSheen,
                      topColor,
                      Color.lerp(topColor, bottomColor, 0.24)!,
                      bottomColor,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  border: Border.all(
                    color: widget.selected
                        ? const Color(0xFFE65100)
                        : basePalette.border,
                    width: widget.selected ? 1.7 : 1.3,
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: widget.selected
                          ? const Color(0xFFB35600)
                          : lipColor,
                      offset: Offset(0, currentLip),
                      blurRadius: 0,
                    ),
                    if (widget.selected)
                      const BoxShadow(
                        color: Color(0x4DFFCA28),
                        offset: Offset(0, 2),
                        blurRadius: 6,
                      ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (widget.leading != null) ...<Widget>[
                      widget.leading!,
                      const SizedBox(width: 5),
                    ],
                    Flexible(
                      child: Text(
                        widget.label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: basePalette.foreground,
                          fontWeight:
                              widget.selected ? FontWeight.w900 : FontWeight.w700,
                          fontSize: widget.fontSize,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Sculpted non-interactive badge ribbon replacing stock Material Chips.
class SolvilleBadge extends StatelessWidget {
  const SolvilleBadge({
    super.key,
    required this.label,
    this.leading,
    this.color = SolvilleTheme.warmCream,
    this.borderColor = const Color(0x78795548),
    this.textColor = SolvilleTheme.timberDark,
    this.fontSize = 11.5,
    this.padding = const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    this.borderRadius = 11.0,
  });

  final String label;
  final Widget? leading;
  final Color color;
  final Color borderColor;
  final Color textColor;
  final double fontSize;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final topTint = Color.lerp(color, Colors.white, 0.45)!;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[topTint, color],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor, width: 1.3),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x163E2723),
            offset: Offset(0, 1.5),
            blurRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (leading != null) ...<Widget>[
            leading!,
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w800,
                fontSize: fontSize,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sculpted recessed timber segmented tab control hooked to [DefaultTabController].
class SolvilleSegmentedTabs extends StatefulWidget {
  const SolvilleSegmentedTabs({
    super.key,
    required this.labels,
    this.icons,
    this.controller,
  });

  final List<String> labels;
  final List<Widget>? icons;
  final TabController? controller;

  @override
  State<SolvilleSegmentedTabs> createState() => _SolvilleSegmentedTabsState();
}

class _SolvilleSegmentedTabsState extends State<SolvilleSegmentedTabs> {
  TabController? _tabController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _attachController(widget.controller ?? DefaultTabController.maybeOf(context));
  }

  @override
  void didUpdateWidget(covariant SolvilleSegmentedTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _attachController(
        widget.controller ?? DefaultTabController.maybeOf(context),
      );
    }
  }

  void _attachController(TabController? next) {
    if (identical(_tabController, next)) return;
    _tabController?.removeListener(_onTabChanged);
    _tabController = next;
    _tabController?.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController?.removeListener(_onTabChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeIndex = _tabController?.index ?? 0;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: SolvilleTheme.recessedSlotDecoration(radius: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 360;
          final items = <Widget>[
            for (var i = 0; i < widget.labels.length; i++)
              _buildSegment(
                index: i,
                label: widget.labels[i],
                icon: (widget.icons != null && i < widget.icons!.length)
                    ? widget.icons![i]
                    : null,
                selected: i == activeIndex,
                compact: isNarrow,
              ),
          ];

          if (isNarrow) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  for (var i = 0; i < items.length; i++) ...<Widget>[
                    if (i > 0) const SizedBox(width: 4),
                    items[i],
                  ],
                ],
              ),
            );
          }

          return Row(
            children: <Widget>[
              for (var i = 0; i < items.length; i++) ...<Widget>[
                if (i > 0) const SizedBox(width: 4),
                Expanded(child: items[i]),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildSegment({
    required int index,
    required String label,
    required Widget? icon,
    required bool selected,
    required bool compact,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _tabController?.animateTo(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 10,
          vertical: selected ? 7 : 8,
        ),
        margin: EdgeInsets.only(bottom: selected ? 2.0 : 0.0),
        decoration: selected
            ? BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: <double>[0.0, 0.18, 1.0],
                  colors: <Color>[
                    Color(0xFFFFFDF7),
                    Color(0xFFFFECA8),
                    Color(0xFFFFD54F),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF8C5320), width: 1.5),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0xFFC48814),
                    offset: Offset(0, 2.2),
                    blurRadius: 0,
                  ),
                  BoxShadow(
                    color: Color(0x283E2723),
                    offset: Offset(0, 3.5),
                    blurRadius: 4,
                  ),
                ],
              )
            : BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
        child: Row(
          mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              icon,
              const SizedBox(width: 5),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected
                      ? SolvilleTheme.timberDark
                      : const Color(0xBB4E342E),
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                  fontSize: compact ? 12 : 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tactile storybook menu card with parchment gradient, outer wood border,
/// and subtle bottom bevel shadow — replacing flat Material [Card]s.
class SolvilleMenuCard extends StatelessWidget {
  const SolvilleMenuCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.margin,
    this.color = SolvilleTheme.parchment,
    this.borderColor,
    this.highlighted = false,
    this.radius = 16.0,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color color;
  final Color? borderColor;
  final bool highlighted;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final topCol = Color.lerp(color, Colors.white, 0.45) ?? color;
    final botCol = Color.lerp(color, const Color(0xFFF1DFC0), 0.25) ?? color;
    final effectiveBorder =
        borderColor ??
        (highlighted ? const Color(0xFFE65100) : const Color(0x88795548));
    final bevelColor = highlighted
        ? const Color(0xFFC47B00)
        : const Color(0x556D4C41);

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[topCol, botCol],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: effectiveBorder,
          width: highlighted ? 1.9 : 1.4,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: bevelColor,
            offset: const Offset(0, 2.5),
            blurRadius: 0,
          ),
          BoxShadow(
            color: highlighted
                ? const Color(0x36FFB300)
                : const Color(0x18261412),
            offset: const Offset(0, 5),
            blurRadius: highlighted ? 10 : 6,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Embossed icon socket badge used to frame emojis or [SolvilleIcon]s in menus.
class SolvilleIconMedallion extends StatelessWidget {
  const SolvilleIconMedallion({
    super.key,
    required this.child,
    this.size = 42.0,
    this.radius,
    this.backgroundColor = SolvilleTheme.warmCream,
    this.borderColor = const Color(0x78795548),
    this.highlighted = false,
  });

  final Widget child;
  final double size;
  final double? radius;
  final Color backgroundColor;
  final Color borderColor;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final topCol = Color.lerp(backgroundColor, Colors.white, 0.55)!;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: radius == null ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: radius == null ? null : BorderRadius.circular(radius!),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[topCol, backgroundColor],
        ),
        border: Border.all(
          color: highlighted ? SolvilleTheme.sunGold : borderColor,
          width: highlighted ? 1.7 : 1.3,
        ),
        boxShadow: <BoxShadow>[
          const BoxShadow(
            color: Color(0x203E2723),
            offset: Offset(0, 1.5),
            blurRadius: 3,
          ),
          if (highlighted)
            const BoxShadow(
              color: Color(0x40FFCA28),
              blurRadius: 6,
            ),
        ],
      ),
      child: child,
    );
  }
}
