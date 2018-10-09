import 'dart:async';

import 'package:flutter/services.dart';

export 'src/store_kit.dart';

class Iap {
  static const MethodChannel _channel = const MethodChannel('iap');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
