import 'package:flutter/material.dart';

import '../../domain/models/catalog.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/solville_l10n_extensions.dart';
import '../theme/solville_theme.dart';
import '../view_models/solville_controller.dart';
import '../widgets/solville_dialog_shell.dart';

/// Town Shop modal offering Seed Licenses, Permanent Upgrades, and Placeable
/// Sprinklers / Animals / Garden Decor.
class ShopModal extends StatelessWidget {
  const ShopModal({super.key, required this.controller});

  final SolvilleController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final l10n = AppLocalizations.of(context);
        final state = controller.state;
        return DefaultTabController(
          length: 3,
          child: SolvilleDialogShell(
            emoji: '🛒',
            title: l10n.shopTitle,
            maxWidth: 680,
            maxHeight: 560,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: SolvilleTheme.sunAmberLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: SolvilleTheme.timberBorder),
              ),
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
                TabBar(
                  isScrollable: MediaQuery.sizeOf(context).width < 420,
                  tabAlignment: MediaQuery.sizeOf(context).width < 420
                      ? TabAlignment.center
                      : TabAlignment.fill,
                  labelColor: SolvilleTheme.timberDark,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w800),
                  tabs: <Widget>[
                    Tab(text: l10n.shopTabUpgrades),
                    Tab(text: l10n.shopTabSeeds),
                    Tab(text: l10n.shopTabBuild),
                  ],
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
      return Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: <Widget>[
              const Text('🌟', style: TextStyle(fontSize: 26)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  maxedTitle,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Chip(label: Text(l10n.shopMaxBadge)),
            ],
          ),
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

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: isGlovesSpotlight
          ? const Color(0xFFFFF3C4)
          : (affordable && !lockedByPass
                ? const Color(0xFFFFFBF0)
                : SolvilleTheme.parchment),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isGlovesSpotlight
              ? const Color(0xFFE65100)
              : (affordable && !lockedByPass
                    ? SolvilleTheme.sunGold
                    : SolvilleTheme.timberBorder.withValues(alpha: 0.45)),
          width: isGlovesSpotlight
              ? 2.4
              : (affordable && !lockedByPass ? 2.0 : 1.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: <Widget>[
            Text(nextDef.emoji, style: const TextStyle(fontSize: 28)),
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFCA28),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            l10n.shopGlovesSpotlight,
                            style: const TextStyle(
                              color: SolvilleTheme.timberDark,
                              fontWeight: FontWeight.w900,
                              fontSize: 10.5,
                            ),
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
                    decoration: BoxDecoration(
                      color: const Color(0x22795548),
                      borderRadius: BorderRadius.circular(8),
                    ),
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
                ? FilledButton.tonal(
                    onPressed: () {
                      Navigator.of(context).pop();
                      controller.openSunPassModal();
                    },
                    child: Text(l10n.shopSunPassBadge),
                  )
                : FilledButton(
                    onPressed: affordable
                        ? () => controller.purchaseUpgrade(track)
                        : null,
                    child: Text(l10n.shopBuyCost(nextDef.cost)),
                  ),
          ],
        ),
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
    return Card(
      margin: EdgeInsets.zero,
      color: lockedByPass ? const Color(0xFFFFF8E1) : SolvilleTheme.parchment,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: SolvilleTheme.timberBorder.withValues(alpha: 0.45),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(crop.emoji, style: const TextStyle(fontSize: 28)),
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '🎁$trialCount',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        color: Color(0xFF2E7D32),
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
                _MiniStatPill('🌱 ${crop.seedCost}☀️'),
                _MiniStatPill('📦 ${crop.baseCrateValue}☀️'),
                _MiniStatPill('⏱ ${crop.growthSeconds.round()}s'),
                if (crop.maxHarvests > 1) _MiniStatPill('×${crop.maxHarvests}'),
                if (crop.id == ProductId.lavender) const _MiniStatPill('🐝 +35%'),
              ],
            ),
            const SizedBox(height: 9),
            if (lockedByPass && trialCount == 0)
              FilledButton.tonal(
                onPressed: onOpenSunPass,
                child: Text(l10n.shopSunPassBadge),
              )
            else if (isUnlocked || trialCount > 0)
              OutlinedButton(
                onPressed: onEquip,
                child: Text(l10n.shopEquipSeed),
              )
            else
              FilledButton(
                onPressed: coins >= crop.licenseCost ? onUnlock : null,
                child: Text(l10n.shopUnlockCost(crop.licenseCost)),
              ),
          ],
        ),
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
                Card(
                  color: const Color(0xFFFFF8E1),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Row(
                      children: <Widget>[
                        Text(
                          nextExp.emoji,
                          style: const TextStyle(fontSize: 28),
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
                            ? FilledButton.tonal(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  controller.openSunPassModal();
                                },
                                child: Text(l10n.shopSunPassBadge),
                              )
                            : FilledButton(
                                onPressed: state.coins >= nextExp.cost
                                    ? controller.expandIsle
                                    : null,
                                child: Text(l10n.shopExpandCost(nextExp.cost)),
                              ),
                      ],
                    ),
                  ),
                ),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  for (final item in SolvilleCatalog.buildItems.values)
                    SizedBox(
                      width: cardWidth,
                      child: Card(
                        margin: EdgeInsets.zero,
                        color: (item.requiresSunPass &&
                                !controller.isSunPassActive)
                            ? const Color(0xFFFFF8E1)
                            : SolvilleTheme.parchment,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: SolvilleTheme.timberBorder.withValues(
                              alpha: 0.45,
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(11),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Text(
                                    item.emoji,
                                    style: const TextStyle(fontSize: 28),
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
                                  ? FilledButton.tonal(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        controller.openSunPassModal();
                                      },
                                      child: Text(l10n.shopSunPassBadge),
                                    )
                                  : FilledButton.tonal(
                                      onPressed: state.coins >= item.cost
                                          ? () {
                                              controller.selectBuildItem(
                                                item.type,
                                              );
                                              Navigator.of(context).pop();
                                            }
                                          : null,
                                      child: Text(l10n.shopPlaceOnFarm),
                                    ),
                            ],
                          ),
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
      decoration: BoxDecoration(
        color: const Color(0x18795548),
        borderRadius: BorderRadius.circular(8),
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
