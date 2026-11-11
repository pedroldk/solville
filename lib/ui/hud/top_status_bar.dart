import 'package:flutter/material.dart';

import '../../domain/models/catalog.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/solville_l10n_extensions.dart';
import '../theme/solville_theme.dart';
import '../view_models/solville_controller.dart';
import '../widgets/solville_pill_button.dart';

/// Adaptive top HUD displaying Coins, Water charges, Stacked Crates, Day/Sun
/// progress, Hot Market Boom ticker, Soothing Soundscape selector, and modals.
class TopStatusBar extends StatefulWidget {
  const TopStatusBar({
    super.key,
    required this.controller,
    required this.onOpenShop,
    required this.onOpenMarket,
    required this.onOpenTrophies,
    required this.onOpenAudio,
    required this.onOpenHelp,
    this.onOpenSunPass,
  });

  final SolvilleController controller;
  final VoidCallback onOpenShop;
  final VoidCallback onOpenMarket;
  final VoidCallback onOpenTrophies;
  final VoidCallback onOpenAudio;
  final VoidCallback onOpenHelp;
  final VoidCallback? onOpenSunPass;

  @override
  State<TopStatusBar> createState() => _TopStatusBarState();
}

class _TopStatusBarState extends State<TopStatusBar> {
  bool _mobileMenuExpanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = widget.controller;
    final state = controller.state;
    final booms = state.market.boomProducts;
    final boomEmojis = booms.map(SolvilleCatalog.productEmoji).join(' ');
    final weatherLabel = l10n.weatherLabel(state.weather);

