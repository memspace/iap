// Copyright (c) 2018, Anatoly Pulyaevskiy.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:iap_core/iap_core.dart';

import 'billing_client.dart';
import 'store_kit_data.dart';

export 'delegates_app_store.dart';
export 'delegates_play_store.dart';

typedef PurchaseHandler = Future<Subscription> Function(
    PurchaseCredentials credentials);

class Product {
  final SKProduct iosProduct;
  final SkuDetails androidProduct;

  Product({this.iosProduct, this.androidProduct});

  String get id => iosProduct?.productIdentifier ?? androidProduct?.sku;
  String get title => iosProduct?.localizedTitle ?? androidProduct?.title;
  String get description =>
      iosProduct?.localizedDescription ?? androidProduct?.description;
  String get price => iosProduct?.price ?? androidProduct?.price;
}

abstract class BillingDelegate {
  void dispose() {}
//  Future<bool> canMakePayments();

  /// Fetches product details from this delegate's platform payment gateway.
  Future<List<Product>> fetchProducts(List<String> productIds);

  /// Initiates purchase flow for specified [product] and this delegate's
  /// platform payment gateway.
  ///
  /// Returns purchase credentials specific to this platform.
  Future<Subscription> purchase(Product product, PurchaseHandler handler);

//  Future<Subscription> restorePurchases(Subscription subscription);
  Future<PurchaseCredentials> fetchPurchaseCredentials(String productId);
}
