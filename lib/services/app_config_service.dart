import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../config/api_config.dart';
import '../models/dtos/app_config_dto.dart';
import '../models/dtos/api_response.dart';
import 'api_debug_service.dart';
import '../utils/http_client_helper.dart';

class AppConfigService extends ChangeNotifier {
  AppConfigDto? _config;
  String? _currentAppVersion;
  bool _isLoading = false;
  bool _isLoaded = false;

  AppConfigDto? get config => _config;
  String? get currentAppVersion => _currentAppVersion;
  bool get isLoading => _isLoading;
  bool get isLoaded => _isLoaded;

  /// Fetches app configuration from the server.
  /// Safe to call multiple times — skips if already loading.
  Future<void> fetchConfig() async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Read current app version from the device
      final packageInfo = await PackageInfo.fromPlatform();
      _currentAppVersion = packageInfo.version;
      print('📱 Current app version: $_currentAppVersion');

      // Log request
      ApiDebugService().logRequest(method: 'GET', url: ApiConfig.appConfigUrl);

      final response = await HttpClientHelper.get(
        Uri.parse(ApiConfig.appConfigUrl),
      );

      // Log response
      ApiDebugService().logResponse(
        method: 'GET',
        url: ApiConfig.appConfigUrl,
        statusCode: response.statusCode,
        responseBody: response.body,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final apiResponse = ApiResponse.fromJson(
          jsonData,
          (data) => AppConfigDto.fromJson(data as Map<String, dynamic>),
        );

        if (apiResponse.success && apiResponse.data != null) {
          _config = apiResponse.data;
          print(
            '✅ App config loaded — '
            'inReview: ${_config!.inReviewVersion}, '
            'forceUpdate: ${_config!.forceUpdateVersion}',
          );
        } else {
          print('⚠️ App config response unsuccessful: ${apiResponse.message}');
        }
      } else {
        print('❌ App config request failed: HTTP ${response.statusCode}');
        ApiDebugService().logError(
          method: 'GET',
          url: ApiConfig.appConfigUrl,
          error: 'HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error fetching app config: $e');
      ApiDebugService().logError(
        method: 'GET',
        url: ApiConfig.appConfigUrl,
        error: e.toString(),
      );
    }

    _isLoading = false;
    _isLoaded = true;
    notifyListeners();
  }

  /// Returns [true] when the current version is lower than [forceUpdateVersion].
  bool isForceUpdateRequired() {
    final forceVersion = _config?.forceUpdateVersion;
    if (!_isLoaded || forceVersion == null || _currentAppVersion == null) {
      return false;
    }
    return _compareSemver(_currentAppVersion!, forceVersion) < 0;
  }

  /// Returns [true] when the current version equals [inReviewVersion],
  /// meaning the app is currently under store review.
  bool isInReviewVersionEqual() {
    final reviewVersion = _config?.inReviewVersion;
    if (!_isLoaded || reviewVersion == null || _currentAppVersion == null) {
      return false;
    }
    return _compareSemver(_currentAppVersion!, reviewVersion) == 0;
  }

  /// Semver comparison — returns -1 if [a] < [b], 0 if equal, 1 if [a] > [b].
  int _compareSemver(String a, String b) {
    final aParts = a.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final bParts = b.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final maxLen = aParts.length > bParts.length
        ? aParts.length
        : bParts.length;
    for (var i = 0; i < maxLen; i++) {
      final ai = i < aParts.length ? aParts[i] : 0;
      final bi = i < bParts.length ? bParts[i] : 0;
      if (ai < bi) return -1;
      if (ai > bi) return 1;
    }
    return 0;
  }
}
