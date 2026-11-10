import 'package:flutter/material.dart';

import '../../domain/models/catalog.dart';
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
        final state = controller.state;
        return DefaultTabController(
          length: 3,
          child: SolvilleDialogShell(
            emoji: '🛒',
            title: 'Solville Town Shop',
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
                const TabBar(
                  labelColor: SolvilleTheme.timberDark,
                  labelStyle: TextStyle(fontWeight: FontWeight.w800),
                  tabs: <Widget>[
                    Tab(text: '⬆️ Upgrades'),
                    Tab(text: '🌱 Seed Licenses'),
                    Tab(text: '🏡 Build & Animals'),
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
    final nextDef = SolvilleCatalog.nextUpgradeFor(track, currentTier);

    if (nextDef == null) {
      final maxGrid = SolvilleCatalog.gridSizeForExpansionTier(
        SolvilleCatalog.maxExpansionTier,
      );
      final maxedTitle = switch (track) {
        UpgradeTrack.wateringCan => 'Solar Mist Jug (Maxed)',
        UpgradeTrack.crateStacker => 'Master Stacker Harness (Maxed)',
        UpgradeTrack.gardenBoots => 'Sunrunner Boots (Maxed)',
        UpgradeTrack.farmExpansion =>
          'Grand Archipelago Estate ($maxGrid×$maxGrid Maxed)',
      };
      return Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          leading: const Text('🌟', style: TextStyle(fontSize: 26)),
          title: Text(
            maxedTitle,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: const Text('Fully upgraded!'),
          trailing: const Chip(label: Text('MAX')),
        ),
      );
    }

    final affordable = coins >= nextDef.cost;
    final lockedByPass = nextDef.requiresSunPass && !controller.isSunPassActive;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Text(nextDef.emoji, style: const TextStyle(fontSize: 28)),
        title: Text(
          lockedByPass ? '${nextDef.name} • ☀️ Sun Pass' : nextDef.name,
          style: const TextStyle(
            color: SolvilleTheme.timberDark,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(nextDef.description),
        trailing: lockedByPass
            ? FilledButton.tonal(
                onPressed: () {
                  Navigator.of(context).pop();
                  controller.openSunPassModal();
                },
                child: const Text('☀️ Sun Pass'),
              )
            : FilledButton(
                onPressed: affordable
                    ? () => controller.purchaseUpgrade(track)
                    : null,
                child: Text('Buy ${nextDef.cost}☀️'),
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
                    ? '${crop.name} • Base Crate ${crop.baseCrateValue}☀️ • ☀️ Sun Pass'
                    : '${crop.name} • Base Crate ${crop.baseCrateValue}☀️',
                style: const TextStyle(
                  color: SolvilleTheme.timberDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
              subtitle: Text(
                '${crop.description}\nPlanting cost: ${crop.seedCost}☀️ • Harvests: ${crop.maxHarvests}x',
              ),
              isThreeLine: true,
              trailing: (crop.requiresSunPass && !controller.isSunPassActive)
                  ? FilledButton.tonal(
                      onPressed: () {
                        Navigator.of(context).pop();
                        controller.openSunPassModal();
                      },
                      child: const Text('☀️ Sun Pass'),
                    )
                  : (state.unlockedSeeds.contains(crop.id)
                        ? OutlinedButton(
                            onPressed: () {
                              controller.selectSeed(crop.id);
                              Navigator.of(context).pop();
                            },
                            child: const Text('Equip Seed'),
                          )
                        : FilledButton(
                            onPressed: state.coins >= crop.licenseCost
                                ? () => controller.unlockSeedLicense(crop.id)
                                : null,
                            child: Text('Unlock ${crop.licenseCost}☀️'),
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
                '${nextExp.name} (Current Isle: ${state.gridSize}×${state.gridSize})',
                style: const TextStyle(
                  color: SolvilleTheme.timberDark,
                  fontWeight: FontWeight.w900,
                ),
              ),
              subtitle: Text(nextExp.description),
              trailing: (nextExp.requiresSunPass && !controller.isSunPassActive)
                  ? FilledButton.tonal(
                      onPressed: () {
                        Navigator.of(context).pop();
                        controller.openSunPassModal();
                      },
                      child: const Text('☀️ Sun Pass'),
                    )
                  : FilledButton(
                      onPressed: state.coins >= nextExp.cost
                          ? controller.expandIsle
                          : null,
                      child: Text('Expand ${nextExp.cost}☀️'),
                    ),
            ),
          ),
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            'Select an item below, then tap any open grass tile on your farm to place it!',
            style: TextStyle(
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
                    ? '${item.name} (${item.cost}☀️ each • ☀️ Sun Pass)'
                    : '${item.name} (${item.cost}☀️ each)',
                style: const TextStyle(
                  color: SolvilleTheme.timberDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
              subtitle: Text(item.description),
              trailing: (item.requiresSunPass && !controller.isSunPassActive)
                  ? FilledButton.tonal(
                      onPressed: () {
                        Navigator.of(context).pop();
                        controller.openSunPassModal();
                      },
                      child: const Text('☀️ Sun Pass'),
                    )
                  : FilledButton.tonal(
                      onPressed: state.coins >= item.cost
                          ? () {
                              controller.selectBuildItem(item.type);
                              Navigator.of(context).pop();
                            }
                          : null,
                      child: const Text('Place on Farm'),
                    ),
            ),
          ),
      ],
    );
  }
}
