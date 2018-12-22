// Copyright (c) 2018, Anatoly Pulyaevskiy.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:iap_core/iap_core.dart';
import 'package:logging/logging.dart';

import 'billing_client.dart';
import 'delegates.dart';

final Logger _logger = Logger('$PlayStoreSubscriptionDelegate');

class PlayStoreSubscriptionDelegate extends BillingDelegate
    implements PurchasesUpdatedListener {
  PlayStoreSubscriptionDelegate() {
    _client = new BillingClient(this);
  }

  BillingClient _client;

  bool _connected = false;

  Future<void> _ensureConnected() async {
    if (_connected) return;
    try {
      await _client.startConnection(onDisconnect: _handleDisconnect);
      _connected = true;
      _logger.info('Started billing connection');
    } on BillingClientException catch (error, trace) {
      _logger.severe('Failed to start billing connection', error, trace);
      rethrow;
    }
  }

  void _handleDisconnect() {
    _connected = false;
    _logger.warning(
        'Billing client disconnected. Will attempt to reconnect before next use.');
  }

  @override
  Future<List<Product>> fetchProducts(List<String> productIds) async {
    await _ensureConnected();
    final details =
        await _client.querySkuDetails(skuType: SkuType.kSubs, skus: productIds);
    _logger.info('$details');
    return details.map((sku) {
      return Product(androidProduct: sku);
    }).toList(growable: false);
  }

  @override
  Future<PurchaseCredentials> fetchPurchaseCredentials(String productId) {
    // TODO: implement fetchPurchaseCredentials
    return null;
  }

  @override
  void onPurchasesUpdated(int responseCode, List<Purchase> purchases) {
    // TODO: implement onPurchasesUpdated
  }

  @override
  Future<Subscription> purchase(Product product, handler) {
    // TODO: implement purchase
    return null;
  }
}
