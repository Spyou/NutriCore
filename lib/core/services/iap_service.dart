import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Thin wrapper around `in_app_purchase` for one-tap consumable tips.
///
/// The three SKUs must exist in Google Play Console → Monetize → In-app
/// products with consumable type. Until they exist the queryProducts call
/// returns an empty list — the UI handles that as "Tips are coming soon".
class IapService {
  static final IapService instance = IapService._();
  IapService._();

  static const Set<String> kTipSkus = {
    'tip_small',
    'tip_medium',
    'tip_large',
  };

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  bool _initialized = false;
  bool _available = false;
  List<ProductDetails> _products = const [];

  bool get isAvailable => _available;
  List<ProductDetails> get products => _products;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      _available = await _iap.isAvailable();
      if (!_available) return;

      _sub = _iap.purchaseStream.listen(
        _onPurchaseUpdate,
        onError: (e) {
          if (kDebugMode) print('IAP stream error: $e');
        },
      );

      final res = await _iap.queryProductDetails(kTipSkus);
      _products = res.productDetails
        ..sort((a, b) => a.rawPrice.compareTo(b.rawPrice));
      if (kDebugMode) {
        print(
          'IAP products loaded: ${_products.map((p) => p.id).toList()} '
          '(notFound=${res.notFoundIDs})',
        );
      }
    } catch (e) {
      if (kDebugMode) print('IAP init failed: $e');
      _available = false;
    }
  }

  Future<bool> buy(ProductDetails product) async {
    if (!_available) return false;
    final param = PurchaseParam(productDetails: product);
    try {
      // Tips are consumables — buyConsumable auto-consumes on Android by
      // default so the user can tip again.
      return await _iap.buyConsumable(purchaseParam: param);
    } catch (e) {
      if (kDebugMode) print('IAP buy failed: $e');
      return false;
    }
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> updates) async {
    for (final p in updates) {
      if (p.status == PurchaseStatus.pending) continue;
      if (p.status == PurchaseStatus.purchased ||
          p.status == PurchaseStatus.restored) {
        _onTipCallback?.call(p.productID);
      }
      if (p.pendingCompletePurchase) {
        try {
          await _iap.completePurchase(p);
        } catch (_) {}
      }
    }
  }

  void Function(String productId)? _onTipCallback;
  void onTip(void Function(String productId)? cb) {
    _onTipCallback = cb;
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }
}
