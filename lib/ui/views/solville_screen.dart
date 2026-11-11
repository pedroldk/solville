import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../game/solville_game.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/solville_l10n_extensions.dart';
import '../hud/bottom_tool_dock.dart';
import '../hud/game_viewport_surface.dart';
import '../hud/tile_inspector_pill.dart';
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
                                TileInspectorPill(
                                  controller: widget.controller,
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
