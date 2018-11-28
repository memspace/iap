// Copyright (c) 2018, Anatoly Pulyaevskiy.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';

/// Information about a product you previously registered in App Store Connect.
///
/// SKProduct objects are returned as part of an [SKProductsResponse].
class SKProduct extends Diagnosticable {
  /// The string that identifies the product to the Apple App Store.
  final String productIdentifier;

  /// A description of the product.
  final String localizedDescription;

  /// The name of the product.
  final String localizedTitle;

  /// The cost of the product in the local currency.
  final String price;

  /// The locale used to format the price of the product.
  final String priceLocale;

  /// The object containing introductory price information for the product.
  final SKProductDiscount introductoryPrice;

  /// The period details for products that are subscriptions.
  final SKProductSubscriptionPeriod subscriptionPeriod;

  /// Indicates whether the App Store has downloadable content for this product.
  final bool isDownloadable;

  /// The lengths of the downloadable files available for this product.
  final List<int> downloadContentLengths;

  /// Identifies which version of the content is available for download.
  final String downloadContentVersion;

  /// Identifier of the subscription group of this product.
  final String subscriptionGroupIdentifier;

  SKProduct._({
    @required this.productIdentifier,
    @required this.localizedDescription,
    @required this.localizedTitle,
    @required this.price,
    @required this.priceLocale,
    this.introductoryPrice,
    this.subscriptionPeriod,
    @required this.isDownloadable,
    @required this.downloadContentLengths,
    @required this.downloadContentVersion,
    this.subscriptionGroupIdentifier,
  })  : assert(productIdentifier != null, 'Product identifier cannot be null'),
        assert(price != null, 'Price cannot be null'),
        assert(priceLocale != null, 'Price locale cannot be null'),
        assert(isDownloadable != null);

  factory SKProduct.fromMap(Map<dynamic, dynamic> data) {
    final productIdentifier = data['productIdentifier'] as String;
    final localizedDescription = data['localizedDescription'] as String;
    final localizedTitle = data['localizedTitle'] as String;
    final price = data['price'] as String;
    final priceLocale = data['priceLocale'] as String;
    final introductoryPrice =
        SKProductDiscount.fromMap(data['introductoryPrice']);
    final subscriptionPeriod =
        SKProductSubscriptionPeriod.fromMap(data['subscriptionPeriod']);
    final isDownloadable = data['isDownloadable'] as bool;
    final downloadContentLengths = data['downloadContentLengths'] != null
        ? List<int>.from(data['downloadContentLengths'])
        : null;
    final downloadContentVersion = data['downloadContentVersion'] as String;
    final subscriptionGroupIdentifier =
        data['subscriptionGroupIdentifier'] as String;
    return SKProduct._(
      productIdentifier: productIdentifier,
      localizedDescription: localizedDescription,
      localizedTitle: localizedTitle,
      price: price,
      priceLocale: priceLocale,
      introductoryPrice: introductoryPrice,
      subscriptionPeriod: subscriptionPeriod,
      isDownloadable: isDownloadable,
      downloadContentLengths: downloadContentLengths,
      downloadContentVersion: downloadContentVersion,
      subscriptionGroupIdentifier: subscriptionGroupIdentifier,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('productIdentifier', productIdentifier,
        showName: false));
    properties
        .add(StringProperty('localizedDescription', localizedDescription));
    properties.add(StringProperty('localizedTitle', localizedTitle));
    properties.add(StringProperty('price', price));
    properties.add(StringProperty('priceLocale', priceLocale));
    properties.add(DiagnosticsProperty<SKProductDiscount>(
        'introductoryPrice', introductoryPrice));
    properties.add(DiagnosticsProperty<SKProductSubscriptionPeriod>(
        'subscriptionPeriod', subscriptionPeriod));
    properties.add(FlagProperty('isDownloadable',
        value: isDownloadable, ifTrue: 'yes', ifFalse: 'no'));
    properties.add(StringProperty(
        'subscriptionGroupIdentifier', subscriptionGroupIdentifier));
  }

