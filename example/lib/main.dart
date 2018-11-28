import 'package:flutter/material.dart';
import 'package:iap/iap.dart';

void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> with SKPaymentTransactionObserver {
  @override
  void initState() {
    super.initState();
    StoreKit.instance.paymentQueue.setTransactionObserver(this);
  }

  @override
  void dispose() {
    StoreKit.instance.paymentQueue.removeTransactionObserver();
    super.dispose();
  }

  @override
  void didUpdateTransactions(
      SKPaymentQueue queue, List<SKPaymentTransaction> transaction) {
    //
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
        appBar: new AppBar(
          title: const Text('In-app purchases example'),
        ),
        body: new Center(
          child: new Text('TODO'),
        ),
      ),
    );
  }
}
