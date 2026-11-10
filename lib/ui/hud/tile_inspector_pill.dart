import 'package:flutter/material.dart';

import '../../domain/models/catalog.dart';
import '../../domain/models/grid_pos.dart';
import '../../domain/models/tile_state.dart';
import '../theme/solville_theme.dart';
import '../view_models/solville_controller.dart';

/// Cozy contextual pill displaying real-time growth, moisture, flower synergy,
/// or artisan progress for the hovered (PC) or tapped (Android) garden tile.
class TileInspectorPill extends StatelessWidget {
  const TileInspectorPill({super.key, required this.controller});

  final SolvilleController controller;

  @override
  Widget build(BuildContext context) {
    final pos = controller.hoveredTile ?? controller.inspectedTile;
    if (pos == null || !controller.state.inBounds(pos)) {
      return const SizedBox.shrink();
    }

    final state = controller.state;
    final tile = state.tileAt(pos);
    final summary = _describeTile(pos, tile);
    if (summary == null) {
      return const SizedBox.shrink();
    }

    final showDismiss =
        controller.hoveredTile == null && controller.inspectedTile != null;
    final canQuickUntill = showDismiss && pos.y > 0 && tile.canQuickUntill;
    final isSunPassPaused =
        tile.structure.requiresSunPass && !controller.isSunPassActive;

    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 16, right: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: SolvilleTheme.panelDecoration(
          color: const Color(0xECFFFDF7),
          radius: 16,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Flexible(
              child: Text(
                isSunPassPaused
                    ? '$summary • ☀️ Sun Pass Paused'
                    : summary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: SolvilleTheme.timberDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            if (isSunPassPaused) ...<Widget>[
              const SizedBox(width: 8),
              InkWell(
                onTap: controller.openSunPassModal,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE082),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: SolvilleTheme.timberBorder),
                  ),
                  child: const Text(
                    '☀️ Unlock',
                    style: TextStyle(
                      color: SolvilleTheme.timberDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
            if (canQuickUntill) ...<Widget>[
              const SizedBox(width: 8),
              InkWell(
                onTap: () => controller.untillTile(pos),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: SolvilleTheme.timberBorder),
                  ),
                  child: const Text(
                    '🌿 Untill',
                    style: TextStyle(
                      color: SolvilleTheme.timberDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
            if (showDismiss) ...<Widget>[
              const SizedBox(width: 6),
              InkWell(
                onTap: controller.clearInspectedTile,
                borderRadius: BorderRadius.circular(10),
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
          ],
        ),
      ),
    );
  }

  String? _describeTile(GridPos pos, TileState tile) {
    final state = controller.state;

    if (tile.droppedCrate != null) {
      final prod = tile.droppedCrate!;
      return '${SolvilleCatalog.productEmoji(prod)} ${SolvilleCatalog.productName(prod)} Crate on ground • Tap to pick up';
    }

    switch (tile.structure) {
      case StructureType.farmhouse:
        return '🏡 Sunlit Homestead • Tap for Soothing Soundscape & Farm Journal';
      case StructureType.well:
        return '🪨 Stone Well • Refills Watering Can (${state.farmer.waterCharges}/${state.maxWaterCharges})';
      case StructureType.barn:
        return '🏚️ Red Barn • ${state.totalBarnCrates} crates stored (Tap to store or open Market)';
      case StructureType.marketStall:
        return '🏪 Market Stall • ${state.market.stallCrates.length}/8 crates displayed';
      case StructureType.lemonTree:
        final pct = (tile.producerProgress * 100).round();
        return tile.producerCrates > 0
            ? '🍋 Sunburst Lemon Tree • ${tile.producerCrates}/2 crates ready! (+2% Charm)'
            : '🍋 Sunburst Lemon Tree • Ripening $pct% (+2% Charm)';
      case StructureType.artisanPress:
        final pct = (tile.producerProgress * 100).round();
        if (tile.producerCrates > 0 && !tile.producerActive) {
          return '🍯 Artisan Preserves Kettle • ${tile.producerCrates}/2 Gourmet Preserves ready!';
        }
        if (tile.producerActive) {
          return '🍯 Artisan Kettle • Simmering Preserves $pct% (${tile.producerCrates}/2 ready)';
        }
        return '🍯 Artisan Kettle • Idle (auto-pulls raw Barn produce or carry a crate here)';
      case StructureType.sprinklerRotary:
        return '💦 Rotary Sprinkler (3×3) • Next mist in ${tile.sprinklerCooldown.toStringAsFixed(1)}s';
      case StructureType.sprinklerSolar:
        return '⛲ Solar Mist Fountain (5×5) • Next mist in ${tile.sprinklerCooldown.toStringAsFixed(1)}s';
      case StructureType.lantern:
        return '🏮 Garden Lantern • +3% Townspeople Tip Charm';
      case StructureType.flowerArch:
        if (tile.crop == null) {
          return '🌸 Blooming Trellis Arch • +6% Tip Charm & +20% nearby Bee speed';
        }
      case StructureType.henhouse:
      case StructureType.beehive:
      case StructureType.cowPaddock:
      case StructureType.none:
        break;
    }

    if (tile.animal != null) {
      final animal = tile.animal!;
      final def = SolvilleCatalog.animals[animal.type]!;
      final pct = (animal.progress * 100).round();
      if (animal.readyCrates > 0) {
        return '${def.emoji} ${def.name} • ${animal.readyCrates} ${SolvilleCatalog.productName(def.product)} ready!';
      }
      if (animal.type == AnimalType.bee) {
        final bonusPct = (controller.beeFlowerBonusAt(pos) * 100).round();
        return '${def.emoji} ${def.name} • $pct% Honey${bonusPct > 0 ? ' (+$bonusPct% Flower Synergy!)' : ''}';
      }
      final feedPct = (animal.feedLevel * 100).round();
      return animal.needsTending
          ? '${def.emoji} ${def.name} • Hungry! Tap to feed (${def.tendCost}☀️)'
          : '${def.emoji} ${def.name} • $pct% • Feed $feedPct%';
    }

    if (tile.crop != null) {
      final crop = tile.crop!;
      final def = SolvilleCatalog.crops[crop.cropId]!;
      final growthPct = (crop.growth * 100).round();
      final moistPct = (tile.moisture * 100).round();
      final compostTag = tile.fertilized ? ' • ✨ +35% Compost' : '';
      if (crop.isRipe) {
        return '${def.emoji} ${def.name} • Ripe! Tap to harvest (${crop.harvestsLeft} left)$compostTag';
      }
      final droopTag = crop.isDrooping ? ' (Thirsty!)' : '';
      return '${def.emoji} ${def.name} • $growthPct% grown • 💧 $moistPct%$droopTag • ${crop.harvestsLeft}x harvest$compostTag';
    }

    if (tile.ground == GroundType.soil) {
      final moistPct = (tile.moisture * 100).round();
      final compostTag = tile.fertilized ? ' • ✨ Composted (+35%)' : '';
      return '🌱 Tilled Garden Bed (${pos.x}, ${pos.y}) • 💧 $moistPct%$compostTag • Tool 7 to untill to grass';
    }

    if (tile.ground == GroundType.weeds) {
      return '🌿 Wild Weeds (${pos.x}, ${pos.y}) • Tap 1–3× to clear, sow & water';
    }

    // Keep hovered empty grass/paths quiet unless explicitly tapped on mobile
    if (controller.hoveredTile != null) {
      return null;
    }

    if (tile.ground == GroundType.stonePath) {
      return '🧱 Sunstone Path (${pos.x}, ${pos.y}) • +40% faster walking';
    }

    return null;
  }
}
