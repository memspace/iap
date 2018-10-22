#import "IapPlugin.h"

@interface IapCodec : NSObject
- (NSArray<NSDictionary *> *)encodeProducts:(NSArray<SKProduct *> *)products;
- (NSDictionary *)encodeProduct:(SKProduct *)product;
- (NSDictionary *)encodeProductDiscount:(SKProductDiscount *)discount API_AVAILABLE(ios(11.2));
- (NSString *)encodePaymentMode:(NSInteger)mode API_AVAILABLE(ios(11.2));
- (NSDictionary *)encodeSubscriptionPeriod:(SKProductSubscriptionPeriod *)period API_AVAILABLE(ios(11.2));
- (NSString *)encodePeriodUnit:(NSInteger)unit API_AVAILABLE(ios(11.2));
- (NSDictionary *)encodeError:(NSError *)error;
- (NSArray<NSDictionary *> *)encodeDownloads:(NSArray<SKDownload *> *)downloads;
- (NSArray<NSDictionary *> *)encodeTransactions:(NSArray<SKPaymentTransaction *> *)transactions;
- (NSDictionary *)encodeTransaction:(SKPaymentTransaction *)transaction;
- (NSDictionary *)encodePayment:(SKPayment *)payment;
- (NSString *)encodeTransactionState:(NSInteger)state;
@end

@implementation IapCodec

- (NSArray<NSDictionary *> *)encodeProducts:(NSArray<SKProduct *> *)products {
    NSMutableArray<NSDictionary *> *data = [[NSMutableArray alloc] init];
    for (SKProduct *product in products) {
        NSDictionary *record = [self encodeProduct:product];
        [data addObject:record];
    }
    return data;
}

- (NSDictionary *)encodeProduct:(SKProduct *)product {
    NSDictionary *introductoryPrice;
    NSDictionary *subscriptionPeriod;
    NSString *subscriptionGroupIdentifier;
    
    if (@available(iOS 12.0, *)){
        subscriptionGroupIdentifier = product.subscriptionGroupIdentifier;
    }
    if (@available(iOS 11.2, *)){
        introductoryPrice = [self encodeProductDiscount:product.introductoryPrice];
        subscriptionPeriod = [self encodeSubscriptionPeriod:product.subscriptionPeriod];
    }
    return @{
        @"productIdentifier": product.productIdentifier,
        @"localizedDescription": product.localizedDescription ? product.localizedDescription : [NSNull null],
        @"localizedTitle": product.localizedTitle ? product.localizedTitle : [NSNull null],
        @"price": [product.price stringValue],
        @"priceLocale": product.priceLocale ? [product.priceLocale localeIdentifier] : [NSNull null],
        @"introductoryPrice": introductoryPrice ? introductoryPrice : [NSNull null],
        @"subscriptionPeriod": subscriptionPeriod ? subscriptionPeriod : [NSNull null],
        @"isDownloadable": [NSNumber numberWithBool:product.isDownloadable],
        @"downloadContentLengths": product.downloadContentLengths ? product.downloadContentLengths :[NSNull null],
        @"downloadContentVersion": product.downloadContentVersion ? product.downloadContentVersion : [NSNull null],
        @"subscriptionGroupIdentifier": subscriptionGroupIdentifier ? subscriptionGroupIdentifier : [NSNull null],
    };
}

-(NSDictionary *)encodeProductDiscount:(SKProductDiscount *)discount API_AVAILABLE(ios(11.2)) {
    if (discount == nil) return nil;
    return @{
             @"price" : [discount.price stringValue],
             @"priceLocale" :discount.priceLocale ? [discount.priceLocale localeIdentifier] : [NSNull null],
             @"paymentMode": [self encodePaymentMode:discount.paymentMode],
             @"numberOfPeriods": [NSNumber numberWithInteger:discount.numberOfPeriods],
             @"subscriptionPeriod": [self encodeSubscriptionPeriod:discount.subscriptionPeriod],
             };
}

-(NSString *)encodePaymentMode:(NSInteger) mode API_AVAILABLE(ios(11.2)) {
    if (mode == SKProductDiscountPaymentModePayAsYouGo) {
        return @"payAsYouGo";
    } else if (mode == SKProductDiscountPaymentModePayUpFront) {
        return @"payUpFront";
    } else if (mode == SKProductDiscountPaymentModeFreeTrial) {
        return @"freeTrial";
    }
    [NSException raise:@"Invalid payment mode" format:@"Mode %ld is invalid", mode];
    return nil;
}

