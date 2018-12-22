// Copyright (c) 2018, Anatoly Pulyaevskiy.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:iap_core/iap_core.dart';
import 'package:logging/logging.dart';

import 'delegates.dart';
import 'store_kit.dart';
import 'store_kit_data.dart';

final Logger _logger = Logger('$AppStoreSubscriptionDelegate');

class _SKPurchaseProcessor {
  final SKPayment payment;
  final PurchaseHandler handler;

  _SKPurchaseProcessor(this.payment, this.handler);

  final _completer = Completer<Subscription>();

  Future<Subscription> get result => _completer.future;

  Future<bool> finalize(PurchaseCredentials credentials) async {
    try {
      final res = await handler(credentials);
      _completer.complete(res);
      return true;
    } catch (error) {
      fail(error);
      return false;
    }
  }

  void fail(Object error) {
    _completer.completeError(error);
  }
}

typedef SKRestoreTransactionsHandler<T> = Future<T> Function(
    List<SKPaymentTransaction> transactions);

class SKRestoreTransactionsProcessor<T> {
  final SKRestoreTransactionsHandler<T> handler;

  final Completer<T> _completer = new Completer<T>();
  final List<SKPaymentTransaction> _transactions = [];

  SKRestoreTransactionsProcessor(this.handler);

  Future<T> get result => _completer.future;

  void addTransaction(SKPaymentTransaction tx) {
    _transactions.add(tx);
  }

  void fail(Object error) {
    _completer.completeError(error);
  }

  Future<void> finalize(SKPaymentQueue queue) async {
    try {
      final T result = await handler(_transactions);
      _completer.complete(result);
    } catch (error) {
      _completer.completeError(error);
    } finally {
      for (var tx in _transactions) {
        await queue.finishTransaction(tx);
      }
    }
  }
}

/// Restores purchased subscription.
class SKSubscriptionRestorer
    extends SKRestoreTransactionsProcessor<Subscription> {
  final Subscription subscription;
  SKSubscriptionRestorer(
      this.subscription, SKRestoreTransactionsHandler<Subscription> handler)
      : super(handler);
}

/// Restores purchase credentials.
class SKPurchaseCredentialsRestorer
    extends SKRestoreTransactionsProcessor<PurchaseCredentials> {
  final String productId;

  SKPurchaseCredentialsRestorer(
      this.productId, SKRestoreTransactionsHandler<PurchaseCredentials> handler)
      : super(handler);
}