  @override
  String toStringShort() {
    return '$runtimeType#$productIdentifier';
  }
}

/// Contains the details of a discount for a subscription product.
///
/// Product discount information is retrieved from the Apple App Store,
/// and is determined by the discounts that you set up in App Store Connect
class SKProductDiscount extends Diagnosticable {
  /// The discount price of the product in the local currency.
  final String price;

  /// The locale used to format the discount price of the product.
  final String priceLocale;

  /// The payment mode for this product discount.
  final PaymentMode paymentMode;

  /// Indicates the number of periods the product discount is available.
  final int numberOfPeriods;

  /// Defines the period for the product discount.
  ///
  /// Represents the duration of a single subscription period. A period is
  /// described as a number of units, where a unit can be any of [PeriodUnit]
  /// values.
  ///
  /// To calculate the total amount of time that the discount price is
  /// available to the user, multiply the subscriptionPeriod by
  /// [numberOfPeriods].
  final SKProductSubscriptionPeriod subscriptionPeriod;

  SKProductDiscount._(this.price, this.priceLocale, this.paymentMode,
      this.numberOfPeriods, this.subscriptionPeriod)
      : assert(price != null, 'Price cannot be null'),
        assert(priceLocale != null, 'Price locale cannot be null'),
        assert(paymentMode != null, 'Payment mode cannot be null'),
        assert(numberOfPeriods != null, 'Number of periods cannot be null');

  factory SKProductDiscount.fromMap(Map<dynamic, dynamic> data) {
    if (data == null) return null;

    final price = data['price'] as String;
    final priceLocale = data['priceLocale'] as String;
    final paymentMode = _decodePaymentMode(data['paymentMode']);
    final numberOfPeriods = data['numberOfPeriods'] as int;
    final subscriptionPediod =
        SKProductSubscriptionPeriod.fromMap(data['subscriptionPediod']);
    return SKProductDiscount._(
        price, priceLocale, paymentMode, numberOfPeriods, subscriptionPediod);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('price', price));
    properties.add(StringProperty('priceLocale', priceLocale));
    properties.add(EnumProperty('paymentMode', paymentMode));
    properties.add(IntProperty('numberOfPeriods', numberOfPeriods));
    properties.add(DiagnosticsProperty<SKProductSubscriptionPeriod>(
        'subscriptionPeriod', subscriptionPeriod));
  }
}

/// Contains the subscription period duration information.
///
/// A subscription period is a duration of time defined as some number of units.
/// For example, a subscription period of two weeks has a unit of [PeriodUnit.week],
/// and a [numberOfUnits] equal to 2.
class SKProductSubscriptionPeriod extends Diagnosticable {
  /// The number of units per subscription period.
  final int numberOfUnits;

  /// The increment of time that a subscription period is specified in.
  final PeriodUnit unit;

  SKProductSubscriptionPeriod._(this.numberOfUnits, this.unit)
      : assert(numberOfUnits != null && unit != null);

  factory SKProductSubscriptionPeriod.fromMap(Map<dynamic, dynamic> data) {
    if (data == null) return null;
    final numberOfUnits = data['numberOfUnits'] as int;
    final unit = _decodePeriodUnit(data['unit']);
    return SKProductSubscriptionPeriod._(numberOfUnits, unit);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('numberOfUnits', numberOfUnits));
    properties.add(EnumProperty('unit', unit));
  }
}

/// Values representing the duration of an interval, from a day up to a year.
enum PeriodUnit { day, month, week, year }

PeriodUnit _decodePeriodUnit(String value) {
  if (value == 'day') return PeriodUnit.day;
  if (value == 'month') return PeriodUnit.month;
  if (value == 'week') return PeriodUnit.week;
  if (value == 'year') return PeriodUnit.year;
  throw new StateError('Unknown period unit "$value".');
}

/// Values representing the payment modes for a product discount.
enum PaymentMode { payAsYouGo, payUpFront, freeTrial }

