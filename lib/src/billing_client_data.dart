// Copyright (c) 2018, Anatoly Pulyaevskiy.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of billing_client;

class Purchase extends Diagnosticable {
  /// Unique order identifier for the transaction.
  final String orderId;

  /// String in JSON format that contains details about the purchase order.
  final String originalJson;

  /// The application package from which the purchase originated.
  final String packageName;

  /// The time the product was purchased.
  final DateTime purchaseTime;

  /// Token that uniquely identifies a purchase for a given item and user pair.
  final String purchaseToken;

  /// String containing the signature of the purchase data that was signed with
  /// the private key of the developer.
  final String signature;

  /// The product Id.
  final String sku;

  /// Indicates whether the subscription renews automatically.
  final bool isAutoRenewing;

  Purchase._({
    this.orderId,
    this.originalJson,
    this.packageName,
    this.purchaseTime,
    this.purchaseToken,
    this.signature,
    this.sku,
    this.isAutoRenewing,
  });

  factory Purchase.fromMap(Map<String, Object> data) {
    final int purchaseTimeMs = data['purchaseTime'] as int;
    return Purchase._(
      orderId: data['orderId'] as String,
      originalJson: data['originalJson'] as String,
      packageName: data['packageName'] as String,
      purchaseTime:
          DateTime.fromMillisecondsSinceEpoch(purchaseTimeMs, isUtc: true),
      purchaseToken: data['purchaseToken'] as String,
      signature: data['signature'] as String,
      sku: data['sku'] as String,
      isAutoRenewing: data['isAutoRenewing'] as bool,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('orderId', orderId));
    properties.add(StringProperty('packageName', packageName));
    properties.add(StringProperty('purchaseTime', '$purchaseTime'));
    properties.add(StringProperty('purchaseToken', purchaseToken));
    properties.add(StringProperty('signature', signature));
    properties.add(StringProperty('sku', sku));
    properties.add(FlagProperty('isAutoRenewing',
        value: isAutoRenewing,
        ifTrue: 'will renew',
        ifFalse: 'will not renew'));
  }
}

/// Represents an in-app product's or subscription's listing details.
class SkuDetails extends Diagnosticable {
  /// The description of this product.
  final String description;

  /// Trial period configured in Google Play Console, specified in ISO 8601
  /// format.
  ///
  /// For example, `P7D` equates to seven days.
  ///
  /// Returned only for subscriptions which have a trial period configured.
  final String freeTrialPeriod;

  /// Formatted introductory price of a subscription, including its currency
  /// sign, such as €3.99.
  ///
  /// The price doesn't include tax.
  ///
  /// Returned only for subscriptions which have an introductory period
  /// configured.
  final String introductoryPrice;

  /// Introductory price in micro-units.
  ///
  /// The currency is the same as [priceCurrencyCode].
  ///
  /// Returned only for subscriptions which have an introductory period
  /// configured.
  final String introductoryPriceAmountMicros;

  /// The number of subscription billing periods for which the user will be
  /// given the introductory price, such as 3.
  ///
  /// Returned only for subscriptions which have an introductory period
  /// configured.
  final String introductoryPriceCycles;

  /// The billing period of the introductory price, specified in ISO 8601
  /// format.
  ///
  /// For example, `P7D` equates to seven days.
  ///
  /// Returned only for subscriptions which have an introductory period
  /// configured.
  final String introductoryPricePeriod;

  /// Formatted price of this item, including its currency sign.
  ///
  /// The price does not include tax.
  final String price;

  /// Price in micro-units, where 1,000,000 micro-units equal one unit of the
  /// currency.
  ///
  /// For example, if price is "€7.99", priceAmountMicros is "7990000". This
  /// value represents the localized, rounded price for a particular currency.
  final int priceAmountMicros;

  /// ISO 4217 currency code for price.
  ///
  /// For example, if price is specified in British pounds sterling,
  /// [priceCurrencyCode] is "GBP".
  final String priceCurrencyCode;

  /// The product Id.
  final String sku;

  /// Subscription period, specified in ISO 8601 format.
  ///
  /// For example, P1W equates to one week, P1M equates to one month, P3M
  /// equates to three months, P6M equates to six months, and P1Y equates to
  /// one year.
  ///
  /// Returned only for subscriptions.
  final String subscriptionPeriod;

  /// The title of this product.
  final String title;

  /// The [SkuType] of this product.
  final String type;

