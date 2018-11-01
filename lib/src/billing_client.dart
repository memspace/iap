library billing_client;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

part 'billing_client_data.dart';
part 'billing_client_types.dart';

class BillingClientException implements Exception {
  /// Response code, one of [BillingResponse] constants.
  final int code;
  final String message;

  BillingClientException(this.code, this.message);

  @override
  String toString() {
    return 'BillingException#$code($message)';
  }
}

/// Main interface for communication between the billing library and user
/// application code.
///
/// It provides convenience methods for in-app billing. You can create one
/// instance of this class for your application and use it to process in-app
/// billing operations.
///
/// After instantiating, you must perform setup in order to start using the
/// object. To perform setup, call the [startConnection] method and provide a
/// listener; that listener will be notified when setup is complete, after
/// which (and not before) you may start calling other methods. After setup is
/// complete, you will typically want to request an inventory of owned items
/// and subscriptions. See [queryPurchases] and [querySkuDetails].
///
/// When you are done with this object, don't forget to call [endConnection]
/// to ensure proper cleanup. This object holds a binding to the in-app billing
/// service and the manager to handle broadcast events, which will leak unless
/// you dispose it correctly.
class BillingClient {
  static const MethodChannel channel = MethodChannel('flutter.memspace.io/iap');

  static final BillingClient instance = BillingClient._();

