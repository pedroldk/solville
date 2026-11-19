import 'package:flutter/material.dart';

import '../../domain/models/catalog.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/solville_l10n_extensions.dart';
import '../theme/solville_theme.dart';
import '../view_models/solville_controller.dart';
import '../widgets/solville_buttons.dart';
import '../widgets/solville_dialog_shell.dart';
import '../widgets/solville_icons.dart';

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
        final l10n = AppLocalizations.of(context);
        final isMobile = MediaQuery.sizeOf(context).shortestSide < 600;
        final state = controller.state;
        final pctVol = (controller.bgmVolume * 100).round();

        return SolvilleDialogShell(
          emoji: '🏡',
          leadingIcon: const SolvilleIcon(
            kind: SolvilleIconKind.farmhouse,
            size: 22,
          ),
          title: l10n.homesteadTitle,
          maxWidth: 580,
          maxHeight: 620,
          shrinkWrap: true,
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            children: <Widget>[
              // 1. Soothing Background Soundscape Card
              SolvilleMenuCard(
                color: SolvilleTheme.warmCream,
                radius: 18,
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const SolvilleIconMedallion(
                          size: 32,
                          child: SolvilleIcon(
                            kind: SolvilleIconKind.musicLullaby,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.homesteadSoundscapeHeading,
                            style: const TextStyle(
                              color: SolvilleTheme.timberDark,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.adaptiveSoundscapeSubtitle(isMobile: isMobile),
                      style: const TextStyle(
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
                          SolvilleChip(
                            selected: controller.bgmTrack == track,
                            label: l10n.bgmTrackLabel(track),
                            fontSize: 12.5,
                            onTap: () => controller.setBgmTrack(track),
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
                        Flexible(
                          child: Text(
                            l10n.homesteadAmbienceVolume,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: SolvilleTheme.timberDark,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
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
                        ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 42),
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
                      title: Text(
                        l10n.homesteadSfxTitle,
                        style: const TextStyle(
                          color: SolvilleTheme.timberDark,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: Text(
                        l10n.homesteadSfxSubtitle,
                        style: const TextStyle(fontSize: 11.5),
                      ),
                      value: controller.sfxEnabled,
                      onChanged: (_) => controller.toggleSfx(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 2. Homestead Farm Journal Summary
              SolvilleMenuCard(
                color: const Color(0xFFFFF8E1),
                radius: 18,
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l10n.homesteadJournalHeading,
                      style: const TextStyle(
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
                          label: l10n.homesteadJournalDay(
                            state.day,
                            l10n.weatherLabel(state.weather),
                          ),
                        ),
                        _JournalBadge(
                          label: l10n.homesteadJournalIsle(state.gridSize),
                        ),
                        _JournalBadge(
                          label: l10n.homesteadJournalCoins(
                            state.lifetimeCoinsEarned,
                          ),
                        ),
                        _JournalBadge(
                          label: l10n.homesteadJournalCrates(
                            state.totalCratesHarvested,
                          ),
                        ),
                        _JournalBadge(
                          label: l10n.homesteadJournalCharm(
                            (state.charmBonus * 100).round(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: SolvilleButton(
                        tone: SolvilleButtonTone.emerald,
                        icon: Icons.save_rounded,
                        label: l10n.homesteadSaveFarm,
                        onPressed: () async {
                          await controller.saveNow();
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 3. Language Selector Card
              SolvilleMenuCard(
                color: SolvilleTheme.warmCream,
                radius: 18,
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l10n.homesteadLanguageHeading,
                      style: const TextStyle(
                        color: SolvilleTheme.timberDark,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.homesteadLanguageSubtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        SolvilleChip(
                          selected: controller.appLocale == null,
                          label: l10n.languageSystem,
                          fontSize: 12,
                          onTap: () => controller.setAppLocale(null),
                        ),
                        for (final loc in SolvilleLocaleHelper.selectableLocales)
                          SolvilleChip(
                            selected: controller.appLocale == loc,
                            label: _localeLabel(l10n, loc),
                            fontSize: 12,
                            onTap: () => controller.setAppLocale(loc),
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

  String _localeLabel(AppLocalizations l10n, Locale locale) {
    return switch ((locale.languageCode, locale.countryCode)) {
      ('en', 'GB') => l10n.languageEnGb,
      ('en', _) => l10n.languageEnUs,
      ('pt', _) => l10n.languagePtPt,
      ('fr', _) => l10n.languageFr,
      ('es', _) => l10n.languageEs,
      ('de', _) => l10n.languageDe,
      _ => locale.toLanguageTag(),
    };
  }
}

class _JournalBadge extends StatelessWidget {
  const _JournalBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: SolvilleTheme.recessedSlotDecoration(
        radius: 11,
        color: SolvilleTheme.parchment,
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
