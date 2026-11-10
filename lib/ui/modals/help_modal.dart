import 'package:flutter/material.dart';

import '../theme/solville_theme.dart';
import '../view_models/solville_controller.dart';
import '../widgets/solville_dialog_shell.dart';

/// Cozy player guide, Android + PC/Steam controls legend, and Save/New Game panel.
class HelpAndControlsModal extends StatelessWidget {
  const HelpAndControlsModal({super.key, required this.controller});

  final SolvilleController controller;

  @override
  Widget build(BuildContext context) {
    return SolvilleDialogShell(
      emoji: '🌻',
      title: 'How to Play Solville & Controls',
      maxWidth: 620,
      maxHeight: 560,
      footer: Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
        child: Wrap(
          spacing: 10,
          runSpacing: 8,
          alignment: WrapAlignment.end,
          children: <Widget>[
            OutlinedButton.icon(
              onPressed: () async {
                await controller.resetNewFarm();
                if (context.mounted) Navigator.of(context).pop();
              },
              icon: const Icon(Icons.restart_alt_rounded),
              label: const Text('Start Fresh Farm'),
            ),
            FilledButton.icon(
              onPressed: () async {
                await controller.saveNow();
                if (context.mounted) Navigator.of(context).pop();
              },
              icon: const Icon(Icons.save_rounded),
              label: const Text('Save Game Now'),
            ),
          ],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
        children: const <Widget>[
          _GuideSection(
            title: '⚡ Multi-Click / Multi-Tap Action Queue',
            body:
                'Inspired by Alice Greenfingers! In Smart mode (1), tap any grass plot 3 times in a row to queue Dig → Sow Seed → Water in one seamless combo! Sol detours to the Stone Well automatically when her watering can runs dry.',
          ),
          _GuideSection(
            title: '📦 Crates, Barn & Market Booms',
            body:
                'Harvest ripe crops or animal goods into wooden Crates, then tap the striped Market Stall to display them for passing townsfolk! Or store crates in the Red Barn and sell them when a 🔥 Market Boom (+45%) hits.',
          ),
          _GuideSection(
            title: '🍋 Lemon Orchards & Artisan Preserves',
            body:
                'Plant Sunburst Lemon Trees in Build mode (6) for carefree passive harvests + Garden Charm. Build an Artisan Preserves Kettle to simmer raw Barn produce (or hand-carried crates) into high-value Gourmet Preserves!',
          ),
          _GuideSection(
            title: '💦 Sprinklers & Bee Synergies',
            body:
                'Buy Rotary (3×3) and Solar Mist (5×5) Sprinklers to automate watering. Plant Fragrant Lavender or Blooming Trellis Arches near Wildflower Apiaries to boost Honey speed!',
          ),
          _GuideSection(
            title: '🏝️ Expanding Your Isle & Untilling Soil',
            body:
                'Your sunny 11×11 starter isle can be expanded all the way up to 35×35 with Sols via the Shop or the "🏝️ Expand Isle" button in Build mode (6)! Select Untill (7) to turn tilled soil, paths, or crops cleanly back into lush green grass.',
          ),
          _GuideSection(
            title: '🖥️ PC / Steam & 📱 Android Controls',
            body:
                '• Tap / Left-Click: Queue action (or tap Farmhouse/Stall to open menus)\n'
                '• Shift + Drag (PC): Sweep across garden rows to batch-queue chores or untill\n'
                '• Right-Click (PC) or "✕ Clear": Cancel queued tasks\n'
                '• Drag / WASD / Arrow Keys: Pan isometric diorama\n'
                '• Pinch (Android) / Scroll Wheel (PC): Zoom camera\n'
                '• Keys 1–7: Tools (7 = Untill to Grass) • H: Harvest Ripe • M: Cozy Music • Space/C: Center',
          ),
        ],
      ),
    );
  }
}

class _GuideSection extends StatelessWidget {
  const _GuideSection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              color: SolvilleTheme.timberDark,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(body, style: const TextStyle(fontSize: 13.5, height: 1.38)),
        ],
      ),
    );
  }
}
