import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solville/data/services/cozy_sound_service.dart';
import 'package:solville/main.dart';
import 'package:solville/ui/view_models/solville_controller.dart';

/// Android phone form factors (logical dp) incl. compact landscape, each at
/// default and elevated (1.3x) system font scale.
const List<(String, Size, double)> _scenarios = <(String, Size, double)>[
  ('360x640 portrait 1.0x', Size(360, 640), 1.0),
  ('360x640 portrait 1.3x', Size(360, 640), 1.3),
  ('390x844 portrait 1.3x', Size(390, 844), 1.3),
  ('844x390 landscape 1.0x', Size(844, 390), 1.0),
  ('640x360 landscape 1.3x', Size(640, 360), 1.3),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  for (final (label, size, scale) in _scenarios) {
    testWidgets('HUD and every modal render without overflow: $label', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final controller = SolvilleController(
        soundService: CozySoundService(silentPlatformOutput: true),
      );
      await controller.initialize();
      await tester.pumpWidget(SolvilleApp(controller: controller));
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull, reason: 'HUD overflow');

      final openers = <String, VoidCallback?>{
        'market': controller.onRequestOpenMarketModal,
        'homestead': controller.onRequestOpenHomesteadModal,
        'sunpass': controller.onRequestOpenSunPassModal,
      };
      for (final entry in openers.entries) {
        expect(entry.value, isNotNull, reason: '${entry.key} hook missing');
        entry.value!();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(
          tester.takeException(),
          isNull,
          reason: '${entry.key} modal overflow at $label',
        );
        // Android back button closes the dialog route.
        await tester.binding.handlePopRoute();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byType(Dialog), findsNothing);
      }

      // Open Shop modal (always visible in TopStatusBar) and verify zero overflow
      await tester.tap(find.text('Shop'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        tester.takeException(),
        isNull,
        reason: 'shop modal overflow at $label',
      );
      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(Dialog), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      controller.dispose();
    });
  }
}
