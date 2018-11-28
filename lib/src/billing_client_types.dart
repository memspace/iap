// Copyright (c) 2018, Anatoly Pulyaevskiy.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of billing_client;

/// Listener interface for purchase updates which happen when, for example,
/// the user buys something within the app or by initiating a purchase from
/// Google Play Store.
abstract class PurchasesUpdatedListener {
  /// Implement this method to get notifications for purchases updates.
  ///
  /// Both purchases initiated by your app and the ones initiated by Play Store
  /// will be reported here.
  void onPurchasesUpdated(int responseCode, List<Purchase> purchases);
}

/// Billing response codes.
abstract class BillingResponse {
  /// Billing API version is not supported for the type requested.
  static const int kBillingUnavailable = 3;

  /// Invalid arguments provided to the API. This error can also indicate that
  /// the application was not correctly signed or properly set up for In-app
  /// Billing in Google Play, or does not have the necessary permissions in
  /// its manifest.
  static const int kDeveloperError = 5;

  /// Fatal error during the API action.
  static const int kError = 6;

  /// Requested feature is not supported by Play Store on the current device.
  static const int kFeatureNotSupported = -2;

  /// Failure to purchase since item is already owned.
  static const int kItemAlreadyOwned = 7;

  ///Failure to consume since item is not owned.
  static const int kItemNotOwned = 8;

  /// Requested product is not available for purchase.
  static const int kItemUnavailable = 4;

  /// Success.
  static const int kOk = 0;

  /// Play Store service is not connected now - potentially transient state.
  ///
  /// E.g. Play Store could have been updated in the background while your app
  /// was still running. So feel free to introduce your retry policy for such
  /// use case. It should lead to a call to [BillingClient.startConnection]
  /// right after or in some time after you received this code.
  static const int kServiceDisconnected = -1;

  /// Network connection is down.
  static const int kServiceUnavailable = 2;

  /// User pressed back or canceled a dialog.
  static const int kUserCanceled = 1;
}

/// Features/capabilities supported by [BillingClient.isFeatureSupported].
abstract class FeatureType {
  /// Purchase/query for in-app items on VR.
  static const String kInAppItemsOnVr = 'inAppItemsOnVr';

  /// Launch a price change confirmation flow.
  static const String kPriceChangeConfirmation = 'priceChangeConfirmation';

  /// Purchase/query for subscriptions.
  static const String kSubscriptions = 'subscriptions';

  /// Purchase/query for subscriptions on VR.
  static const String kSubscriptionsOnVr = 'subscriptionsOnVr';

  /// Subscriptions update/replace.
  static const String kSubscriptionsUpdate = 'subscriptionsUpdate';
}

/// Supported SKU types.
abstract class SkuType {
  /// A type of SKU for in-app products.
  static const String kInApp = 'inapp';

  /// A type of SKU for subscriptions.
  static const String kSubs = 'subs';
}

/// Replace SKU proration modes.
abstract class ProrationMode {
  /// Replacement takes effect when the old plan expires, and the new price
  /// will be charged at the same time.
  static const int kDeferred = 4;

  /// Replacement takes effect immediately, and the billing cycle remains the
  /// same. The price for the remaining period will be charged. This option is
  /// only available for subscription upgrade.
  static const int kImmediateAndChargeProratedPrice = 2;

  /// Replacement takes effect immediately, and the new price will be charged on
  /// next recurrence time. The billing cycle stays the same.
  static const int kImmediateWithoutProration = 3;

  /// Replacement takes effect immediately, and the remaining time will be
  /// prorated and credited to the user. This is the current default behavior.
  static const int kImmediateWithTimeProration = 1;

  /// No doc
  static const int kUnknownSubscriptionUpgradeDowngradePolicy = 0;
}
