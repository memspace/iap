// Copyright (c) 2018, Anatoly Pulyaevskiy.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iap/iap.dart';

Future<Null> simulateEvent(String name, Map<dynamic, dynamic> data) async {
  await BinaryMessages.handlePlatformMessage(
    StoreKit.channel.name,
    StoreKit.channel.codec.encodeMethodCall(MethodCall(name, data)),
    (_) {},
  );
}

void main() {
  final List<MethodCall> log = <MethodCall>[];
  Object response;

  StoreKit.channel.setMockMethodCallHandler((call) async {
    log.add(call);
    return response;
  });

  tearDown(() {
    log.clear();
    response = null;
  });

  group('StoreKit', () {
    test('fetch appStoreReceiptUrl', () async {
      response = '/some/path/to/receipt/file';
      final result = await StoreKit.instance.appStoreReceiptUrl;
      expect(result, Uri.parse('/some/path/to/receipt/file'));
      expect(log, <Matcher>[
        isMethodCall('StoreKit#appStoreReceiptUrl', arguments: null)
      ]);
    });

    test('fetch null appStoreReceiptUrl', () async {
      final result = await StoreKit.instance.appStoreReceiptUrl;
      expect(result, isNull);
      expect(log, <Matcher>[
        isMethodCall('StoreKit#appStoreReceiptUrl', arguments: null)
      ]);
    });

    test('refreshReceipt', () async {
      await StoreKit.instance.refreshReceipt();
      expect(log,
          <Matcher>[isMethodCall('StoreKit#refreshReceipt', arguments: null)]);
    });

    test('fetch products', () async {
      response = {
        'products': [testProduct],
        'invalidProductIdentifiers': ['invalid.id']
      };
      final result =
          await StoreKit.instance.products([testProductId, 'invalid.id']);
      expect(log, <Matcher>[
        isMethodCall('StoreKit#products', arguments: {
          'productIdentifiers': [testProductId, 'invalid.id']
        })
      ]);
      expect(result, isInstanceOf<SKProductsResponse>());
      expect(result.invalidProductIdentifiers, ['invalid.id']);

      final product = result.products.single;
      expect(product.productIdentifier, testProductId);
      expect(product.localizedTitle, 'Monthly Subscription');
      expect(product.localizedDescription, 'Subscription');
      expect(product.price, '2.99');
      expect(product.priceLocale, 'en_US');
      expect(product.subscriptionPeriod.numberOfUnits, 1);
      expect(product.subscriptionPeriod.unit, PeriodUnit.month);
      expect(product.isDownloadable, isFalse);
      expect(product.subscriptionGroupIdentifier, '123456');
    });
  });

  group('SKPaymentQueue', () {
    test('canMakePayments', () async {
      response = true;
      final result = await StoreKit.instance.paymentQueue.canMakePayments();
      expect(result, isTrue);
      expect(log, <Matcher>[
        isMethodCall('SKPaymentQueue#canMakePayments', arguments: null)
      ]);
    });

    test('addPayment', () async {
      final payment = SKPayment.fromMap({
        'productIdentifier': testProductId,
        'quantity': 1,
        'simulatesAskToBuyInSandbox': true,
      });
      await StoreKit.instance.paymentQueue.addPayment(payment);
      expect(log, <Matcher>[
        isMethodCall('SKPaymentQueue#addPayment', arguments: {
          'payment': {
            'productIdentifier': testProductId,
            'quantity': 1,
            'applicationUsername': null,
            'simulatesAskToBuyInSandbox': true,
          }
        })
      ]);
    });
  });

  group('SKPaymentTransactionObserver', () {
    test('set observer', () async {
      final observer = TestObserver();
      await StoreKit.instance.paymentQueue.setTransactionObserver(observer);

      expect(log, <Matcher>[
        isMethodCall('SKPaymentQueue#enableObserver', arguments: null)
      ]);
    });

    test('remove observer', () async {
      await StoreKit.instance.paymentQueue.removeTransactionObserver();
      expect(log, <Matcher>[
        isMethodCall('SKPaymentQueue#disableObserver', arguments: null)
      ]);
    });

    test('handle updated transactions', () async {
      final observer = TestObserver();
      await StoreKit.instance.paymentQueue.setTransactionObserver(observer);

      await simulateEvent('SKPaymentQueue#didUpdateTransactions', {
        'transactions': {1: testTransaction},
      });
      expect(observer.updatedTransactions, isNotNull);
      expect(observer.updatedTransactions, isNotEmpty);
    });

    test('handle removed transactions', () async {
      final observer = TestObserver();
      await StoreKit.instance.paymentQueue.setTransactionObserver(observer);

      await simulateEvent('SKPaymentQueue#didRemoveTransactions', {
        'transactions': [testTransaction]
      });
      expect(observer.removedTransactions, isNotNull);
      expect(observer.removedTransactions, isNotEmpty);
    });

    test('handle failed restore', () async {
      final observer = TestObserver();
      await StoreKit.instance.paymentQueue.setTransactionObserver(observer);

      await simulateEvent(
          'SKPaymentQueue#failedToRestoreCompletedTransactions', {
        'error': {'code': 'testError', 'localizedDescription': 'Did not work'}
      });
      expect(observer.failedRestoreError, isNotNull);
      expect(observer.failedRestoreError.code, 'testError');
      expect(observer.failedRestoreError.localizedDescription, 'Did not work');
    });

    test('handle completed restore', () async {
      final observer = TestObserver();
      await StoreKit.instance.paymentQueue.setTransactionObserver(observer);
      await simulateEvent(
          'SKPaymentQueue#didRestoreCompletedTransactions', null);
      expect(observer.restoreCompleted, isTrue);
    });

    test('handle store payment', () async {
      final observer = TestObserver();
      await StoreKit.instance.paymentQueue.setTransactionObserver(observer);
      await simulateEvent('SKPaymentQueue#didReceiveStorePayment', {
        'payment': {'productIdentifier': testProductId, 'quantity': 1},
        'product': testProduct,
      });
      expect(observer.storePayment, isNotNull);
      expect(observer.storePayment.payment.productIdentifier, testProductId);
      expect(observer.storePayment.payment.quantity, 1);
    });

    test('finish transaction', () async {
      final observer = TestObserver();
      await StoreKit.instance.paymentQueue.setTransactionObserver(observer);

      await simulateEvent('SKPaymentQueue#didUpdateTransactions', {
        'transactions': {1: testTransaction},
      });
      final tx = observer.updatedTransactions.single;
      await StoreKit.instance.paymentQueue.finishTransaction(tx);
      expect(log, <Matcher>[
        isMethodCall('SKPaymentQueue#enableObserver', arguments: null),
        isMethodCall(
          'SKPaymentQueue#finishTransaction',
          arguments: {'handle': 1},
        )
      ]);
    });

    test('restore completed transactions', () async {
      await StoreKit.instance.paymentQueue
          .restoreCompletedTransactions(applicationUsername: 'abc');
      expect(log, <Matcher>[
        isMethodCall(
          'SKPaymentQueue#restoreCompletedTransactions',
          arguments: {'applicationUsername': 'abc'},
        )
      ]);
    });

    test('downloads not implemented', () async {
      expect(() {
        StoreKit.instance.paymentQueue.startDownloads(null);
      }, throwsUnimplementedError);
      expect(() {
        StoreKit.instance.paymentQueue.cancelDownloads(null);
      }, throwsUnimplementedError);
      expect(() {
        StoreKit.instance.paymentQueue.pauseDownloads(null);
      }, throwsUnimplementedError);
      expect(() {
        StoreKit.instance.paymentQueue.resumeDownloads(null);
      }, throwsUnimplementedError);
    });
  });

  group('SKPayment', () {
    test('create for product', () {
      final product = SKProduct.fromMap(testProduct);
      final payment = SKPayment.withProduct(product);
      expect(payment.productIdentifier, product.productIdentifier);
      expect(payment.quantity, 1);
    });

    test('equality', () {
      final product = SKProduct.fromMap(testProduct);
      final payment1 = SKPayment.withProduct(product);
      final payment2 = SKPayment.withProduct(product);
      expect(payment1, equals(payment2));
    });
  });
}

