import 'dart:io';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import 'http_client_helper.dart';

/// Authenticated API client that automatically handles token refresh on 401 errors
class AuthenticatedApiClient {
  final AuthService _authService;

  AuthenticatedApiClient(this._authService);

  /// Make an authenticated GET request with automatic token refresh on 401
  Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
    bool allowSelfSigned = true,
    bool retryOn401 = true,
  }) async {
    return _makeRequest(
      () => _getWithToken(url, headers, allowSelfSigned),
      retryOn401: retryOn401,
    );
  }

  /// Make an authenticated POST request with automatic token refresh on 401
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    bool allowSelfSigned = true,
    bool retryOn401 = true,
  }) async {
    return _makeRequest(
      () => _postWithToken(url, headers, body, allowSelfSigned),
      retryOn401: retryOn401,
    );
  }

  /// Make an authenticated PUT request with automatic token refresh on 401
  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    bool allowSelfSigned = true,
    bool retryOn401 = true,
  }) async {
    return _makeRequest(
      () => _putWithToken(url, headers, body, allowSelfSigned),
      retryOn401: retryOn401,
    );
  }

  /// Make an authenticated DELETE request with automatic token refresh on 401
  Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    bool allowSelfSigned = true,
    bool retryOn401 = true,
  }) async {
    return _makeRequest(
      () => _deleteWithToken(url, headers, body, allowSelfSigned),
      retryOn401: retryOn401,
    );
  }

  /// Internal method to make request with automatic retry on 401
  Future<http.Response> _makeRequest(
    Future<http.Response> Function() requestFn, {
    bool retryOn401 = true,
  }) async {
    // Make initial request
    var response = await requestFn();

    // If we get a 401 and retry is enabled, try to refresh token and retry once
    if (response.statusCode == 401 && retryOn401) {
      print('🔄 Got 401 error, attempting to refresh token...');
      
      // Attempt to refresh token
      final refreshError = await _authService.refreshToken();
      
      if (refreshError == null) {
        // Token refreshed successfully, retry the request
        print('✅ Token refreshed, retrying request...');
        response = await requestFn();
      } else {
        print('❌ Token refresh failed: $refreshError');
        // Token refresh failed, return the original 401 response
      }
    }

    return response;
  }

  /// GET request with current token
  Future<http.Response> _getWithToken(
    Uri url,
    Map<String, String>? headers,
    bool allowSelfSigned,
  ) async {
    final token = _authService.token;
    final headersWithAuth = Map<String, String>.from(headers ?? {});
    
    if (token != null) {
      headersWithAuth['Authorization'] = 'Bearer $token';
    }

    return HttpClientHelper.get(
      url,
      headers: headersWithAuth,
      allowSelfSigned: allowSelfSigned,
    );
  }

  /// POST request with current token
  Future<http.Response> _postWithToken(
    Uri url,
    Map<String, String>? headers,
    Object? body,
    bool allowSelfSigned,
  ) async {
    final token = _authService.token;
    final headersWithAuth = Map<String, String>.from(headers ?? {});
    
    if (token != null) {
      headersWithAuth['Authorization'] = 'Bearer $token';
    }

    return HttpClientHelper.post(
      url,
      headers: headersWithAuth,
      body: body,
      allowSelfSigned: allowSelfSigned,
    );
  }

  /// PUT request with current token
  Future<http.Response> _putWithToken(
    Uri url,
    Map<String, String>? headers,
    Object? body,
    bool allowSelfSigned,
  ) async {
    final token = _authService.token;
    final headersWithAuth = Map<String, String>.from(headers ?? {});
    
    if (token != null) {
      headersWithAuth['Authorization'] = 'Bearer $token';
    }

    return HttpClientHelper.put(
      url,
      headers: headersWithAuth,
      body: body,
      allowSelfSigned: allowSelfSigned,
    );
  }

  /// DELETE request with current token
  Future<http.Response> _deleteWithToken(
    Uri url,
    Map<String, String>? headers,
    Object? body,
    bool allowSelfSigned,
  ) async {
    final token = _authService.token;
    final headersWithAuth = Map<String, String>.from(headers ?? {});
    
    if (token != null) {
      headersWithAuth['Authorization'] = 'Bearer $token';
    }

    return HttpClientHelper.delete(
      url,
      headers: headersWithAuth,
      body: body,
      allowSelfSigned: allowSelfSigned,
    );
  }
}