    return LayoutBuilder(
      builder: (context, constraints) {
        final mediaSize = MediaQuery.sizeOf(context);
        final isMobile =
            constraints.maxWidth < 600 || mediaSize.shortestSide < 600;
        final compact = constraints.maxWidth < 820 || isMobile;

        final statChildren = <Widget>[
          _StatChip(
            emoji: '☀️',
            label: '${state.coins}',
            tooltip: l10n.hudSolsTooltip,
            highlight: const Color(0xFFFFF3C4),
            compact: isMobile,
          ),
          _StatChip(
            emoji: '🪣',
            label: '${state.farmer.waterCharges}/${state.maxWaterCharges}',
            tooltip: l10n.hudWaterTooltip,
            highlight: const Color(0xFFE1F5FE),
            compact: isMobile,
          ),
          _StatChip(
            emoji: '📦',
            label: '${state.farmer.carriedCrates.length}/${state.maxCarryCrates}',
            tooltip: l10n.hudCratesTooltip,
            highlight: const Color(0xFFFFECB3),
            compact: isMobile,
          ),
          _DayWeatherChip(
            day: state.day,
            progress: state.dayProgress,
            weatherLabel: compact
                ? weatherLabel.split(' ').first
                : weatherLabel,
            onNextMorning: controller.restToNextMorning,
            compact: isMobile,
          ),
        ];

        final pillPadding = isMobile
            ? const EdgeInsets.symmetric(horizontal: 8, vertical: 5)
            : const EdgeInsets.symmetric(horizontal: 10, vertical: 6);
        final pillRadius = isMobile ? 11.0 : 14.0;
        final pillFontSize = isMobile ? 11.0 : 12.5;
        final pillEmojiSize = isMobile ? 12.5 : 14.0;

        final actionChildren = <Widget>[
          SolvillePillButton(
            emoji: '📈',
            label: isMobile
                ? boomEmojis
                : (compact
                      ? l10n.hudMarketCompact(boomEmojis)
                      : l10n.hudMarketFull(
                          boomEmojis,
                          state.market.stallCrates.length,
                        )),
            backgroundColor: const Color(0xFFFFF8E1),
            padding: pillPadding,
            borderRadius: pillRadius,
            fontSize: pillFontSize,
            emojiSize: pillEmojiSize,
            onTap: widget.onOpenMarket,
          ),
          SolvillePillButton(
            emoji: '🛒',
            label: l10n.hudShop,
            backgroundColor: const Color(0xFFE8F5E9),
            padding: pillPadding,
            borderRadius: pillRadius,
            fontSize: pillFontSize,
            emojiSize: pillEmojiSize,
            onTap: widget.onOpenShop,
          ),
          if (!controller.entitlements.isFullEditionBuild &&
              widget.onOpenSunPass != null)
            SolvillePillButton(
              emoji: controller.entitlements.hasLifetimePass
                  ? '👑'
                  : (controller.entitlements.hasAnnualPass ? '🌻' : '☀️'),
              label: compact
                  ? (controller.isSunPassActive
                        ? l10n.hudPassShortActive
                        : l10n.hudPassShort)
                  : l10n.entitlementStatusPillText(
                      controller.entitlements,
                      controller.nowUtc,
                    ),
              tooltip: l10n.hudSunPassTooltip,
              backgroundColor: controller.isSunPassActive
                  ? const Color(0xFFFFE082)
                  : const Color(0xFFFFF3E0),
              padding: pillPadding,
              borderRadius: pillRadius,
              fontSize: pillFontSize,
              emojiSize: pillEmojiSize,
              onTap: widget.onOpenSunPass!,
            ),
          if (!isMobile || _mobileMenuExpanded) ...<Widget>[
            SolvillePillButton(
              emoji: '🏆',
              label:
                  '${state.unlockedTrophies.length}/${SolvilleCatalog.trophies.length}',
              backgroundColor: const Color(0xFFFFECB3),
              padding: pillPadding,
              borderRadius: pillRadius,
              fontSize: pillFontSize,
              emojiSize: pillEmojiSize,
              onTap: widget.onOpenTrophies,
            ),
            SolvillePillButton(
              emoji: controller.bgmTrack.shortEmoji,
              label: l10n.bgmTrackShortTitle(
                controller.bgmTrack,
                compact: compact,
                isMobile: isMobile,
              ),
              tooltip: l10n.hudHomesteadTooltip,
              backgroundColor: const Color(0xFFE1F5FE),
              padding: pillPadding,
              borderRadius: pillRadius,
              fontSize: pillFontSize,
              emojiSize: pillEmojiSize,
              onTap: widget.onOpenAudio,
            ),
            if (isMobile) ...<Widget>[
              _CompactHudIconButton(
                tooltip: controller.sfxEnabled
                    ? l10n.hudMuteSfx
                    : l10n.hudEnableSfx,
                icon: controller.sfxEnabled
                    ? Icons.volume_up_rounded
                    : Icons.volume_off_rounded,
                onTap: controller.toggleSfx,
              ),
              _CompactHudIconButton(
                tooltip: l10n.hudHelpTooltip,
                icon: Icons.help_outline_rounded,
                onTap: widget.onOpenHelp,
              ),
            ] else ...<Widget>[
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: controller.sfxEnabled
                    ? l10n.hudMuteSfx
                    : l10n.hudEnableSfx,
                onPressed: controller.toggleSfx,
                icon: Icon(
                  controller.sfxEnabled
                      ? Icons.volume_up_rounded
                      : Icons.volume_off_rounded,
                  color: SolvilleTheme.timberDark,
                  size: 20,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: l10n.hudHelpTooltip,
                onPressed: widget.onOpenHelp,
                icon: const Icon(
                  Icons.help_outline_rounded,
                  color: SolvilleTheme.timberDark,
                  size: 20,
                ),
              ),
            ],
          ],
          if (isMobile)
            _CompactHudIconButton(
              tooltip: _mobileMenuExpanded
                  ? l10n.hudHideExtra
                  : l10n.hudShowExtra,
              icon: _mobileMenuExpanded
                  ? Icons.chevron_left_rounded
                  : Icons.more_horiz_rounded,
              backgroundColor: _mobileMenuExpanded
                  ? const Color(0xFFFFECB3)
                  : SolvilleTheme.warmCream,
              onTap: () => setState(() {
                _mobileMenuExpanded = !_mobileMenuExpanded;
              }),
            ),
        ];

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 6 : 10,
            vertical: isMobile ? 4 : 8,
          ),
          child: Wrap(
            spacing: isMobile ? 6 : 8,
            runSpacing: isMobile ? 4 : 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              // Left cluster: Sols, Water, Carried Crates, Day
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 7 : 12,
                  vertical: isMobile ? 4 : 7,
                ),
                decoration: SolvilleTheme.panelDecoration(
                  radius: isMobile ? 16 : 22,
                ),
                child: isMobile
                    ? SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: _withHorizontalSpacing(statChildren, 5),
                        ),
                      )
                    : Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: statChildren,
                      ),
              ),

              // Right cluster: Market Ticker, Shop, Pass, and collapsible utilities
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 6 : 8,
                  vertical: isMobile ? 4 : 6,
                ),
                decoration: SolvilleTheme.panelDecoration(
                  radius: isMobile ? 16 : 22,
                ),
                child: isMobile
                    ? SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: _withHorizontalSpacing(actionChildren, 4),
                        ),
                      )
                    : Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: actionChildren,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _withHorizontalSpacing(List<Widget> children, double gap) {
    final result = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        result.add(SizedBox(width: gap));
      }
      result.add(children[i]);
    }
    return result;
  }
}