-(NSDictionary *)encodeSubscriptionPeriod:(SKProductSubscriptionPeriod *)period API_AVAILABLE(ios(11.2)) {
    if (period == nil) return nil;
    return @{
             @"numberOfUnits": [NSNumber numberWithInteger:period.numberOfUnits],
             @"unit": [self encodePeriodUnit:period.unit],
             };
}

-(NSString *)encodePeriodUnit:(NSInteger)unit API_AVAILABLE(ios(11.2)) {
    if (unit == SKProductPeriodUnitDay) {
        return @"day";
    } else if (unit == SKProductPeriodUnitWeek) {
        return @"week";
    } else if (unit == SKProductPeriodUnitMonth) {
        return @"month";
    } else if (unit == SKProductPeriodUnitYear) {
        return @"year";
    }
    [NSException raise:@"Invalid period unit" format:@"Unit %ld is invalid", unit];
    return nil;
}

- (NSDictionary  *)encodeError:(NSError *)error {
    NSString *code;
    if ([error.domain isEqualToString:SKErrorDomain]) {
        code = [self encodeSKErrorCode:error.code];
    } else if ([error.domain isEqualToString:NSURLErrorDomain]) {
        code = [self encodeNSUrlErrorCode:error.code];
    }
    if (code == nil) {
        code = [NSString stringWithFormat:@"%@#%@", error.domain, [@(error.code) stringValue]];
    }
    return @{
        @"code": code ? code : [NSNull null],
        @"localizedDescription": error.localizedDescription ? error.localizedDescription: [NSNull null],
    };
}

- (NSString *)encodeSKErrorCode:(NSInteger)code {
    if (code == SKErrorStoreProductNotAvailable) return @"SKErrorStoreProductNotAvailable";
    if (@available(iOS 9.3, *)) {
        if (code == SKErrorUnknown) return @"SKErrorUnknown";
        if (code == SKErrorClientInvalid) return @"SKErrorClientInvalid";
        if (code == SKErrorPaymentCancelled) return @"SKErrorPaymentCancelled";
        if (code == SKErrorPaymentInvalid) return @"SKErrorPaymentInvalid";
        if (code == SKErrorPaymentNotAllowed) return @"SKErrorPaymentNotAllowed";
        if (code == SKErrorCloudServicePermissionDenied) return @"SKErrorCloudServicePermissionDenied";
        if (code == SKErrorCloudServiceNetworkConnectionFailed) return @"SKErrorCloudServiceNetworkConnectionFailed";
    }
    if (@available(iOS 10.3, *)) {
        if (code == SKErrorCloudServiceRevoked) return @"SKErrorCloudServiceRevoked";
    }
    return nil;
}

- (NSString *)encodeNSUrlErrorCode:(NSInteger)code {
    // Common error codes list taken from: https://developer.apple.com/documentation/storekit/handling_errors?language=objc
    if (code == NSURLErrorTimedOut) return @"NSURLErrorTimedOut";
    if (code == NSURLErrorCannotFindHost) return @"NSURLErrorCannotFindHost";
    if (code == NSURLErrorCannotConnectToHost) return @"NSURLErrorCannotConnectToHost";
    if (code == NSURLErrorNetworkConnectionLost) return @"NSURLErrorNetworkConnectionLost";
    if (code == NSURLErrorNotConnectedToInternet) return @"NSURLErrorNotConnectedToInternet";
    if (code == NSURLErrorUserCancelledAuthentication) return @"NSURLErrorUserCancelledAuthentication";
    if (code == NSURLErrorSecureConnectionFailed) return @"NSURLErrorSecureConnectionFailed";
    return nil;
}

- (NSArray<NSDictionary *> *)encodeDownloads:(NSArray<SKDownload *> *)downloads {
    NSMutableArray<NSDictionary *> *data = [[NSMutableArray alloc] init];
    for (SKDownload * download in downloads) {
        NSDictionary * record = [self encodeDownload:download];
        [data addObject:record];
    }
    return data;
}

