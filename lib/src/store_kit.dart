import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Support for in-app purchases and interactions with the App Store.
class StoreKit {
  static const MethodChannel _channel =
      const MethodChannel('flutter.memspace.io/iap');

  static StoreKit _instance;

  static StoreKit get instance {
    if (_instance != null) return _instance;
    _instance = StoreKit._();
    return _instance;
  }

  StoreKit._() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method == 'SKPaymentQueue#didUpdateTransactions') {
      final data = Map<String, dynamic>.from(call.arguments);
      final transactions = _decodeTransactions(data['transactions']);
      paymentQueue._observer.didUpdateTransactions(paymentQueue, transactions);
    } else if (call.method == 'SKPaymentQueue#didRemoveTransactions') {
      final data = Map<String, dynamic>.from(call.arguments);
      final transactions = _decodeTransactions(data['transactions']);
      paymentQueue._observer.didRemoveTransactions(paymentQueue, transactions);
    } else if (call.method ==
        'SKPaymentQueue#failedToRestoreCompletedTransactions') {
      final data = Map<String, dynamic>.from(call.arguments);
      final error = SKError.fromJson(data['error']);
      paymentQueue._observer
          .failedToRestoreCompletedTransactions(paymentQueue, error);
    } else if (call.method ==
        'SKPaymentQueue#didRestoreCompletedTransactions') {
      paymentQueue._observer.didRestoreCompletedTransactions(paymentQueue);
    } else if (call.method == 'SKPaymentQueue#didUpdateDownloads') {
      final data = Map<String, dynamic>.from(call.arguments);
      final downloads = _decodeDownloads(data['downloads']);
      paymentQueue._observer.didUpdateDownloads(paymentQueue, downloads);
    } else if (call.method == 'SKPaymentQueue#shouldAddStorePayment') {
      final data = Map<String, dynamic>.from(call.arguments);
      final payment = SKPayment.fromJson(data['payment']);
      final product = SKProduct.fromJson(data['product']);
      return paymentQueue._observer
          .shouldAddStorePayment(paymentQueue, payment, product);
    } else {
      throw new UnimplementedError('Method "${call.method}" not implemented');
    }
  }

  List<SKPaymentTransaction> _decodeTransactions(List data) {
    return data
        .map((item) => SKPaymentTransaction.fromJson(item))
        .toList(growable: false);
  }

  List<SKDownload> _decodeDownloads(List data) {
    return data
        .map((item) => SKDownload.fromJson(item))
        .toList(growable: false);
  }

  /// Retrieves localized information from the App Store about a specified
  /// list of products.
  ///
  /// Use this method to present localized prices and other information to
  /// the user without having to maintain that list of product information itself.
  Future<SKProductsResponse> products(List<String> productIdentifiers) async {
    assert(productIdentifiers != null && productIdentifiers.isNotEmpty);
    final Map<String, dynamic> data =
        await _channel.invokeMethod('StoreKit#products', {
      'productIdentifiers': productIdentifiers,
    });
    return SKProductsResponse.fromJson(data);
  }

  SKPaymentQueue get paymentQueue => SKPaymentQueue.instance;
}

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
  }) : assert(productIdentifier != null &&
            localizedDescription != null &&
            localizedTitle != null &&
            price != null &&
            priceLocale != null &&
            isDownloadable != null &&
            downloadContentLengths != null &&
            downloadContentVersion != null);

  factory SKProduct.fromJson(Map<String, dynamic> data) {
    final productIdentifier = data['productIdentifier'] as String;
    final localizedDescription = data['localizedDescription'] as String;
    final localizedTitle = data['localizedTitle'] as String;
    final price = data['price'] as String;
    final priceLocale = data['priceLocale'] as String;
    final introductoryPrice =
        SKProductDiscount.fromJson(data['introductoryPrice']);
    final subscriptionPeriod =
        SKProductSubscriptionPeriod.fromJson(data['subscriptionPeriod']);
    final isDownloadable = data['isDownloadable'] as bool;
    final downloadContentLengths =
        List<int>.from(data['downloadContentLengths']);
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
    properties.add(FlagProperty('isDownloadable', value: isDownloadable));
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
  final SKProductSubscriptionPeriod subscriptionPeriod;

  SKProductDiscount._(this.price, this.priceLocale, this.paymentMode,
      this.numberOfPeriods, this.subscriptionPeriod)
      : assert(price != null &&
            priceLocale != null &&
            paymentMode != null &&
            numberOfPeriods != null &&
            subscriptionPeriod != null);

  factory SKProductDiscount.fromJson(Map<String, dynamic> data) {
    if (data == null) return null;

    final price = data['price'] as String;
    final priceLocale = data['priceLocale'] as String;
    final paymentMode = _decodePaymentMode(data['paymentMode']);
    final numberOfPeriods = data['numberOfPeriods'] as int;
    final subscriptionPediod =
        SKProductSubscriptionPeriod.fromJson(data['subscriptionPediod']);
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

  factory SKProductSubscriptionPeriod.fromJson(Map<String, dynamic> data) {
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

SKPaymentTransactionState _decodeTransactionState(String value) {
  if (value == 'purchasing') return SKPaymentTransactionState.purchasing;
  if (value == 'purchased') return SKPaymentTransactionState.purchased;
  if (value == 'failed') return SKPaymentTransactionState.failed;
  if (value == 'restored') return SKPaymentTransactionState.restored;
  if (value == 'deferred') return SKPaymentTransactionState.deferred;
  throw new StateError('Unknown transaction state "$value".');
}

/// An App Store response to a request for information about a list of products.
class SKProductsResponse {
  /// A list of products, one product for each valid product identifier
  /// provided in the original request.
  final List<SKProduct> products;

  /// An array of product identifier strings that were not recognized by
  /// the App Store.
  final List<String> invalidProductIdentifiers;

  SKProductsResponse._(this.products, this.invalidProductIdentifiers);

  SKProductsResponse.fromJson(Map<String, dynamic> data)
      : products = data['products'],
        invalidProductIdentifiers = data['invalidProductIdentifiers'];
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
class SKPaymentTransaction {
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
  /// For a list of error constants, see SKErrorDomain in StoreKit Constants.
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

  factory SKPaymentTransaction.fromJson(Map<String, dynamic> data) {
    if (data == null) return null;
    final payment =
        SKPayment.fromJson(Map<String, dynamic>.from(data['payment']));
    final transactionIdentifier = data['transactionIdentifier'] as String;
    final transctionDate = data['transactionDate'] != null
        ? DateTime.fromMicrosecondsSinceEpoch(data['transactionDate'])
        : null;
    final original = SKPaymentTransaction.fromJson(data['original']);
    final error = SKError.fromJson(data['error']);
    final downloads = List.from(data['downloads'])
        .map((item) => SKDownload.fromJson(item))
        .toList(growable: false);
    final transactionState = _decodeTransactionState(data['transactionState']);
    return SKPaymentTransaction._(
      payment: payment,
      transactionIdentifier: transactionIdentifier,
      transactionDate: transctionDate,
      original: original,
      error: error,
      downloads: downloads,
      transactionState: transactionState,
    );
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

  factory SKDownload.fromJson(Map<String, dynamic> data) {
    final contentIdentifier = data['contentIdentifier'] as String;
    final contentLength = data['contentLength'] as int;
    final contentVersion = data['contentVersion'] as String;
    final transaction = SKPaymentTransaction.fromJson(data['transaction']);
    final state = _decodeDownloadState(data['state']);
    final progress = data['progress'] as double;
    final timeRemaining = data['timeRemaining'] as int;
    final error = SKError.fromJson(data['error']);
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

  /// Indicates that your app canceled the download.
  canceled,
}

SKDownloadState _decodeDownloadState(String value) {
  if (value == null) return null;
  if (value == 'waiting') return SKDownloadState.waiting;
  if (value == 'active') return SKDownloadState.active;
  if (value == 'paused') return SKDownloadState.paused;
  if (value == 'finished') return SKDownloadState.finished;
  if (value == 'failed') return SKDownloadState.failed;
  if (value == 'canceled') return SKDownloadState.canceled;
  throw new StateError('Unknown download state "$value".');
}

/// StoreKit error.
class SKError {
  final int code;
  final String localizedDescription;

  SKError._(this.code, this.localizedDescription);

  factory SKError.fromJson(Map<String, dynamic> data) {
    if (data == null) return null;
    final errorCode = data['errorCode'] as int;
    final localizedDescription = data['localizedDescription'] as String;
    return SKError._(errorCode, localizedDescription);
  }
}

/// A request to the App Store to process payment for additional
/// functionality offered by your app.
///
/// A payment object encapsulates a string that identifies a particular
/// product and the quantity of those items the user would like to purchase.
class SKPayment {
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
  final bool simulatesAskToBuyInSandbox;

  SKPayment._({
    @required this.productIdentifier,
    @required this.quantity,
    this.applicationUsername,
    @required this.simulatesAskToBuyInSandbox,
  }) : assert(productIdentifier != null &&
            quantity != null &&
            simulatesAskToBuyInSandbox != null);

  factory SKPayment.withProduct(
    SKProduct product, {
    int quantity: 1,
    String applicationUsername,
    bool simulatesAskToBuyInSandbox: false,
  }) {
    assert(product != null, 'Product cannot be null.');
    assert(quantity != null && quantity >= 1, 'Invalid quantity for payment.');
    return SKPayment._(
      productIdentifier: product.productIdentifier,
      quantity: quantity,
      applicationUsername: applicationUsername,
      simulatesAskToBuyInSandbox: simulatesAskToBuyInSandbox,
    );
  }

  factory SKPayment.fromJson(Map<String, dynamic> data) {
    final productIdentifier = data['productIdentifier'] as String;
    final quantity = data['quantity'] as int;
    final applicationUsername = data['applicationUsername'] as String;
    final simulatesAskToBuyInSandbox =
        data['simulatesAskToBuyInSandbox'] as bool;
    return SKPayment._(
      productIdentifier: productIdentifier,
      quantity: quantity,
      applicationUsername: applicationUsername,
      simulatesAskToBuyInSandbox: simulatesAskToBuyInSandbox,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'productIdentifier': productIdentifier,
      'quantity': quantity,
      'applicationUsername': applicationUsername,
      'simulatesAskToBuyInSandbox': simulatesAskToBuyInSandbox,
    };
  }
}

/// A queue of payment transactions to be processed by the App Store.
///
/// The payment queue communicates with the App Store and presents a user interface
/// so that the user can authorize payment. The contents of the queue are
/// persistent between launches of your app.
class SKPaymentQueue {
  static SKPaymentQueue _instance;

  static SKPaymentQueue get instance {
    if (_instance != null) return _instance;
    _instance = SKPaymentQueue._();
    return _instance;
  }

  SKPaymentTransactionObserver _observer;

  SKPaymentQueue._();

  /// Indicates whether the user is allowed to make payments.
  ///
  /// Returned Future resolves to `true` if the user is allowed to
  /// authorize payment.
  ///
  /// An iPhone can be restricted from accessing the Apple App Store.
  /// For example, parents can restrict their children’s ability to purchase
  /// additional content. Your application should confirm that the user is
  /// allowed to authorize payments before adding a payment to the queue.
  /// Your application may also want to alter its behavior or appearance when
  /// the user is not allowed to authorize payments.
  Future<bool> canMakePayments() async {
    final bool value =
        await StoreKit._channel.invokeMethod('SKPaymentQueue#canMakePayments');
    return value;
  }

  /// Sets an observer on this payment queue.
  ///
  /// Your application should set an observer to the payment queue during
  /// application initialization. If there is no observer attached to the queue,
  /// the payment queue does not synchronize its list of pending transactions
  /// with the Apple App Store, because there is no observer to respond
  /// to updated transactions.
  ///
  /// If an application quits when transactions are still being processed,
  /// those transactions are not lost. The next time the application launches,
  /// the payment queue will resume processing the transactions. Your application
  /// should always expect to be notified of completed transactions.
  void setTransactionObserver(SKPaymentTransactionObserver observer) {
    _observer = observer;
    StoreKit._channel.invokeMethod('SKPaymentQueue#setTransactionObserver');
  }

  /// Removes previously set observer from this payment queue.
  ///
  /// If there is no observer attached to the queue, the payment queue does not
  /// synchronize its list of pending transactions with the Apple App Store,
  /// because there is no observer to respond to updated transactions.
  void removeTransactionObserver() {
    _observer = null;
    StoreKit._channel.invokeMethod('SKPaymentQueue#removeTransactionObserver');
  }

  /// Returns a list of pending transactions.
  ///
  /// The value of this property is undefined when there are no observers
  /// attached to the payment queue.
  Future<List<SKPaymentTransaction>> get transactions async {
    final result =
        await StoreKit._channel.invokeMethod('SKPaymentQueue#transactions');
    final data = List<Map<String, dynamic>>.from(result);
    return data
        .map((tx) => SKPaymentTransaction.fromJson(tx))
        .toList(growable: false);
  }

  /// Adds a payment request to the queue.
  ///
  /// An application should always have at least one observer of the payment queue
  /// before adding payment requests.
  ///
  /// The payment request must have a product identifier registered with the Apple
  /// App Store and a quantity greater than 0. If either property is invalid,
  /// this method throws an exception.
  ///
  /// When a payment request is added to the queue, the payment queue processes
  /// that request with the Apple App Store and arranges for payment from the user.
  /// When that transaction is complete or if a failure occurs, the payment queue
  /// sends the [SKPaymentTransaction] object that encapsulates the request
  /// to all transaction observers.
  Future<void> addPayment(SKPayment payment) async {
    final data = {
      'payment': payment.toJson(),
    };
    await StoreKit._channel.invokeMethod('SKPaymentQueue#addPayment', data);
  }

  /// Completes a pending transaction.
  ///
  /// Your application should call this method from a transaction observer that
  /// received a notification from the payment queue. Calling `finishTransaction`
  /// on a transaction removes it from the queue. Your application should call
  /// this method only after it has successfully processed the transaction and
  /// unlocked the functionality purchased by the user.
  ///
  /// Calling this method on a transaction that is in the
  /// [SKPaymentTransactionState.purchasing] state throws an exception.
  Future<void> finishTransaction(SKPaymentTransaction transaction) async {
    assert(transaction != null);
    assert(
        transaction.transactionIdentifier != null,
        'Attempt to finalize transaction without identifier. '
        'This indicates that provided transaction has not been processed by the App Store yet '
        'and is not in either "purchsed" or "restored" state. '
        'Only purchased transactions can be finalized.');
    final data = <String, dynamic>{
      'transactionIdentifier': transaction.transactionIdentifier,
    };
    await StoreKit._channel
        .invokeMethod('SKPaymentQueue#finishTransaction', data);
  }

  /// Asks the payment queue to restore previously completed purchases.
  ///
  /// Use this method to restore finished transactions—that is, transactions for
  /// which you have already called [finishTransaction]. You call this method
  /// in one of the following situations:
  ///
  /// * To install purchases on additional devices
  /// * To restore purchases for an application that the user deleted and reinstalled
  ///
  /// When you create a new product to be sold in your store, you choose whether
  /// that product can be restored or not. See the In-App Purchase Programming Guide
  /// for more information.
  ///
  /// The payment queue delivers a new transaction for each previously completed
  /// transaction that can be restored. Each transaction includes a copy of
  /// the original transaction.
  ///
  /// After the transactions are delivered, the payment queue calls the
  /// [SKPaymentTransactionObserver.didRestoreCompletedTransactions] method. If an error
  /// occurred while restoring transactions, the observer will be notified through
  /// [SKPaymentTransactionObserver.failedToRestoreCompletedTransactions].
  ///
  /// This method has no effect in the following situations:
  ///
  /// * All transactions are unfinished.
  /// * The user did not purchase anything that is restorable.
  /// * You tried to restore items that are not restorable, such as a non-renewing
  ///   subscription or a consumable product.
  /// * Your app's build version does not meet the guidelines for the `CFBundleVersion` key.
  Future<void> restoreCompletedTransactions(
      {String applicationUsername}) async {
    final data = <String, dynamic>{'applicationUsername': applicationUsername};
    await StoreKit._channel
        .invokeMethod('SKPaymentQueue#restoreCompletedTransactions', data);
  }

  /// Adds a set of downloads to the download list.
  ///
  /// In order for a download object to be queued, it must be associated with a transaction
  /// that has been successfully purchased, but not yet finished.
  Future<void> startDownloads(List<SKDownload> downloads) {
    // TODO: implement startDownloads
    throw new UnimplementedError();
  }

  /// Removes a set of downloads from the download list.
  Future<void> cancelDownloads(List<SKDownload> downloads) {
    // TODO: implement cancelDownloads
    throw new UnimplementedError();
  }

  /// Pauses a set of downloads.
  Future<void> pauseDownloads(List<SKDownload> downloads) {
    // TODO: implement pauseDownloads
    throw new UnimplementedError();
  }

  /// Resumes a set of downloads.
  Future<void> resumeDownloads(List<SKDownload> downloads) {
    // TODO: implement resumeDownloads
    throw new UnimplementedError();
  }
}

/// Observer of [SKPaymentQueue] with a set of methods that process transactions,
/// unlock purchased functionality, and continue promoted in-app purchases.
abstract class SKPaymentTransactionObserver {
  /// Tells this observer that one or more transactions have been updated.
  ///
  /// The application should process each transaction by examining the transaction’s
  /// `transactionState` property. If `transactionState` is [SKPaymentTransactionState.purchased],
  /// payment was successfully received for the desired functionality. The application
  /// should make the functionality available to the user. If transactionState is
  /// [SKPaymentTransactionState.failed], the application can read the transaction’s
  /// error property to return a meaningful error to the user.
  ///
  /// Once a transaction is processed, it should be removed from the payment queue
  /// by calling [SKPaymentQueue.finishTransaction] method, passing the transaction
  /// as a parameter.
  ///
  /// Important: Once the transaction is finished, Store Kit can not tell you that
  /// this item is already purchased. It is important that applications process
  /// the transaction completely before calling `finishTransaction`.
  void didUpdateTransactions(
      SKPaymentQueue queue, List<SKPaymentTransaction> transactions);

  /// Tells this observer that one or more transactions have been removed from the queue.
  ///
  /// Your application does not typically need to implement this method but might
  /// implement it to update its own user interface to reflect that a transaction
  /// has been completed.
  void didRemoveTransactions(
      SKPaymentQueue queue, List<SKPaymentTransaction> transactions) {}

  /// Tells this observer that an error occurred while restoring transactions.
  void failedToRestoreCompletedTransactions(
      SKPaymentQueue queue, SKError error) {}

  /// Tells this observer that the payment queue has finished sending restored
  /// transactions.
  ///
  /// This method is called after all restorable transactions have been
  /// processed by the payment queue. Your application is not required to do
  /// anything in this method.
  void didRestoreCompletedTransactions(SKPaymentQueue queue) {}

  /// Tells the observer that the payment queue has updated one or more
  /// download objects.
  ///
  /// When a download object is updated, its `downloadState` property describes
  /// how it changed.
  void didUpdateDownloads(SKPaymentQueue queue, List<SKDownload> downloads) {}

  /// Tells the observer that a user initiated an in-app purchase from the App Store.
  ///
  /// Return `true` to continue the transaction in your app. Return `false` to
  /// defer or cancel the transaction.
  ///
  /// If you return false, you can continue the transaction later by manually
  /// adding the SKPayment payment to the SKPaymentQueue queue.
  ///
  /// This delegate method is called when the user starts an in-app purchase in the
  /// App Store, and the transaction continues in your app. Specifically, if your app
  /// is already installed, the method is called automatically.
  ///
  /// If your app is not yet installed when the user starts the in-app purchase in the
  /// App Store, the user gets a notification when the app installation is complete.
  /// This method is called when the user taps the notification. Otherwise, if the user
  /// opens the app manually, this method is called only if the app is opened soon
  /// after the purchase was started.
  bool shouldAddStorePayment(
      SKPaymentQueue queue, SKPayment payment, SKProduct product) {
    return false;
  }
}
