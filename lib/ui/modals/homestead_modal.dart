import 'package:flutter/material.dart';

import '../../domain/models/catalog.dart';
import '../theme/solville_theme.dart';
import '../view_models/solville_controller.dart';
import '../widgets/solville_dialog_shell.dart';

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

        return SolvilleDialogShell(
          emoji: '🏡',
          title: 'Sunlit Homestead & Cozy Soundscape',
          maxWidth: 580,
          maxHeight: 580,
          shrinkWrap: true,
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            children: <Widget>[
              // 1. Soothing Background Soundscape Card
              Material(
                color: SolvilleTheme.warmCream,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: Color(0x44795548), width: 1.4),
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
                        style: TextStyle(fontSize: 12.5, color: Colors.black87),
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
                              onSelected: (_) => controller.setBgmTrack(track),
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
                              onChanged: controller.setBgmVolume,
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
                          label: 'Day ${state.day} • ${state.weather.label}',
                        ),
                        _JournalBadge(
                          label: '🏝️ ${state.gridSize}×${state.gridSize} Isle',
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
                          label: const Text('🌅 Rest Until Next Morning'),
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
