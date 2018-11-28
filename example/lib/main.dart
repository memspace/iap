// Copyright (c) 2018, Anatoly Pulyaevskiy.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This example currently only shows some basics of using iOS StoreKit.
// Setting up in-app payments is a complex topic and cannot be covered in a
// simple example like this. Refer to official documentation for each platform
// for more details.

import 'package:flutter/material.dart';
import 'package:iap/iap.dart';

void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

/// Define a transaction observer responsible for processing payment updates.
class ExamplePaymentTransactionObserver extends SKPaymentTransactionObserver {
  @override
  void didUpdateTransactions(
      SKPaymentQueue queue, List<SKPaymentTransaction> transactions) async {
    for (final tx in transactions) {
      switch (tx.transactionState) {
        case SKPaymentTransactionState.purchased:
          // Validate transaction, unlock content, etc...
          // Make sure to call `finishTransaction` when done, otherwise
          // this transaction will be redelivered by the queue on next application
          // launch.
          await queue.finishTransaction(tx);
          break;
        case SKPaymentTransactionState.failed:
          // ...
          await queue.finishTransaction(tx);
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

  final SKPaymentTransactionObserver _observer =
      ExamplePaymentTransactionObserver();

  /// Whether user is allowed to make payments
  bool _canMakePayments;

  /// The product we want to provide for user to purchase.
  SKProduct _product;

  // Payment being processed.
  SKPayment _payment;

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
    if (_payment != null) {
      // Payment processing in progress, show loader
      child = CircularProgressIndicator();
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
      _payment = SKPayment.withProduct(_product);
      // Initiate purchase flow. From this point purchase handling must be
      // done in the transaction observer's `didUpdateTransactions` method.
      StoreKit.instance.paymentQueue.addPayment(_payment);
    });
  }
}
