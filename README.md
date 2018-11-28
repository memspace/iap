Flutter plugin for interacting with iOS StoreKit and Android Billing Library.

[![Build Status](https://travis-ci.com/memspace/iap.svg?branch=master)](https://travis-ci.com/memspace/iap) [![codecov](https://codecov.io/gh/memspace/iap/branch/master/graph/badge.svg)](https://codecov.io/gh/memspace/iap)

**Work in progress.**

### How this plugin is different from others

The main difference is that instead of providing unified interface for in-app purchases
on iOS and Android, this plugin exposes two separate APIs.

There are several benefits to this approach:

* We can expose _complete_ API interfaces for both platforms, without having to look for lowest
  common denominator of those APIs.
* Dart interfaces are designed to match native ones most of the time. `StoreKit` for iOS follows
  native interface in 99% of cases. `BillingClient` for Android is very similar as well, but also
  simplifies some parts of native protocol (mostly replaces listeners with Dart `Future`s).
* Developers familiar with native APIs would find it easier to learn. You can simply refer to
  official documentation in most cases to find details about certain method of field.

All Dart code is thoroughly documented with information taken directly from 
Apple Developers website (for StoreKit) and Android Developers website (for BillingClient).

Note that future versions may introduce unified interfaces for specific use cases, for instance,
handling of in-app subscriptions.

### StoreKit (iOS)

> Plugin currently implements all native APIs except for **downloads**.
> If you are looking for this functionality consider submitting a pull request
> or leaving your :+1: [here](https://github.com/memspace/iap/issues/1).

Interacting with StoreKit in Flutter is almost 100% identical to the native ObjectiveC
interface.

#### Prerequisites

Make sure to

* Complete Agreements, Tax and Bankings
* Setup your products in AppStore Connect
* Enable In-App Purchases for your app in XCode

#### Complete example

Checkout a complete example of interacting with StoreKit in the example app in this repo. Note
that in-app purchases is a complex topic and it would be really hard to cover everything
in a simple example app like this, so it is highly recommended to read official documentation
on setting up in-app purchases for each platform.

#### Getting products

```dart
final productIds = ['my.product1', 'my.product2'];
final SKProductsResponse response = await StoreKit.instance.products(productIds);
print(response.products); // list of valid [SKProduct]s
print(response.invalidProductIdentifiers) // list of invalid IDs
```

#### App Store Receipt

```dart
// Get receipt path on device
final Uri receiptUrl = await StoreKit.instance.appStoreReceiptUrl;
// Request a refresh of receipt
await StoreKit.instance.refreshReceipt();
```

#### Handling payments and transactions

Payments and transactions are handled within `SKPaymentQueue`.

It is important to set an observer on this queue as early as possible after
your app launch. Observer is responsible for processing all events
triggered by the queue. Create an observer by extending following class:

```dart
abstract class SKPaymentTransactionObserver {
  void didUpdateTransactions(SKPaymentQueue queue, List<SKPaymentTransaction> transactions);
  void didRemoveTransactions(SKPaymentQueue queue, List<SKPaymentTransaction> transactions) {}
  void failedToRestoreCompletedTransactions(SKPaymentQueue queue, SKError error) {}
  void didRestoreCompletedTransactions(SKPaymentQueue queue) {}
  void didUpdateDownloads(SKPaymentQueue queue, List<SKDownload> downloads) {}
  void didReceiveStorePayment(SKPaymentQueue queue, SKPayment payment, SKProduct product) {}
}
```

See API documentation for more details on these methods.

Make sure to implement `didUpdateTransactions` and process all transactions
according to your needs. Typical implementation should normally look like this:

```dart
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
      // ...
    }
  }
}
```

Before attempting to add a payment always check if the user can actually
make payments:

```dart
final bool canPay = await StoreKit.instance.paymentQueue.canMakePayments();
```

When that's verified and you've set an observer on the queue you can add
payments. For instance:

```dart
final SKProductsResponse response = await StoreKit.instance.products(['my.inapp.subscription']);
final SKProduct product = response.products.single;
final SKPayment = SKPayment.withProduct(product);
await StoreKit.instance.paymentQueue.addPayment(payment);
// ...
// Use observer to track progress of this payment...
```

#### Restoring completed transactions

```dart
await StoreKit.instance.paymentQueue.restoreCompletedTransactions();
/// Optionally implement `didRestoreCompletedTransactions` and 
/// `failedToRestoreCompletedTransactions` on observer to track
/// result of this operation.
```

### BillingClient (Android)

This plugin wraps official [Google Play Billing Library](https://developer.android.com/google/play/billing/billing_library_overview).
Use `BillingClient` class as the main entry point.

Constructor of `BillingClient` class expects an instance of `PurchaseUpdatedListener` interface
which looks like this:

```dart
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
```

#### Using `BillingClient`

To begin working with Play Billing service always start from establishing connection using
`startConnection` method:

```dart
import 'package:iap/iap.dart';

bool _connected = false;

void main() async {
  final client = BillingClient(yourPurchaseListener);
  await client.startConnection(onDisconnect: handleDisconnect);
  _connected = true;

  // ...fetch SKUDetails, launch billing flows, query purchase history, etc

  await client.endConnection(); // Always call [endConnection] when work with this client is done.
}

void handleDisconnect() {
  // Client disconnected. Make sure to call [startConnection] next time before invoking
  // any other method of the client.
  _connected = false;
}
```
