import '../../domain/models/entitlement_state.dart';
import 'monetization_service.dart';

/// Stub monetization bridge for Web / non-IO platforms where AdMob and native
/// mobile store billing are unavailable.
class PlatformMonetizationBridge {
  bool get isSupported => false;
  bool get isRewardedAdReady => !kFullEdition;

  Future<void> initialize({
    void Function(String productId)? onOwnedProductRestored,
  }) async {}

  Future<MonetizationResult> showRewardedAd() async =>
      MonetizationResult.success;

  Future<MonetizationResult> purchaseProduct(String productId) async =>
      MonetizationResult.success;

  Future<Set<String>> restorePurchases() async => const <String>{};

  void dispose() {}
}
