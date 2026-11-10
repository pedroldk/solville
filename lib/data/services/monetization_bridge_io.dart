import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../domain/models/entitlement_state.dart';
import 'monetization_service.dart';

const String _envAndroidRewardedAdUnitId = String.fromEnvironment(
  'ADMOB_REWARDED_AD_UNIT_ID',
);
const String _envIosRewardedAdUnitId = String.fromEnvironment(
  'ADMOB_IOS_REWARDED_AD_UNIT_ID',
);

/// Mobile AdMob (`google_mobile_ads`) + Play Store / App Store (`in_app_purchase`)
/// bridge for Android and iOS, with automatic safe no-ops on desktop/Steam.
class PlatformMonetizationBridge {
  static const String _androidTestRewardedId =
      'ca-app-pub-3940256099942544/5224354917';
  static const String _androidProdRewardedId =
      'ca-app-pub-3113832650326844/3002351599';
  static const String _iosTestRewardedId =
      'ca-app-pub-3940256099942544/1712485313';

  bool get isSupported =>
      !kFullEdition && (Platform.isAndroid || Platform.isIOS);

  RewardedAd? _rewardedAd;
  bool _isLoadingAd = false;
  bool _mobileAdsInitialized = false;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  void Function(String productId)? _onOwnedProductRestored;

  Completer<MonetizationResult>? _pendingPurchaseCompleter;
  String? _pendingPurchaseProductId;
  final Set<String> _restoredProductIds = <String>{};

  bool get isRewardedAdReady =>
      isSupported ? _rewardedAd != null : !kFullEdition;

  String get _rewardedAdUnitId {
    if (Platform.isIOS) {
      if (!kDebugMode && _envIosRewardedAdUnitId.isNotEmpty) {
        return _envIosRewardedAdUnitId;
      }
      return _iosTestRewardedId;
    }
    if (kDebugMode) {
      return _androidTestRewardedId;
    }
    if (_envAndroidRewardedAdUnitId.isNotEmpty) {
      return _envAndroidRewardedAdUnitId;
    }
    return _androidProdRewardedId;
  }

  Future<void> initialize({
    void Function(String productId)? onOwnedProductRestored,
  }) async {
    _onOwnedProductRestored = onOwnedProductRestored;
    if (!isSupported) return;

    if (!_mobileAdsInitialized) {
      _mobileAdsInitialized = true;
      try {
        await MobileAds.instance.initialize();
        _preloadRewardedAd();
      } catch (_) {}
    }

    _purchaseSub ??= InAppPurchase.instance.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (_) {
        _completePendingPurchase(MonetizationResult.unavailable);
      },
    );
  }

  void _preloadRewardedAd() {
    if (!isSupported || _isLoadingAd || _rewardedAd != null) return;
    _isLoadingAd = true;
    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _isLoadingAd = false;
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (_) {
          _isLoadingAd = false;
          _rewardedAd = null;
        },
      ),
    );
  }

  Future<RewardedAd?> _loadRewardedAdOnDemand() {
    if (_rewardedAd != null) {
      final ad = _rewardedAd;
      _rewardedAd = null;
      return Future<RewardedAd?>.value(ad);
    }
    final completer = Completer<RewardedAd?>();
    _isLoadingAd = true;
    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _isLoadingAd = false;
          if (!completer.isCompleted) {
            completer.complete(ad);
          } else {
            ad.dispose();
          }
        },
        onAdFailedToLoad: (_) {
          _isLoadingAd = false;
          if (!completer.isCompleted) {
            completer.complete(null);
          }
        },
      ),
    );
    return completer.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () => null,
    );
  }

  Future<MonetizationResult> showRewardedAd() async {
    if (!isSupported) {
      return MonetizationResult.success;
    }

    final ad = await _loadRewardedAdOnDemand();
    if (ad == null) {
      _preloadRewardedAd();
      return MonetizationResult.unavailable;
    }

    final completer = Completer<MonetizationResult>();
    var earnedReward = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _preloadRewardedAd();
        if (!completer.isCompleted) {
          completer.complete(
            earnedReward
                ? MonetizationResult.success
                : MonetizationResult.cancelled,
          );
        }
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _preloadRewardedAd();
        if (!completer.isCompleted) {
          completer.complete(MonetizationResult.unavailable);
        }
      },
    );

    await ad.show(
      onUserEarnedReward: (_, _) {
        earnedReward = true;
      },
    );

    return completer.future;
  }

  Future<MonetizationResult> purchaseProduct(String productId) async {
    if (!isSupported) {
      return MonetizationResult.success;
    }

    try {
      final available = await InAppPurchase.instance.isAvailable();
      if (!available) return MonetizationResult.unavailable;

      final response = await InAppPurchase.instance.queryProductDetails(
        <String>{productId},
      );
      if (response.productDetails.isEmpty) {
        return MonetizationResult.unavailable;
      }

      final completer = Completer<MonetizationResult>();
      _pendingPurchaseCompleter = completer;
      _pendingPurchaseProductId = productId;

      final param = PurchaseParam(productDetails: response.productDetails.first);
      final started = await InAppPurchase.instance.buyNonConsumable(
        purchaseParam: param,
      );
      if (!started) {
        _completePendingPurchase(MonetizationResult.cancelled);
      }

      return completer.future.timeout(
        const Duration(minutes: 3),
        onTimeout: () {
          _completePendingPurchase(MonetizationResult.cancelled);
          return MonetizationResult.cancelled;
        },
      );
    } catch (_) {
      _completePendingPurchase(MonetizationResult.unavailable);
      return MonetizationResult.unavailable;
    }
  }

  Future<Set<String>> restorePurchases() async {
    if (!isSupported) {
      return const <String>{};
    }

    try {
      final available = await InAppPurchase.instance.isAvailable();
      if (!available) return const <String>{};
      _restoredProductIds.clear();
      await InAppPurchase.instance.restorePurchases();
      await Future<void>.delayed(const Duration(seconds: 2));
      return Set<String>.from(_restoredProductIds);
    } catch (_) {
      return const <String>{};
    }
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        _restoredProductIds.add(purchase.productID);
        _onOwnedProductRestored?.call(purchase.productID);
        if (purchase.pendingCompletePurchase) {
          try {
            await InAppPurchase.instance.completePurchase(purchase);
          } catch (_) {}
        }
        if (_pendingPurchaseProductId == purchase.productID) {
          _completePendingPurchase(MonetizationResult.success);
        }
      } else if (purchase.status == PurchaseStatus.canceled) {
        if (_pendingPurchaseProductId == purchase.productID) {
          _completePendingPurchase(MonetizationResult.cancelled);
        }
      } else if (purchase.status == PurchaseStatus.error) {
        if (_pendingPurchaseProductId == purchase.productID) {
          _completePendingPurchase(MonetizationResult.unavailable);
        }
      }
    }
  }

  void _completePendingPurchase(MonetizationResult result) {
    final completer = _pendingPurchaseCompleter;
    _pendingPurchaseCompleter = null;
    _pendingPurchaseProductId = null;
    if (completer != null && !completer.isCompleted) {
      completer.complete(result);
    }
  }

  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    unawaited(_purchaseSub?.cancel());
    _purchaseSub = null;
  }
}