  /// Returns true if sku is rewarded instead of paid.
  ///
  /// If rewarded, developer should call [BillingClient.loadRewardedSku] before
  /// attempting to launch purchase in order to ensure the reward is available
  /// to the user.
  final bool isRewarded;

  /// Internal handle which holds reference to SkuDetails object on the native
  /// side.
  final int _handle;

  SkuDetails._({
    int handle,
    this.description,
    this.freeTrialPeriod,
    this.introductoryPrice,
    this.introductoryPriceAmountMicros,
    this.introductoryPriceCycles,
    this.introductoryPricePeriod,
    this.price,
    this.priceAmountMicros,
    this.priceCurrencyCode,
    this.sku,
    this.subscriptionPeriod,
    this.title,
    this.type,
    this.isRewarded,
  })  : assert(handle != null),
        _handle = handle;

  factory SkuDetails.fromMap(Map<String, Object> data) {
    return SkuDetails._(
      handle: data['_handle'] as int,
      description: data['description'] as String,
      freeTrialPeriod: data['freeTrialPeriod'] as String,
      introductoryPrice: data['introductoryPrice'] as String,
      introductoryPriceAmountMicros:
          data['introductoryPriceAmountMicros'] as String,
      introductoryPriceCycles: data['introductoryPriceCycles'] as String,
      introductoryPricePeriod: data['introductoryPricePeriod'] as String,
      price: data['price'] as String,
      priceAmountMicros: data['priceAmountMicros'] as int,
      priceCurrencyCode: data['priceCurrencyCode'] as String,
      sku: data['sku'] as String,
      subscriptionPeriod: data['subscriptionPeriod'] as String,
      title: data['title'] as String,
      type: data['type'] as String,
      isRewarded: data['isRewarded'] as bool,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('sku', sku, showName: false));
    properties.add(IntProperty('_handle', _handle));
    properties.add(StringProperty('description', description));
    properties.add(StringProperty('title', title));
    properties.add(StringProperty('type', type));
    properties.add(StringProperty('price', price));
    properties.add(StringProperty('priceCurrencyCode', priceCurrencyCode));
    properties.add(IntProperty('priceAmountMicros', priceAmountMicros));
    properties.add(StringProperty('subscriptionPeriod', subscriptionPeriod));
    properties.add(StringProperty('freeTrialPeriod', freeTrialPeriod));
    properties.add(StringProperty('introductoryPrice', introductoryPrice));
    properties.add(StringProperty(
        'introductoryPriceAmountMicros', introductoryPriceAmountMicros));
    properties.add(
        StringProperty('introductoryPriceCycles', introductoryPriceCycles));
    properties.add(
        StringProperty('introductoryPricePeriod', introductoryPricePeriod));
    properties.add(StringProperty('introductoryPrice', introductoryPrice));
    properties.add(FlagProperty('isRewarded',
        value: isRewarded, ifTrue: 'rewarded', ifFalse: 'not rewarded'));
  }

  @override
  String toStringShort() {
    return '$runtimeType#$sku';
  }
}

class BillingFlowParams {
  /// Obfuscated string that is uniquely associated with the user's account in
  /// your app (optional).
  final String accountId;

  /// The SKU that the user is upgrading or downgrading from.
  ///
  /// Required to replace an old subscription.
  final String oldSku;

  /// The mode of proration during subscription upgrade/downgrade.
  ///
  /// This value will only be effective if [oldSku] is set.
  ///
  /// Optional:
  ///   * To buy in-app item
  ///   * To create a new subscription
  ///   * To replace an old subscription
  final int replaceSkusProrationMode;

  /// The SKU that is being purchased or upgraded/downgraded to as published in
  /// the Google Developer console.
  final String sku;

  /// The details of the item being purchase.
  final SkuDetails skuDetails;

  /// Indicates whether you wish to launch a VR purchase flow (optional).
  final bool vrPurchaseFlow;

  BillingFlowParams({
    this.accountId,
    this.oldSku,
    this.replaceSkusProrationMode,
    this.sku,
    this.skuDetails,
    this.vrPurchaseFlow,
  });

  Map<String, Object> toMap() {
    return {
      'accountId': accountId,
      'oldSku': oldSku,
      'replaceSkusProrationMode': replaceSkusProrationMode,
      'sku': sku,
      'skuDetails': skuDetails._handle,
      'vrPurchaseFlow': vrPurchaseFlow,
    };
  }
}
