Flutter plugin for interacting with iOS StoreKit and Android Billing Library.

Work in progress.

### How this plugin is different from others

The main difference is that this plugin does **not** provide common
interface for interacting with Andoid and iOS payment APIs. The reason is simply 
because those APIs have very little in common, so defining a common interface would
suffer from many inconsistencies and limitations.

> This clearly goes against best practices [described by a Google engineer](good-plugins).
> However I believe this is a rare case where it is more beneficial to
> take a slightly different path. Similarly to how [device_info]() plugin did.

[good-plugins]: https://medium.com/flutter-io/writing-a-good-flutter-plugin-1a561b986c9c?linkId=57996885
[device_info]: https://pub.dartlang.org/packages/device_info

Instead this plugin aims to provide two distinct interfaces for iOS StoreKit
and Android BillingClient. This way we can expose complete feature set
for both platforms. It is up to the user of this plugin to define a unified
interface inside their app which suites their workflow best.

There is additional benefit of having the same API interface in your Dart code
as you can rely on a lot of information available in official docs as well as
on the Internet. This makes it easier to get started and learn.

All Dart code is thoroughly documented with information taken directly from 
Apple developers website (for StoreKit).

### Status

Current version only implements iOS portion with Android side coming next.

### StoreKit

> Plugin currently implements all native APIs except for **downloads**.
> If you are looking for this functionality consider submitting a pull request
> or leaving your :+1: [here](https://github.com/memspace/iap/issues/1).

Interacting with StoreKit in Flutter is almost 100% identical to the native ObjectiveC
interface.

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
