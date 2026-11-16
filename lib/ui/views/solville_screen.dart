import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/models/catalog.dart';
import '../../game/solville_game.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/solville_l10n_extensions.dart';
import '../hud/bottom_tool_dock.dart';
import '../hud/game_viewport_surface.dart';
import '../hud/top_status_bar.dart';
import '../modals/help_modal.dart';
import '../modals/homestead_modal.dart';
import '../modals/market_and_barn_modal.dart';
import '../modals/shop_modal.dart';
import '../modals/sun_pass_modal.dart';
import '../modals/trophy_cabinet_modal.dart';
import '../theme/solville_theme.dart';
import '../view_models/solville_controller.dart';

/// Root playable screen combining the Flame 2.5D Isometric Diorama and adaptive
/// Flutter HUD overlays.
///
/// Uses [RepaintBoundary] layers to isolate the 60fps Flame canvas from HUD
/// widget rebuilds.
class SolvilleScreen extends StatefulWidget {
  const SolvilleScreen({super.key, required this.controller});

  final SolvilleController controller;

  @override
  State<SolvilleScreen> createState() => _SolvilleScreenState();
}

class _SolvilleScreenState extends State<SolvilleScreen>
    with WidgetsBindingObserver {
  late final SolvilleGame _game;
  bool _questPinCollapsed = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _game = SolvilleGame(controller: widget.controller);
    widget.controller.onRequestOpenMarketModal = _openMarket;
    widget.controller.onRequestOpenHomesteadModal = _openAudioAndHomestead;
    widget.controller.onRequestOpenSunPassModal = _openSunPass;
  }

  @override
  void dispose() {
    if (identical(widget.controller.onRequestOpenMarketModal, _openMarket)) {
      widget.controller.onRequestOpenMarketModal = null;
    }
    if (identical(
      widget.controller.onRequestOpenHomesteadModal,
      _openAudioAndHomestead,
    )) {
      widget.controller.onRequestOpenHomesteadModal = null;
    }
    if (identical(widget.controller.onRequestOpenSunPassModal, _openSunPass)) {
      widget.controller.onRequestOpenSunPassModal = null;
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Auto-save cleanly and pause/resume BGM across all Android/iOS lifecycle states!
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        widget.controller.onAppBackgrounded();
        unawaited(widget.controller.saveNow(showToast: false));
      case AppLifecycleState.resumed:
        if (!kIsWeb &&
            (defaultTargetPlatform == TargetPlatform.android ||
                defaultTargetPlatform == TargetPlatform.iOS)) {
          unawaited(
            SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky),
          );
        }
        widget.controller.onAppResumed();
    }
  }

  void _openShop() => _openShopTab(0);

  void _openShopTab(int initialTab) {
    widget.controller.notifyUserGestureForAudio();
    showDialog<void>(
      context: context,
      builder: (_) => ShopModal(
        controller: widget.controller,
        initialTab: initialTab,
      ),
    );
  }

  void _openMarket() {
    widget.controller.notifyUserGestureForAudio();
    showDialog<void>(
      context: context,
      builder: (_) => MarketAndBarnModal(controller: widget.controller),
    );
  }

  void _openTrophies() {
    widget.controller.notifyUserGestureForAudio();
    showDialog<void>(
      context: context,
      builder: (_) => TrophyCabinetModal(controller: widget.controller),
    );
  }

  void _openAudioAndHomestead() {
    widget.controller.notifyUserGestureForAudio();
    showDialog<void>(
      context: context,
      builder: (_) => HomesteadAndAudioModal(controller: widget.controller),
    );
  }

  void _openHelp() {
    widget.controller.notifyUserGestureForAudio();
    showDialog<void>(
      context: context,
      builder: (_) => HelpAndControlsModal(controller: widget.controller),
    );
  }

  void _openSunPass() {
    widget.controller.notifyUserGestureForAudio();
    showDialog<void>(
      context: context,
      builder: (_) => SunPassModal(controller: widget.controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          widget.controller.handleBackNavigation();
        }
      },
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            // 1. 2.5D Isometric Flame Diorama isolated in its own RepaintBoundary
            RepaintBoundary(child: GameViewportSurface(game: _game)),

            // 2. Safe-area responsive HUD overlays isolated in RepaintBoundary
            SafeArea(
              child: RepaintBoundary(
                child: ListenableBuilder(
                  listenable: widget.controller,
                  builder: (context, _) {
                    final l10n = AppLocalizations.of(context);
                    widget.controller.syncLocalizedWorldLabels(
                      spotlightHarvest: l10n.spotlightHarvest,
                      spotlightSell: l10n.spotlightSell,
                      spotlightPlant: l10n.spotlightPlant,
                      landmarkHomestead: l10n.landmarkHomesteadPill,
                      landmarkRefill: l10n.landmarkRefillPill,
                      landmarkBarn: l10n.landmarkBarnPill,
                    );
                    final toastData = widget.controller.toast;
                    final toast = toastData != null
                        ? l10n.resolveToast(toastData)
                        : widget.controller.toastMessage;
                    final state = widget.controller.state;
                    final express = state.market.expressOrder;
                    final dailyReq = state.market.dailyRequest;
                    final showDailyReq =
                        dailyReq != null && !dailyReq.isCompleted;
                    final activeQuest = state.activeQuest;
                    final questProg = state.activeQuestProgress;
                    final isCompactScreen =
                        MediaQuery.sizeOf(context).shortestSide < 600 ||
                        MediaQuery.sizeOf(context).width < 860;
                    final showEventBadges =
                        express != null ||
                        showDailyReq ||
                        state.market.isRushActive ||
                        state.comboStreak >= 2;

                    final viewportW =
                        MediaQuery.sizeOf(context).width -
                        MediaQuery.paddingOf(context).horizontal;
                    final compactQuestMaxWidth = math.max(
                      200.0,
                      math.min(420.0, viewportW - 24),
                    );

                    Widget buildQuestPill({required bool compact}) {
                      if (activeQuest == null) return const SizedBox.shrink();
                      final radius = compact ? 12.0 : 16.0;
                      return ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: compact
                              ? compactQuestMaxWidth
                              : double.infinity,
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          decoration: SolvilleTheme.panelDecoration(
                            color: questProg.isReadyToClaim
                                ? const Color(0xF5FFE082)
                                : const Color(0xEEFFFDF6),
                            borderColor: questProg.isReadyToClaim
                                ? const Color(0xFFE65100)
                                : SolvilleTheme.timberBorder,
                            radius: radius,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(radius),
                            clipBehavior: Clip.antiAlias,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Flexible(
                                  child: InkWell(
                                    onTap: () => widget.controller
                                        .claimOrFocusActiveQuest(
                                          onOpenShop: _openShopTab,
                                          onOpenMarket: _openMarket,
                                        ),
                                    child: Padding(
                                      padding: compact
                                          ? const EdgeInsets.fromLTRB(
                                              8,
                                              3,
                                              4,
                                              3,
                                            )
                                          : const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          Text(
                                            activeQuest.emoji,
                                            style: TextStyle(
                                              fontSize: compact ? 13 : 18,
                                            ),
                                          ),
                                          SizedBox(width: compact ? 5 : 7),
                                          Flexible(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: <Widget>[
                                                Text(
                                                  compact
                                                      ? '${activeQuest.stepNumber}/${SolvilleCatalog.quests.length}: ${l10n.questTitle(activeQuest.id)}'
                                                      : l10n.questGoalHeader(
                                                          activeQuest.stepNumber,
                                                          SolvilleCatalog
                                                              .quests
                                                              .length,
                                                          l10n.questTitle(
                                                            activeQuest.id,
                                                          ),
                                                        ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: SolvilleTheme
                                                        .timberDark,
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: compact
                                                        ? 11
                                                        : 12.5,
                                                  ),
                                                ),
                                                if (!compact)
                                                  Text(
                                                    l10n.questHint(
                                                      activeQuest.id,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      color: SolvilleTheme
                                                          .timberDark
                                                          .withValues(
                                                            alpha: 0.78,
                                                          ),
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(width: compact ? 6 : 8),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: compact ? 6 : 8,
                                              vertical: compact ? 2 : 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: questProg.isReadyToClaim
                                                  ? const Color(0xFFE65100)
                                                  : const Color(0x22795548),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              questProg.isReadyToClaim
                                                  ? l10n.questClaimBtn(
                                                      activeQuest.rewardCoins,
                                                    )
                                                  : '${questProg.current}/${questProg.required} • +${activeQuest.rewardCoins}☀️',
                                              style: TextStyle(
                                                color: questProg.isReadyToClaim
                                                    ? Colors.white
                                                    : SolvilleTheme.timberDark,
                                                fontWeight: FontWeight.w900,
                                                fontSize: compact ? 10 : 11.5,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                if (compact)
                                  InkWell(
                                    onTap: () => setState(() {
                                      _questPinCollapsed = true;
                                    }),
                                    child: const Padding(
                                      padding: EdgeInsets.fromLTRB(4, 5, 7, 5),
                                      child: Icon(
                                        Icons.expand_less_rounded,
                                        size: 16,
                                        color: SolvilleTheme.timberDark,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    final compactBadgePad = isCompactScreen
                        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 3)
                        : const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          );
                    final badgeRadius = isCompactScreen ? 12.0 : 14.0;
                    final badgeFontSize = isCompactScreen ? 11.0 : 11.5;

                    final eventBadgeWidgets = <Widget>[
                      if (showDailyReq)
                        InkWell(
                          borderRadius: BorderRadius.circular(badgeRadius),
                          onTap: _openMarket,
                          child: Container(
                            padding: compactBadgePad,
                            decoration: SolvilleTheme.panelDecoration(
                              color: const Color(0xF2FFF8E1),
                              radius: badgeRadius,
                            ),
                            child: Text(
                              '💌 ${SolvilleCatalog.productEmoji(dailyReq.product)} ${dailyReq.deliveredCount}/${dailyReq.requiredCount} +${dailyReq.bonusReward}☀️',
                              style: TextStyle(
                                color: SolvilleTheme.timberDark,
                                fontWeight: FontWeight.w800,
                                fontSize: badgeFontSize,
                              ),
                            ),
                          ),
                        ),
                      if (express != null)
                        InkWell(
                          borderRadius: BorderRadius.circular(badgeRadius),
                          onTap: _openMarket,
                          child: Container(
                            padding: compactBadgePad,
                            decoration: SolvilleTheme.panelDecoration(
                              color: const Color(0xF2FFF3E0),
                              radius: badgeRadius,
                            ),
                            child: Text(
                              '⚡ ${SolvilleCatalog.productEmoji(express.product)} ${express.deliveredCount}/${express.requiredCount} +${express.bonusCoins}☀️ • ${express.remainingSeconds.ceil()}s',
                              style: TextStyle(
                                color: SolvilleTheme.timberDark,
                                fontWeight: FontWeight.w800,
                                fontSize: badgeFontSize,
                              ),
                            ),
                          ),
                        ),
                      if (state.market.isRushActive)
                        Container(
                          padding: compactBadgePad,
                          decoration: SolvilleTheme.panelDecoration(
                            color: const Color(0xF2FFE082),
                            radius: badgeRadius,
                          ),
                          child: Text(
                            '${l10n.hudRushBadge} ${state.market.rushSecondsRemaining.ceil()}s',
                            style: TextStyle(
                              color: SolvilleTheme.timberDark,
                              fontWeight: FontWeight.w900,
                              fontSize: badgeFontSize,
                            ),
                          ),
                        ),
                      if (state.comboStreak >= 2)
                        Container(
                          padding: compactBadgePad,
                          decoration: SolvilleTheme.panelDecoration(
                            color: const Color(0xF2E8F5E9),
                            radius: badgeRadius,
                          ),
                          child: Text(
                            '✨ ${state.comboStreak}×',
                            style: TextStyle(
                              color: const Color(0xFF2E7D32),
                              fontWeight: FontWeight.w900,
                              fontSize: badgeFontSize,
                            ),
                          ),
                        ),
                    ];

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Flexible(
                          child: SingleChildScrollView(
                            physics: const ClampingScrollPhysics(),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                TopStatusBar(
                                  controller: widget.controller,
                                  onOpenShop: _openShop,
                                  onOpenMarket: _openMarket,
                                  onOpenTrophies: _openTrophies,
                                  onOpenAudio: _openAudioAndHomestead,
                                  onOpenHelp: _openHelp,
                                  onOpenSunPass: _openSunPass,
                                  isJournalExpanded: !_questPinCollapsed,
                                  onToggleJournal: () => setState(() {
                                    _questPinCollapsed = !_questPinCollapsed;
                                  }),
                                ),
                                if (!_questPinCollapsed &&
                                    (activeQuest != null || showEventBadges))
                                  if (isCompactScreen)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: 2,
                                        left: 8,
                                        right: 8,
                                      ),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: <Widget>[
                                              if (activeQuest != null)
                                                buildQuestPill(compact: true),
                                              for (final badge
                                                  in eventBadgeWidgets)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        left: 5,
                                                      ),
                                                  child: badge,
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    )
                                  else ...<Widget>[
                                    if (activeQuest != null)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 4,
                                          left: 10,
                                          right: 10,
                                        ),
                                        child: ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            maxWidth: 680,
                                          ),
                                          child: buildQuestPill(compact: false),
                                        ),
                                      ),
                                    if (showEventBadges)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 4,
                                          left: 12,
                                          right: 12,
                                        ),
                                        child: Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          alignment: WrapAlignment.center,
                                          children: eventBadgeWidgets,
                                        ),
                                      ),
                                  ],
                                if (toast != null)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 6,
                                      left: 16,
                                      right: 16,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 7,
                                      ),
                                      decoration: SolvilleTheme.panelDecoration(
                                        color: const Color(0xF5FFF8E1),
                                        radius: 18,
                                      ),
                                      child: Text(
                                        toast,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: SolvilleTheme.timberDark,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        Flexible(
                          child: SingleChildScrollView(
                            physics: const ClampingScrollPhysics(),
                            child: BottomToolDock(
                              controller: widget.controller,
                              game: _game,
                              onOpenShop: _openShop,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