PaymentMode _decodePaymentMode(String value) {
  if (value == 'payAsYouGo') return PaymentMode.payAsYouGo;
  if (value == 'payUpFront') return PaymentMode.payUpFront;
  if (value == 'freeTrial') return PaymentMode.freeTrial;
  throw new StateError('Unknown payment mode "$value".');
}

/// Values representing the state of a transaction.
enum SKPaymentTransactionState {
  /// The transaction is being processed by the App Store.
  purchasing,

  /// The App Store successfully processed payment. Your application
  /// should provide the content the user purchased.
  purchased,

  /// The transaction failed. Check the [SKPaymentTransaction.error] property
  /// to determine what happened.
  failed,

  /// This transaction restores content previously purchased by the user.
  /// Read the [SKPaymentTransaction.original] property to obtain information
  /// about the original purchase.
  restored,

  /// The transaction is in the queue, but its final status is pending external
  /// action such as Ask to Buy. Update your UI to show the deferred state,
  /// and wait for another callback that indicates the final status.
  deferred,
}

String _encodeTransactionState(SKPaymentTransactionState state) {
  if (state == SKPaymentTransactionState.purchasing) return 'purchasing';
  if (state == SKPaymentTransactionState.purchased) return 'purchased';
  if (state == SKPaymentTransactionState.failed) return 'failed';
  if (state == SKPaymentTransactionState.restored) return 'restored';
  if (state == SKPaymentTransactionState.deferred) return 'deferred';
  throw new StateError('Unknown transaction state $state.');
}

SKPaymentTransactionState _decodeTransactionState(String value) {
  if (value == 'purchasing') return SKPaymentTransactionState.purchasing;
  if (value == 'purchased') return SKPaymentTransactionState.purchased;
  if (value == 'failed') return SKPaymentTransactionState.failed;
  if (value == 'restored') return SKPaymentTransactionState.restored;
  if (value == 'deferred') return SKPaymentTransactionState.deferred;
  throw new StateError('Unknown transaction state "$value".');
}

/// An App Store response to a request for information about a list of products.
class SKProductsResponse extends Diagnosticable {
  /// A list of products, one product for each valid product identifier
  /// provided in the original request.
  final List<SKProduct> products;

  /// An array of product identifier strings that were not recognized by
  /// the App Store.
  final List<String> invalidProductIdentifiers;

  SKProductsResponse._(this.products, this.invalidProductIdentifiers);

  SKProductsResponse.fromMap(Map<dynamic, dynamic> data)
      : products = List.from(data['products'])
            .map((item) => SKProduct.fromMap(item))
            .toList(growable: false),
        invalidProductIdentifiers =
            List<String>.from(data['invalidProductIdentifiers']);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IterableProperty('products', products));
    properties.add(IterableProperty(
        'invalidProductIdentifiers', invalidProductIdentifiers));
  }
}

/// An object in the payment queue.
///
/// A payment transaction is created whenever a payment is added to the payment
/// queue.
///
/// Transactions are delivered to your app when the App Store has finished
/// processing the payment. Completed transactions provide a receipt and
/// transaction identifier that your app can use to save a permanent record
/// of the processed payment.
class SKPaymentTransaction extends Diagnosticable {
  /// The payment for the transaction.
  ///
  /// Each payment transaction is created in response to a payment that your
  /// application added to the payment queue.
  final SKPayment payment;

  /// A string that uniquely identifies a successful payment transaction.
  ///
  /// The contents of this property are undefined except when [transactionState]
  /// is set to [SKPaymentTransactionState.purchased] or
  /// [SKPaymentTransactionState.restored].
  ///
  /// The transactionIdentifier is a string that uniquely identifies the
  /// processed payment. Your application may wish to record this string as part of
  /// an audit trail for App Store purchases.
  ///
  /// The value of this property corresponds to the Transaction Identifier
  /// property in the receipt.
  final String transactionIdentifier;

  /// The date the transaction was added to the App Store’s payment queue.
  ///
  /// The contents of this property are undefined except when [transactionState]
  /// is set to [SKPaymentTransactionState.purchased] or
  /// [SKPaymentTransactionState.restored].
  final DateTime transactionDate;

