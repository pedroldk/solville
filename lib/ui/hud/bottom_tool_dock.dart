import 'package:flutter/material.dart';

import '../../domain/models/catalog.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/market_state.dart';
import '../../game/solville_game.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/solville_l10n_extensions.dart';
import '../theme/solville_theme.dart';
import '../view_models/solville_controller.dart';
import '../widgets/solville_pill_button.dart';

enum _ActiveTray { none, seeds, build, tools }

/// Zen-first adaptive bottom dock for Android, Web & Desktop:
/// - Unified 5-button dock (Smart, Seeds, Build, Manual Tools, Sweep) + compact
///   camera re-center button across all screen sizes.
/// - Seed, Build, and Manual Tool trays open only on tap and auto-close on
///   selection so the diorama stays uncluttered.
/// - Live Tile Inspector Pill appears only when a tile is actively inspected.
class BottomToolDock extends StatefulWidget {
  const BottomToolDock({
    super.key,
    required this.controller,
    required this.game,
    required this.onOpenShop,
  });

  final SolvilleController controller;
  final SolvilleGame game;
  final VoidCallback onOpenShop;

  @override
  State<BottomToolDock> createState() => _BottomToolDockState();
}

class _BottomToolDockState extends State<BottomToolDock> {
  _ActiveTray _activeTray = _ActiveTray.none;

  void _closeTray() {
    if (_activeTray != _ActiveTray.none) {
      setState(() => _activeTray = _ActiveTray.none);
    }
  }

  void _toggleTray(_ActiveTray tray) {
    setState(() {
      _activeTray = _activeTray == tray ? _ActiveTray.none : tray;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = widget.controller;
    final game = widget.game;
    final mediaSize = MediaQuery.sizeOf(context);
    final isMobile = mediaSize.shortestSide < 600;
    final isCompact = mediaSize.width < 860 || isMobile;
    final state = controller.state;
    final showTray = _activeTray != _ActiveTray.none;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isCompact ? 6 : 10,
        0,
        isCompact ? 6 : 10,
        isCompact ? 4 : 10,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Row 0: Slim Live Tile Inspector Pill (hidden while a tray is open)
          if (!showTray)
            _TileInspectorPill(
              controller: controller,
              hideOnActionQueue: isCompact,
            ),

          // Row 1: Action Queue status pill only when tasks are queued
          if (!showTray && state.actionQueue.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: isCompact ? 4 : 6),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 9 : 12,
                  vertical: isCompact ? 4 : 5,
                ),
                decoration: SolvilleTheme.panelDecoration(
                  color: const Color(0xF5FFF8E1),
                  radius: 20,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      l10n.dockQueuedCount(state.actionQueue.length),
                      style: TextStyle(
                        color: SolvilleTheme.timberDark,
                        fontWeight: FontWeight.w800,
                        fontSize: isCompact ? 11.5 : 12.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: controller.clearActionQueue,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFCDD2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          l10n.dockClear,
                          style: const TextStyle(
                            color: Color(0xFFB71C1C),
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Row 2: Unified Pop-Up Tray (Seeds, Build, or Manual Tools)
          if (showTray)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: switch (_activeTray) {
                _ActiveTray.seeds => _SeedSelectorStrip(
                  controller: controller,
                  onOpenShop: () {
                    _closeTray();
                    widget.onOpenShop();
                  },
                  onCloseTray: _closeTray,
                ),
                _ActiveTray.build => _BuildSelectorStrip(
                  controller: controller,
                  onCloseTray: _closeTray,
                ),
                _ActiveTray.tools => _ManualToolsTray(
                  controller: controller,
                  onClose: _closeTray,
                ),
                _ActiveTray.none => const SizedBox.shrink(),
              },
            ),

          // Row 3: Unified 5-Button Zen Dock + Camera Re-center Icon
          _buildUnifiedDock(
            l10n,
            controller,
            state,
            game,
            isMobile: isMobile,
          ),
        ],
      ),
    );
  }