class AppStoreSubscriptionDelegate extends SKPaymentTransactionObserver
    implements BillingDelegate {
  static String kIosReceiptNotFoundError = 'IOS_RECEIPT_NOT_FOUND';
  static String kIosInvalidProductsError = 'IOS_INVALID_PRODUCTS';

  SKRestoreTransactionsProcessor _restorer;
  _SKPurchaseProcessor _activator;
  PurchaseHandler _refreshHandler;

  AppStoreSubscriptionDelegate(PurchaseHandler refreshHandler) {
    _refreshHandler = refreshHandler;
  }

  /// Retrieves contents of App Store receipt file stored on user's device.
  ///
  /// The file may not be present on the device in which case this method
  /// returns `null` unless [refresh] argument is set to `true`.
  ///
  /// If [refresh] is set to `true` and the file is not present on device
  /// then this method initiates "refresh receipt" flow with StoreKit. This
  /// may produce a dialog asking the user to enter their Apple ID password.
  Future<String> appStoreReceipt({bool refresh: false}) async {
    final receiptUrl = await StoreKit.instance.appStoreReceiptUrl;
    final receiptFile = File(receiptUrl.toFilePath());
    bool exists = await receiptFile.exists();
    if (exists) {
      final data = await receiptFile.readAsBytes();
      return base64.encode(data);
    }
    if (!refresh) return null;
    // Attempt to refresh receipt. It could be missing on a device
    // in some cases (e.g. user is not signed in with their Apple ID yet).
    // Note, this might prompt user to enter their Apple ID credentials.
    await StoreKit.instance.refreshReceipt();
    if (await receiptFile.exists()) {
      final data = await receiptFile.readAsBytes();
      return base64.encode(data);
    }
    throw new BillingException(
        kIosReceiptNotFoundError, 'Receipt file is not present on device.');
  }

  Future<List<Product>> fetchProducts(List<String> productIds) async {
    final response = await StoreKit.instance.products(productIds);
    if (response.invalidProductIdentifiers.isNotEmpty) {
      throw BillingException(
          kIosInvalidProductsError,
          'Invalid product identifiers provided',
          response.invalidProductIdentifiers);
    }
    final products = response.products.map((item) {
      return Product(iosProduct: item);
    }).toList(growable: false);

    return products;
  }

  @override
  Future<Subscription> purchase(Product product, PurchaseHandler handler) {
    assert(_activator == null);
    final payment = SKPayment.withProduct(product.iosProduct);
    _activator = _SKPurchaseProcessor(payment, handler);
    _activator.result.whenComplete(() {
      _activator = null;
    });
    StoreKit.instance.paymentQueue.addPayment(payment);
    return _activator.result;
  }

  @override
  Future<PurchaseCredentials> fetchPurchaseCredentials(String productId) {
    assert(_restorer == null);
    _restorer = SKPurchaseCredentialsRestorer(productId, _restoreCredentials);
    StoreKit.instance.paymentQueue
        .restoreCompletedTransactions()
        .catchError((error, trace) {
      _logger.severe('Failed to init restore purchases', error, trace);
      _restorer.fail(error);
    }).whenComplete(() {
      _logger.info('Request to restore purchases has been sent.');
    });
    return _restorer.result;
  }

  @override
  void dispose() {
    // TODO: implement dispose
  }

  _SKPurchaseProcessor _createRefresher() {
    final refresher = _SKPurchaseProcessor(null, _refreshHandler);
    refresher.result.catchError((error, trace) {
      _logger.severe('Failed to refresh subscription', error, trace);
    });
    return refresher;
  }

  @override
  void didUpdateTransactions(
      SKPaymentQueue queue, List<SKPaymentTransaction> transactions) async {
    for (final tx in transactions) {
      switch (tx.transactionState) {
        case SKPaymentTransactionState.purchasing:
          // no-op, note that there is no need to call finishTransaction too.
          break;
        case SKPaymentTransactionState.purchased:
          final processor = (_activator?.payment == tx.payment)
              ? _activator
              : _createRefresher();
          try {
            final credentials = await _collectCredentials(tx);
            final success = await processor.finalize(credentials);
            if (success) {
              await queue.finishTransaction(tx);
            }
          } catch (error) {
            processor.fail(error);
          }
          break;
        case SKPaymentTransactionState.restored:
          assert(_restorer != null);
          _restorer.addTransaction(tx);
          break;
        case SKPaymentTransactionState.failed:
          _logger.warning('Payment transaction failed.', tx.error);
          await queue.finishTransaction(tx);
          if (_activator?.payment == tx.payment) {
            if (tx.error.code == SKError.kSKCancelled) {
              // User cancelled this purchase, complete with nothing.
              _activator.finalize(null);
              _activator = null;
            }
          }
          break;
        case SKPaymentTransactionState.deferred:
          // We should receive another status update for this transaction,
          // it is safe to finish this notification here.
          await queue.finishTransaction(tx);
          break;
      }
    }
  }

  @override
  void failedToRestoreCompletedTransactions(
      SKPaymentQueue queue, SKError error) {
    if (_restorer is SKSubscriptionRestorer) {
      if (error.code == SKError.kSKCancelled) {
        _restorer.finalize(queue);
      } else {
        _restorer.fail(error);
      }
    } else {
      _restorer.fail(error);
    }
  }

  @override
  void didRestoreCompletedTransactions(SKPaymentQueue queue) {
    _restorer.finalize(queue).catchError((error, trace) {
//      _logger.severe(
//          'Failure in finalize transactions with $_restorer', error, trace);
    }).whenComplete(() {
      _restorer = null;
    });
  }

  Future<PurchaseCredentials> _restoreCredentials(
      List<SKPaymentTransaction> transactions) async {
//    _logger.info(
//        'Restoring purchase credentials from ${transactions.length} transactions.');
    assert(_restorer is SKPurchaseCredentialsRestorer);
    if (transactions.isEmpty) return null;
    SKPurchaseCredentialsRestorer restorer = _restorer;
    final productId = restorer.productId;

    final tx = transactions.firstWhere(
        (item) => item.payment.productIdentifier == productId,
        orElse: () => null);
    if (tx == null) {
      return null;
    }
    return _collectCredentials(tx.original);
  }

  Future<PurchaseCredentials> _collectCredentials(
      SKPaymentTransaction transaction) async {
    final transactionId = transaction.transactionIdentifier;
    final receipt = await appStoreReceipt(refresh: true);
    return PurchaseCredentials.appStore(transactionId, receipt);
  }
}
