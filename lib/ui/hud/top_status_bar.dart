import 'package:flutter/material.dart';

import '../../domain/models/catalog.dart';
import '../theme/solville_theme.dart';
import '../view_models/solville_controller.dart';

/// Adaptive top HUD displaying Coins, Water charges, Stacked Crates, Day/Sun
/// progress, Hot Market Boom ticker, Soothing Soundscape selector, and modals.
class TopStatusBar extends StatelessWidget {
  const TopStatusBar({
    super.key,
    required this.controller,
    required this.onOpenShop,
    required this.onOpenMarket,
    required this.onOpenTrophies,
    required this.onOpenAudio,
    required this.onOpenHelp,
  });

  final SolvilleController controller;
  final VoidCallback onOpenShop;
  final VoidCallback onOpenMarket;
  final VoidCallback onOpenTrophies;
  final VoidCallback onOpenAudio;
  final VoidCallback onOpenHelp;

  String _bgmShortTitle(BgmTrack track, {required bool compact}) {
    if (compact) return 'Audio';
    return switch (track) {
      BgmTrack.sunnyLullaby => 'Lullaby',
      BgmTrack.morningMeadow => 'Meadow',
      BgmTrack.cozyRain => 'Cozy Rain',
      BgmTrack.off => 'Music Off',
    };
  }

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final booms = state.market.boomProducts;
    final boomEmojis = booms.map(SolvilleCatalog.productEmoji).join(' ');

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 820;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              // Left cluster: Sols, Water, Carried Crates, Day
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: SolvilleTheme.panelDecoration(radius: 22),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    _StatChip(
                      emoji: '☀️',
                      label: '${state.coins}',
                      tooltip: 'Sols (Solville Coins)',
                      highlight: const Color(0xFFFFF3C4),
                    ),
                    _StatChip(
                      emoji: '🪣',
                      label:
                          '${state.farmer.waterCharges}/${state.maxWaterCharges}',
                      tooltip: 'Watering Can charges (refill at Stone Well)',
                      highlight: const Color(0xFFE1F5FE),
                    ),
                    _StatChip(
                      emoji: '📦',
                      label:
                          '${state.farmer.carriedCrates.length}/${state.maxCarryCrates}',
                      tooltip:
                          'Carried Crates (deliver to Market Stall or Barn)',
                      highlight: const Color(0xFFFFECB3),
                    ),
                    _DayWeatherChip(
                      day: state.day,
                      progress: state.dayProgress,
                      weatherLabel: compact
                          ? state.weather.label.split(' ').first
                          : state.weather.label,
                      onNextMorning: controller.restToNextMorning,
                    ),
                  ],
                ),
              ),

              // Right cluster: Market Ticker, Shop, Trophies, Soothing Audio, Help
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: SolvilleTheme.panelDecoration(radius: 22),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    _HudActionButton(
                      emoji: '📈',
                      label: compact
                          ? 'Market $boomEmojis'
                          : 'Market 🔥 $boomEmojis (${state.market.stallCrates.length}/8)',
                      color: const Color(0xFFFFF8E1),
                      onTap: onOpenMarket,
                    ),
                    _HudActionButton(
                      emoji: '🛒',
                      label: 'Shop',
                      color: const Color(0xFFE8F5E9),
                      onTap: onOpenShop,
                    ),
                    _HudActionButton(
                      emoji: '🏆',
                      label:
                          '${state.unlockedTrophies.length}/${SolvilleCatalog.trophies.length}',
                      color: const Color(0xFFFFECB3),
                      onTap: onOpenTrophies,
                    ),
                    _HudActionButton(
                      emoji: controller.bgmTrack.shortEmoji,
                      label: _bgmShortTitle(
                        controller.bgmTrack,
                        compact: compact,
                      ),
                      color: const Color(0xFFE1F5FE),
                      onTap: onOpenAudio,
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: controller.sfxEnabled
                          ? 'Mute Garden SFX'
                          : 'Enable Garden SFX',
                      onPressed: controller.toggleSfx,
                      icon: Icon(
                        controller.sfxEnabled
                            ? Icons.volume_up_rounded
                            : Icons.volume_off_rounded,
                        color: SolvilleTheme.timberDark,
                        size: 20,
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'How to Play, Controls & Save',
                      onPressed: onOpenHelp,
                      icon: const Icon(
                        Icons.help_outline_rounded,
                        color: SolvilleTheme.timberDark,
                        size: 20,
                      ),
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

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.emoji,
    required this.label,
    required this.tooltip,
    required this.highlight,
  });

  final String emoji;
  final String label;
  final String tooltip;
  final Color highlight;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: highlight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x33795548)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(emoji, style: const TextStyle(fontSize: 15)),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: SolvilleTheme.timberDark,
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayWeatherChip extends StatelessWidget {
  const _DayWeatherChip({
    required this.day,
    required this.progress,
    required this.weatherLabel,
    required this.onNextMorning,
  });

  final int day;
  final double progress;
  final String weatherLabel;
  final VoidCallback onNextMorning;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            strokeWidth: 3,
            backgroundColor: const Color(0x33795548),
            valueColor: const AlwaysStoppedAnimation<Color>(
              SolvilleTheme.sunGold,
            ),
          ),
        ),
        const SizedBox(width: 7),
        Text(
          'Day $day • $weatherLabel',
          style: const TextStyle(
            color: SolvilleTheme.timberDark,
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
          ),
        ),
        const SizedBox(width: 6),
        Tooltip(
          message: 'Rest & start next morning with fresh Market Trends',
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onNextMorning,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE0B2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: SolvilleTheme.timberBorder),
              ),
              child: const Text(
                '🌅 Next Day',
                style: TextStyle(
                  color: SolvilleTheme.timberDark,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HudActionButton extends StatelessWidget {
  const _HudActionButton({
    required this.emoji,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: SolvilleTheme.timberBorder, width: 1.4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  color: SolvilleTheme.timberDark,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
