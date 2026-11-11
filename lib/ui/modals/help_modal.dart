import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/solville_theme.dart';
import '../view_models/solville_controller.dart';
import '../widgets/solville_dialog_shell.dart';

/// Cozy player guide, Android + PC/Steam controls legend, and Save/New Game panel.
class HelpAndControlsModal extends StatelessWidget {
  const HelpAndControlsModal({super.key, required this.controller});

  final SolvilleController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SolvilleDialogShell(
      emoji: '🌻',
      title: l10n.helpTitle,
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
              label: Text(l10n.helpStartFresh),
            ),
            FilledButton.icon(
              onPressed: () async {
                await controller.saveNow();
                if (context.mounted) Navigator.of(context).pop();
              },
              icon: const Icon(Icons.save_rounded),
              label: Text(l10n.helpSaveNow),
            ),
          ],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
        children: <Widget>[
          _GuideSection(title: l10n.helpSec1Title, body: l10n.helpSec1Body),
          _GuideSection(title: l10n.helpSec2Title, body: l10n.helpSec2Body),
          _GuideSection(title: l10n.helpSec3Title, body: l10n.helpSec3Body),
          _GuideSection(title: l10n.helpSec4Title, body: l10n.helpSec4Body),
          _GuideSection(title: l10n.helpSec5Title, body: l10n.helpSec5Body),
          _GuideSection(title: l10n.helpSec6Title, body: l10n.helpSec6Body),
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
