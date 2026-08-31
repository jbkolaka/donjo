library;

import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

class BackendUri {
  static const String renderUrl = 'https://donjo-api-qwxb.onrender.com';
  static const int port = 8080;
  static const String desktopUrl = 'http://localhost:$port';

  static String backendUri = desktopUrl;

  static Future<String> resolve() async {
    if (kIsWeb) {
      return backendUri = renderUrl;
    }
    if (Platform.isAndroid) {
      final android = await DeviceInfoPlugin().androidInfo;
      if (!android.isPhysicalDevice) {
        return backendUri = 'http://10.0.2.2:$port';
      }
      return backendUri = 'http://127.0.0.1:$port';
    }
    if (Platform.isIOS) {
      final ios = await DeviceInfoPlugin().iosInfo;
      if (!ios.isPhysicalDevice) {
        return backendUri = 'http://127.0.0.1:$port';
      }
      return backendUri = renderUrl;
    }
    return backendUri = desktopUrl;
  }
}
