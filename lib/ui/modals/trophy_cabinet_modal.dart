import 'package:flutter/material.dart';

import '../../domain/models/catalog.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/solville_l10n_extensions.dart';
import '../theme/solville_theme.dart';
import '../view_models/solville_controller.dart';
import '../widgets/solville_buttons.dart';
import '../widgets/solville_dialog_shell.dart';
import '../widgets/solville_icons.dart';

/// Displays all 12 Alice Greenfingers-inspired Milestone Trophies and Steam
/// Achievement synchronization status.
class TrophyCabinetModal extends StatelessWidget {
  const TrophyCabinetModal({super.key, required this.controller});

  final SolvilleController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final l10n = AppLocalizations.of(context);
        final unlocked = controller.state.unlockedTrophies;
        return SolvilleDialogShell(
          emoji: '🏆',
          leadingIcon: const SolvilleIcon(
            kind: SolvilleIconKind.trophy,
            size: 22,
          ),
          title: l10n.trophyCabinetTitle(
            unlocked.length,
            SolvilleCatalog.trophies.length,
          ),
          maxWidth: 660,
          maxHeight: 560,
          trailing: SolvilleBadge(
            label: controller.isSteamActive
                ? l10n.trophySteamSynced
                : l10n.trophyLocalCabinet,
            color: controller.isSteamActive
                ? const Color(0xFFE8F5E9)
                : SolvilleTheme.warmCream,
            borderColor: controller.isSteamActive
                ? const Color(0xFF43A047)
                : const Color(0x78795548),
            fontSize: 11.5,
          ),
          child: GridView.builder(
            padding: const EdgeInsets.all(14),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 310,
              mainAxisExtent: MediaQuery.textScalerOf(
                context,
              ).scale(128.0).clamp(124.0, 185.0),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: SolvilleCatalog.trophies.length,
            itemBuilder: (context, index) {
              final def = SolvilleCatalog.trophies[index];
              final isDone = unlocked.contains(def.id);
              return SolvilleMenuCard(
                padding: const EdgeInsets.all(10),
                color: isDone
                    ? const Color(0xFFFFF8E1)
                    : const Color(0xFFF6F2E9),
                borderColor: isDone ? null : const Color(0xFFB5A999),
                highlighted: isDone,
                radius: 15,
                child: Row(
                  children: <Widget>[
                    SolvilleIconMedallion(
                      size: 44,
                      highlighted: isDone,
                      backgroundColor: isDone
                          ? const Color(0xFFFFECB3)
                          : const Color(0xFFE8E2D6),
                      child: isDone
                          ? Text(
                              def.emoji,
                              style: const TextStyle(fontSize: 24),
                            )
                          : const SolvilleIcon(
                              kind: SolvilleIconKind.padlock,
                              size: 24,
                            ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            l10n.trophyTitle(def.id),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: isDone
                                  ? SolvilleTheme.timberDark
                                  : Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Flexible(
                            child: Text(
                              l10n.trophyDescription(def.id),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11.5),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isDone
                                ? l10n.trophyClaimed(def.rewardCoins)
                                : l10n.trophyReward(def.rewardCoins),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: isDone
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFFE65100),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