class _CompactHudIconButton extends StatelessWidget {
  const _CompactHudIconButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.backgroundColor = SolvilleTheme.parchment,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          borderRadius: BorderRadius.circular(11),
          onTap: onTap,
          child: Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: SolvilleTheme.timberBorder,
                width: 1.3,
              ),
            ),
            child: Icon(icon, color: SolvilleTheme.timberDark, size: 17),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.emoji,
    required this.label,
    required this.tooltip,
    required this.highlight,
    this.compact = false,
  });

  final String emoji;
  final String label;
  final String tooltip;
  final Color highlight;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 9,
          vertical: compact ? 2 : 4,
        ),
        decoration: BoxDecoration(
          color: highlight,
          borderRadius: BorderRadius.circular(compact ? 10 : 14),
          border: Border.all(color: const Color(0x33795548)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(emoji, style: TextStyle(fontSize: compact ? 12.5 : 15)),
            SizedBox(width: compact ? 3.5 : 5),
            Text(
              label,
              style: TextStyle(
                color: SolvilleTheme.timberDark,
                fontWeight: FontWeight.w800,
                fontSize: compact ? 11.5 : 13.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayWeatherChip extends StatelessWidget {
  const _DayWeatherChip({
    required this.day,
    required this.progress,
    required this.weatherLabel,
    required this.onNextMorning,
    this.compact = false,
  });

  final int day;
  final double progress;
  final String weatherLabel;
  final VoidCallback onNextMorning;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          width: compact ? 14 : 18,
          height: compact ? 14 : 18,
          child: CircularProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            strokeWidth: compact ? 2.2 : 3,
            backgroundColor: const Color(0x33795548),
            valueColor: const AlwaysStoppedAnimation<Color>(
              SolvilleTheme.sunGold,
            ),
          ),
        ),
        SizedBox(width: compact ? 5 : 7),
        Text(
          compact
              ? l10n.hudDayWeatherCompact(day, weatherLabel)
              : l10n.hudDayWeatherFull(day, weatherLabel),
          style: TextStyle(
            color: SolvilleTheme.timberDark,
            fontWeight: FontWeight.w700,
            fontSize: compact ? 11 : 12.5,
          ),
        ),
        SizedBox(width: compact ? 5 : 6),
        Tooltip(
          message: l10n.hudNextMorningTooltip,
          child: InkWell(
            borderRadius: BorderRadius.circular(compact ? 10 : 12),
            onTap: onNextMorning,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 8 : 9,
                vertical: compact ? 4 : 5,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE0B2),
                borderRadius: BorderRadius.circular(compact ? 10 : 12),
                border: Border.all(color: SolvilleTheme.timberBorder),
              ),
              child: Text(
                compact ? l10n.hudNextCompact : l10n.hudNextFull,
                style: TextStyle(
                  color: SolvilleTheme.timberDark,
                  fontSize: compact ? 10.5 : 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
