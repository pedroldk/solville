import 'package:flutter/material.dart';

import '../../domain/models/catalog.dart';
import '../theme/solville_theme.dart';
import '../view_models/solville_controller.dart';
import '../widgets/solville_dialog_shell.dart';

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
        final unlocked = controller.state.unlockedTrophies;
        return SolvilleDialogShell(
          emoji: '🏆',
          title:
              'Trophy Cabinet (${unlocked.length}/${SolvilleCatalog.trophies.length})',
          maxWidth: 660,
          maxHeight: 560,
          trailing: Chip(
            backgroundColor: controller.isSteamActive
                ? const Color(0xFFE8F5E9)
                : SolvilleTheme.warmCream,
            label: Text(
              controller.isSteamActive ? '🎮 Steam Synced' : '💾 Local Cabinet',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          child: GridView.builder(
            padding: const EdgeInsets.all(14),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 310,
              mainAxisExtent: 124,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: SolvilleCatalog.trophies.length,
            itemBuilder: (context, index) {
              final def = SolvilleCatalog.trophies[index];
              final isDone = unlocked.contains(def.id);
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDone
                      ? const Color(0xFFFFF8E1)
                      : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDone
                        ? SolvilleTheme.sunGold
                        : const Color(0xFFBDBDBD),
                    width: isDone ? 2.0 : 1.2,
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Text(
                      isDone ? def.emoji : '🔒',
                      style: const TextStyle(fontSize: 28),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            def.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: isDone
                                  ? SolvilleTheme.timberDark
                                  : Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            def.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11.5),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isDone
                                ? '✓ Claimed +${def.rewardCoins}☀️'
                                : 'Reward: +${def.rewardCoins}☀️',
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
