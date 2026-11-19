import 'package:flutter/material.dart';

import '../../domain/models/catalog.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/solville_l10n_extensions.dart';
import '../theme/solville_theme.dart';
import '../view_models/solville_controller.dart';
import '../widgets/solville_buttons.dart';
import '../widgets/solville_icons.dart';
import '../widgets/solville_pill_button.dart';

/// Adaptive centered top HUD displaying Market, Shop, Quest pin, Trophies,
/// Soundscape, Cozy Version / Sun Pass, SFX mute, and Help controls.
class TopStatusBar extends StatelessWidget {
  const TopStatusBar({
    super.key,
    required this.controller,
    required this.onOpenShop,
    required this.onOpenMarket,
    required this.onOpenTrophies,
    required this.onOpenAudio,
    required this.onOpenHelp,
    this.onOpenSunPass,
    this.onToggleJournal,
    this.isJournalExpanded = false,
  });

  final SolvilleController controller;
  final VoidCallback onOpenShop;
  final VoidCallback onOpenMarket;
  final VoidCallback onOpenTrophies;
  final VoidCallback onOpenAudio;
  final VoidCallback onOpenHelp;
  final VoidCallback? onOpenSunPass;
  final VoidCallback? onToggleJournal;
  final bool isJournalExpanded;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = controller.state;
    final booms = state.market.boomProducts;
    final boomEmojis = booms.map(SolvilleCatalog.productEmoji).join(' ');