-(NSDictionary *)encodeDownload:(SKDownload *)download {
    NSString *state;
    if (@available(iOS 12.0, *)) {
        state = [self encodeDownloadState:download.state];
    }
    NSInteger timeRemaining = [[NSNumber numberWithDouble:download.timeRemaining] integerValue];
    NSDictionary *error;
    if (download.error != nil) {
        error = [self encodeError:download.error];
    }
    NSString *contentUrl;
    if (download.contentURL != nil) {
        contentUrl = [download.contentURL absoluteString];
    }
    return @{
        @"contentIdentifier": download.contentIdentifier,
        @"contentLength": [NSNumber numberWithLong:download.contentLength],
        @"contentVersion": download.contentVersion,
        @"transaction": [self encodeTransaction:download.transaction],
        @"state": state ? state: [NSNull null],
        @"progress": [NSNumber numberWithFloat:download.progress],
        @"timeRemaining": [NSNumber numberWithInteger:timeRemaining],
        @"error": error ? error : [NSNull null],
        @"contentUrl": contentUrl ? contentUrl : [NSNull null],
    };
}

- (NSArray<NSDictionary *> *)encodeTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
    NSMutableArray<NSDictionary *> *data = [[NSMutableArray alloc] init];
    for (SKPaymentTransaction *tx in transactions) {
        NSDictionary *record = [self encodeTransaction:tx];
        [data addObject:record];
    }
    return data;
}


-(NSDictionary *)encodeTransaction:(SKPaymentTransaction *)transaction {
    if (transaction == nil) return nil;
    
    NSNumber *transactionDateMSec;
    if (transaction.transactionDate != nil) {
        long msecs = transaction.transactionDate.timeIntervalSince1970 * 1000;
        transactionDateMSec = [NSNumber numberWithLong:msecs];
    }
    NSDictionary *original = [self encodeTransaction:transaction.originalTransaction];
    NSDictionary *error;
    if (transaction.error != nil) {
        error = [self encodeError:transaction.error];
    }
    return @{
        @"payment" : [self encodePayment:transaction.payment],
        @"transactionIdentifier" :transaction.transactionIdentifier ? transaction.transactionIdentifier : [NSNull null],
        @"transactionDate": transactionDateMSec ? transactionDateMSec : [NSNull null],
        @"original": original ? original : [NSNull null],
        @"error": error ? error : [NSNull null],
        @"downloads": [[NSArray alloc] init], // TODO
        @"transactionState": [self encodeTransactionState:transaction.transactionState],
    };
}

-(NSDictionary *)encodePayment:(SKPayment *)payment {
    NSNumber *simulatesAskToBuyInSandbox;
    if (@available(iOS 8.3, *)) {
        simulatesAskToBuyInSandbox = [NSNumber numberWithBool:payment.simulatesAskToBuyInSandbox];
    }
    return @{
         @"productIdentifier": payment.productIdentifier,
         @"quantity": [NSNumber numberWithInteger:payment.quantity],
         @"applicationUsername": payment.applicationUsername ? payment.applicationUsername : [NSNull null],
         @"simulatesAskToBuyInSandbox": simulatesAskToBuyInSandbox ? simulatesAskToBuyInSandbox : [NSNull null],
     };
}

-(NSString *)encodeTransactionState:(NSInteger)state {
    if (state == SKPaymentTransactionStateFailed) {
        return @"failed";
    } else if (state == SKPaymentTransactionStateDeferred) {
        return @"deferred";
    } else if (state == SKPaymentTransactionStateRestored) {
        return @"restored";
    } else if (state == SKPaymentTransactionStatePurchased) {
        return @"purchased";
    } else if (state == SKPaymentTransactionStatePurchasing) {
        return @"purchasing";
    }
    [NSException raise:@"Invalid transaction state" format:@"State %ld is invalid", state];
    return nil;
}

-(NSString *)encodeDownloadState:(NSInteger)state {
    if (state == SKDownloadStateFailed) {
        return @"failed";
    } else if (state == SKDownloadStateActive) {
        return @"active";
    } else if (state == SKDownloadStatePaused) {
        return @"paused";
    } else if (state == SKDownloadStateWaiting) {
        return @"waiting";
    } else if (state == SKDownloadStateFinished) {
        return @"finished";
    } else if (state == SKDownloadStateCancelled) {
        return @"cancelled";
    }
    [NSException raise:@"Invalid download state" format:@"State %ld is invalid", state];
    return nil;
}

