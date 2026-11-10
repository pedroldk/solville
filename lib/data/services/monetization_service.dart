import 'dart:async';

import '../../domain/models/entitlement_state.dart';
import 'monetization_bridge_stub.dart'
    if (dart.library.io) 'monetization_bridge_io.dart';

/// Result of a rewarded video ad request or store purchase operation.
enum MonetizationResult {
  success,
  cancelled,
  unavailable;

  bool get isSuccess => this == MonetizationResult.success;
}

/// Service coordinating AdMob Rewarded Video Ads (+24h Sun Pass, stackable to 48h,
/// and Daily Sunny Surge) and In-App Purchases (`solville_sun_pass_yearly` at
/// 2,99€/year and `solville_lifetime_cozy` at 4,99€).
///
/// Automatically wires `google_mobile_ads` and `in_app_purchase` on Android/iOS
/// (when `!kFullEdition`), while remaining a safe zero-crash preview stub on
/// Windows/Desktop/Web and in unit tests.
class MonetizationService {
  MonetizationService({
    this.simulatedLatency = Duration.zero,
    this.enablePlatformSdk = true,
    this.onShowRewardedAd,
    this.onPurchaseProduct,
    this.onRestorePurchases,
  });

  /// Optional delay when simulating ad playback or store sheet in dev/preview.
  final Duration simulatedLatency;

  /// Set to `false` in headless tests to bypass native AdMob/Billing channels.
  final bool enablePlatformSdk;

  final Future<MonetizationResult> Function()? onShowRewardedAd;
  final Future<MonetizationResult> Function(String productId)?
  onPurchaseProduct;
  final Future<Set<String>> Function()? onRestorePurchases;

  final PlatformMonetizationBridge _bridge = PlatformMonetizationBridge();

  bool _isBusy = false;
  bool get isBusy => _isBusy;

  bool get isRewardedAdReady =>
      enablePlatformSdk ? _bridge.isRewardedAdReady : true;

  Future<void> initialize({
    void Function(String productId)? onOwnedProductRestored,
  }) async {
    if (!enablePlatformSdk) return;
    await _bridge.initialize(onOwnedProductRestored: onOwnedProductRestored);
  }

  /// Displays a full-screen opt-in rewarded ad and returns [MonetizationResult.success]
  /// only after the user finishes watching the ad.
  Future<MonetizationResult> showRewardedAd() async {
    if (_isBusy) return MonetizationResult.cancelled;
    _isBusy = true;
    try {
      if (onShowRewardedAd != null) {
        return await onShowRewardedAd!();
      }
      if (enablePlatformSdk && _bridge.isSupported) {
        return await _bridge.showRewardedAd();
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

  /// Initiates purchase of the 2,99€/year Sun Pass subscription.
  Future<MonetizationResult> purchaseAnnualPass() =>
      _purchaseProduct(EntitlementState.annualPassProductId);

  /// Initiates purchase of the 4,99€ one-time Lifetime Cozy Edition.
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

  /// Queries the store for previously purchased subscriptions or lifetime unlocks.
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