    return LayoutBuilder(
      builder: (context, constraints) {
        final mediaSize = MediaQuery.sizeOf(context);
        final isMobile =
            constraints.maxWidth < 860 || mediaSize.shortestSide < 600;
        final ultraNarrow = constraints.maxWidth <= 380;
        final compact = constraints.maxWidth < 920 || isMobile;

        final pillPadding = ultraNarrow
            ? const EdgeInsets.symmetric(horizontal: 5.5, vertical: 4.5)
            : (isMobile
                  ? const EdgeInsets.symmetric(horizontal: 8, vertical: 5)
                  : const EdgeInsets.symmetric(horizontal: 10, vertical: 6));
        final pillRadius = ultraNarrow ? 10.0 : (isMobile ? 11.0 : 14.0);
        final pillFontSize = ultraNarrow ? 10.5 : (isMobile ? 11.0 : 12.5);
        final pillEmojiSize = ultraNarrow ? 11.5 : (isMobile ? 12.5 : 14.0);

        final hasDailyReq =
            state.market.dailyRequest != null &&
            !state.market.dailyRequest!.isCompleted;
        final activeQuest = state.activeQuest;
        final questProg = state.activeQuestProgress;
        final dimSecondary = state.isOnboardingActive;

        final iconSize = ultraNarrow ? 13.0 : (isMobile ? 14.5 : 16.0);
        final bgmIconKind = switch (controller.bgmTrack) {
          BgmTrack.sunnyLullaby => SolvilleIconKind.musicLullaby,
          BgmTrack.morningMeadow => SolvilleIconKind.musicMeadow,
          BgmTrack.cozyRain => SolvilleIconKind.musicRain,
          BgmTrack.off => SolvilleIconKind.musicOff,
        };

        final menuItems = <Widget>[
          SolvillePillButton(
            emoji: '☀️',
            leadingIcon: SolvilleIcon(
              kind: SolvilleIconKind.sunCoin,
              size: iconSize,
            ),
            label: '${state.coins}',
            tooltip: l10n.hudSolsTooltip,
            isMeter: true,
            backgroundColor: const Color(0xFFFFF8E1),
            padding: pillPadding,
            borderRadius: pillRadius,
            fontSize: pillFontSize,
            emojiSize: pillEmojiSize,
            onTap: onOpenShop,
          ),
          SolvillePillButton(
            emoji: '💧',
            leadingIcon: SolvilleIcon(
              kind: SolvilleIconKind.waterCan,
              size: iconSize,
            ),
            label: '${state.farmer.waterCharges}/${state.maxWaterCharges}',
            tooltip: l10n.hudWaterTooltip,
            isMeter: true,
            highlighted: state.farmer.waterCharges == 0,
            backgroundColor: state.farmer.waterCharges == 0
                ? const Color(0xFFFFE082)
                : const Color(0xFFE1F5FE),
            padding: pillPadding,
            borderRadius: pillRadius,
            fontSize: pillFontSize,
            emojiSize: pillEmojiSize,
            onTap: controller.refillOrFocusWell,
          ),
          _focusWrap(
            SolvillePillButton(
              emoji: '📈',
              leadingIcon: SolvilleIcon(
                kind: SolvilleIconKind.marketChart,
                size: iconSize,
              ),
              label: isMobile ? boomEmojis : l10n.hudMarketCompact(boomEmojis),
              highlighted: state.market.isRushActive,
              badgeEmoji: state.market.expressOrder != null
                  ? '⚡'
                  : (hasDailyReq ? '💌' : null),
              backgroundColor: state.market.isRushActive
                  ? const Color(0xFFFFE082)
                  : const Color(0xFFFFF8E1),
              padding: pillPadding,
              borderRadius: pillRadius,
              fontSize: pillFontSize,
              emojiSize: pillEmojiSize,
              onTap: onOpenMarket,
            ),
            dim: dimSecondary,
          ),
          SolvillePillButton(
            emoji: '🛒',
            leadingIcon: SolvilleIcon(
              kind: SolvilleIconKind.shopBasket,
              size: iconSize,
            ),
            label: l10n.hudShop,
            highlighted: state.shouldSpotlightGloves,
            badgeEmoji: state.shouldSpotlightGloves ? '🧤' : null,
            backgroundColor: state.shouldSpotlightGloves
                ? const Color(0xFFFFE082)
                : const Color(0xFFE8F5E9),
            padding: pillPadding,
            borderRadius: pillRadius,
            fontSize: pillFontSize,
            emojiSize: pillEmojiSize,
            onTap: onOpenShop,
          ),
          if (activeQuest != null && onToggleJournal != null)
            questProg.isReadyToClaim
                ? SolvillePillButton(
                    emoji: '✨',
                    label: l10n
                        .questClaimBtn(activeQuest.rewardCoins)
                        .replaceFirst('✨ ', ''),
                    highlighted: true,
                    backgroundColor: const Color(0xFFFFE082),
                    padding: pillPadding,
                    borderRadius: pillRadius,
                    fontSize: pillFontSize,
                    emojiSize: pillEmojiSize,
                    onTap: () => controller.claimOrFocusActiveQuest(
                      onOpenShop: (_) => onOpenShop(),
                      onOpenMarket: onOpenMarket,
                    ),
                  )
                : SolvillePillButton(
                    emoji: activeQuest.emoji,
                    label:
                        '${activeQuest.stepNumber}/${SolvilleCatalog.quests.length}',
                    highlighted: isJournalExpanded || state.isOnboardingActive,
                    backgroundColor:
                        (isJournalExpanded || state.isOnboardingActive)
                        ? const Color(0xFFFFECB3)
                        : const Color(0xFFFFF8E1),
                    padding: pillPadding,
                    borderRadius: pillRadius,
                    fontSize: pillFontSize,
                    emojiSize: pillEmojiSize,
                    onTap: onToggleJournal!,
                  ),
          _focusWrap(
            SolvillePillButton(
              emoji: '🏆',
              leadingIcon: SolvilleIcon(
                kind: SolvilleIconKind.trophy,
                size: iconSize,
              ),
              label:
                  '${state.unlockedTrophies.length}/${SolvilleCatalog.trophies.length}',
              backgroundColor: const Color(0xFFFFECB3),
              padding: pillPadding,
              borderRadius: pillRadius,
              fontSize: pillFontSize,
              emojiSize: pillEmojiSize,
              onTap: onOpenTrophies,
            ),
            dim: dimSecondary,
          ),
          SolvillePillButton(
            emoji: controller.bgmTrack.shortEmoji,
            leadingIcon: SolvilleIcon(
              kind: bgmIconKind,
              size: iconSize,
            ),
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
            onTap: onOpenAudio,
          ),
          if (!controller.entitlements.isFullEditionBuild &&
              onOpenSunPass != null)
            _focusWrap(
              SolvillePillButton(
                emoji: controller.entitlements.isPermanentSupporter
                    ? '👑'
                    : '☀️',
                leadingIcon: SolvilleIcon(
                  kind: controller.entitlements.isPermanentSupporter
                      ? SolvilleIconKind.crown
                      : SolvilleIconKind.sunCoin,
                  size: iconSize,
                ),
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
                onTap: onOpenSunPass!,
              ),
              dim: dimSecondary,
            ),
          SolvilleIconButton(
            tooltip: controller.sfxEnabled
                ? l10n.hudMuteSfx
                : l10n.hudEnableSfx,
            tone: SolvilleButtonTone.cream,
            size: ultraNarrow ? 30 : 34,
            iconSize: ultraNarrow ? 15 : 17,
            icon: controller.sfxEnabled
                ? Icons.volume_up_rounded
                : Icons.volume_off_rounded,
            onPressed: controller.toggleSfx,
          ),
          SolvilleIconButton(
            tooltip: l10n.hudHelpTooltip,
            tone: SolvilleButtonTone.cream,
            size: ultraNarrow ? 30 : 34,
            iconSize: ultraNarrow ? 15 : 17,
            icon: Icons.help_outline_rounded,
            onPressed: onOpenHelp,
          ),
        ];

        return Padding(
          padding: EdgeInsets.fromLTRB(
            ultraNarrow ? 4 : (isMobile ? 8 : 10),
            isMobile ? 4 : 8,
            ultraNarrow ? 4 : (isMobile ? 8 : 10),
            isMobile ? 2 : 6,
          ),
          child: Align(
            alignment: Alignment.center,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: ultraNarrow ? 4 : (isMobile ? 6 : 8),
                vertical: isMobile ? 4 : 6,
              ),
              decoration: SolvilleTheme.hudBarDecoration(
                radius: isMobile ? 16 : 22,
              ),
              child: isMobile
                  ? SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: _withHorizontalSpacing(
                          menuItems,
                          ultraNarrow ? 2.5 : 4,
                        ),
                      ),
                    )
                  : Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: menuItems,
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _focusWrap(Widget child, {required bool dim}) {
    return AnimatedOpacity(
      opacity: dim ? 0.55 : 1.0,
      duration: const Duration(milliseconds: 220),
      child: child,
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