  Future _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'BillingClient#disconnected':
        _disconnected();
        break;
      case 'BillingClient#purchasesUpdated':
        final args = Map<String, Object>.from(call.arguments);
        final int responseCode = args['responseCode'];
        final list = List.from(args['purchases']);
        final purchases = list.map((item) {
          return Purchase.fromMap(Map<String, Object>.from(item));
        }).toList(growable: false);
        _listener.onPurchasesUpdated(responseCode, purchases);
        break;
      default:
        throw new UnimplementedError('Method ${call.method} not implemented.');
    }
  }

  BillingClient._() {
    channel.setMethodCallHandler(_handleMethodCall);
  }

  PurchasesUpdatedListener _listener;

  /// Sets listener for purchase updates, replaces any previously set listener.
  ///
  void setListener(PurchasesUpdatedListener listener) {
    _listener = listener;
  }

  /// Consumes a given in-app product.
  ///
  /// Returns response code of consume operation, which is one of
  /// [BillingResponse] constants.
  ///
  /// Consuming can only be done on an item that's owned, and as a result of
  /// consumption, the user will no longer own it.
  Future<int> consume(String purchaseToken) async {
    final int result =
        await channel.invokeMethod('BillingClient#consume', purchaseToken);
    if (result == 0) return result;
    throw BillingClientException(result, 'Failed to consume purchase.');
  }

  /// Closes the connection and releases all held resources such as service
  /// connections.
  ///
  /// Call this method once you are done with this BillingClient reference.
  Future<void> endConnection() async {
    _onDisconnect = null;
    await channel.invokeMethod('BillingClient#endConnection');
  }

  /// Check if specified feature or capability is supported by the Play Store.
  ///
  /// [feature] is one of [FeatureType] constants.
  Future<int> isFeatureSupported(String feature) async {
    final int responseCode =
        await channel.invokeMethod('BillingClient#isFeatureSupported', feature);
    return responseCode;
  }

  /// Checks if the client is currently connected to the service, so that
  /// requests to other methods will succeed.
  ///
  /// Returns true if the client is currently connected to the service, false
  /// otherwise.
  ///
  /// Note: It also means that [SkuType.kInApp] items are supported for purchasing,
  /// queries and all other actions. If you need to check support for
  /// [SkuType.kSubs] or something different, use [isFeatureSupported] method.
  Future<bool> isReady() async {
    final bool ready = await channel.invokeMethod('BillingClient#isReady');
    return ready;
  }

  /// Initiate the billing flow for an in-app purchase or subscription.
  ///
  /// Shows the Google Play purchase screen. The result will be delivered via
  /// registered listener.
  Future<void> launchBillingFlow(BillingFlowParams params) async {
    assert(params != null);
    final int responseCode = await channel.invokeMethod(
        'BillingClient#launchBillingFlow', params.toMap());
    if (responseCode == 0) return;
    throw BillingClientException(responseCode, 'Failed to launch billing flow.');
  }

  /// Initiate a flow to confirm the change of price for an item subscribed by
  /// the user.
  ///
  /// [skuDetails] specifies the SKU that has the pending price change.
  ///
  /// When the price of a user subscribed item has changed, launch this flow to
  /// take users to a screen with price change information. User can confirm
  /// the new price or cancel the flow.
  Future<void> launchPriceChangeConfirmationFlow(
      {SkuDetails skuDetails}) async {
    assert(skuDetails != null);

    final int responseCode = await channel.invokeMethod(
      'BillingClient#launchPriceChangeConfirmationFlow',
      skuDetails._handle,
    );
    if (responseCode == 0) return;
    throw BillingClientException(
        responseCode, 'Failed to launch price change confirmation flow.');
  }

  /// Loads a rewarded sku specified by [skuDetails].
  ///
  /// There is no guarantee that a rewarded sku will always be available. After
  /// a successful response, only then should the offer be given to a user to
  /// obtain a rewarded item and call [launchBillingFlow].
  ///
  /// If the rewarded sku is available, then returned Future completes
  /// successfully. Otherwise it completes with [BillingClientException] containing
  /// response code of the operation (normally
  /// [BillingResponse.kItemUnavailable]).
  Future<void> loadRewardedSku({SkuDetails skuDetails}) async {
    assert(skuDetails != null);

    final int responseCode = await channel.invokeMethod(
        'BillingClient#loadRewardedSku', skuDetails._handle);
    if (responseCode == 0) return;
    throw BillingClientException(responseCode, 'Failed to load rewarded SKU.');
  }

  /// Returns the most recent purchase made by the user for each SKU type, even
  /// if that purchase is expired, canceled, or consumed.
  ///
  /// [skuType] must be one of [SkuType] constants.
  ///
  /// If query fails then returned Future completes with [BillingClientException]
  /// containing response code of the error.
  Future<List<Purchase>> queryPurchaseHistory(String skuType) async {
    final result = await channel.invokeMethod(
        'BillingClient#queryPurchaseHistory', skuType);
    final response = Map<String, Object>.from(result);
    final code = response['responseCode'] as int;
    if (code != 0) {
      throw new BillingClientException(code, 'Failed to fetch purchase history.');
    }
    final list = List.from(response['purchases']);
    return list.map((item) {
      return Purchase.fromMap(Map<String, Object>.from(item));
    }).toList(growable: false);
  }

  /// Get purchases details for all the items bought within your app.
  ///
  /// This method uses a cache of Google Play Store app without initiating a
  /// network request.
  ///
  /// [skuType] must be one of [SkuType] constants.
  ///
  /// If query fails then returned Future completes with [BillingClientException]
  /// containing response code of the error.
  ///
  /// Note: It's recommended for security purposes to go through purchases
  /// verification on your backend (if you have one) by calling the following
  /// API: https://developers.google.com/android-publisher/api-ref/purchases/products/get
  Future<List<Purchase>> queryPurchases(String skuType) async {
    final result =
        await channel.invokeMethod('BillingClient#queryPurchases', skuType);
    final response = Map<String, Object>.from(result);
    final code = response['responseCode'] as int;
    if (code != 0) {
      throw new BillingClientException(code, 'Failed to fetch purchases.');
    }
    final list = List.from(response['purchases']);
    return list.map((item) {
      return Purchase.fromMap(Map<String, Object>.from(item));
    }).toList(growable: false);
  }

  /// Perform a network query to get SKU details and return the result.
  Future<List<SkuDetails>> querySkuDetails(
      {String skuType, List<String> skus}) async {
    final args = {'skuType': skuType, 'skus': skus};
    final result =
        await channel.invokeMethod('BillingClient#querySkuDetails', args);

    final data = new Map<String, Object>.from(result);
    final int responseCode = data['responseCode'];
    if (responseCode != 0) {
      throw new BillingClientException(responseCode, 'Failed to fetch SKU details.');
    }

    final list = new List.from(data['skuDetails']);
    return list.map((item) {
      return new SkuDetails.fromMap(Map<String, Object>.from(item));
    }).toList(growable: false);
  }

  /// Developers are able to specify whether this app is child directed or not
  /// to ensure compliance with US COPPA & EEA age of consent laws.
  ///
  /// This is most relevant for rewarded SKUs as child directed applications
  /// are explicitly not allowed to collect information that can be used to
  /// personalize the rewarded videos to the user.
  Future<void> setChildDirected(int childDirected) async {
    await channel.invokeMethod('BillingClient#setChildDirected', childDirected);
  }

  /// Starts up this client's setup process asynchronously.
  ///
  /// Returned Future completes with [BillingResponse.kOk] on success, otherwise
  /// it completes with [BillingClientException] containing response code.
  ///
  /// [onDisconnect] callback can be used to get notified when this client
  /// looses connection and indicates that you need initialize new connection
  /// using [startConnection] in order to continue using this client.
  Future<int> startConnection({@required VoidCallback onDisconnect}) async {
    assert(
        _listener != null,
        'Must set purchase listener before starting billing connection. '
        'See BillingClient.instance.setListener().');
    assert(_onDisconnect == null,
        'Attempting to start new connection while there is already an active one.');

    _onDisconnect = onDisconnect;
    final int result =
        await channel.invokeMethod('BillingClient#startConnection');
    if (result == 0) return result;
    _onDisconnect = null;
    throw BillingClientException(result, 'Failed to start billing connection.');
  }

  VoidCallback _onDisconnect;
  void _disconnected() {
    if (_onDisconnect != null) {
      _onDisconnect = null;
      _onDisconnect();
    }
  }
}