  /// The transaction that was restored by the App Store.
  ///
  /// The contents of this property are undefined except when [transactionState]
  /// is set to [SKPaymentTransactionState.restored].
  ///
  /// When a transaction is restored, the current transaction holds a new
  /// transaction identifier, receipt, and so on. Your application will read
  /// this property to retrieve the restored transaction.
  final SKPaymentTransaction original;

  /// Describes the error that occurred while processing the transaction.
  ///
  /// The error property is undefined except when [transactionState] is set to
  /// [SKPaymentTransactionState.failed]. Your application can read the error
  /// property to determine why the transaction failed.
  ///
  /// Error codes could belong to SKErrorDomain or NSURLErrorDomain.
  ///
  /// See also:
  ///
  ///   - Handling errors: https://developer.apple.com/documentation/storekit/handling_errors?language=objc
  final SKError error;

  /// An array of download objects representing the downloadable content
  /// associated with the transaction.
  ///
  /// The contents of this property are undefined except when [transactionState] is
  /// set to [SKPaymentTransactionState.purchased]. The [SKDownload] objects
  /// stored in this property must be used to download the transaction’s content
  /// before the transaction is finished. After the transaction is finished,
  /// the download objects are no longer queueable.
  final List<SKDownload> downloads;

  /// The current state of the transaction.
  final SKPaymentTransactionState transactionState;

  SKPaymentTransaction._({
    @required this.payment,
    this.transactionIdentifier,
    this.transactionDate,
    this.original,
    this.error,
    @required this.downloads,
    @required this.transactionState,
  });

  factory SKPaymentTransaction.fromMap(Map<dynamic, dynamic> data) {
    if (data == null) return null;
    final payment = SKPayment.fromMap(data['payment']);
    final transactionIdentifier = data['transactionIdentifier'] as String;
    final transactionDate = data['transactionDate'] != null
        ? DateTime.fromMillisecondsSinceEpoch(data['transactionDate'])
        : null;
    final original = SKPaymentTransaction.fromMap(data['original']);
    final error = SKError.fromMap(data['error']);
    final downloads = List.from(data['downloads'])
        .map((item) => SKDownload.fromMap(item))
        .toList(growable: false);
    final transactionState = _decodeTransactionState(data['transactionState']);
    return SKPaymentTransaction._(
      payment: payment,
      transactionIdentifier: transactionIdentifier,
      transactionDate: transactionDate,
      original: original,
      error: error,
      downloads: downloads,
      transactionState: transactionState,
    );
  }

  /// Returns a Map containing information about this transaction.
  Map<String, dynamic> toMap({bool includeDownloads: true}) {
    return <String, dynamic>{
      'payment': payment.toMap(),
      'transactionIdentifier': transactionIdentifier,
      'transctionDate': transactionDate?.millisecondsSinceEpoch,
      'original': original?.toMap(),
      'error': error?.toMap(),
      'downloads': (downloads != null && includeDownloads)
          ? downloads.map((dl) => dl.toMap()).toList(growable: false)
          : null,
      'transactionState': _encodeTransactionState(transactionState),
    };
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<SKPayment>('payment', payment));
    properties
        .add(StringProperty('transactionIdentifier', transactionIdentifier));
    properties.add(
        StringProperty('transctionDate', transactionDate?.toIso8601String()));
    properties.add(DiagnosticsProperty<SKError>('error', error));
    properties.add(IterableProperty('downloads', downloads));
    properties.add(EnumProperty('transactionState', transactionState));
  }
}