@end

@interface IapStorePayment : NSObject
@property (atomic, retain) SKPayment *payment;
@property (atomic, retain) SKProduct *product;
@end

@implementation IapStorePayment

@end

@interface IapObserver : NSObject<SKPaymentTransactionObserver>

@property (atomic, retain) FlutterMethodChannel *channel;

- (BOOL)finishTransaction:(NSNumber *)handle;
- (void)enable;
- (void)disable;
@end

@implementation IapObserver{
    IapCodec *_codec;
    // Transactions received from updateTransactions callback and waiting to be finished.
    NSMutableDictionary *_unfinishedTransactions;
    // Transactions waiting to be sent to the Flutter side. Observer on the Flutter side
    // may be registered with a delay so we cannot send updated transactions immediately
    // as they may simply get lost.
    // When Flutter-side observer is registered it sends a notification which indicates
    // that we can start delivering transactions.
    NSMutableDictionary *_pendingTransactions;
    // Indicates whether events should be sent to Flutter side immediately or cached.
    BOOL _enabled;
    // Store payment waiting to be sent to the Flutter side. Similarly to
    // _pendingTransactions.
    IapStorePayment *_pendingStorePayment;
    int _nextTransactionHandle;
    
}

- (instancetype)init {
    self = [super init];
    _codec = [[IapCodec alloc] init];
    _unfinishedTransactions = [[NSMutableDictionary alloc] init];
    _pendingTransactions = [[NSMutableDictionary alloc] init];
    _enabled = NO;
    _nextTransactionHandle = 0;
    return self;
}

- (BOOL)finishTransaction:(NSNumber *)handle {
    SKPaymentTransaction *tx = [_unfinishedTransactions objectForKey:handle];
    if (tx == nil) {
        return NO;
    }
    [[SKPaymentQueue defaultQueue] finishTransaction:tx];
    [_unfinishedTransactions removeObjectForKey:handle];
    return YES;
}

- (void)enable {
    _enabled = YES;
    if (_pendingTransactions.count > 0) {
        NSDictionary *data = @{@"transactions":_pendingTransactions};
        [self.channel invokeMethod:@"SKPaymentQueue#didUpdateTransactions" arguments:data];
        [_pendingTransactions removeAllObjects];
    }
    if (_pendingStorePayment != nil) {
        NSDictionary *data = @{
            @"payment": [_codec encodePayment:_pendingStorePayment.payment],
            @"product": [_codec encodeProduct:_pendingStorePayment.product],
        };
        [self.channel invokeMethod:@"SKPaymentQueue#didReceiveStorePayment" arguments:data];
        _pendingStorePayment = nil;
    }
}

- (void)disable {
    _enabled = NO;
}

-(void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
    NSMutableDictionary *transactionMap = [[NSMutableDictionary alloc] init];
    for (SKPaymentTransaction *tx in transactions) {
        NSNumber *handle = [NSNumber numberWithInt:_nextTransactionHandle++];
        [_unfinishedTransactions setObject:tx forKey:handle];
        
        NSDictionary *txData = [_codec encodeTransaction:tx];
        [transactionMap setObject:txData forKey:handle];
    }
    if (_enabled) {
        NSDictionary *data = @{@"transactions":transactionMap};
        [self.channel invokeMethod:@"SKPaymentQueue#didUpdateTransactions" arguments:data];
    } else {
        [_pendingTransactions addEntriesFromDictionary:transactionMap];
    }
    
}