  Widget _buildUnifiedDock(
    AppLocalizations l10n,
    SolvilleController controller,
    GameState state,
    SolvilleGame game, {
    required bool isMobile,
  }) {
    final isManualActive =
        state.activeTool == ToolMode.dig ||
        state.activeTool == ToolMode.water ||
        state.activeTool == ToolMode.compost ||
        state.activeTool == ToolMode.remove;

    final (String manualEmoji, String manualLabel) = switch (state.activeTool) {
      ToolMode.water => ('🪣', l10n.toolWater),
      ToolMode.compost => ('✨', l10n.toolCompost),
      ToolMode.remove => ('🌿', l10n.toolRemove),
      _ => ('⛏️', l10n.toolDig),
    };

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: SolvilleTheme.panelDecoration(radius: 18),
          child: Row(
            children: <Widget>[
              Expanded(
                child: _ToolSlotButton(
                  hotkey: '1',
                  showHotkey: false,
                  compact: true,
                  emoji: '🖐️',
                  label: l10n.toolSmart,
                  selected:
                      state.activeTool == ToolMode.smart &&
                      _activeTray == _ActiveTray.none,
                  onTap: () {
                    controller.selectTool(ToolMode.smart);
                    _closeTray();
                  },
                ),
              ),
              Expanded(
                child: _ToolSlotButton(
                  hotkey: '3',
                  showHotkey: false,
                  compact: true,
                  emoji: SolvilleCatalog.productEmoji(state.selectedSeed),
                  label: l10n.toolSeed,
                  selected:
                      state.activeTool == ToolMode.seed ||
                      _activeTray == _ActiveTray.seeds,
                  onTap: () {
                    controller.selectTool(ToolMode.seed);
                    _toggleTray(_ActiveTray.seeds);
                  },
                ),
              ),
              Expanded(
                child: _ToolSlotButton(
                  hotkey: '6',
                  showHotkey: false,
                  compact: true,
                  emoji: '🔨',
                  label: l10n.toolBuild,
                  selected:
                      state.activeTool == ToolMode.build ||
                      _activeTray == _ActiveTray.build,
                  onTap: () {
                    controller.selectTool(ToolMode.build);
                    _toggleTray(_ActiveTray.build);
                  },
                ),
              ),
              Expanded(
                child: _ToolSlotButton(
                  hotkey: '2',
                  showHotkey: false,
                  compact: true,
                  emoji: manualEmoji,
                  label: manualLabel,
                  selected:
                      isManualActive || _activeTray == _ActiveTray.tools,
                  onTap: () => _toggleTray(_ActiveTray.tools),
                ),
              ),
              Expanded(
                child: _ToolSlotButton(
                  hotkey: 'S',
                  showHotkey: false,
                  compact: true,
                  icon: Icons.gesture_rounded,
                  label: l10n.dockSweepLabel,
                  selected: controller.paintSweepMode,
                  onTap: controller.togglePaintSweepMode,
                ),
              ),
              const SizedBox(width: 2),
              Tooltip(
                message: l10n.adaptiveCenterCameraTooltip(isMobile: isMobile),
                child: IconButton(
                  onPressed: game.centerCameraOnFarmer,
                  style: IconButton.styleFrom(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    minimumSize: const Size(34, 34),
                    fixedSize: const Size(34, 34),
                    padding: EdgeInsets.zero,
                  ),
                  icon: const Icon(
                    Icons.my_location_rounded,
                    size: 18,
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
}

class _ManualToolsTray extends StatelessWidget {
  const _ManualToolsTray({required this.controller, required this.onClose});

  final SolvilleController controller;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = controller.state;
    final active = state.activeTool;
    final readyHarvests = state.readyHarvestCount;
    final thirstyPlots = state.thirstyPlotCount;

    final tools = <(ToolMode, String, String)>[
      (ToolMode.dig, '⛏️', l10n.toolDig),
      (ToolMode.water, '🪣', l10n.toolWater),
      (
        ToolMode.compost,
        '✨',
        '${l10n.toolCompost} (${SolvilleCatalog.compostCost}☀️)',
      ),
      (ToolMode.remove, '🌿', '${l10n.toolRemove} (${l10n.toolRemoveSub})'),
    ];

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560, maxHeight: 220),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 6, 8, 8),
        decoration: SolvilleTheme.panelDecoration(radius: 18),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(
                    '⛏️ ${l10n.toolDig} / ${l10n.toolWater} / ${l10n.toolRemove}',
                    style: const TextStyle(
                      color: SolvilleTheme.timberDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: onClose,
                    child: const Padding(
                      padding: EdgeInsets.all(2),
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: SolvilleTheme.timberDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: <Widget>[
                  for (final (mode, emoji, label) in tools)
                    ChoiceChip(
                      selected: active == mode,
                      selectedColor: const Color(0xFFFFE082),
                      backgroundColor: SolvilleTheme.parchment,
                      label: Text(
                        '$emoji $label',
                        style: const TextStyle(
                          color: SolvilleTheme.timberDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      onSelected: (_) {
                        controller.selectTool(mode);
                        onClose();
                      },
                    ),
                ],
              ),
              if (readyHarvests > 0 || thirstyPlots > 0) ...<Widget>[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: <Widget>[
                    if (readyHarvests > 0)
                      SolvillePillButton(
                        emoji: '🌾',
                        label: l10n.dockHarvestRipe(readyHarvests),
                        backgroundColor: const Color(0xFFE8F5E9),
                        borderRadius: 14,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        fontSize: 11.5,
                        onTap: () {
                          controller.queueAllReadyHarvests();
                          onClose();
                        },
                      ),
                    if (thirstyPlots > 0)
                      SolvillePillButton(
                        emoji: '💧',
                        label: l10n.dockWaterDry(thirstyPlots),
                        backgroundColor: const Color(0xFFE1F5FE),
                        borderRadius: 14,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        fontSize: 11.5,
                        onTap: () {
                          controller.queueAllThirstyPlots();
                          onClose();
                        },
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SeedSelectorStrip extends StatelessWidget {
  const _SeedSelectorStrip({
    required this.controller,
    required this.onOpenShop,
    required this.onCloseTray,
  });

  final SolvilleController controller;
  final VoidCallback onOpenShop;
  final VoidCallback onCloseTray;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = controller.state;
    final unlockedCrops = SolvilleCatalog.crops.values
        .where(
          (c) =>
              state.unlockedSeeds.contains(c.id) ||
              (state.trialSeeds[c.id] ?? 0) > 0,
        )
        .toList();
    final hasLocked = SolvilleCatalog.crops.values.any(
      (c) => !state.unlockedSeeds.contains(c.id),
    );

    final chips = <Widget>[
      for (final crop in unlockedCrops)
        Builder(
          builder: (context) {
            final trialCount = state.trialSeeds[crop.id] ?? 0;
            final hasTrial = trialCount > 0;
            final isSunPassLocked =
                crop.requiresSunPass && !controller.isSunPassActive;
            final needsUnlock = !state.unlockedSeeds.contains(crop.id);
            final chipBg = (isSunPassLocked || needsUnlock) && hasTrial
                ? const Color(0xFFE8F5E9)
                : (isSunPassLocked
                      ? const Color(0xFFFFF3E0)
                      : SolvilleTheme.parchment);
            final isBoom = state.market.trendFor(crop.id) == MarketTrend.boom;
            final isOrdered =
                state.market.expressOrder?.product == crop.id ||
                (state.market.dailyRequest != null &&
                    !state.market.dailyRequest!.isCompleted &&
                    state.market.dailyRequest!.product == crop.id);
            final demandTag = isBoom
                ? (isOrdered ? ' 🔥💌' : ' 🔥')
                : (isOrdered ? ' 💌' : '');
            final chipLabel = hasTrial && (isSunPassLocked || needsUnlock)
                ? '${crop.emoji} ${l10n.productShortName(crop.id)} 🎁$trialCount$demandTag'
                : (isSunPassLocked
                      ? '${l10n.dockSeedLockedLabel(crop.emoji, l10n.productShortName(crop.id))}$demandTag'
                      : (hasTrial
                            ? '${crop.emoji} ${l10n.productShortName(crop.id)} ${crop.seedCost}☀️ • 🎁$trialCount$demandTag'
                            : '${crop.emoji} ${l10n.productShortName(crop.id)} ${crop.seedCost}☀️$demandTag'));
            return ChoiceChip(
              selected: state.selectedSeed == crop.id,
              selectedColor: const Color(0xFFFFE082),
              backgroundColor: chipBg,
              label: Text(
                chipLabel,
                style: const TextStyle(
                  color: SolvilleTheme.timberDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              onSelected: (_) {
                controller.selectSeed(crop.id);
                onCloseTray();
              },
            );
          },
        ),
      if (hasLocked)
        ActionChip(
          backgroundColor: const Color(0xFFE8F5E9),
          label: Text(
            l10n.dockUnlockSeeds,
            style: const TextStyle(
              color: SolvilleTheme.timberDark,
              fontWeight: FontWeight.w800,
              fontSize: 11.5,
            ),
          ),
          onPressed: onOpenShop,
        ),
    ];

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560, maxHeight: 220),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 6, 8, 8),
        decoration: SolvilleTheme.panelDecoration(radius: 18),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(
                    '🌱 ${l10n.toolSeed}',
                    style: const TextStyle(
                      color: SolvilleTheme.timberDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: onCloseTray,
                    child: const Padding(
                      padding: EdgeInsets.all(2),
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: SolvilleTheme.timberDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: chips,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BuildSelectorStrip extends StatelessWidget {
  const _BuildSelectorStrip({
    required this.controller,
    required this.onCloseTray,
  });

  final SolvilleController controller;
  final VoidCallback onCloseTray;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = controller.state;
    final expTier = state.upgradeTier(UpgradeTrack.farmExpansion);
    final nextExp = SolvilleCatalog.nextUpgradeFor(
      UpgradeTrack.farmExpansion,
      expTier,
    );
    final nextSize = SolvilleCatalog.gridSizeForExpansionTier(expTier + 1);

    final chips = <Widget>[
      if (nextExp != null)
        ActionChip(
          backgroundColor:
              (nextExp.requiresSunPass && !controller.isSunPassActive)
              ? const Color(0xFFFFF3E0)
              : (state.coins >= nextExp.cost
                    ? const Color(0xFFFFE082)
                    : const Color(0xFFFFF8E1)),
          label: Text(
            nextExp.requiresSunPass && !controller.isSunPassActive
                ? l10n.dockExpandIsleLocked(state.gridSize, nextSize)
                : l10n.dockExpandIsle(state.gridSize, nextSize, nextExp.cost),
            style: const TextStyle(
              color: SolvilleTheme.timberDark,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          onPressed: () {
            controller.expandIsle();
            onCloseTray();
          },
        ),
      for (final def in SolvilleCatalog.buildItems.values)
        ChoiceChip(
          selected: state.selectedBuildItem == def.type,
          selectedColor: const Color(0xFFB3E5FC),
          backgroundColor: (def.requiresSunPass && !controller.isSunPassActive)
              ? const Color(0xFFFFF3E0)
              : SolvilleTheme.parchment,
          label: Text(
            def.requiresSunPass && !controller.isSunPassActive
                ? l10n.dockBuildLockedLabel(
                    def.emoji,
                    l10n.buildItemName(def.type),
                  )
                : '${def.emoji} ${l10n.buildItemName(def.type)} (${def.cost}☀️)',
            style: const TextStyle(
              color: SolvilleTheme.timberDark,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          onSelected: (_) {
            controller.selectBuildItem(def.type);
            onCloseTray();
          },
        ),
    ];

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560, maxHeight: 240),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 6, 8, 8),
        decoration: SolvilleTheme.panelDecoration(radius: 18),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(
                    '🔨 ${l10n.toolBuild}',
                    style: const TextStyle(
                      color: SolvilleTheme.timberDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: onCloseTray,
                    child: const Padding(
                      padding: EdgeInsets.all(2),
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: SolvilleTheme.timberDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: chips,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolSlotButton extends StatelessWidget {
  const _ToolSlotButton({
    required this.hotkey,
    required this.label,
    required this.selected,
    required this.onTap,
    this.emoji,
    this.icon,
    this.showHotkey = true,
    this.compact = false,
  });

  final String hotkey;
  final String? emoji;
  final IconData? icon;
  final String label;
  final bool selected;
  final bool showHotkey;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = compact ? 13.0 : 14.0;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 2 : 3),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(
              0,
              selected ? (compact ? -2.0 : -3.5) : 0,
              0,
            ),
            constraints: compact
                ? const BoxConstraints(minWidth: 0, minHeight: 42)
                : const BoxConstraints(minWidth: 68, minHeight: 48),
            padding: compact
                ? const EdgeInsets.symmetric(horizontal: 4, vertical: 4)
                : const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: selected
                  ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[Color(0xFFFFE082), Color(0xFFFFCA28)],
                    )
                  : null,
              color: selected ? null : SolvilleTheme.warmCream,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: selected
                    ? const Color(0xFFE65100)
                    : const Color(0x55795548),
                width: selected ? 1.8 : 1.1,
              ),
              boxShadow: selected
                  ? const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x4DFFCA28),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (showHotkey) ...<Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0x33E65100)
                              : const Color(0x1F4E342E),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          hotkey,
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xBB4E342E),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    if (icon != null)
                      Icon(
                        icon,
                        size: compact ? 17 : 18,
                        color: selected
                            ? const Color(0xFFE65100)
                            : SolvilleTheme.timberDark,
                      )
                    else
                      Text(
                        emoji ?? '',
                        style: TextStyle(fontSize: compact ? 15 : 17),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: SolvilleTheme.timberDark,
                    fontSize: compact ? 10.5 : 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TileInspectorPill extends StatelessWidget {
  const _TileInspectorPill({
    required this.controller,
    required this.hideOnActionQueue,
  });

  final SolvilleController controller;
  final bool hideOnActionQueue;

  @override
  Widget build(BuildContext context) {
    if (hideOnActionQueue && controller.state.actionQueue.isNotEmpty) {
      return const SizedBox.shrink();
    }
    final raw = controller.activeInspection;
    if (raw == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final info = l10n.localizeTileInspection(
      controller.state,
      raw,
      isSunPassActive: controller.isSunPassActive,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: SolvilleTheme.panelDecoration(
            color: const Color(0xF5FFFDF6),
            radius: 14,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(info.emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  info.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SolvilleTheme.timberDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 11.5,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3C4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '👆 ${info.nextTapHint}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: SolvilleTheme.timberDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 10.5,
                    ),
                  ),
                ),
              ),
              if (info.canCycleKettleRecipe) ...<Widget>[
                const SizedBox(width: 6),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => controller.toggleKettleRecipe(info.pos),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE1F5FE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('🔄', style: TextStyle(fontSize: 11)),
                  ),
                ),
              ],
              if (info.canQuickUntill) ...<Widget>[
                const SizedBox(width: 6),
                Tooltip(
                  message: l10n.inspectorClearTooltip,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      controller.untillTile(info.pos);
                      controller.inspectTile(null);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF66BB6A)),
                      ),
                      child: const Text('🌿', style: TextStyle(fontSize: 11)),
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 4),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => controller.inspectTile(null),
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(
                    Icons.close_rounded,
                    size: 14,
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
}
