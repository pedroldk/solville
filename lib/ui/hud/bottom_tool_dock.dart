import 'package:flutter/material.dart';

import '../../domain/models/catalog.dart';
import '../../domain/models/game_state.dart';
import '../../game/solville_game.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/solville_l10n_extensions.dart';
import '../theme/solville_theme.dart';
import '../view_models/solville_controller.dart';
import '../widgets/solville_pill_button.dart';

/// Thumb-friendly adaptive bottom dock for Android & PC/Steam:
/// - Action Queue status pill (`Clear Queue`) + one-tap `Harvest Ripe` & `Water Dry`
/// - Contextual Seed Packet or Build Item selector strip
/// - Tool belt (`1` Auto, `2` Dig, `3` Seed, `4` Water, `5` Compost, `6` Build, `7` Clear)
class BottomToolDock extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isMobile = MediaQuery.sizeOf(context).shortestSide < 600;
    final state = controller.state;
    final showSeeds =
        state.activeTool == ToolMode.smart || state.activeTool == ToolMode.seed;
    final showBuild = state.activeTool == ToolMode.build;
    final readyHarvests = state.readyHarvestCount;
    final thirstyPlots = state.thirstyPlotCount;

    return Padding(
      padding: EdgeInsets.fromLTRB(10, 0, 10, isMobile ? 6 : 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Row 1: Action Queue pill + Batch Garden Helpers + Camera quick controls
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                if (state.actionQueue.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
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
                          style: const TextStyle(
                            color: SolvilleTheme.timberDark,
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: controller.clearActionQueue,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
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
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (readyHarvests > 0)
                  SolvillePillButton(
                    emoji: '🌾',
                    label: l10n.dockHarvestRipe(readyHarvests),
                    tooltip: l10n.adaptiveHarvestRipeTooltip(
                      isMobile: isMobile,
                    ),
                    backgroundColor: const Color(0xFFE8F5E9),
                    borderRadius: 18,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 6,
                    ),
                    fontSize: 12,
                    onTap: controller.queueAllReadyHarvests,
                  ),
                if (thirstyPlots > 0)
                  SolvillePillButton(
                    emoji: '💧',
                    label: l10n.dockWaterDry(thirstyPlots),
                    tooltip: l10n.dockWaterDryTooltip,
                    backgroundColor: const Color(0xFFE1F5FE),
                    borderRadius: 18,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 6,
                    ),
                    fontSize: 12,
                    onTap: controller.queueAllThirstyPlots,
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: SolvilleTheme.panelDecoration(radius: 18),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: l10n.adaptiveCenterCameraTooltip(
                          isMobile: isMobile,
                        ),
                        onPressed: game.centerCameraOnFarmer,
                        icon: const Icon(
                          Icons.my_location_rounded,
                          size: 18,
                          color: SolvilleTheme.timberDark,
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: l10n.dockZoomInTooltip,
                        onPressed: () => game.adjustZoom(1.15),
                        icon: const Icon(
                          Icons.add_rounded,
                          size: 18,
                          color: SolvilleTheme.timberDark,
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: l10n.dockZoomOutTooltip,
                        onPressed: () => game.adjustZoom(0.87),
                        icon: const Icon(
                          Icons.remove_rounded,
                          size: 18,
                          color: SolvilleTheme.timberDark,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 18,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        color: const Color(0x33795548),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: controller.togglePaintSweepMode,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: controller.paintSweepMode
                                ? const Color(0xFFFFD54F)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: controller.paintSweepMode
                                ? Border.all(
                                    color: const Color(0xFFE65100),
                                    width: 1.5,
                                  )
                                : null,
                          ),
                          child: Icon(
                            Icons.gesture_rounded,
                            size: 18,
                            color: controller.paintSweepMode
                                ? const Color(0xFFE65100)
                                : SolvilleTheme.timberDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Row 2: Contextual Seed Bag or Build Palette Strip
          if (showSeeds)
            _SeedSelectorStrip(controller: controller, onOpenShop: onOpenShop),
          if (showBuild) _BuildSelectorStrip(controller: controller),

          const SizedBox(height: 6),

          // Row 3: Main Tool Belt
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 780),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: SolvilleTheme.panelDecoration(radius: 22),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      _ToolSlotButton(
                        hotkey: '1',
                        showHotkey: !isMobile,
                        emoji: '🖐️',
                        label: l10n.toolSmart,
                        selected: state.activeTool == ToolMode.smart,
                        onTap: () => controller.selectTool(ToolMode.smart),
                      ),
                      _ToolSlotButton(
                        hotkey: '2',
                        showHotkey: !isMobile,
                        emoji: '🪏',
                        label: l10n.toolDig,
                        selected: state.activeTool == ToolMode.dig,
                        onTap: () => controller.selectTool(ToolMode.dig),
                      ),
                      _ToolSlotButton(
                        hotkey: '3',
                        showHotkey: !isMobile,
                        emoji: SolvilleCatalog.productEmoji(state.selectedSeed),
                        label: l10n.toolSeed,
                        selected: state.activeTool == ToolMode.seed,
                        onTap: () => controller.selectTool(ToolMode.seed),
                      ),
                      _ToolSlotButton(
                        hotkey: '4',
                        showHotkey: !isMobile,
                        emoji: '🪣',
                        label: l10n.toolWater,
                        selected: state.activeTool == ToolMode.water,
                        onTap: () => controller.selectTool(ToolMode.water),
                      ),
                      _ToolSlotButton(
                        hotkey: '5',
                        showHotkey: !isMobile,
                        emoji: '✨',
                        label: l10n.toolCompost,
                        subLabel: '${SolvilleCatalog.compostCost}☀️',
                        selected: state.activeTool == ToolMode.compost,
                        onTap: () => controller.selectTool(ToolMode.compost),
                      ),
                      _ToolSlotButton(
                        hotkey: '6',
                        showHotkey: !isMobile,
                        emoji: '🔨',
                        label: l10n.toolBuild,
                        selected: state.activeTool == ToolMode.build,
                        onTap: () => controller.selectTool(ToolMode.build),
                      ),
                      _ToolSlotButton(
                        hotkey: '7',
                        showHotkey: !isMobile,
                        emoji: '🌿',
                        label: l10n.toolRemove,
                        subLabel: l10n.toolRemoveSub,
                        selected: state.activeTool == ToolMode.remove,
                        onTap: () => controller.selectTool(ToolMode.remove),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeedSelectorStrip extends StatelessWidget {
  const _SeedSelectorStrip({
    required this.controller,
    required this.onOpenShop,
  });

  final SolvilleController controller;
  final VoidCallback onOpenShop;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = controller.state;
    final unlockedCrops = SolvilleCatalog.crops.values
        .where((c) => state.unlockedSeeds.contains(c.id))
        .toList();
    final hasLocked =
        unlockedCrops.length < SolvilleCatalog.crops.values.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: SolvilleTheme.panelDecoration(radius: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (final crop in unlockedCrops)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: ChoiceChip(
                  selected: state.selectedSeed == crop.id,
                  selectedColor: const Color(0xFFFFE082),
                  backgroundColor:
                      (crop.requiresSunPass && !controller.isSunPassActive)
                      ? const Color(0xFFFFF3E0)
                      : SolvilleTheme.parchment,
                  label: Text(
                    crop.requiresSunPass && !controller.isSunPassActive
                        ? l10n.dockSeedLockedLabel(
                            crop.emoji,
                            l10n.productShortName(crop.id),
                          )
                        : '${crop.emoji} ${l10n.productShortName(crop.id)} (${crop.seedCost}☀️)',
                    style: const TextStyle(
                      color: SolvilleTheme.timberDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  onSelected: (_) => controller.selectSeed(crop.id),
                ),
              ),
            if (hasLocked)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: ActionChip(
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
              ),
          ],
        ),
      ),
    );
  }
}

class _BuildSelectorStrip extends StatelessWidget {
  const _BuildSelectorStrip({required this.controller});

  final SolvilleController controller;

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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: SolvilleTheme.panelDecoration(radius: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (nextExp != null)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ActionChip(
                  backgroundColor:
                      (nextExp.requiresSunPass && !controller.isSunPassActive)
                      ? const Color(0xFFFFF3E0)
                      : (state.coins >= nextExp.cost
                            ? const Color(0xFFFFE082)
                            : const Color(0xFFFFF8E1)),
                  label: Text(
                    nextExp.requiresSunPass && !controller.isSunPassActive
                        ? l10n.dockExpandIsleLocked(state.gridSize, nextSize)
                        : l10n.dockExpandIsle(
                            state.gridSize,
                            nextSize,
                            nextExp.cost,
                          ),
                    style: const TextStyle(
                      color: SolvilleTheme.timberDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  onPressed: controller.expandIsle,
                ),
              ),
            for (final def in SolvilleCatalog.buildItems.values)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: ChoiceChip(
                  selected: state.selectedBuildItem == def.type,
                  selectedColor: const Color(0xFFB3E5FC),
                  backgroundColor:
                      (def.requiresSunPass && !controller.isSunPassActive)
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
                  onSelected: (_) => controller.selectBuildItem(def.type),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ToolSlotButton extends StatelessWidget {
  const _ToolSlotButton({
    required this.hotkey,
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
    this.showHotkey = true,
    this.subLabel,
  });

  final String hotkey;
  final String emoji;
  final String label;
  final String? subLabel;
  final bool selected;
  final bool showHotkey;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(0, selected ? -3.5 : 0, 0),
            constraints: const BoxConstraints(minWidth: 68, minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: selected
                  ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[Color(0xFFFFE082), Color(0xFFFFCA28)],
                    )
                  : null,
              color: selected ? null : SolvilleTheme.warmCream,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? const Color(0xFFE65100)
                    : const Color(0x55795548),
                width: selected ? 2.2 : 1.2,
              ),
              boxShadow: selected
                  ? const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x4DFFCA28),
                        blurRadius: 8,
                        offset: Offset(0, 3),
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
                    Text(emoji, style: const TextStyle(fontSize: 17)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subLabel != null ? '$label ($subLabel)' : label,
                  style: const TextStyle(
                    color: SolvilleTheme.timberDark,
                    fontSize: 11.5,
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
