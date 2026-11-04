import 'package:flutter/material.dart';

import '../../domain/models/catalog.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/grid_pos.dart';
import '../../domain/models/tile_state.dart';
import '../../game/solville_game.dart';
import '../theme/solville_theme.dart';
import '../view_models/solville_controller.dart';

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

  int _countReadyHarvests(GameState state) {
    var count = 0;
    for (var y = 1; y < state.gridSize; y++) {
      for (var x = 0; x < state.gridSize; x++) {
        final pos = GridPos(x, y);
        final tile = state.tileAt(pos);
        final ready =
            (tile.crop != null && tile.crop!.isRipe) ||
            (tile.animal != null && tile.animal!.readyCrates > 0) ||
            tile.producerCrates > 0 ||
            tile.droppedCrate != null;
        if (!ready) continue;
        if (state.actionQueue.any((a) => a.target == pos)) continue;
        count++;
      }
    }
    return count;
  }

  int _countThirstyPlots(GameState state) {
    var count = 0;
    for (var y = 1; y < state.gridSize; y++) {
      for (var x = 0; x < state.gridSize; x++) {
        final pos = GridPos(x, y);
        final tile = state.tileAt(pos);
        if (tile.ground != GroundType.soil ||
            tile.crop == null ||
            tile.crop!.isRipe ||
            tile.moisture >= 0.65) {
          continue;
        }
        final alreadyQueued = state.actionQueue.any(
          (a) => a.target == pos && a.kind == ActionKind.water,
        );
        if (alreadyQueued) continue;
        count++;
      }
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final showSeeds =
        state.activeTool == ToolMode.smart || state.activeTool == ToolMode.seed;
    final showBuild = state.activeTool == ToolMode.build;
    final readyHarvests = _countReadyHarvests(state);
    final thirstyPlots = _countThirstyPlots(state);

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
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
                          '⚡ ${state.actionQueue.length} Queued',
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
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFCDD2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              '✕ Clear',
                              style: TextStyle(
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
                  _QuickBatchButton(
                    emoji: '🌾',
                    label: 'Harvest Ripe ($readyHarvests)',
                    tooltip: 'Queue all ripe harvests & crates (Hotkey: H)',
                    background: const Color(0xFFE8F5E9),
                    onTap: controller.queueAllReadyHarvests,
                  ),
                if (thirstyPlots > 0)
                  _QuickBatchButton(
                    emoji: '💧',
                    label: 'Water Dry ($thirstyPlots)',
                    tooltip: 'Queue watering on thirsty garden beds',
                    background: const Color(0xFFE1F5FE),
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
                        tooltip: 'Center on Sol (Space / C)',
                        onPressed: game.centerCameraOnFarmer,
                        icon: const Icon(
                          Icons.my_location_rounded,
                          size: 18,
                          color: SolvilleTheme.timberDark,
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Zoom In',
                        onPressed: () => game.adjustZoom(1.15),
                        icon: const Icon(
                          Icons.add_rounded,
                          size: 18,
                          color: SolvilleTheme.timberDark,
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Zoom Out',
                        onPressed: () => game.adjustZoom(0.87),
                        icon: const Icon(
                          Icons.remove_rounded,
                          size: 18,
                          color: SolvilleTheme.timberDark,
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
                        emoji: '🖐️',
                        label: 'Smart',
                        selected: state.activeTool == ToolMode.smart,
                        onTap: () => controller.selectTool(ToolMode.smart),
                      ),
                      _ToolSlotButton(
                        hotkey: '2',
                        emoji: '🪏',
                        label: 'Dig',
                        selected: state.activeTool == ToolMode.dig,
                        onTap: () => controller.selectTool(ToolMode.dig),
                      ),
                      _ToolSlotButton(
                        hotkey: '3',
                        emoji: SolvilleCatalog.productEmoji(state.selectedSeed),
                        label: 'Seeds',
                        selected: state.activeTool == ToolMode.seed,
                        onTap: () => controller.selectTool(ToolMode.seed),
                      ),
                      _ToolSlotButton(
                        hotkey: '4',
                        emoji: '🪣',
                        label: 'Water',
                        selected: state.activeTool == ToolMode.water,
                        onTap: () => controller.selectTool(ToolMode.water),
                      ),
                      _ToolSlotButton(
                        hotkey: '5',
                        emoji: '✨',
                        label: 'Compost',
                        subLabel: '${SolvilleCatalog.compostCost}☀️',
                        selected: state.activeTool == ToolMode.compost,
                        onTap: () => controller.selectTool(ToolMode.compost),
                      ),
                      _ToolSlotButton(
                        hotkey: '6',
                        emoji: '🔨',
                        label: 'Build',
                        selected: state.activeTool == ToolMode.build,
                        onTap: () => controller.selectTool(ToolMode.build),
                      ),
                      _ToolSlotButton(
                        hotkey: '7',
                        emoji: '🧹',
                        label: 'Clear',
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

class _QuickBatchButton extends StatelessWidget {
  const _QuickBatchButton({
    required this.emoji,
    required this.label,
    required this.tooltip,
    required this.background,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final String tooltip;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: SolvilleTheme.timberBorder, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(emoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: const TextStyle(
                    color: SolvilleTheme.timberDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
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

class _SeedSelectorStrip extends StatelessWidget {
  const _SeedSelectorStrip({
    required this.controller,
    required this.onOpenShop,
  });

  final SolvilleController controller;
  final VoidCallback onOpenShop;

  @override
  Widget build(BuildContext context) {
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
                  backgroundColor: SolvilleTheme.parchment,
                  label: Text(
                    '${crop.emoji} ${crop.name.split(' ').last} (${crop.seedCost}☀️)',
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
                  label: const Text(
                    '+ Unlock Seeds',
                    style: TextStyle(
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
    final state = controller.state;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: SolvilleTheme.panelDecoration(radius: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (final def in SolvilleCatalog.buildItems.values)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: ChoiceChip(
                  selected: state.selectedBuildItem == def.type,
                  selectedColor: const Color(0xFFB3E5FC),
                  backgroundColor: SolvilleTheme.parchment,
                  label: Text(
                    '${def.emoji} ${def.name} (${def.cost}☀️)',
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
    this.subLabel,
  });

  final String hotkey;
  final String emoji;
  final String label;
  final String? subLabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Material(
        color: selected ? const Color(0xFFFFD54F) : SolvilleTheme.warmCream,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minWidth: 68),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? const Color(0xFFE65100)
                    : const Color(0x55795548),
                width: selected ? 2.2 : 1.2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      hotkey,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0x994E342E),
                      ),
                    ),
                    const SizedBox(width: 4),
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
