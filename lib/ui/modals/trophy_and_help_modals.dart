import 'package:flutter/material.dart';

import '../../domain/models/catalog.dart';
import '../theme/solville_theme.dart';
import '../view_models/solville_controller.dart';

/// Cozy Soundscape & Sunlit Homestead modal (opened from the top Audio button
/// or by tapping the Farmhouse in the 2.5D isometric diorama).
class HomesteadAndAudioModal extends StatelessWidget {
  const HomesteadAndAudioModal({super.key, required this.controller});

  final SolvilleController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final state = controller.state;
        final pctVol = (controller.bgmVolume * 100).round();

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580, maxHeight: 580),
            child: Container(
              decoration: SolvilleTheme.panelDecoration(
                color: SolvilleTheme.parchment,
                radius: 24,
              ),
              child: Material(
                type: MaterialType.transparency,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 12, 6),
                      child: Row(
                        children: <Widget>[
                          const Text('🏡', style: TextStyle(fontSize: 24)),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Sunlit Homestead & Cozy Soundscape',
                              style: TextStyle(
                                color: SolvilleTheme.timberDark,
                                fontSize: 18.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                        children: <Widget>[
                          // 1. Soothing Background Soundscape Card
                          Material(
                            color: SolvilleTheme.warmCream,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                              side: const BorderSide(
                                color: Color(0x44795548),
                                width: 1.4,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                              const Row(
                                children: <Widget>[
                                  Text('🎵', style: TextStyle(fontSize: 18)),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Soothing Background Soundscape',
                                      style: TextStyle(
                                        color: SolvilleTheme.timberDark,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Choose a gentle, seamlessly looping garden ambience (press M anytime on PC to cycle):',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: <Widget>[
                                  for (final track in BgmTrack.values)
                                    ChoiceChip(
                                      selected: controller.bgmTrack == track,
                                      selectedColor: const Color(0xFFFFE082),
                                      backgroundColor: SolvilleTheme.parchment,
                                      label: Text(
                                        track.label,
                                        style: const TextStyle(
                                          color: SolvilleTheme.timberDark,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                      onSelected: (_) {
                                        controller.setBgmTrack(track);
                                      },
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: <Widget>[
                                  const Icon(
                                    Icons.music_note_rounded,
                                    size: 18,
                                    color: SolvilleTheme.timberDark,
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Ambience Volume',
                                    style: TextStyle(
                                      color: SolvilleTheme.timberDark,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Expanded(
                                    child: Slider(
                                      value: controller.bgmVolume,
                                      min: 0.0,
                                      max: 1.0,
                                      activeColor: SolvilleTheme.terracotta,
                                      onChanged: (val) {
                                        controller.setBgmVolume(val);
                                      },
                                    ),
                                  ),
                                  SizedBox(
                                    width: 40,
                                    child: Text(
                                      '$pctVol%',
                                      textAlign: TextAlign.end,
                                      style: const TextStyle(
                                        color: SolvilleTheme.timberDark,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SwitchListTile.adaptive(
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                activeTrackColor: SolvilleTheme.meadowGreen,
                                title: const Text(
                                  '🔊 Tactile Garden Sound Effects (SFX)',
                                  style: TextStyle(
                                    color: SolvilleTheme.timberDark,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                                subtitle: const Text(
                                  'Gentle chimes when digging, watering, harvesting & earning Sols',
                                  style: TextStyle(fontSize: 11.5),
                                ),
                                value: controller.sfxEnabled,
                                onChanged: (_) => controller.toggleSfx(),
                              ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                        // 2. Homestead Farm Journal Summary
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: const Color(0x44795548),
                              width: 1.4,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Text(
                                '📖 Sol\'s Homestead Journal',
                                style: TextStyle(
                                  color: SolvilleTheme.timberDark,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 10,
                                runSpacing: 8,
                                children: <Widget>[
                                  _JournalBadge(
                                    label:
                                        'Day ${state.day} • ${state.weather.label}',
                                  ),
                                  _JournalBadge(
                                    label:
                                        '☀️ ${state.lifetimeCoinsEarned} Lifetime Sols',
                                  ),
                                  _JournalBadge(
                                    label:
                                        '📦 ${state.totalCratesHarvested} Crates Harvested',
                                  ),
                                  _JournalBadge(
                                    label:
                                        '🌸 +${(state.charmBonus * 100).round()}% Garden Charm',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 10,
                                runSpacing: 8,
                                alignment: WrapAlignment.end,
                                children: <Widget>[
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      controller.restToNextMorning();
                                      Navigator.of(context).pop();
                                    },
                                    icon: const Icon(Icons.wb_twilight_rounded),
                                    label: const Text(
                                      '🌅 Rest Until Next Morning',
                                    ),
                                  ),
                                  FilledButton.icon(
                                    onPressed: () async {
                                      await controller.saveNow();
                                      if (context.mounted) {
                                        Navigator.of(context).pop();
                                      }
                                    },
                                    icon: const Icon(Icons.save_rounded),
                                    label: const Text('Save Farm'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
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

class _JournalBadge extends StatelessWidget {
  const _JournalBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: SolvilleTheme.parchment,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x33795548)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: SolvilleTheme.timberDark,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

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
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 660, maxHeight: 560),
            child: Container(
              decoration: SolvilleTheme.panelDecoration(
                color: SolvilleTheme.parchment,
                radius: 24,
              ),
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
                    child: Row(
                      children: <Widget>[
                        const Text('🏆', style: TextStyle(fontSize: 24)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Trophy Cabinet (${unlocked.length}/${SolvilleCatalog.trophies.length})',
                            style: const TextStyle(
                              color: SolvilleTheme.timberDark,
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Chip(
                          backgroundColor: controller.isSteamActive
                              ? const Color(0xFFE8F5E9)
                              : SolvilleTheme.warmCream,
                          label: Text(
                            controller.isSteamActive
                                ? '🎮 Steam Synced'
                                : '💾 Local Cabinet',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(14),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
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
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Cozy player guide, Android + PC/Steam controls legend, and Save/New Game panel.
class HelpAndControlsModal extends StatelessWidget {
  const HelpAndControlsModal({super.key, required this.controller});

  final SolvilleController controller;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 560),
        child: Container(
          decoration: SolvilleTheme.panelDecoration(
            color: SolvilleTheme.parchment,
            radius: 24,
          ),
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 12, 6),
                child: Row(
                  children: <Widget>[
                    const Text('🌻', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'How to Play Solville & Controls',
                        style: TextStyle(
                          color: SolvilleTheme.timberDark,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
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
                      title: '🖥️ PC / Steam & 📱 Android Controls',
                      body:
                          '• Tap / Left-Click: Queue action (or tap Farmhouse/Stall to open menus)\n'
                          '• Shift + Drag (PC): Sweep across garden rows to batch-queue chores\n'
                          '• Right-Click (PC) or "✕ Clear": Cancel queued tasks\n'
                          '• Drag / WASD / Arrow Keys: Pan isometric diorama\n'
                          '• Pinch (Android) / Scroll Wheel (PC): Zoom camera\n'
                          '• Keys 1–7: Tools • H: Harvest All Ripe • M: Cycle Cozy Music • Space/C: Center',
                    ),
                  ],
                ),
              ),
              Padding(
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
            ],
          ),
        ),
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
