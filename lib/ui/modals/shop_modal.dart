import 'package:flutter/material.dart';

import '../../domain/models/catalog.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/solville_l10n_extensions.dart';
import '../theme/solville_theme.dart';
import '../view_models/solville_controller.dart';
import '../widgets/solville_buttons.dart';
import '../widgets/solville_dialog_shell.dart';
import '../widgets/solville_icons.dart';

/// Town Shop modal offering Seed Licenses, Permanent Upgrades, and Placeable
/// Sprinklers / Animals / Garden Decor.
class ShopModal extends StatelessWidget {
  const ShopModal({super.key, required this.controller, this.initialTab = 0});

  final SolvilleController controller;
  final int initialTab;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final l10n = AppLocalizations.of(context);
        final state = controller.state;
        return DefaultTabController(
          initialIndex: initialTab.clamp(0, 2),
          length: 3,
          child: SolvilleDialogShell(
            emoji: '🛒',
            leadingIcon: const SolvilleIcon(
              kind: SolvilleIconKind.shopBasket,
              size: 22,
            ),
            title: l10n.shopTitle,
            maxWidth: 680,
            maxHeight: 560,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: SolvilleTheme.goldAccentDecoration(radius: 14),
              child: Text(
                '☀️ ${state.coins}',
                style: const TextStyle(
                  color: SolvilleTheme.timberDark,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ),
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                  child: SolvilleSegmentedTabs(
                    labels: <String>[
                      l10n.shopTabUpgrades,
                      l10n.shopTabSeeds,
                      l10n.shopTabBuild,
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: <Widget>[
                      _UpgradesTab(controller: controller),
                      _SeedsTab(controller: controller),
                      _BuildItemsTab(controller: controller),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _UpgradesTab extends StatelessWidget {
  const _UpgradesTab({required this.controller});

  final SolvilleController controller;

  String _statBadge(
    UpgradeTrack track,
    int nextTier,
    int currentGridSize,
  ) {
    return switch ((track, nextTier)) {
      (UpgradeTrack.wateringCan, 1) => '💧 5 → 10',
      (UpgradeTrack.wateringCan, _) => '💧 10 → 18',
      (UpgradeTrack.crateStacker, 1) => '📦 1 → 2',
      (UpgradeTrack.crateStacker, _) => '📦 2 → 4',
      (UpgradeTrack.gardenBoots, 1) => '👟 +28%',
      (UpgradeTrack.gardenBoots, _) => '👟 +55%',
      (UpgradeTrack.farmExpansion, final tier) =>
        '🏝️ $currentGridSize×$currentGridSize → ${SolvilleCatalog.gridSizeForExpansionTier(tier)}×${SolvilleCatalog.gridSizeForExpansionTier(tier)}',
    };
  }

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    return ListView(
      padding: const EdgeInsets.all(14),
      children: <Widget>[
        for (final track in UpgradeTrack.values)
          _buildUpgradeCard(
            context,
            track,
            state.upgradeTier(track),
            state.coins,
            isGlovesSpotlight:
                track == UpgradeTrack.crateStacker &&
                state.shouldSpotlightGloves,
          ),
      ],
    );
  }

  Widget _buildUpgradeCard(
    BuildContext context,
    UpgradeTrack track,
    int currentTier,
    int coins, {
    bool isGlovesSpotlight = false,
  }) {
    final l10n = AppLocalizations.of(context);
    final nextDef = SolvilleCatalog.nextUpgradeFor(track, currentTier);

    if (nextDef == null) {
      final maxGrid = SolvilleCatalog.gridSizeForExpansionTier(
        SolvilleCatalog.maxExpansionTier,
      );
      final maxedTitle = l10n.upgradeMaxedTitle(track, maxGrid);
      return SolvilleMenuCard(
        margin: const EdgeInsets.only(bottom: 10),
        color: const Color(0xFFFFFBF0),
        highlighted: true,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: <Widget>[
            const SolvilleIconMedallion(
              size: 42,
              radius: 13,
              highlighted: true,
              child: Text('🌟', style: TextStyle(fontSize: 23)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                maxedTitle,
                style: const TextStyle(
                  color: SolvilleTheme.timberDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SolvilleBadge(
              label: l10n.shopMaxBadge,
              color: const Color(0xFFE8F5E9),
              borderColor: const Color(0xFF43A047),
              textColor: const Color(0xFF1B5E20),
            ),
          ],
        ),
      );
    }

    final affordable = coins >= nextDef.cost;
    final lockedByPass = nextDef.requiresSunPass && !controller.isSunPassActive;
    final upgradeName = l10n.upgradeName(track, nextDef.tier);
    final statBadge = _statBadge(
      track,
      nextDef.tier,
      controller.state.gridSize,
    );

    return SolvilleMenuCard(
      margin: const EdgeInsets.only(bottom: 10),
      highlighted: isGlovesSpotlight || (affordable && !lockedByPass),
      color: isGlovesSpotlight
          ? const Color(0xFFFFF3C4)
          : (affordable && !lockedByPass
                ? const Color(0xFFFFFBF0)
                : SolvilleTheme.parchment),
      borderColor: isGlovesSpotlight ? const Color(0xFFE65100) : null,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: <Widget>[
          SolvilleIconMedallion(
            size: 46,
            radius: 13,
            highlighted: isGlovesSpotlight,
            backgroundColor: isGlovesSpotlight
                ? const Color(0xFFFFECB3)
                : SolvilleTheme.warmCream,
            child: Text(nextDef.emoji, style: const TextStyle(fontSize: 25)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    Text(
                      lockedByPass
                          ? l10n.shopItemSunPass(upgradeName)
                          : upgradeName,
                      style: const TextStyle(
                        color: SolvilleTheme.timberDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                      ),
                    ),
                    if (isGlovesSpotlight)
                      SolvilleBadge(
                        label: l10n.shopGlovesSpotlight,
                        color: const Color(0xFFFFCA28),
                        borderColor: const Color(0xFFE65100),
                        fontSize: 10.5,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: SolvilleTheme.recessedSlotDecoration(radius: 8),
                  child: Text(
                    statBadge,
                    style: const TextStyle(
                      color: SolvilleTheme.timberDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          lockedByPass
              ? SolvilleButton(
                  tone: SolvilleButtonTone.amber,
                  compact: true,
                  label: l10n.shopSunPassBadge,
                  onPressed: () {
                    Navigator.of(context).pop();
                    controller.openSunPassModal();
                  },
                )
              : SolvilleButton(
                  tone: SolvilleButtonTone.emerald,
                  label: l10n.shopBuyCost(nextDef.cost),
                  onPressed: affordable
                      ? () => controller.purchaseUpgrade(track)
                      : null,
                ),
        ],
      ),
    );
  }
}

class _SeedsTab extends StatelessWidget {
  const _SeedsTab({required this.controller});

  final SolvilleController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = controller.state;

    return LayoutBuilder(
      builder: (context, constraints) {
        final twoCol = constraints.maxWidth >= 460;
        final cardWidth = twoCol
            ? (constraints.maxWidth - 28 - 10) / 2
            : constraints.maxWidth - 28;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(14),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              for (final crop in SolvilleCatalog.crops.values)
                SizedBox(
                  width: cardWidth,
                  child: _SeedVisualCard(
                    crop: crop,
                    trialCount: state.trialSeeds[crop.id] ?? 0,
                    isUnlocked: state.unlockedSeeds.contains(crop.id),
                    isSunPassActive: controller.isSunPassActive,
                    coins: state.coins,
                    l10n: l10n,
                    onOpenSunPass: () {
                      Navigator.of(context).pop();
                      controller.openSunPassModal();
                    },
                    onEquip: () {
                      controller.selectSeed(crop.id);
                      Navigator.of(context).pop();
                    },
                    onUnlock: () => controller.unlockSeedLicense(crop.id),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SeedVisualCard extends StatelessWidget {
  const _SeedVisualCard({
    required this.crop,
    required this.trialCount,
    required this.isUnlocked,
    required this.isSunPassActive,
    required this.coins,
    required this.l10n,
    required this.onOpenSunPass,
    required this.onEquip,
    required this.onUnlock,
  });

  final CropDef crop;
  final int trialCount;
  final bool isUnlocked;
  final bool isSunPassActive;
  final int coins;
  final AppLocalizations l10n;
  final VoidCallback onOpenSunPass;
  final VoidCallback onEquip;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    final lockedByPass = crop.requiresSunPass && !isSunPassActive;
    return SolvilleMenuCard(
      color: lockedByPass ? const Color(0xFFFFF8E1) : SolvilleTheme.parchment,
      radius: 15,
      padding: const EdgeInsets.all(11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              SolvilleIconMedallion(
                size: 40,
                radius: 12,
                backgroundColor: lockedByPass
                    ? const Color(0xFFFFF0C4)
                    : SolvilleTheme.warmCream,
                child: Text(crop.emoji, style: const TextStyle(fontSize: 23)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.productName(crop.id),
                  style: const TextStyle(
                    color: SolvilleTheme.timberDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
              ),
              if (trialCount > 0)
                SolvilleBadge(
                  label: '🎁$trialCount',
                  color: const Color(0xFFE8F5E9),
                  borderColor: const Color(0xFF43A047),
                  textColor: const Color(0xFF2E7D32),
                  fontSize: 11,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  borderRadius: 8,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: <Widget>[
              _MiniStatPill('🌱 ${crop.seedCost}☀️'),
              _MiniStatPill('📦 ${crop.baseCrateValue}☀️'),
              _MiniStatPill('⏱ ${crop.growthSeconds.round()}s'),
              if (crop.maxHarvests > 1) _MiniStatPill('×${crop.maxHarvests}'),
              if (crop.id == ProductId.lavender) const _MiniStatPill('🐝 +35%'),
            ],
          ),
          const SizedBox(height: 9),
          if (lockedByPass && trialCount == 0)
            SolvilleButton(
              tone: SolvilleButtonTone.amber,
              compact: true,
              expand: true,
              label: l10n.shopSunPassBadge,
              onPressed: onOpenSunPass,
            )
          else if (isUnlocked || trialCount > 0)
            SolvilleButton(
              tone: SolvilleButtonTone.cream,
              compact: true,
              expand: true,
              label: l10n.shopEquipSeed,
              onPressed: onEquip,
            )
          else
            SolvilleButton(
              tone: SolvilleButtonTone.emerald,
              compact: true,
              expand: true,
              label: l10n.shopUnlockCost(crop.licenseCost),
              onPressed: coins >= crop.licenseCost ? onUnlock : null,
            ),
        ],
      ),
    );
  }
}

class _BuildItemsTab extends StatelessWidget {
  const _BuildItemsTab({required this.controller});

  final SolvilleController controller;

  String _capabilityBadge(BuildItemType type) => switch (type) {
    BuildItemType.sprinklerRotary => '💦 3×3',
    BuildItemType.sprinklerSolar => '💦 5×5',
    BuildItemType.lemonTree => '🍋 24s • 🌸+2%',
    BuildItemType.artisanPress => '🍯 3× Recipes',
    BuildItemType.henhouse => '🥚 16s',
    BuildItemType.beehive => '🍯 20s • 🌸',
    BuildItemType.cowPaddock => '🥛 22s',
    BuildItemType.stonePath => '👟 +40%',
    BuildItemType.lantern => '🌸 +3%',
    BuildItemType.flowerArch => '🌸 +6% • 🐝+20%',
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = controller.state;
    final expTier = state.upgradeTier(UpgradeTrack.farmExpansion);
    final nextExp = SolvilleCatalog.nextUpgradeFor(
      UpgradeTrack.farmExpansion,
      expTier,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final twoCol = constraints.maxWidth >= 460;
        final cardWidth = twoCol
            ? (constraints.maxWidth - 28 - 10) / 2
            : constraints.maxWidth - 28;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (nextExp != null)
                SolvilleMenuCard(
                  color: const Color(0xFFFFF8E1),
                  highlighted:
                      !nextExp.requiresSunPass && state.coins >= nextExp.cost,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: <Widget>[
                      SolvilleIconMedallion(
                        size: 44,
                        radius: 13,
                        highlighted: true,
                        child: Text(
                          nextExp.emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              l10n.shopCurrentIsleTitle(
                                l10n.upgradeName(
                                  UpgradeTrack.farmExpansion,
                                  nextExp.tier,
                                ),
                                state.gridSize,
                              ),
                              style: const TextStyle(
                                color: SolvilleTheme.timberDark,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            _MiniStatPill(
                              '🏝️ ${state.gridSize}×${state.gridSize} → ${SolvilleCatalog.gridSizeForExpansionTier(nextExp.tier)}×${SolvilleCatalog.gridSizeForExpansionTier(nextExp.tier)}',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      (nextExp.requiresSunPass && !controller.isSunPassActive)
                          ? SolvilleButton(
                              tone: SolvilleButtonTone.amber,
                              compact: true,
                              label: l10n.shopSunPassBadge,
                              onPressed: () {
                                Navigator.of(context).pop();
                                controller.openSunPassModal();
                              },
                            )
                          : SolvilleButton(
                              tone: SolvilleButtonTone.emerald,
                              label: l10n.shopExpandCost(nextExp.cost),
                              onPressed: state.coins >= nextExp.cost
                                  ? controller.expandIsle
                                  : null,
                            ),
                    ],
                  ),
                ),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  for (final item in SolvilleCatalog.buildItems.values)
                    SizedBox(
                      width: cardWidth,
                      child: SolvilleMenuCard(
                        color: (item.requiresSunPass &&
                                !controller.isSunPassActive)
                            ? const Color(0xFFFFF8E1)
                            : SolvilleTheme.parchment,
                        radius: 15,
                        padding: const EdgeInsets.all(11),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                SolvilleIconMedallion(
                                  size: 40,
                                  radius: 12,
                                  backgroundColor:
                                      (item.requiresSunPass &&
                                          !controller.isSunPassActive)
                                      ? const Color(0xFFFFF0C4)
                                      : SolvilleTheme.warmCream,
                                  child: Text(
                                    item.emoji,
                                    style: const TextStyle(fontSize: 23),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    l10n.buildItemName(item.type),
                                    style: const TextStyle(
                                      color: SolvilleTheme.timberDark,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: <Widget>[
                                _MiniStatPill('${item.cost}☀️'),
                                _MiniStatPill(_capabilityBadge(item.type)),
                              ],
                            ),
                            const SizedBox(height: 9),
                            (item.requiresSunPass &&
                                    !controller.isSunPassActive)
                                ? SolvilleButton(
                                    tone: SolvilleButtonTone.amber,
                                    compact: true,
                                    expand: true,
                                    label: l10n.shopSunPassBadge,
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      controller.openSunPassModal();
                                    },
                                  )
                                : SolvilleButton(
                                    tone: SolvilleButtonTone.primary,
                                    compact: true,
                                    expand: true,
                                    label: l10n.shopPlaceOnFarm,
                                    onPressed: state.coins >= item.cost
                                        ? () {
                                            controller.selectBuildItem(
                                              item.type,
                                            );
                                            Navigator.of(context).pop();
                                          }
                                        : null,
                                  ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MiniStatPill extends StatelessWidget {
  const _MiniStatPill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: SolvilleTheme.recessedSlotDecoration(
        radius: 8,
        color: const Color(0xFFF3E6CA),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: SolvilleTheme.timberDark,
          fontWeight: FontWeight.w800,
          fontSize: 11.5,
        ),
      ),
    );
  }
}
