import 'package:flutter/services.dart';

class ScreenProtectionService {
  static const MethodChannel _channel = MethodChannel('com.tamergat.app/screen_protection');

  static Future<void> enable() async {
    try {
      await _channel.invokeMethod('enableScreenshotProtection');
    } on PlatformException catch (e) {
      print("Failed to enable screenshot protection: '${e.message}'.");
    }
  }

  static Future<void> disable() async {
    try {
      await _channel.invokeMethod('disableScreenshotProtection');
    } on PlatformException catch (e) {
      print("Failed to disable screenshot protection: '${e.message}'.");
    }
  }
}
