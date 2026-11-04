import 'package:flutter/material.dart';

import '../../domain/models/catalog.dart';
import '../theme/solville_theme.dart';
import '../view_models/solville_controller.dart';

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
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680, maxHeight: 560),
              child: Container(
                decoration: SolvilleTheme.panelDecoration(
                  color: SolvilleTheme.parchment,
                  radius: 24,
                ),
                child: Column(
                  children: <Widget>[
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 12, 6),
                      child: Row(
                        children: <Widget>[
                          const Text('🛒', style: TextStyle(fontSize: 24)),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Solville Town Shop',
                              style: TextStyle(
                                color: SolvilleTheme.timberDark,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: SolvilleTheme.sunAmberLight,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: SolvilleTheme.timberBorder,
                              ),
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
                          const SizedBox(width: 6),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),

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
          _buildUpgradeCard(context, track, state.upgradeTier(track), state.coins),
      ],
    );
  }

  Widget _buildUpgradeCard(
    BuildContext context,
    UpgradeTrack track,
    int currentTier,
    int coins,
  ) {
    UpgradeTierDef? nextDef;
    for (final u in SolvilleCatalog.upgrades) {
      if (u.track == track && u.tier == currentTier + 1) {
        nextDef = u;
        break;
      }
    }

    if (nextDef == null) {
      final maxedTitle = switch (track) {
        UpgradeTrack.wateringCan => 'Solar Mist Jug (Maxed)',
        UpgradeTrack.crateStacker => 'Master Stacker Harness (Maxed)',
        UpgradeTrack.gardenBoots => 'Sunrunner Boots (Maxed)',
        UpgradeTrack.farmExpansion => 'Grand Oasis Estate (Maxed)',
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
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Text(nextDef.emoji, style: const TextStyle(fontSize: 28)),
        title: Text(
          nextDef.name,
          style: const TextStyle(
            color: SolvilleTheme.timberDark,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(nextDef.description),
        trailing: FilledButton(
          onPressed: affordable ? () => controller.purchaseUpgrade(track) : null,
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
                '${crop.name} • Base Crate ${crop.baseCrateValue}☀️',
                style: const TextStyle(
                  color: SolvilleTheme.timberDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
              subtitle: Text(
                '${crop.description}\nPlanting cost: ${crop.seedCost}☀️ • Harvests: ${crop.maxHarvests}x',
              ),
              isThreeLine: true,
              trailing: state.unlockedSeeds.contains(crop.id)
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
                    ),
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
    return ListView(
      padding: const EdgeInsets.all(14),
      children: <Widget>[
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
                '${item.name} (${item.cost}☀️ each)',
                style: const TextStyle(
                  color: SolvilleTheme.timberDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
              subtitle: Text(item.description),
              trailing: FilledButton.tonal(
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
