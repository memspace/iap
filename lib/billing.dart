// Copyright (c) 2018, Anatoly Pulyaevskiy.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library iap.billing;

import 'src/server.dart';
import 'src/subscription_store.dart';

abstract class Billing {
  /// Creates a new subscription store which uses provided billing [server]
  /// implementation.
  static SubscriptionStore createSubscriptionStore(
      SubscriptionBillingServer server) {
    return SubscriptionStore(server);
  }
}