/// Downloadable content associated with a product.
///
/// When you create a product in App Store Connect, you can associate one or more
/// pieces of downloadable content with it. At runtime, when a product is
/// purchased by a user, your app uses SKDownload objects to download the content
/// from the App Store.
///
/// Your app never directly creates a SKDownload object. Instead, after a payment
/// is processed, your app reads the transaction object’s downloads property to
/// retrieve an array of SKDownload objects associated with the transaction.
///
/// To download the content, you queue a download object on the payment queue and
/// wait for the content to be downloaded. After a download completes, read the
/// download object’s contentURL property to get a URL to the downloaded content.
/// Your app must process the downloaded file before completing the transaction.
/// For example, it might copy the file into a directory whose contents are persistent.
/// When all downloads are complete, you finish the transaction. After the transaction
/// is finished, the download objects cannot be queued to the payment queue and any
/// URLs to the downloaded content are invalid.
class SKDownload extends Diagnosticable {
  /// Each piece of downloadable content associated with a product has its own
  /// unique identifier.
  ///
  /// The content identifier is specified in App Store Connect when you add the content.
  final String contentIdentifier;

  /// The length of the downloadable content, in bytes.
  final int contentLength;

  /// Identifies which version of the content is available for download.
  ///
  /// The version string must be formatted as a series of integers separated by periods.
  final String contentVersion;

  /// The transaction associated with this downloadable file.
  ///
  /// A download object is always associated with a payment transaction. The download
  /// object may only be queued after payment is processed and before the transaction
  /// is finished.
  final SKPaymentTransaction transaction;

  /// The current state of the download object.
  ///
  /// After you queue a download object, the payment queue object calls your transaction
  /// observer when the state of the download object changes. Your transaction observer
  /// should read the state property and use it to determine how to proceed.
  /// For more information on the different states, see [SKDownloadState].
  final SKDownloadState state;

  /// Indicates how much of the file has been downloaded.
  ///
  /// The value of this property is a floating point number between 0.0 and 1.0,
  /// inclusive, where 0.0 means no data has been download and 1.0 means all the data
  /// has been downloaded. Typically, your app uses the value of this property to update
  /// a user interface element, such as a progress bar, that displays how much of the
  /// file has been downloaded.
  ///
  /// Do not use the value of this property to determine whether the download has
  /// completed. Instead, use the [state] property.
  final double progress;

  /// Estimated time, in seconds, to finish downloading the content.
  ///
  /// The system attempts to estimate how long it will take to finish downloading the file.
  /// If it cannot create a good estimate, the value of this property is set to
  /// [SKDownloadTimeRemainingUnknown].
  final int timeRemaining;

  /// Error that prevented the content from being downloaded.
  ///
  /// The value of this property is valid only when the [state] property is set to
  /// [SKDownloadState.failed].
  final SKError error;

  /// The local location of the downloaded file.
  ///
  /// The value of this property is valid only when the downloadState property is
  /// set to [SKDownloadState.finished]. The URL becomes invalid after the transaction
  /// object associated with the download is finalized.
  final Uri contentUrl;

  SKDownload._({
    this.contentIdentifier,
    this.contentLength,
    this.contentVersion,
    this.transaction,
    this.state,
    this.progress,
    this.timeRemaining,
    this.error,
    this.contentUrl,
  });

  factory SKDownload.fromMap(Map<dynamic, dynamic> data) {
    final contentIdentifier = data['contentIdentifier'] as String;
    final contentLength = data['contentLength'] as int;
    final contentVersion = data['contentVersion'] as String;
    final transaction = SKPaymentTransaction.fromMap(data['transaction']);
    final state = _decodeDownloadState(data['state']);
    final progress = data['progress'] as double;
    final timeRemaining = data['timeRemaining'] as int;
    final error = SKError.fromMap(data['error']);
    final contentUrl =
        data['contentUrl'] != null ? Uri.parse(data['contentUrl']) : null;
    return SKDownload._(
      contentIdentifier: contentIdentifier,
      contentLength: contentLength,
      contentVersion: contentVersion,
      transaction: transaction,
      state: state,
      progress: progress,
      timeRemaining: timeRemaining,
      error: error,
      contentUrl: contentUrl,
    );
  }

  /// Returns the local location for the previously downloaded file.
  ///
  /// Use this method to locate the content on subsequent launches of your app.
  Future<Uri> contentUrlForProductId(String productId) {
    throw new UnimplementedError();
  }

