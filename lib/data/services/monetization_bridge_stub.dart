import 'monetization_service.dart';

/// Stub monetization bridge for Web / non-IO platforms where native mobile
/// store billing is unavailable.
class PlatformMonetizationBridge {
  bool get isSupported => false;

  Future<void> initialize({
    void Function(String productId)? onOwnedProductRestored,
  }) async {}

  Future<MonetizationResult> purchaseProduct(String productId) async =>
      MonetizationResult.success;

  Future<Set<String>> restorePurchases() async => const <String>{};

  void dispose() {}
}
