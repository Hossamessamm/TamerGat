import 'package:flutter/material.dart';

class ApiLog {
  final DateTime timestamp;
  final String method;
  final String url;
  final Map<String, String>? headers;
  final String? requestBody;
  final int? statusCode;
  final String? responseBody;
  final String? error;

  ApiLog({
    required this.timestamp,
    required this.method,
    required this.url,
    this.headers,
    this.requestBody,
    this.statusCode,
    this.responseBody,
    this.error,
  });
}

class ApiDebugService extends ChangeNotifier {
  static final ApiDebugService _instance = ApiDebugService._internal();
  factory ApiDebugService() => _instance;
  ApiDebugService._internal();

  final List<ApiLog> _logs = [];
  List<ApiLog> get logs => List.unmodifiable(_logs);

  void logRequest({
    required String method,
    required String url,
    Map<String, String>? headers,
    String? body,
  }) {
    final log = ApiLog(
      timestamp: DateTime.now(),
      method: method,
      url: url,
      headers: headers,
      requestBody: body,
    );
    _logs.insert(0, log);
    
    // Schedule notification after the current frame to avoid build-time updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
    
    print('🔵 API Request: $method $url');
    if (headers != null) print('Headers: $headers');
    if (body != null) print('Body: $body');
  }

  void logResponse({
    required String method,
    required String url,
    required int statusCode,
    String? responseBody,
  }) {
    // Find the matching request log and update it
    final index = _logs.indexWhere((log) => log.url == url && log.method == method && log.statusCode == null);
    if (index != -1) {
      final oldLog = _logs[index];
      _logs[index] = ApiLog(
        timestamp: oldLog.timestamp,
        method: oldLog.method,
        url: oldLog.url,
        headers: oldLog.headers,
        requestBody: oldLog.requestBody,
        statusCode: statusCode,
        responseBody: responseBody,
      );
    }
    
    // Schedule notification after the current frame to avoid build-time updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
    
    print('🟢 API Response: $statusCode');
    if (responseBody != null) print('Response: $responseBody');
  }

  void logError({
    required String method,
    required String url,
    required String error,
  }) {
    final index = _logs.indexWhere((log) => log.url == url && log.method == method && log.error == null);
    if (index != -1) {
      final oldLog = _logs[index];
      _logs[index] = ApiLog(
        timestamp: oldLog.timestamp,
        method: oldLog.method,
        url: oldLog.url,
        headers: oldLog.headers,
        requestBody: oldLog.requestBody,
        error: error,
      );
    }
    
    // Schedule notification after the current frame to avoid build-time updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
    
    print('🔴 API Error: $error');
  }

  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }
}
