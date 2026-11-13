import 'dart:async';

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

  void _openShop() {
    widget.controller.notifyUserGestureForAudio();
    showDialog<void>(
      context: context,
      builder: (_) => ShopModal(controller: widget.controller),
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
                    final toastData = widget.controller.toast;
                    final toast = toastData != null
                        ? l10n.resolveToast(toastData)
                        : widget.controller.toastMessage;
                    final state = widget.controller.state;
                    final express = state.market.expressOrder;
                    final showEventBadges =
                        express != null ||
                        state.market.isRushActive ||
                        state.comboStreak >= 2;
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
                                      children: <Widget>[
                                        if (express != null)
                                          InkWell(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            onTap: _openMarket,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                              decoration:
                                                  SolvilleTheme.panelDecoration(
                                                    color: const Color(
                                                      0xF2FFF3E0,
                                                    ),
                                                    radius: 14,
                                                  ),
                                              child: Text(
                                                '⚡ ${SolvilleCatalog.productEmoji(express.product)} ${express.deliveredCount}/${express.requiredCount} +${express.bonusCoins}☀️ • ${express.remainingSeconds.ceil()}s',
                                                style: const TextStyle(
                                                  color:
                                                      SolvilleTheme.timberDark,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 11.5,
                                                ),
                                              ),
                                            ),
                                          ),
                                        if (state.market.isRushActive)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration:
                                                SolvilleTheme.panelDecoration(
                                                  color: const Color(
                                                    0xF2FFE082,
                                                  ),
                                                  radius: 14,
                                                ),
                                            child: Text(
                                              '${l10n.hudRushBadge} ${state.market.rushSecondsRemaining.ceil()}s',
                                              style: const TextStyle(
                                                color: SolvilleTheme.timberDark,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 11.5,
                                              ),
                                            ),
                                          ),
                                        if (state.comboStreak >= 2)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 9,
                                              vertical: 4,
                                            ),
                                            decoration:
                                                SolvilleTheme.panelDecoration(
                                                  color: const Color(
                                                    0xF2E8F5E9,
                                                  ),
                                                  radius: 14,
                                                ),
                                            child: Text(
                                              '✨ ${state.comboStreak}×',
                                              style: const TextStyle(
                                                color: Color(0xFF2E7D32),
                                                fontWeight: FontWeight.w900,
                                                fontSize: 11.5,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
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
