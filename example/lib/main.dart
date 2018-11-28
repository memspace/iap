// Copyright (c) 2018, Anatoly Pulyaevskiy.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This example currently only shows some basics of using iOS StoreKit.
// Setting up in-app payments is a complex topic and cannot be covered in a
// simple example like this. Refer to official documentation for each platform
// for more details.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:iap/iap.dart';

void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

/// Define a transaction observer responsible for processing payment updates.
/// In this example we also make this class encapsulate the whole purchase
/// flow since it leads to a bit cleaner separation of concerns.
class ExamplePurchaseProcessor extends SKPaymentTransactionObserver {
  /// Payment initiated by the user and is currently being processed.
  SKPayment _payment;
  Completer<SKPaymentTransaction> _completer;

  Future<SKPaymentTransaction> purchase(SKProduct product) {
    assert(_payment == null, 'There is already purchase in progress.');
    _payment = SKPayment.withProduct(product);
    _completer = Completer<SKPaymentTransaction>();
    StoreKit.instance.paymentQueue.addPayment(_payment);
    return _completer.future;
  }

  @override
  void didUpdateTransactions(
      SKPaymentQueue queue, List<SKPaymentTransaction> transactions) async {
    // Note that this method can be invoked by StoreKit even if there is no
    // active purchase initiated by the user (via [purchase] method), so
    // you should take this into account.
    // We only handle two states here (purchased and failed) and omit the rest
    // for brevity purposes.
    for (final tx in transactions) {
      switch (tx.transactionState) {
        case SKPaymentTransactionState.purchased:
          // Validate transaction, unlock content, etc...
          // Make sure to call `finishTransaction` when done, otherwise
          // this transaction will be redelivered by the queue on next application
          // launch.
          await queue.finishTransaction(tx);
          if (_payment == tx.payment) {
            // This transaction is related to an active purchase initiated
            // by user in UI. Signal it's been completed successfully.
            _completer.complete(tx);
            _payment = null;
            _completer = null;
          }
          break;
        case SKPaymentTransactionState.failed:
          // Purchase failed, make sure to notify the user in some way.
          await queue.finishTransaction(tx);
          if (_payment == tx.payment) {
            // This transaction is related to an active purchase as well.
            // Signal to the user that it failed. We pass the same transaction
            // object for simplicity here.
            _completer.completeError(tx);
            _payment = null;
            _completer = null;
          }
          break;
        default:
          // TODO: handle other states
          break;
      }
    }
  }
}

class _MyAppState extends State<MyApp> {
  // ID of the product we are selling.
  static const String kProductId = 'com.example.product.id';

  final ExamplePurchaseProcessor _observer = ExamplePurchaseProcessor();

  /// Whether user is allowed to make payments
  bool _canMakePayments;

  /// The product we want to provide for user to purchase.
  SKProduct _product;

  Future<SKPaymentTransaction> _purchaseFuture;

  SKPaymentTransaction _transaction;

  @override
  void initState() {
    super.initState();
    // Always register your transaction observer with StoreKit. It is highly
    // recommended to register your observer as early as possible.
    StoreKit.instance.paymentQueue.setTransactionObserver(_observer);
    // Check if user can actually make payments.
    // Note error-handling is omitted for brevity.
    StoreKit.instance.paymentQueue
        .canMakePayments()
        .then(_handleCanMakePayments);
  }

  void _handleCanMakePayments(bool value) {
    setState(() {
      _canMakePayments = value;
      StoreKit.instance.products([kProductId]).then(_handleProducts);
    });
  }

  void _handleProducts(SKProductsResponse response) {
    // Note error-handling is omitted for brevity. If you have an issue with
    // your product it will appear in [response.invalidProductIds].
    setState(() {
      _product = response.products.single;
    });
  }

  @override
  void dispose() {
    // Don't forget to remove your observer when your app state is rebuilding.
    StoreKit.instance.paymentQueue.removeTransactionObserver();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (_purchaseFuture != null) {
      // Payment processing
      if (_transaction == null) {
        child = CircularProgressIndicator();
      } else if (_transaction.transactionState ==
          SKPaymentTransactionState.purchased) {
        child = Text('Enjoy your product');
      } else {
        child = Text('Purchase failed: ${_transaction.transactionState}');
      }
    } else if (_canMakePayments == null) {
      // Haven't initialized yet, show loader
      child = CircularProgressIndicator();
    } else if (!_canMakePayments) {
      child = Text('Payments disabled');
    } else if (_product == null) {
      child = CircularProgressIndicator();
    } else {
      child = FlatButton(
          onPressed: _purchase, child: Text('Buy for ${_product.price}'));
    }
    return new MaterialApp(
      home: new Scaffold(
        appBar: new AppBar(
          title: const Text('In-app purchases example'),
        ),
        body: new Center(child: child),
      ),
    );
  }

  void _purchase() {
    setState(() {
      // Initiate purchase flow. From this point purchase handling must be
      // done in the transaction observer's `didUpdateTransactions` method.
      _purchaseFuture = _observer.purchase(_product);
      _purchaseFuture.then(_handlePurchase).catchError(_handlePurchaseError);
    });
  }

  void _handlePurchase(SKPaymentTransaction tx) {
    setState(() {
      _transaction = tx;
    });
  }

  void _handlePurchaseError(error) {
    if (error is SKPaymentTransaction) {
      setState(() {
        _transaction = error;
      });
    } else {
      setState(() {
        // TODO: set error state
      });
    }
  }
}