  /// Deletes the previously downloaded file.
  Future<void> deleteContentForProductId(String productId) {
    throw new UnimplementedError();
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'contentIdentifier': contentIdentifier,
      'contentLength': contentLength,
      'contentVersion': contentVersion,
      'transaction': transaction.toMap(includeDownloads: false),
      'state': _encodeDownloadState(state),
      'progress': progress,
      'timeRemaining': timeRemaining,
      'error': error?.toMap(),
      'contentUrl': contentUrl?.toString(),
    };
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('contentIdentifier', contentIdentifier,
        showName: false));
    properties.add(IntProperty('contentLength', contentLength));
    properties.add(StringProperty('contentVersion', contentVersion));
    properties.add(
        DiagnosticsProperty<SKPaymentTransaction>('transaction', transaction));
    properties.add(EnumProperty('state', state));
    properties.add(DoubleProperty('progress', progress));
    properties.add(IntProperty('timeRemaining', timeRemaining));
    properties.add(DiagnosticsProperty<SKError>('error', error));
    properties.add(DiagnosticsProperty<Uri>('contentUrl', contentUrl));
  }
}

const int SKDownloadTimeRemainingUnknown = -1;

/// The states that a download operation can be in.
enum SKDownloadState {
  /// Indicates that the download has not started yet.
  waiting,

  /// Indicates that the content is currently being downloaded.
  active,

  /// Indicates that your app paused the download.
  paused,

  /// Indicates that the content was successfully downloaded.
  finished,

  /// Indicates that an error occurred while the file was being downloaded.
  failed,

  /// Indicates that your app cancelled the download.
  cancelled,
}

String _encodeDownloadState(SKDownloadState state) {
  if (state == SKDownloadState.waiting) return 'waiting';
  if (state == SKDownloadState.active) return 'active';
  if (state == SKDownloadState.paused) return 'paused';
  if (state == SKDownloadState.finished) return 'finished';
  if (state == SKDownloadState.failed) return 'failed';
  if (state == SKDownloadState.cancelled) return 'cancelled';
  throw new StateError('Unknown download state $state.');
}

SKDownloadState _decodeDownloadState(String value) {
  if (value == null) return null;
  if (value == 'waiting') return SKDownloadState.waiting;
  if (value == 'active') return SKDownloadState.active;
  if (value == 'paused') return SKDownloadState.paused;
  if (value == 'finished') return SKDownloadState.finished;
  if (value == 'failed') return SKDownloadState.failed;
  if (value == 'cancelled') return SKDownloadState.cancelled;
  throw new StateError('Unknown download state "$value".');
}

/// StoreKit error.
class SKError {
  // kSK* error codes originated in StoreKit service layer.
  static const String kSKUnknown = 'SKErrorUnknown';
  static const String kSKClientInvalid = 'SKErrorClientInvalid';
  static const String kSKCancelled = 'SKErrorPaymentCancelled';
  static const String kSKPaymentInvalid = 'SKErrorPaymentInvalid';
  static const String kSKPaymentNotAllowed = 'SKErrorPaymentNotAllowed';
  static const String kSKCloudServicePermissionDenied =
      'SKErrorCloudServicePermissionDenied';
  static const String kSKCloudServiceNetworkConnectionFailed =
      'SKErrorCloudServiceNetworkConnectionFailed';

  // kUrl* error codes originated in network transport layer.
  static const String kUrlTimedOut = 'NSURLErrorTimedOut';
  static const String kUrlCannotFindHost = 'NSURLErrorCannotFindHost';
  static const String kUrlCannotConnectToHost = 'NSURLErrorCannotConnectToHost';
  static const String kUrlNetworkConnectionLost =
      'NSURLErrorNetworkConnectionLost';
  static const String kUrlNotConnectedToInternet =
      'NSURLErrorNotConnectedToInternet';
  static const String kUrlUserCancelledAuthentication =
      'NSURLErrorUserCancelledAuthentication';
  static const String kUrlSecureConnectionFailed =
      'NSURLErrorSecureConnectionFailed';

