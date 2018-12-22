// Copyright (c) 2018, Anatoly Pulyaevskiy.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:iap_core/iap_core.dart';

class LookupPurchaseResult {
  final Subscription subscription;
  final Map<String, Object> details;

  LookupPurchaseResult(this.subscription, this.details);
}

/// Billing server interface for managing user subscriptions.
abstract class SubscriptionBillingServer extends ChangeNotifier {
  String _userId;

  String get userId => _userId;
  @protected
  set userId(String value) {
    if (_userId != value) {
      _userId = value;
      notifyListeners();
    }
  }

  /// Activates subscription purchase with specified [credentials].
  Future<Subscription> activatePurchase(PurchaseCredentials credentials);

  Future<Subscription> refreshPurchase(PurchaseCredentials credentials);

  /// Looks up purchased subscription based on specified [credentials].
  Future<LookupPurchaseResult> lookupPurchase(PurchaseCredentials credentials);

  /// Retrieves user subscription from this data store.
  Future<Subscription> fetchSubscription();
}

class _PendingPurchase {
  final PurchaseCredentials credentials;
  final Completer<Subscription> _completer = Completer();

  _PendingPurchase(this.credentials);

  Future<Subscription> get result => _completer.future;
}

// ignore: unused_element
class _ExampleServer extends SubscriptionBillingServer {
  final List<_PendingPurchase> _pendingPurchases = [];

  @override
  Future<Subscription> activatePurchase(PurchaseCredentials credentials) {
    // TODO: implement activatePurchase
    return null;
  }

  Future<Subscription> refreshPurchase(PurchaseCredentials credentials) {
    final purchase = _PendingPurchase(credentials);
    _pendingPurchases.add(purchase);
    _processPendingPurchases();
    return purchase.result;
  }

  @override
  Future<Subscription> fetchSubscription() {
    if (_userId == null) return null;
    return null;
  }

  @override
  Future<LookupPurchaseResult> lookupPurchase(PurchaseCredentials credentials) {
    // TODO: implement findPurchase
    return null;
  }

  Future<void> _processPendingPurchases() async {
    if (_userId == null) return; // No authenticated user yet, wait
  }
}
