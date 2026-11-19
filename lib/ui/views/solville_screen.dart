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
import '../modals/day_stats_modal.dart';
import '../modals/help_modal.dart';
import '../modals/homestead_modal.dart';
import '../modals/market_and_barn_modal.dart';
import '../modals/shop_modal.dart';
import '../modals/sun_pass_modal.dart';
import '../modals/trophy_cabinet_modal.dart';
import '../theme/solville_theme.dart';
import '../view_models/solville_controller.dart';
import '../widgets/solville_buttons.dart';
import '../widgets/solville_pill_button.dart';

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
  late bool _questPinCollapsed;
  bool _isDayStatsOpen = false;

  void _handleTutorialReplayed() {
    if (mounted) {
      setState(() => _questPinCollapsed = false);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _questPinCollapsed =
        !widget.controller.state.isOnboardingActive &&
        widget.controller.state.claimedQuestsCount >= 3;
    _game = SolvilleGame(controller: widget.controller);
    widget.controller.onRequestOpenMarketModal = _openMarket;
    widget.controller.onRequestOpenHomesteadModal = _openAudioAndHomestead;
    widget.controller.onRequestOpenSunPassModal = _openSunPass;
    widget.controller.onRequestOpenDayStatsModal = _openDayStats;
    widget.controller.onTutorialReplayed = _handleTutorialReplayed;
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
    if (identical(
      widget.controller.onRequestOpenDayStatsModal,
      _openDayStats,
    )) {
      widget.controller.onRequestOpenDayStatsModal = null;
    }
    if (identical(
      widget.controller.onTutorialReplayed,
      _handleTutorialReplayed,
    )) {
      widget.controller.onTutorialReplayed = null;
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Auto-save cleanly and pause/resume BGM across lifecycle states, keeping
    // desktop music playing when the window merely loses focus (inactive).
    final isDesktop =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.linux);
    switch (state) {
      case AppLifecycleState.inactive:
        if (!isDesktop) {
          widget.controller.onAppBackgrounded();
        }
        unawaited(widget.controller.saveNow(showToast: false));
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
      barrierColor: const Color(0x7A24160E),
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
      barrierColor: const Color(0x7A24160E),
      builder: (_) => MarketAndBarnModal(controller: widget.controller),
    );
  }

  void _openTrophies() {
    widget.controller.notifyUserGestureForAudio();
    showDialog<void>(
      context: context,
      barrierColor: const Color(0x7A24160E),
      builder: (_) => TrophyCabinetModal(controller: widget.controller),
    );
  }

  void _openAudioAndHomestead() {
    widget.controller.notifyUserGestureForAudio();
    showDialog<void>(
      context: context,
      barrierColor: const Color(0x7A24160E),
      builder: (_) => HomesteadAndAudioModal(controller: widget.controller),
    );
  }

  void _openHelp() {
    widget.controller.notifyUserGestureForAudio();
    showDialog<void>(
      context: context,
      barrierColor: const Color(0x7A24160E),
      builder: (_) => HelpAndControlsModal(controller: widget.controller),
    );
  }

  void _openSunPass() {
    widget.controller.notifyUserGestureForAudio();
    showDialog<void>(
      context: context,
      barrierColor: const Color(0x7A24160E),
      builder: (_) => SunPassModal(controller: widget.controller),
    );
  }

  void _openDayStats() {
    if (!mounted || _isDayStatsOpen) return;
    _isDayStatsOpen = true;
    widget.controller.notifyUserGestureForAudio();
    final wasAlreadyPaused = widget.controller.isPaused;
    if (!wasAlreadyPaused) {
      widget.controller.togglePause();
    }
    showDialog<void>(
      context: context,
      barrierColor: const Color(0x7A24160E),
      builder: (_) => DayStatsModal(controller: widget.controller),
    ).whenComplete(() {
      if (!mounted) return;
      _isDayStatsOpen = false;
      if (!wasAlreadyPaused && widget.controller.isPaused) {
        widget.controller.togglePause();
      }
    });
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
                      spotlightStepDig: l10n.spotlightStepDig,
                      spotlightStepPlant: l10n.spotlightStepPlant,
                      spotlightStepWater: l10n.spotlightStepWater,
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
                      final isOnboarding = state.isOnboardingActive;
                      return ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: compact
                              ? compactQuestMaxWidth
                              : double.infinity,
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: const <double>[0.0, 0.16, 1.0],
                              colors: questProg.isReadyToClaim
                                  ? const <Color>[
                                      Color(0xFFFFFDF0),
                                      Color(0xFFFFF3C4),
                                      Color(0xFFFFE082),
                                    ]
                                  : (isOnboarding
                                        ? const <Color>[
                                            Color(0xFFFFFFFE),
                                            Color(0xFFFFFAEB),
                                            Color(0xFFFFEEBD),
                                          ]
                                        : const <Color>[
                                            Color(0xFFFFFFFE),
                                            Color(0xFFFFFBF0),
                                            Color(0xFFFFF0CF),
                                          ]),
                            ),
                            borderRadius: BorderRadius.circular(radius),
                            border: Border.all(
                              color:
                                  (questProg.isReadyToClaim || isOnboarding)
                                  ? const Color(0xFFE65100)
                                  : const Color(0xFF6D442B),
                              width: 1.9,
                            ),
                            boxShadow: const <BoxShadow>[
                              BoxShadow(
                                color: SolvilleTheme.cedarDark,
                                offset: Offset(0, 2.8),
                                blurRadius: 0,
                              ),
                              BoxShadow(
                                color: Color(0x2E261412),
                                offset: Offset(0, 5),
                                blurRadius: 10,
                              ),
                            ],
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
                                              7,
                                              4,
                                              4,
                                              4,
                                            )
                                          : const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          SolvilleIconMedallion(
                                            size: compact ? 26 : 34,
                                            highlighted:
                                                questProg.isReadyToClaim,
                                            child: Text(
                                              activeQuest.emoji,
                                              style: TextStyle(
                                                fontSize: compact ? 13.5 : 17,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: compact ? 5 : 8),
                                          Flexible(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: <Widget>[
                                                if (!compact && isOnboarding)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          bottom: 2,
                                                        ),
                                                    child: Text(
                                                      l10n.tutorialMayorBadge,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        color: Color(
                                                          0xFFE65100,
                                                        ),
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        fontSize: 10.5,
                                                      ),
                                                    ),
                                                  ),
                                                Text(
                                                  compact
                                                      ? '${activeQuest.stepNumber}/${SolvilleCatalog.quests.length}: ${l10n.questTitle(activeQuest.id)}'
                                                      : l10n.questGoalHeader(
                                                          activeQuest
                                                              .stepNumber,
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
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: compact
                                                        ? 10.0
                                                        : 11.0,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(width: compact ? 6 : 8),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: compact ? 7 : 10,
                                              vertical: compact ? 3 : 4,
                                            ),
                                            decoration: questProg.isReadyToClaim
                                                ? BoxDecoration(
                                                    gradient:
                                                        const LinearGradient(
                                                          begin: Alignment
                                                              .topCenter,
                                                          end: Alignment
                                                              .bottomCenter,
                                                          colors: <Color>[
                                                            Color(0xFF66BB6A),
                                                            Color(0xFF2E7D32),
                                                          ],
                                                        ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                    border: Border.all(
                                                      color: const Color(
                                                        0xFF144418,
                                                      ),
                                                      width: 1.3,
                                                    ),
                                                    boxShadow: const <BoxShadow>[
                                                      BoxShadow(
                                                        color: Color(
                                                          0xFF1B5E20,
                                                        ),
                                                        offset: Offset(0, 2.0),
                                                        blurRadius: 0,
                                                      ),
                                                    ],
                                                  )
                                                : SolvilleTheme.recessedSlotDecoration(
                                                    radius: 10,
                                                  ),
                                            child: Text(
                                              questProg.isReadyToClaim
                                                  ? l10n.questClaimBtn(
                                                      activeQuest.rewardCoins,
                                                    )
                                                  : (compact
                                                        ? '${questProg.current}/${questProg.required} 👇'
                                                        : '${questProg.current}/${questProg.required} • +${activeQuest.rewardCoins}☀️ • ${l10n.tutorialShowMeBtn}'),
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
                                Padding(
                                  padding: EdgeInsets.only(
                                    right: compact ? 5 : 7,
                                  ),
                                  child: SolvilleIconButton(
                                    tone: SolvilleButtonTone.cream,
                                    icon: Icons.expand_less_rounded,
                                    size: compact ? 26 : 30,
                                    iconSize: compact ? 15 : 17,
                                    borderRadius: compact ? 13 : 15,
                                    onPressed: () => setState(() {
                                      _questPinCollapsed = true;
                                    }),
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
                        SolvillePillButton(
                          emoji: '',
                          label:
                              '💌 ${SolvilleCatalog.productEmoji(dailyReq.product)} ${dailyReq.deliveredCount}/${dailyReq.requiredCount} +${dailyReq.bonusReward}☀️',
                          backgroundColor: const Color(0xFFFFF8E1),
                          padding: compactBadgePad,
                          borderRadius: badgeRadius,
                          fontSize: badgeFontSize,
                          emojiSize: badgeFontSize + 1,
                          onTap: _openMarket,
                        ),
                      if (express != null)
                        SolvillePillButton(
                          emoji: '',
                          label:
                              '⚡ ${SolvilleCatalog.productEmoji(express.product)} ${express.deliveredCount}/${express.requiredCount} +${express.bonusCoins}☀️ • ${express.remainingSeconds.ceil()}s',
                          highlighted: true,
                          backgroundColor: const Color(0xFFFFF3E0),
                          padding: compactBadgePad,
                          borderRadius: badgeRadius,
                          fontSize: badgeFontSize,
                          emojiSize: badgeFontSize + 1,
                          onTap: _openMarket,
                        ),
                      if (state.market.isRushActive)
                        SolvilleBadge(
                          label:
                              '${l10n.hudRushBadge} ${state.market.rushSecondsRemaining.ceil()}s',
                          color: const Color(0xFFFFE082),
                          borderColor: const Color(0xFFE65100),
                          padding: compactBadgePad,
                          borderRadius: badgeRadius,
                          fontSize: badgeFontSize,
                        ),
                      if (state.comboStreak >= 2)
                        SolvilleBadge(
                          label: '✨ ${state.comboStreak}×',
                          color: const Color(0xFFE8F5E9),
                          borderColor: const Color(0xFF2E7D32),
                          textColor: const Color(0xFF1B5E20),
                          padding: compactBadgePad,
                          borderRadius: badgeRadius,
                          fontSize: badgeFontSize,
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
                                        alignment: Alignment.center,
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
                                      decoration: SolvilleTheme.hudBarDecoration(
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
