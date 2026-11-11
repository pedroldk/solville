import 'package:flutter/material.dart';

import '../../domain/models/catalog.dart';
import '../../domain/models/grid_pos.dart';
import '../../domain/models/tile_state.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/solville_l10n_extensions.dart';
import '../theme/solville_theme.dart';
import '../view_models/solville_controller.dart';

/// Cozy contextual pill displaying real-time growth, moisture, flower synergy,
/// or artisan progress for the hovered (PC) or tapped (Android) garden tile.
class TileInspectorPill extends StatelessWidget {
  const TileInspectorPill({super.key, required this.controller});

  final SolvilleController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pos = controller.hoveredTile ?? controller.inspectedTile;
    if (pos == null || !controller.state.inBounds(pos)) {
      return const SizedBox.shrink();
    }

    final state = controller.state;
    final tile = state.tileAt(pos);
    final summary = _describeTile(l10n, pos, tile);
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
                    ? l10n.inspectorSunPassPaused(summary)
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
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE082),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: SolvilleTheme.timberBorder),
                  ),
                  child: Text(
                    l10n.inspectorUnlockBtn,
                    style: const TextStyle(
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
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: SolvilleTheme.timberBorder),
                  ),
                  child: Text(
                    l10n.inspectorUntillBtn,
                    style: const TextStyle(
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
                  padding: EdgeInsets.all(6),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
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

  String? _describeTile(AppLocalizations l10n, GridPos pos, TileState tile) {
    final state = controller.state;

    if (tile.droppedCrate != null) {
      final prod = tile.droppedCrate!;
      return l10n.inspectorCrateOnGround(
        SolvilleCatalog.productEmoji(prod),
        l10n.productName(prod),
      );
    }

    switch (tile.structure) {
      case StructureType.farmhouse:
        return l10n.inspectorFarmhouse;
      case StructureType.well:
        return l10n.inspectorWell(
          state.farmer.waterCharges,
          state.maxWaterCharges,
        );
      case StructureType.barn:
        return l10n.inspectorBarn(state.totalBarnCrates);
      case StructureType.marketStall:
        return l10n.inspectorMarketStall(state.market.stallCrates.length);
      case StructureType.lemonTree:
        final pct = (tile.producerProgress * 100).round();
        return tile.producerCrates > 0
            ? l10n.inspectorLemonReady(tile.producerCrates)
            : l10n.inspectorLemonRipening(pct);
      case StructureType.artisanPress:
        final pct = (tile.producerProgress * 100).round();
        if (tile.producerCrates > 0 && !tile.producerActive) {
          return l10n.inspectorKettleReady(tile.producerCrates);
        }
        if (tile.producerActive) {
          return l10n.inspectorKettleSimmering(pct, tile.producerCrates);
        }
        return l10n.inspectorKettleIdle;
      case StructureType.sprinklerRotary:
        return l10n.inspectorRotarySprinkler(
          tile.sprinklerCooldown.toStringAsFixed(1),
        );
      case StructureType.sprinklerSolar:
        return l10n.inspectorSolarSprinkler(
          tile.sprinklerCooldown.toStringAsFixed(1),
        );
      case StructureType.lantern:
        return l10n.inspectorLantern;
      case StructureType.flowerArch:
        if (tile.crop == null) {
          return l10n.inspectorFlowerArch;
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
      final animalName = l10n.animalName(animal.type);
      final pct = (animal.progress * 100).round();
      if (animal.readyCrates > 0) {
        return l10n.inspectorAnimalReady(
          def.emoji,
          animalName,
          animal.readyCrates,
          l10n.productName(def.product),
        );
      }
      if (animal.type == AnimalType.bee) {
        final bonusPct = (controller.beeFlowerBonusAt(pos) * 100).round();
        final bonus = bonusPct > 0 ? l10n.inspectorBeeSynergy(bonusPct) : '';
        return l10n.inspectorBeeProducing(def.emoji, animalName, pct, bonus);
      }
      final feedPct = (animal.feedLevel * 100).round();
      return animal.needsTending
          ? l10n.inspectorAnimalHungry(def.emoji, animalName, def.tendCost)
          : l10n.inspectorAnimalProducing(def.emoji, animalName, pct, feedPct);
    }

    if (tile.crop != null) {
      final crop = tile.crop!;
      final def = SolvilleCatalog.crops[crop.cropId]!;
      final cropName = l10n.productName(crop.cropId);
      final growthPct = (crop.growth * 100).round();
      final moistPct = (tile.moisture * 100).round();
      final compostTag = tile.fertilized ? l10n.inspectorCompostTag : '';
      if (crop.isRipe) {
        return l10n.inspectorCropRipe(
          def.emoji,
          cropName,
          crop.harvestsLeft,
          compostTag,
        );
      }
      final droopTag = crop.isDrooping ? l10n.inspectorCropThirsty : '';
      return l10n.inspectorCropGrowing(
        def.emoji,
        cropName,
        growthPct,
        moistPct,
        droopTag,
        crop.harvestsLeft,
        compostTag,
      );
    }

    if (tile.ground == GroundType.soil) {
      final moistPct = (tile.moisture * 100).round();
      final compostTag = tile.fertilized ? l10n.inspectorSoilComposted : '';
      return l10n.inspectorSoil(pos.x, pos.y, moistPct, compostTag);
    }

    if (tile.ground == GroundType.weeds) {
      return l10n.inspectorWeeds(pos.x, pos.y);
    }

    // Keep hovered empty grass/paths quiet unless explicitly tapped on mobile
    if (controller.hoveredTile != null) {
      return null;
    }

    if (tile.ground == GroundType.stonePath) {
      return l10n.inspectorStonePath(pos.x, pos.y);
    }

    return null;
  }
}
