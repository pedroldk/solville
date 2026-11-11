import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solville/data/services/cozy_sound_service.dart';
import 'package:solville/l10n/app_localizations.dart';
import 'package:solville/l10n/solville_l10n_extensions.dart';
import 'package:solville/main.dart';
import 'package:solville/ui/view_models/solville_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('SolvilleLocaleHelper resolution & serialization', () {
    test('resolves all 6 target locales accurately', () {
      expect(
        SolvilleLocaleHelper.resolveLocale(
          const Locale('en', 'US'),
          AppLocalizations.supportedLocales,
        ),
        equals(const Locale('en', 'US')),
      );
      expect(
        SolvilleLocaleHelper.resolveLocale(
          const Locale('en', 'GB'),
          AppLocalizations.supportedLocales,
        ),
        equals(const Locale('en', 'GB')),
      );
      expect(
        SolvilleLocaleHelper.resolveLocale(
          const Locale('pt', 'PT'),
          AppLocalizations.supportedLocales,
        ),
        equals(const Locale('pt', 'PT')),
      );
      expect(
        SolvilleLocaleHelper.resolveLocale(
          const Locale('pt'),
          AppLocalizations.supportedLocales,
        ),
        equals(const Locale('pt', 'PT')),
      );
      expect(
        SolvilleLocaleHelper.resolveLocale(
          const Locale('fr', 'FR'),
          AppLocalizations.supportedLocales,
        ),
        equals(const Locale('fr')),
      );
      expect(
        SolvilleLocaleHelper.resolveLocale(
          const Locale('es', 'ES'),
          AppLocalizations.supportedLocales,
        ),
        equals(const Locale('es')),
      );
      expect(
        SolvilleLocaleHelper.resolveLocale(
          const Locale('de', 'DE'),
          AppLocalizations.supportedLocales,
        ),
        equals(const Locale('de')),
      );
    });

    test('round-trips storage codes', () {
      for (final loc in SolvilleLocaleHelper.selectableLocales) {
        final code = SolvilleLocaleHelper.toStorageCode(loc);
        expect(SolvilleLocaleHelper.parseLocaleCode(code), equals(loc));
      }
      expect(SolvilleLocaleHelper.toStorageCode(null), isNull);
      expect(SolvilleLocaleHelper.parseLocaleCode(null), isNull);
    });
  });

  group('Multi-language UI & in-game switching', () {
    testWidgets(
      'switches between US English, British English, PT-PT, French, Spanish, and German and persists choice',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1280, 720);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final controller = SolvilleController(
          soundService: CozySoundService(silentPlatformOutput: true),
        );
        await controller.initialize();

        await tester.pumpWidget(SolvilleApp(controller: controller));
        await tester.pump(const Duration(milliseconds: 50));

        // 1. Default US English
        expect(find.text('Shop'), findsOneWidget);
        expect(find.text('Lullaby'), findsOneWidget);

        // Open Homestead modal and scroll to Language selector
        await tester.tap(find.text('Lullaby'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));
        await tester.drag(find.byType(ListView), const Offset(0, -600));
        await tester.pump(const Duration(milliseconds: 50));
        expect(find.text('🌐 Language'), findsOneWidget);

        // 2. Switch to British English (en_GB)
        await tester.ensureVisible(find.text('🇬🇧 English (UK)'));
        await tester.pump();
        await tester.tap(find.text('🇬🇧 English (UK)'));
        await tester.pump(const Duration(milliseconds: 50));
        expect(controller.appLocale, equals(const Locale('en', 'GB')));
        expect(find.text('Sunlit Homestead & Cosy Soundscape'), findsOneWidget);
        expect(find.text('Save Farm'), findsOneWidget);

        // 3. Switch to European Portuguese (pt_PT)
        await tester.ensureVisible(find.text('🇵🇹 Português (PT)'));
        await tester.pump();
        await tester.tap(find.text('🇵🇹 Português (PT)'));
        await tester.pump(const Duration(milliseconds: 50));
        expect(controller.appLocale, equals(const Locale('pt', 'PT')));
        expect(find.text('Casa da Quinta e Ambiente Sonoro'), findsOneWidget);
        expect(find.text('Guardar Quinta'), findsOneWidget);
        expect(find.text('Loja'), findsOneWidget);

        // 4. Switch to French (fr)
        await tester.ensureVisible(find.text('🇫🇷 Français'));
        await tester.pump();
        await tester.tap(find.text('🇫🇷 Français'));
        await tester.pump(const Duration(milliseconds: 50));
        expect(controller.appLocale, equals(const Locale('fr')));
        expect(find.text('Boutique'), findsOneWidget);
        expect(find.text('Sauvegarder'), findsOneWidget);

        // 5. Switch to Spanish (es)
        await tester.ensureVisible(find.text('🇪🇸 Español'));
        await tester.pump();
        await tester.tap(find.text('🇪🇸 Español'));
        await tester.pump(const Duration(milliseconds: 50));
        expect(controller.appLocale, equals(const Locale('es')));
        expect(find.text('Tienda'), findsOneWidget);
        expect(find.text('Guardar Granja'), findsOneWidget);

        // 6. Switch to German (de)
        await tester.ensureVisible(find.text('🇩🇪 Deutsch'));
        await tester.pump();
        await tester.tap(find.text('🇩🇪 Deutsch'));
        await tester.pump(const Duration(milliseconds: 50));
        expect(controller.appLocale, equals(const Locale('de')));
        expect(find.text('Laden'), findsOneWidget);
        expect(find.text('Hof speichern'), findsOneWidget);

        // Close modal and verify persistence across a fresh controller
        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        controller.dispose();

        final reloadedController = SolvilleController(
          soundService: CozySoundService(silentPlatformOutput: true),
        );
        await reloadedController.initialize();
        expect(reloadedController.appLocale, equals(const Locale('de')));

        await tester.pumpWidget(SolvilleApp(controller: reloadedController));
        await tester.pump(const Duration(milliseconds: 50));
        expect(find.text('Laden'), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        reloadedController.dispose();
      },
    );

    testWidgets(
      'renders HUD and modals cleanly without overflow on mobile in all 6 languages',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final expectations = <(Locale, String, String)>[
          (const Locale('en', 'US'), 'Shop', 'Solville Town Shop'),
          (const Locale('en', 'GB'), 'Shop', '🌱 Seed Licences'),
          (const Locale('pt', 'PT'), 'Loja', 'Loja da Aldeia de Solville'),
          (const Locale('fr'), 'Boutique', 'Boutique de Solville'),
          (const Locale('es'), 'Tienda', 'Tienda de Solville'),
          (const Locale('de'), 'Laden', 'Solville Dorfladen'),
        ];

        for (final (locale, shopBtn, shopDialogText) in expectations) {
          final controller = SolvilleController(
            soundService: CozySoundService(silentPlatformOutput: true),
          );
          await controller.initialize();
          await controller.setAppLocale(locale);

          await tester.pumpWidget(SolvilleApp(controller: controller));
          await tester.pump(const Duration(milliseconds: 50));

          expect(find.text(shopBtn), findsOneWidget);
          await tester.tap(find.text(shopBtn));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 250));
          expect(find.text(shopDialogText), findsOneWidget);

          await tester.tap(find.byIcon(Icons.close_rounded));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 250));

          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
          controller.dispose();
        }
      },
    );
  });
}