final testProductId = 'com.example.sub.monthly';
final Map<dynamic, dynamic> testProduct = {
  'productIdentifier': testProductId,
  'localizedDescription': 'Subscription',
  'localizedTitle': 'Monthly Subscription',
  'price': '2.99',
  'priceLocale': 'en_US',
  'introductoryPrice': null,
  'subscriptionPeriod': {'numberOfUnits': 1, 'unit': 'month'},
  'isDownloadable': false,
  'downloadContentLengths': null,
  'downloadContentVersion': null,
  'subscriptionGroupIdentifier': '123456',
};
final txJson =
    '{"quantity":"1","purchase_date_ms":"1539299269000","expires_date_pst":"2018-10-11 16:12:49 America/Los_Angeles","is_in_intro_offer_period":"false","expires_date":"2018-10-11 23:12:49 Etc/GMT","transaction_id":"1000000456425087","is_trial_period":"false","original_transaction_id":"1000000456423828","original_purchase_date_pst":"2018-10-11 16:02:49 America/Los_Angeles","product_id":"com.example.subscription.monthly","purchase_date":"2018-10-11 23:07:49 Etc/GMT","original_purchase_date_ms":"1539298969000","web_order_line_item_id":"1000000040774520","expires_date_ms":"1539299569000","purchase_date_pst":"2018-10-11 16:07:49 America/Los_Angeles","original_purchase_date":"2018-10-11 23:02:49 Etc/GMT"}';

final Map<String, dynamic> testTransaction = {
  'transactionIdentifier': '1000000348579',
  'transactionDate': 1539299269000,
  'payment': {'productIdentifier': testProductId, 'quantity': 1},
  'downloads': [],
  'transactionState': 'purchased'
};

class _StorePayment {
  final SKPayment payment;
  final SKProduct product;

  _StorePayment(this.payment, this.product);
}

class TestObserver extends SKPaymentTransactionObserver {
  List<SKPaymentTransaction> updatedTransactions;
  List<SKPaymentTransaction> removedTransactions;
  SKError failedRestoreError;
  bool restoreCompleted;
  _StorePayment storePayment;

  @override
  void didUpdateTransactions(
      SKPaymentQueue queue, List<SKPaymentTransaction> transactions) {
    updatedTransactions = transactions;
  }

  @override
  void didRemoveTransactions(
      SKPaymentQueue queue, List<SKPaymentTransaction> transactions) {
    super.didRemoveTransactions(queue, transactions);
    removedTransactions = transactions;
  }

  @override
  void failedToRestoreCompletedTransactions(
      SKPaymentQueue queue, SKError error) {
    super.failedToRestoreCompletedTransactions(queue, error);
    failedRestoreError = error;
  }

  @override
  void didRestoreCompletedTransactions(SKPaymentQueue queue) {
    super.didRestoreCompletedTransactions(queue);
    restoreCompleted = true;
  }

  @override
  void didReceiveStorePayment(
      SKPaymentQueue queue, SKPayment payment, SKProduct product) {
    super.didReceiveStorePayment(queue, payment, product);
    storePayment = _StorePayment(payment, product);
  }
}
