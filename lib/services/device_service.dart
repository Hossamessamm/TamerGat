import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class DeviceService {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  
  /// Get or generate a unique device ID
  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if device ID already exists
    String? deviceId = prefs.getString(ApiConfig.deviceIdKey);
    
    if (deviceId != null && deviceId.isNotEmpty) {
      return deviceId;
    }
    
    // Generate new device ID
    deviceId = await _generateDeviceId();
    
    // Save device ID
    await prefs.setString(ApiConfig.deviceIdKey, deviceId);
    
    return deviceId;
  }
  
  /// Generate a unique device ID based on platform
  static Future<String> _generateDeviceId() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return 'android_${androidInfo.id}';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return 'ios_${iosInfo.identifierForVendor}';
      } else if (Platform.isWindows) {
        final windowsInfo = await _deviceInfo.windowsInfo;
        return 'windows_${windowsInfo.deviceId}';
      } else if (Platform.isLinux) {
        final linuxInfo = await _deviceInfo.linuxInfo;
        return 'linux_${linuxInfo.machineId}';
      } else if (Platform.isMacOS) {
        final macInfo = await _deviceInfo.macOsInfo;
        return 'macos_${macInfo.systemGUID}';
      } else {
        // Fallback: generate random ID
        return 'web_${DateTime.now().millisecondsSinceEpoch}';
      }
    } catch (e) {
      // Fallback: generate timestamp-based ID
      return 'device_${DateTime.now().millisecondsSinceEpoch}';
    }
  }
  
  /// Clear stored device ID (useful for testing)
  static Future<void> clearDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ApiConfig.deviceIdKey);
  }
}