- (void)paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
    if (_enabled) {
        NSDictionary *data = @{@"transactions":[_codec encodeTransactions:transactions]};
        [self.channel invokeMethod:@"SKPaymentQueue#didRemoveTransactions" arguments:data];
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
    if (_enabled) {
        NSDictionary *data = @{@"error": [_codec encodeError:error]};
        [self.channel invokeMethod:@"SKPaymentQueue#failedToRestoreCompletedTransactions" arguments:data];
    }
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
    if (_enabled) {
        [self.channel invokeMethod:@"SKPaymentQueue#didRestoreCompletedTransactions" arguments:nil];
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedDownloads:(NSArray<SKDownload *> *)downloads {
    if (_enabled) {
        NSDictionary *data = @{@"downloads": [_codec encodeDownloads:downloads]};
        [self.channel invokeMethod:@"SKPaymentQueue#didUpdateDownloads" arguments:data];
    }
}

- (BOOL)paymentQueue:(SKPaymentQueue *)queue shouldAddStorePayment:(SKPayment *)payment
          forProduct:(SKProduct *)product {
    // We have to step away from this API contract on the Flutter side.
    // Since we do not control when Flutter observer is registered it is not clear
    // how long we should wait here, which makes this interaction fragile.
    // Instead we turn it into one-way notification similar to all other methods in this class.
    // User will receive this notification as soon as Flutter-side observer is registered,
    // and should still be able to "resume" purchase by simply adding this payment to the
    // payment queue.

    if (_enabled) {
        NSDictionary *data = @{
            @"payment": [_codec encodePayment:payment],
            @"product": [_codec encodeProduct:product],
        };
        [self.channel invokeMethod:@"SKPaymentQueue#didReceiveStorePayment" arguments:data];
    } else {
        // Only keep track of the latest payment received from the App Store as it represents
        // most recent user action.
        _pendingStorePayment = [[IapStorePayment alloc] init];
        _pendingStorePayment.payment = payment;
        _pendingStorePayment.product = product;
    }
    
    return NO;
}

@end

static NSString *const CHANNEL_NAME = @"flutter.memspace.io/iap";

@interface IapPlugin()
    @property(nonatomic, retain) FlutterMethodChannel *channel;
    @property(nonatomic, retain) IapObserver *observer;
@end

@implementation IapPlugin {
    IapCodec *_codec;
    NSMutableDictionary<NSValue *, FlutterResult> *_productRequests;
    NSMutableDictionary<NSValue *, FlutterResult> *_refreshReceiptRequests;
    NSArray<SKProduct *> *_products;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
    FlutterMethodChannel *channel = [FlutterMethodChannel methodChannelWithName:CHANNEL_NAME binaryMessenger:[registrar messenger]];
    IapPlugin *instance = [[IapPlugin alloc] init];
    IapObserver *observer = [[IapObserver alloc] init];
    instance.channel = channel;
    observer.channel = channel;
    instance.observer = observer;

    [registrar addMethodCallDelegate:instance channel:channel];
    [[SKPaymentQueue defaultQueue] addTransactionObserver:observer];
}

- (instancetype)init {
    self = [super init];
    _codec = [[IapCodec alloc] init];
    _productRequests = [[NSMutableDictionary alloc] init];
    _refreshReceiptRequests = [[NSMutableDictionary alloc] init];
    _products = [[NSArray alloc] init];
    return self;
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    if ([@"StoreKit#products" isEqualToString:call.method]) {
        NSArray<NSString *> *ids = (NSArray<NSString *> *)call.arguments[@"productIdentifiers"];
        [self sendProductsRequest:ids result:result];
    } else if ([@"StoreKit#refreshReceipt" isEqualToString:call.method]) {
        [self refreshReceipt:result];
    } else if ([@"StoreKit#appStoreReceiptUrl" isEqualToString:call.method]) {
        NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
        result(receiptURL.absoluteString);
    } else if ([@"SKPaymentQueue#canMakePayments" isEqualToString:call.method]) {
        BOOL canMakePayments = [SKPaymentQueue canMakePayments];
        result([NSNumber numberWithBool:canMakePayments]);
    } else if ([@"SKPaymentQueue#addPayment" isEqualToString:call.method]) {
        NSDictionary *data = (NSDictionary *)call.arguments[@"payment"];
        [self addPayment:data result:result];
    } else if ([@"SKPaymentQueue#finishTransaction" isEqualToString:call.method]) {
        NSNumber *handle = call.arguments[@"handle"];
        [self finishTransaction:handle result:result];
    } else if ([@"SKPaymentQueue#restoreCompletedTransactions" isEqualToString:call.method]) {
        NSString *applicationUsername = call.arguments[@"applicationUsername"];
        [self restoreTransactions:applicationUsername result:result];
    } else if ([@"SKPaymentQueue#enableObserver" isEqualToString:call.method]) {
        [_observer enable];
        result(nil);
    } else if ([@"SKPaymentQueue#disableObserver" isEqualToString:call.method]) {
        [_observer disable];
        result(nil);
    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (void)sendProductsRequest:(NSArray<NSString *> *)identifiers result:(FlutterResult)result {
    SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithArray:identifiers]];
    [request setDelegate:self];
    [_productRequests setObject:result forKey:[NSValue valueWithNonretainedObject:request]];
    [request start];
}

- (void)productsRequest:(nonnull SKProductsRequest *)request didReceiveResponse:(nonnull SKProductsResponse *)response {
    NSValue *key = [NSValue valueWithNonretainedObject:request];
    FlutterResult result = [_productRequests objectForKey:key];
    if (result == nil) return;
    _products = response.products;
    [_productRequests removeObjectForKey:key];
    NSDictionary *payload = @{
        @"products": [_codec encodeProducts:response.products],
        @"invalidProductIdentifiers": response.invalidProductIdentifiers,
    };
    result(payload);
}

- (void)refreshReceipt:(FlutterResult)result {
    SKReceiptRefreshRequest *request = [[SKReceiptRefreshRequest alloc] init];
    [request setDelegate:self];
    [_refreshReceiptRequests setObject:result forKey:[NSValue valueWithNonretainedObject:request]];
    [request start];
}

- (void)requestDidFinish:(SKRequest *)request {
    if ([request isKindOfClass:[SKReceiptRefreshRequest class]]) {
        NSValue *key = [NSValue valueWithNonretainedObject:request];
        FlutterResult result = [_refreshReceiptRequests objectForKey:key];
        if (result == nil) return;
        [_refreshReceiptRequests removeObjectForKey:key];
        result(nil);
    }
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    if ([request isKindOfClass:[SKReceiptRefreshRequest class]]) {
        NSValue *key = [NSValue valueWithNonretainedObject:request];
        FlutterResult result = [_refreshReceiptRequests objectForKey:key];
        if (result == nil) return;
        [_refreshReceiptRequests removeObjectForKey:key];
        NSDictionary *errorData = [_codec encodeError:error];
        NSString *code = [errorData objectForKey:@"code"];
        result([FlutterError errorWithCode:code message:error.localizedDescription details:nil]);
    }
}

- (void)addPayment:(nonnull NSDictionary *)paymentData result:(FlutterResult)result {
    NSString *productId = [paymentData objectForKey:@"productIdentifier"];
    SKProduct *product = [self lookupProduct:productId];
    if (product == nil) {
        NSDictionary *details = @{
            @"productId": productId ? productId : [NSNull null],
            @"productsLength": [NSNumber numberWithInteger:_products.count],
        };
        result([FlutterError errorWithCode:@"IAPStoreKitProductMissing" message:@"Must fetch products before adding payments" details:details]);
        return;
    }
    SKMutablePayment *payment = [SKMutablePayment paymentWithProduct: product];
    NSNumber *quantity = [paymentData objectForKey:@"quantity"];
    NSString *applicationUsername = [paymentData objectForKey:@"applicationUsername"];
    NSNumber *simulatesAskToBuyInSandbox = [paymentData objectForKey:@"simulatesAskToBuyInSandbox"];
    
    payment.quantity = [quantity integerValue];
    payment.applicationUsername = applicationUsername;
    if (@available(iOS 8.3, *)) {
        if ([simulatesAskToBuyInSandbox isEqual:[NSNull null]] == NO) {
            payment.simulatesAskToBuyInSandbox = [simulatesAskToBuyInSandbox boolValue];
        }
    }
    
    [[SKPaymentQueue defaultQueue] addPayment:payment];
    result(nil);
}

- (SKProduct *)lookupProduct:(NSString *)productId {
    for (SKProduct *product in _products) {
        if ([productId isEqualToString:product.productIdentifier]) return product;
    }
    return nil;
}

- (void)finishTransaction:(nonnull NSNumber *)handle result:(FlutterResult)result {
    BOOL finished = [self.observer finishTransaction:handle];
    if (finished == YES) {
        result(nil);
    } else {
        result([FlutterError errorWithCode:@"IAPStoreKitTransactionMissing" message:@"No transaction found for provided identifier" details:nil]);
    }
}

- (void)restoreTransactions:(nonnull NSString *)applicationUsername result:(FlutterResult)result {
    if ([applicationUsername isEqual:[NSNull null]]) {
        [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
    } else {
        [[SKPaymentQueue defaultQueue] restoreCompletedTransactionsWithApplicationUsername:applicationUsername];
    }
    result(nil);
}

@end
