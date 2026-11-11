import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'l10n/app_localizations.dart';
import 'l10n/solville_l10n_extensions.dart';
import 'ui/theme/solville_theme.dart';
import 'ui/view_models/solville_controller.dart';
import 'ui/views/solville_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable edge-to-edge immersive mode on Android while remaining adaptive
  // across portrait, landscape, foldables, and resizable desktop windows.
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  final controller = SolvilleController();
  unawaited(controller.initialize());

  runApp(SolvilleApp(controller: controller));
}

class SolvilleApp extends StatelessWidget {
  const SolvilleApp({super.key, required this.controller});

  final SolvilleController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      child: SolvilleScreen(controller: controller),
      builder: (context, child) {
        return MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          debugShowCheckedModeBanner: false,
          theme: SolvilleTheme.buildTheme(),
          locale: controller.appLocale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          localeResolutionCallback: SolvilleLocaleHelper.resolveLocale,
          home: child,
        );
      },
    );
  }
}