  final String code;
  final String localizedDescription;

  SKError._(this.code, this.localizedDescription);

  factory SKError.fromMap(Map<dynamic, dynamic> data) {
    if (data == null) return null;
    final code = data['code'] as String;
    final localizedDescription = data['localizedDescription'] as String;
    return SKError._(code, localizedDescription);
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'code': code,
      'localizedDescription': localizedDescription,
    };
  }

  @override
  String toString() {
    return 'SKError#$code($localizedDescription)';
  }
}

/// A request to the App Store to process payment for additional
/// functionality offered by your app.
///
/// A payment object encapsulates a string that identifies a particular
/// product and the quantity of those items the user would like to purchase.
class SKPayment extends Diagnosticable {
  /// A string used to identify a product that can be purchased from within
  /// your application.
  final String productIdentifier;

  /// The number of items the user wants to purchase.
  final int quantity;

  /// An opaque identifier for the user’s account on your system.
  ///
  /// This is used to help the store detect irregular activity.
  /// For example, in a game, it would be unusual for dozens of different
  /// iTunes Store accounts making purchases on behalf of the same in-game character.
  ///
  /// The recommended implementation is to use a one-way hash of the
  /// user’s account name to calculate the value for this property.
  final String applicationUsername;

  /// Produces an "ask to buy" flow for this payment in the sandbox.
  ///
  /// Available since iOS 8.3.
  final bool simulatesAskToBuyInSandbox;

  SKPayment._({
    @required this.productIdentifier,
    @required this.quantity,
    this.applicationUsername,
    this.simulatesAskToBuyInSandbox,
  }) : assert(productIdentifier != null &&
            quantity != null &&
            simulatesAskToBuyInSandbox != null);

  factory SKPayment.withProduct(
    SKProduct product, {
    int quantity: 1,
    String applicationUsername,
    bool simulatesAskToBuyInSandbox,
  }) {
    assert(product != null, 'Product cannot be null.');
    assert(quantity != null && quantity >= 1, 'Invalid quantity for payment.');
    return SKPayment._(
      productIdentifier: product.productIdentifier,
      quantity: quantity,
      applicationUsername: applicationUsername,
      simulatesAskToBuyInSandbox: simulatesAskToBuyInSandbox ?? false,
    );
  }

  factory SKPayment.fromMap(Map<dynamic, dynamic> data) {
    final productIdentifier = data['productIdentifier'] as String;
    final quantity = data['quantity'] as int;
    final applicationUsername = data['applicationUsername'] as String;
    final simulatesAskToBuyInSandbox =
        data['simulatesAskToBuyInSandbox'] as bool;
    return SKPayment._(
      productIdentifier: productIdentifier,
      quantity: quantity,
      applicationUsername: applicationUsername,
      simulatesAskToBuyInSandbox: simulatesAskToBuyInSandbox ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SKPayment) return false;
    SKPayment typedOther = other;
    return productIdentifier == typedOther.productIdentifier &&
        quantity == typedOther.quantity &&
        applicationUsername == typedOther.applicationUsername &&
        simulatesAskToBuyInSandbox == typedOther.simulatesAskToBuyInSandbox;
  }

  @override
  int get hashCode {
    return hashValues(productIdentifier, quantity, applicationUsername,
        simulatesAskToBuyInSandbox);
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'productIdentifier': productIdentifier,
      'quantity': quantity,
      'applicationUsername': applicationUsername,
      'simulatesAskToBuyInSandbox': simulatesAskToBuyInSandbox,
    };
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('productIdentifier', productIdentifier));
    properties.add(IntProperty('quantity', quantity));
    properties.add(StringProperty('applicationUsername', applicationUsername));
    properties.add(FlagProperty(
      'simulatesAskToBuyInSandbox',
      value: simulatesAskToBuyInSandbox,
      ifTrue: 'simulatesAskToBuyInSandbox',
    ));
  }
}
