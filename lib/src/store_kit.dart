import 'dart:async';

import 'package:flutter/services.dart';

import 'store_kit_data.dart';

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
      final input = Map<String, dynamic>.from(call.arguments);
      final data = Map<int, dynamic>.from(input['transactions']);
      final Map<int, SKPaymentTransaction> transactions =
          data.map((handle, item) {
        final tx = SKPaymentTransaction.fromMap(item);
        return MapEntry<int, SKPaymentTransaction>(handle, tx);
      });
      paymentQueue._enqueueUpdatedTransactions(transactions);
    } else if (call.method == 'SKPaymentQueue#didRemoveTransactions') {
      final data = Map<String, dynamic>.from(call.arguments);
      final transactions = _decodeTransactions(data['transactions']);
      paymentQueue._enqueueRemovedTransactions(transactions);
    } else if (call.method ==
        'SKPaymentQueue#failedToRestoreCompletedTransactions') {
      final data = Map<String, dynamic>.from(call.arguments);
      final error = SKError.fromMap(data['error']);
      paymentQueue._observer
          .failedToRestoreCompletedTransactions(paymentQueue, error);
    } else if (call.method ==
        'SKPaymentQueue#didRestoreCompletedTransactions') {
      paymentQueue._observer.didRestoreCompletedTransactions(paymentQueue);
    } else if (call.method == 'SKPaymentQueue#didUpdateDownloads') {
      final data = Map<String, dynamic>.from(call.arguments);
      final downloads = _decodeDownloads(data['downloads']);
      paymentQueue._observer.didUpdateDownloads(paymentQueue, downloads);
    } else if (call.method == 'SKPaymentQueue#didReceiveStorePayment') {
      final data = Map<String, dynamic>.from(call.arguments);
      final payment = SKPayment.fromMap(data['payment']);
      final product = SKProduct.fromMap(data['product']);
      paymentQueue._enqueueStorePayment(payment, product);
    } else {
      throw new UnimplementedError('Method "${call.method}" not implemented');
    }
  }

  List<SKPaymentTransaction> _decodeTransactions(List data) {
    return data
        .map((item) => SKPaymentTransaction.fromMap(item))
        .toList(growable: false);
  }

  List<SKDownload> _decodeDownloads(List data) {
    return data.map((item) => SKDownload.fromMap(item)).toList(growable: false);
  }

  /// Retrieves localized information from the App Store about a specified
  /// list of products.
  ///
  /// Use this method to present localized prices and other information to
  /// the user without having to maintain that list of product information itself.
  Future<SKProductsResponse> products(List<String> productIdentifiers) async {
    assert(productIdentifiers != null && productIdentifiers.isNotEmpty);
    final data = await _channel.invokeMethod('StoreKit#products', {
      'productIdentifiers': productIdentifiers,
    });
    return SKProductsResponse.fromMap(data);
  }

  /// Default payment queue for adding and processing payments.
  SKPaymentQueue get paymentQueue => SKPaymentQueue.instance;

  /// The file URL for the bundle’s App Store receipt.
  ///
  /// For an application purchased from the App Store, use this property to locate
  /// the receipt. This property makes no guarantee about whether there is a
  /// file at the URL — only that if a receipt is present, that is its location.
  Future<Uri> get appStoreReceiptUrl async {
    final String response =
        await _channel.invokeMethod('StoreKit#appStoreReceiptUrl');
    if (response == null) return null;
    return Uri.parse(response);
  }

  /// Request to refresh the receipt, which represents the user's
  /// transactions with your app.
  ///
  /// Use this API to request a new receipt if the receipt is invalid or missing.
  Future<void> refreshReceipt() async {
    await _channel.invokeMethod('StoreKit#refreshReceipt');
  }
}

class _StorePayment {
  final SKPayment payment;
  final SKProduct product;

  _StorePayment(this.payment, this.product);
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

  /// Cache of all udpated _and_ unfinished transactions.
  final _updatedTransactions = Map<int, SKPaymentTransaction>();
  final _removedTransactions = List<SKPaymentTransaction>();
  final _receivedStorePayments = List<_StorePayment>();

  /// Transaction observer.
  SKPaymentTransactionObserver _observer;

  SKPaymentQueue._();

  /// Adds updated [transactions] to this queue.
  ///
  /// If there is an observer registered with this queue then it
  /// gets notified immediately, otherwise it will be notified upon
  /// registration.
  ///
  /// See [setTransactionObserver] for details.
  void _enqueueUpdatedTransactions(
      Map<int, SKPaymentTransaction> transactions) {
    print('IAP: Queueing updated transactions');
    _updatedTransactions.addAll(transactions);
    if (_observer != null) {
      print('IAP: Notifying observer');
      _observer.didUpdateTransactions(
          this, transactions.values.toList(growable: false));
    }
  }

