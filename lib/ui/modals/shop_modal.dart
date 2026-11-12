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
          ),
      ],
    );
  }

  Widget _buildUpgradeCard(
    BuildContext context,
    UpgradeTrack track,
    int currentTier,
    int coins,
  ) {
    final l10n = AppLocalizations.of(context);
    final nextDef = SolvilleCatalog.nextUpgradeFor(track, currentTier);

    if (nextDef == null) {
      final maxGrid = SolvilleCatalog.gridSizeForExpansionTier(
        SolvilleCatalog.maxExpansionTier,
      );
      final maxedTitle = l10n.upgradeMaxedTitle(track, maxGrid);
      return Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          leading: const Text('🌟', style: TextStyle(fontSize: 26)),
          title: Text(
            maxedTitle,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(l10n.shopFullyUpgraded),
          trailing: Chip(label: Text(l10n.shopMaxBadge)),
        ),
      );
    }

    final affordable = coins >= nextDef.cost;
    final lockedByPass = nextDef.requiresSunPass && !controller.isSunPassActive;
    final upgradeName = l10n.upgradeName(track, nextDef.tier);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: affordable && !lockedByPass
          ? const Color(0xFFFFFBF0)
          : SolvilleTheme.parchment,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: affordable && !lockedByPass
              ? SolvilleTheme.sunGold
              : SolvilleTheme.timberBorder.withValues(alpha: 0.45),
          width: affordable && !lockedByPass ? 2.0 : 1.5,
        ),
      ),
      child: ListTile(
        leading: Text(nextDef.emoji, style: const TextStyle(fontSize: 28)),
        title: Text(
          lockedByPass ? l10n.shopItemSunPass(upgradeName) : upgradeName,
          style: const TextStyle(
            color: SolvilleTheme.timberDark,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(l10n.upgradeDescription(track, nextDef.tier)),
        trailing: lockedByPass
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
    return ListView(
      padding: const EdgeInsets.all(14),
      children: <Widget>[
        for (final crop in SolvilleCatalog.crops.values)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: Text(crop.emoji, style: const TextStyle(fontSize: 28)),
              title: Text(
                crop.requiresSunPass && !controller.isSunPassActive
                    ? l10n.shopSeedBaseCrateSunPass(
                        l10n.productName(crop.id),
                        crop.baseCrateValue,
                      )
                    : l10n.shopSeedBaseCrate(
                        l10n.productName(crop.id),
                        crop.baseCrateValue,
                      ),
                style: const TextStyle(
                  color: SolvilleTheme.timberDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
              subtitle: Text(
                l10n.shopSeedSubtitle(
                  l10n.cropDescription(crop.id),
                  crop.seedCost,
                  crop.maxHarvests,
                ),
              ),
              isThreeLine: true,
              trailing: (crop.requiresSunPass && !controller.isSunPassActive)
                  ? FilledButton.tonal(
                      onPressed: () {
                        Navigator.of(context).pop();
                        controller.openSunPassModal();
                      },
                      child: Text(l10n.shopSunPassBadge),
                    )
                  : (state.unlockedSeeds.contains(crop.id)
                        ? OutlinedButton(
                            onPressed: () {
                              controller.selectSeed(crop.id);
                              Navigator.of(context).pop();
                            },
                            child: Text(l10n.shopEquipSeed),
                          )
                        : FilledButton(
                            onPressed: state.coins >= crop.licenseCost
                                ? () => controller.unlockSeedLicense(crop.id)
                                : null,
                            child: Text(l10n.shopUnlockCost(crop.licenseCost)),
                          )),
            ),
          ),
      ],
    );
  }
}

class _BuildItemsTab extends StatelessWidget {
  const _BuildItemsTab({required this.controller});

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

    return ListView(
      padding: const EdgeInsets.all(14),
      children: <Widget>[
        if (nextExp != null)
          Card(
            color: const Color(0xFFFFF8E1),
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Text(
                nextExp.emoji,
                style: const TextStyle(fontSize: 28),
              ),
              title: Text(
                l10n.shopCurrentIsleTitle(
                  l10n.upgradeName(UpgradeTrack.farmExpansion, nextExp.tier),
                  state.gridSize,
                ),
                style: const TextStyle(
                  color: SolvilleTheme.timberDark,
                  fontWeight: FontWeight.w900,
                ),
              ),
              subtitle: Text(
                l10n.upgradeDescription(
                  UpgradeTrack.farmExpansion,
                  nextExp.tier,
                ),
              ),
              trailing: (nextExp.requiresSunPass && !controller.isSunPassActive)
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
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            l10n.shopBuildHint,
            style: const TextStyle(
              color: SolvilleTheme.timberDark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        for (final item in SolvilleCatalog.buildItems.values)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: Text(item.emoji, style: const TextStyle(fontSize: 28)),
              title: Text(
                item.requiresSunPass && !controller.isSunPassActive
                    ? l10n.shopBuildItemTitleSunPass(
                        l10n.buildItemName(item.type),
                        item.cost,
                      )
                    : l10n.shopBuildItemTitle(
                        l10n.buildItemName(item.type),
                        item.cost,
                      ),
                style: const TextStyle(
                  color: SolvilleTheme.timberDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
              subtitle: Text(l10n.buildItemDescription(item.type)),
              trailing: (item.requiresSunPass && !controller.isSunPassActive)
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
                              controller.selectBuildItem(item.type);
                              Navigator.of(context).pop();
                            }
                          : null,
                      child: Text(l10n.shopPlaceOnFarm),
                    ),
            ),
          ),
      ],
    );
  }
}
