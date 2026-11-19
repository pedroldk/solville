import 'dart:async';

import '../../domain/models/entitlement_state.dart';
import 'monetization_bridge_stub.dart'
    if (dart.library.io) 'monetization_bridge_io.dart';

/// Result of a store purchase operation.
enum MonetizationResult {
  success,
  cancelled,
  unavailable;

  bool get isSuccess => this == MonetizationResult.success;
}

/// Service coordinating the one-time Full Game In-App Purchase
/// (`solville_lifetime_cozy`) and purchase restoration.
///
/// Automatically wires `in_app_purchase` on Android/iOS (when `!kFullEdition`),
/// while remaining a safe zero-crash preview stub on Windows/Desktop/Web and in
/// unit tests.
class MonetizationService {
  MonetizationService({
    this.simulatedLatency = Duration.zero,
    this.enablePlatformSdk = true,
    this.onPurchaseProduct,
    this.onRestorePurchases,
  });

  /// Optional delay when simulating the store sheet in dev/preview.
  final Duration simulatedLatency;

  /// Set to `false` in headless tests to bypass native Billing channels.
  final bool enablePlatformSdk;

  final Future<MonetizationResult> Function(String productId)?
  onPurchaseProduct;
  final Future<Set<String>> Function()? onRestorePurchases;

  final PlatformMonetizationBridge _bridge = PlatformMonetizationBridge();

  bool _isBusy = false;
  bool get isBusy => _isBusy;

  Future<void> initialize({
    void Function(String productId)? onOwnedProductRestored,
  }) async {
    if (!enablePlatformSdk) return;
    await _bridge.initialize(onOwnedProductRestored: onOwnedProductRestored);
  }

  /// Initiates purchase of the one-time Full Game unlock.
  Future<MonetizationResult> purchaseLifetimePass() =>
      _purchaseProduct(EntitlementState.lifetimePassProductId);

  Future<MonetizationResult> _purchaseProduct(String productId) async {
    if (_isBusy) return MonetizationResult.cancelled;
    _isBusy = true;
    try {
      if (onPurchaseProduct != null) {
        return await onPurchaseProduct!(productId);
      }
      if (enablePlatformSdk && _bridge.isSupported) {
        return await _bridge.purchaseProduct(productId);
      }
      if (simulatedLatency > Duration.zero) {
        await Future<void>.delayed(simulatedLatency);
      }
      return MonetizationResult.success;
    } catch (_) {
      return MonetizationResult.unavailable;
    } finally {
      _isBusy = false;
    }
  }

  /// Queries the store for previously purchased Full Game unlocks.
  Future<Set<String>> restorePurchases() async {
    if (_isBusy) return const <String>{};
    _isBusy = true;
    try {
      if (onRestorePurchases != null) {
        return await onRestorePurchases!();
      }
      if (enablePlatformSdk && _bridge.isSupported) {
        return await _bridge.restorePurchases();
      }
      if (simulatedLatency > Duration.zero) {
        await Future<void>.delayed(simulatedLatency);
      }
      return const <String>{};
    } catch (_) {
      return const <String>{};
    } finally {
      _isBusy = false;
    }
  }

  void dispose() {
    _bridge.dispose();
  }
}
