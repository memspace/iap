// Copyright (c) 2018, Anatoly Pulyaevskiy.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:iap_core/iap_core.dart';
import 'package:flutter/foundation.dart';

import 'delegates.dart';
import 'server.dart';

/// Manages billing details and flows of subscription products.
///
/// This service class is designed specifically to handle in-app subscriptions
/// in a platform-agnostic way. It implements necessary logic for listing,
/// purchasing and renewing subscriptions. It also relies on a backend
/// server implementation responsible for verification and storage of
/// subscription data. See [SubscriptionBillingServer] for more details on how
/// to setup and implement the backend side.
///
/// ## Subscription state
///
/// SubscriptionStore keeps local state of current user subscription which
/// can be retrieved using [subscription] field.
/// Since this class is also a [ChangeNotifier] you can listen to
/// subscription updates by adding a listener with [addListener] method.
///
/// ## On authentication
///
/// SubscriptionStore delegates all authentication responsibilities to
/// concrete implementations [SubscriptionBillingServer]. When working on
/// your [SubscriptionBillingServer] you need to make sure authentication with
/// the backend side is handled according to your application needs.
class SubscriptionStore extends ChangeNotifier {
  final SubscriptionBillingServer server;

  BillingDelegate _delegate;
  Subscription _subscription;
  Future<Subscription> _inFlightFetch;

  SubscriptionStore(this.server) {
    server.addListener(_serverRefresh);

    if (Platform.isIOS) {
      _delegate = AppStoreSubscriptionDelegate(_refreshPurchase);
    } else if (Platform.isAndroid) {
      _delegate = PlayStoreSubscriptionDelegate();
    } else {
      throw UnsupportedError(
          'Unsupported platform ${Platform.operatingSystem}');
    }
  }

  void _serverRefresh() async {
    if (_subscription != null) {
      final saved = _subscription;
      _subscription = null;
      if (server.userId != saved.userId && server.userId != null) {
        await subscription;
      }
    }
  }

  /// Current state of user subscription.
  Future<Subscription> get subscription async {
    if (_subscription != null) return _subscription;
    if (_inFlightFetch != null) return _inFlightFetch;
    _inFlightFetch = server.fetchSubscription();
    try {
      _subscription = await _inFlightFetch;
      notifyListeners();
      return _subscription;
    } finally {
      _inFlightFetch = null;
    }
  }

  /// Fetches product details for specified [productIds].
  ///
  /// Products specified by [productIds] must represent auto-renewable
  /// subscriptions.
  ///
  /// For iOS this method performs a products request in StoreKit. For Android
  /// performs a query for SKU details in PlayStore Billing service.
  Future<List<Product>> fetchProducts(List<String> productIds) =>
      _delegate.fetchProducts(productIds);

  /// Initiates purchase of subscription [product].
  ///
  /// Starts platform-specific purchase flow and waits for the user to complete
  /// purchase on the native side. When purchase is completed by the user
  /// purchase details are sent to the [server] which validates and activates
  /// user's subscription.
  ///
  /// Returns updated [Subscription] containing details of purchase.
  Future<Subscription> purchaseSubscription(Product product) async {
    final result = await _delegate.purchase(product, _activatePurchase);
    return result;
  }

  Future<Subscription> _activatePurchase(
      PurchaseCredentials credentials) async {
    if (credentials == null) return null;
    _subscription = await server.activatePurchase(credentials);
    notifyListeners();
    return _subscription;
  }

  Future<Subscription> _refreshPurchase(PurchaseCredentials credentials) async {
    _subscription = await server.refreshPurchase(credentials);
    notifyListeners();
    return _subscription;
  }

  /// Performs subscription lookup in user's purchase history.
  ///
  /// For iOS devices performs "restore completed transactions" flow to find
  /// any purchases associated with [productId] and uses this information to
  /// query for existing subscription on the [server].
  /// Note that this may trigger Apple ID sign in dialog.
  ///
  /// For Android devices performs a query in PlayStore purchase history to
  /// find a transaction associated with [productId] and then queries for
  /// existing subscription on the [server].
  ///
  /// Returns [LookupPurchaseResult] containing subscription, if found,
  /// and any additional details provided by the server.
  Future<LookupPurchaseResult> lookupSubscription(String productId) async {
    final credentials = await _delegate.fetchPurchaseCredentials(productId);
    final result = await server.lookupPurchase(credentials);
    return result;
  }
}
