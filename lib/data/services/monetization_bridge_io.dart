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
  bool _disposed = false;
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
    if (!isSupported || _disposed) return;

    if (!_mobileAdsInitialized) {
      _mobileAdsInitialized = true;
      try {
        await MobileAds.instance.initialize().timeout(
          const Duration(seconds: 8),
        );
        _preloadRewardedAd();
      } catch (_) {}
    }

    if (_purchaseSub == null) {
      try {
        _purchaseSub = InAppPurchase.instance.purchaseStream.listen(
          _handlePurchaseUpdates,
          onError: (_) {
            _completePendingPurchase(MonetizationResult.unavailable);
          },
        );
        // On Android, Play Billing queries local Play Store cache silently
        // without prompting a sign-in dialog, restoring entitlements after reinstall.
        if (Platform.isAndroid) {
          unawaited(_silentRestoreOnAndroid());
        }
      } catch (_) {}
    }
  }

  Future<void> _silentRestoreOnAndroid() async {
    try {
      final available = await InAppPurchase.instance.isAvailable().timeout(
        const Duration(seconds: 6),
        onTimeout: () => false,
      );
      if (!available || _disposed) return;
      await InAppPurchase.instance.restorePurchases().timeout(
        const Duration(seconds: 6),
      );
    } catch (_) {}
  }

  void _preloadRewardedAd() {
    if (!isSupported || _disposed || _isLoadingAd || _rewardedAd != null) {
      return;
    }
    _isLoadingAd = true;
    try {
      RewardedAd.load(
        adUnitId: _rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _isLoadingAd = false;
            if (_disposed) {
              ad.dispose();
              return;
            }
            if (_rewardedAd != null) {
              ad.dispose();
              return;
            }
            _rewardedAd = ad;
          },
          onAdFailedToLoad: (_) {
            _isLoadingAd = false;
            _rewardedAd = null;
          },
        ),
      );
    } catch (_) {
      _isLoadingAd = false;
    }
  }

  Future<RewardedAd?> _loadRewardedAdOnDemand() {
    if (_rewardedAd != null) {
      final ad = _rewardedAd;
      _rewardedAd = null;
      return Future<RewardedAd?>.value(ad);
    }
    final completer = Completer<RewardedAd?>();
    _isLoadingAd = true;
    try {
      RewardedAd.load(
        adUnitId: _rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _isLoadingAd = false;
            if (_disposed) {
              ad.dispose();
              if (!completer.isCompleted) completer.complete(null);
              return;
            }
            if (!completer.isCompleted) {
              completer.complete(ad);
            } else if (_rewardedAd == null) {
              // Cache late-arriving ad for the next request instead of wasting it.
              _rewardedAd = ad;
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
    } catch (_) {
      _isLoadingAd = false;
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    }
    return completer.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () {
        _isLoadingAd = false;
        return null;
      },
    );
  }

  Future<MonetizationResult> showRewardedAd() async {
    if (!isSupported) {
      return MonetizationResult.success;
    }
    if (_disposed) {
      return MonetizationResult.unavailable;
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

    try {
      await ad.show(
        onUserEarnedReward: (_, _) {
          earnedReward = true;
        },
      );
    } catch (_) {
      ad.dispose();
      _preloadRewardedAd();
      if (!completer.isCompleted) {
        completer.complete(MonetizationResult.unavailable);
      }
    }

    return completer.future.timeout(
      const Duration(minutes: 2),
      onTimeout: () =>
          earnedReward ? MonetizationResult.success : MonetizationResult.unavailable,
    );
  }

  Future<MonetizationResult> purchaseProduct(String productId) async {
    if (!isSupported) {
      return MonetizationResult.success;
    }
    if (_disposed) {
      return MonetizationResult.unavailable;
    }

    try {
      final available = await InAppPurchase.instance.isAvailable().timeout(
        const Duration(seconds: 8),
        onTimeout: () => false,
      );
      if (!available) return MonetizationResult.unavailable;

      final response = await InAppPurchase.instance
          .queryProductDetails(<String>{productId})
          .timeout(const Duration(seconds: 10));
      if (response.error != null || response.productDetails.isEmpty) {
        return MonetizationResult.unavailable;
      }

      _completePendingPurchase(MonetizationResult.cancelled);
      final completer = Completer<MonetizationResult>();
      _pendingPurchaseCompleter = completer;
      _pendingPurchaseProductId = productId;

      final param = PurchaseParam(productDetails: response.productDetails.first);
      final started = await InAppPurchase.instance
          .buyNonConsumable(purchaseParam: param)
          .timeout(const Duration(seconds: 15), onTimeout: () => false);
      if (!started) {
        _completePendingPurchase(MonetizationResult.cancelled);
      }

      return await completer.future.timeout(
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
    if (!isSupported || _disposed) {
      return const <String>{};
    }

    try {
      final available = await InAppPurchase.instance.isAvailable().timeout(
        const Duration(seconds: 8),
        onTimeout: () => false,
      );
      if (!available) return const <String>{};
      _restoredProductIds.clear();
      await InAppPurchase.instance.restorePurchases().timeout(
        const Duration(seconds: 8),
      );
      await Future<void>.delayed(const Duration(seconds: 2));
      return Set<String>.from(_restoredProductIds);
    } catch (_) {
      return Set<String>.from(_restoredProductIds);
    }
  }

  bool _isAlreadyOwnedError(PurchaseDetails purchase) {
    final code = (purchase.error?.code ?? '').toLowerCase();
    final msg = (purchase.error?.message ?? '').toLowerCase();
    final details = (purchase.error?.details?.toString() ?? '').toLowerCase();
    return code.contains('already_owned') ||
        code.contains('itemalreadyowned') ||
        msg.contains('already_owned') ||
        msg.contains('itemalreadyowned') ||
        msg.contains('already owned') ||
        details.contains('already_owned') ||
        details.contains('itemalreadyowned');
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      final pid = purchase.productID;
      final matchesPending =
          _pendingPurchaseProductId != null &&
          (_pendingPurchaseProductId == pid || pid.isEmpty);

      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        final effectiveProductId =
            pid.isNotEmpty ? pid : (_pendingPurchaseProductId ?? '');
        if (effectiveProductId.isNotEmpty) {
          _restoredProductIds.add(effectiveProductId);
          _onOwnedProductRestored?.call(effectiveProductId);
        }
        if (purchase.pendingCompletePurchase) {
          try {
            await InAppPurchase.instance
                .completePurchase(purchase)
                .timeout(const Duration(seconds: 8));
          } catch (_) {}
        }
        if (matchesPending) {
          _completePendingPurchase(MonetizationResult.success);
        }
      } else if (purchase.status == PurchaseStatus.canceled) {
        if (matchesPending) {
          _completePendingPurchase(MonetizationResult.cancelled);
        }
      } else if (purchase.status == PurchaseStatus.error) {
        if (_isAlreadyOwnedError(purchase)) {
          final ownedId =
              pid.isNotEmpty ? pid : (_pendingPurchaseProductId ?? '');
          if (ownedId.isNotEmpty) {
            _restoredProductIds.add(ownedId);
            _onOwnedProductRestored?.call(ownedId);
          }
          if (matchesPending) {
            _completePendingPurchase(MonetizationResult.success);
          }
        } else if (matchesPending) {
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
    _disposed = true;
    _completePendingPurchase(MonetizationResult.cancelled);
    _rewardedAd?.dispose();
    _rewardedAd = null;
    unawaited(_purchaseSub?.cancel());
    _purchaseSub = null;
  }
}