  /// Adds removed [transactions] to this queue.
  ///
  /// If there is an observer registered with this queue then it
  /// gets notified immediately, otherwise it will be notified upon
  /// registration.
  ///
  /// See [setTransactionObserver] for details.
  void _enqueueRemovedTransactions(List<SKPaymentTransaction> transactions) {
    if (_observer != null) {
      _observer.didRemoveTransactions(this, transactions);
    } else {
      _removedTransactions.addAll(transactions);
    }
  }

  /// Adds store payment to this queue.
  ///
  /// If there is an observer registered with this queue then it
  /// gets notified immediately, otherwise it will be notified upon
  /// registration.
  ///
  /// See [setTransactionObserver] for details.
  void _enqueueStorePayment(SKPayment payment, SKProduct product) {
    if (_observer != null) {
      _observer.didReceiveStorePayment(this, payment, product);
    } else {
      _receivedStorePayments.add(_StorePayment(payment, product));
    }
  }

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
  /// application initialization.
  ///
  /// If an application quits when transactions are still being processed,
  /// those transactions are not lost. The next time the application launches,
  /// the payment queue will resume processing the transactions. Your application
  /// should always expect to be notified of completed transactions.
  void setTransactionObserver(SKPaymentTransactionObserver observer) {
    _observer = observer;
    print('IAP: observer is set');
    if (_updatedTransactions.isNotEmpty) {
      print('IAP: found unhandled transactions, notifying.');
      _observer.didUpdateTransactions(
          this, _updatedTransactions.values.toList(growable: false));
    }
    if (_removedTransactions.isNotEmpty) {
      _observer.didRemoveTransactions(
          this, _removedTransactions.toList(growable: false));
      _removedTransactions.clear();
    }
    if (_receivedStorePayments.isNotEmpty) {
      while (_receivedStorePayments.isNotEmpty) {
        final item = _receivedStorePayments.removeLast();
        _observer.didReceiveStorePayment(this, item.payment, item.product);
      }
    }
  }

  /// Removes previously set observer from this payment queue.
  void removeTransactionObserver() {
    _observer = null;
  }

  /// Returns a list of unfinished transactions.
  ///
  /// The value of this property is undefined when there are no observers
  /// attached to the payment queue.
  Future<List<SKPaymentTransaction>> get transactions async {
    final result =
        await StoreKit._channel.invokeMethod('SKPaymentQueue#transactions');
    final data = List.from(result);
    return data
        .map((tx) => SKPaymentTransaction.fromMap(tx))
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
      'payment': payment.toMap(),
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
        'Attempt to finish transaction without identifier. '
        'This indicates that provided transaction has not been processed by the App Store yet '
        'and is not in either "purchased" or "restored" state. '
        'Only purchased transactions can be finalized.');

    final entry = _updatedTransactions.entries.firstWhere((entry) {
      return identical(entry.value, transaction);
    }, orElse: () => null);

    assert(
        entry != null,
        'Provided transaction cannot be finished. '
        'It could have been already finished or it is not coming from '
        'didUpdateTransactions() call of SKPaymentTransactionObserver.');

    final data = <String, dynamic>{'handle': entry.key};
    _updatedTransactions.remove(entry.key);

    try {
      await StoreKit._channel
          .invokeMethod('SKPaymentQueue#finishTransaction', data);
    } catch (error) {
      // Add the entry back to unfinished list.
      _updatedTransactions.addEntries([entry]);
      rethrow;
    }
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
  /// [SKPaymentTransactionState.failed], the application can read the transaction��s
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
  /// This delegate method is called when the user starts an in-app purchase in the
  /// App Store, and the transaction continues in your app. Specifically, if your app
  /// is already installed, the method is called automatically.
  ///
  /// Use this information to determine if user already purchased this product
  /// or should continue with this purchase. To proceed with this purchase
  /// simply add provided [payment] object to the queue.
  ///
  /// ### Implementation details
  ///
  /// This method works as a replacement to native `paymentQueue:shouldAddStorePayment:forProduct:`.
  /// When native observer receives `shoudlAddStorePayment` callback it
  /// always returns `NO` to payment queue but sends the payment details
  /// to Flutter side. If there is already observer registered on the
  /// Flutter side it is notified immediately. Otherwise it is notified
  /// upon registration.
  ///
  /// See also:
  ///
  ///   - [Documentation for paymentQueue:shouldAddStorePayment:forProduct:](https://developer.apple.com/documentation/storekit/skpaymenttransactionobserver/2877502-paymentqueue?language=objc)
  void didReceiveStorePayment(
      SKPaymentQueue queue, SKPayment payment, SKProduct product) {}
}
