import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';
import '../config/api_config.dart';

class HttpClientHelper {
  static CookieJar? _cookieJar;
  static bool _isInitialized = false;

  /// Initialize cookie jar (call this once at app startup)
  static Future<void> initCookieJar() async {
    if (_isInitialized) return;
    
    try {
      final directory = await getApplicationDocumentsDirectory();
      _cookieJar = PersistCookieJar(
        storage: FileStorage('${directory.path}/.cookies/'),
      );
      _isInitialized = true;
      print('✅ Cookie jar initialized');
    } catch (e) {
      print('⚠️ Failed to initialize cookie jar: $e');
      // Fallback to memory cookie jar
      _cookieJar = CookieJar();
      _isInitialized = true;
    }
  }

  /// Get cookie jar instance
  static CookieJar get cookieJar {
    if (!_isInitialized) {
      throw Exception('Cookie jar not initialized. Call initCookieJar() first.');
    }
    return _cookieJar!;
  }

  /// Creates an HTTP client that accepts self-signed certificates
  /// This should only be used in development/testing environments
  static http.Client createClient({bool allowSelfSigned = true}) {
    if (allowSelfSigned) {
      final ioClient = HttpClient()
        ..badCertificateCallback = (X509Certificate cert, String host, int port) {
          // In production, you should validate the certificate properly
          // For now, we accept all certificates (including self-signed)
          print('⚠️ Accepting certificate for $host:$port');
          return true;
        };
      
      return IOClient(ioClient);
    }
    
    return http.Client();
  }

  /// Add cookies to request headers
  static Future<Map<String, String>> _addCookiesToHeaders(
    Uri url,
    Map<String, String>? existingHeaders,
  ) async {
    final headers = Map<String, String>.from(existingHeaders ?? {});
    
    // Add Tenant ID
    headers['x-tenant-id'] = ApiConfig.tenantId;
    print('🔑 Added x-tenant-id header: ${ApiConfig.tenantId} for ${url.host}${url.path}');
    
    if (_isInitialized && _cookieJar != null) {
      try {
        final cookies = await _cookieJar!.loadForRequest(url);
        if (cookies.isNotEmpty) {
          final cookieHeader = cookies.map((cookie) => '${cookie.name}=${cookie.value}').join('; ');
          headers['Cookie'] = cookieHeader;
          print('🍪 Loaded ${cookies.length} cookie(s) for ${url.host}${url.path}');
          for (final cookie in cookies) {
            final valuePreview = cookie.value.length > 30 ? '${cookie.value.substring(0, 30)}...' : cookie.value;
            print('   - ${cookie.name}=$valuePreview (domain: ${cookie.domain ?? "null"}, path: ${cookie.path ?? "null"}, value length: ${cookie.value.length})');
          }
          print('🍪 Cookie header: ${cookieHeader.length > 150 ? "${cookieHeader.substring(0, 150)}..." : cookieHeader}');
        } else {
          print('🍪 No cookies found for ${url.host}${url.path}');
        }
      } catch (e) {
        print('⚠️ Error loading cookies: $e');
      }
    }
    
    return headers;
  }

  /// Save cookies from response
  static Future<void> _saveCookiesFromResponse(Uri url, http.Response response) async {
    if (_isInitialized && _cookieJar != null) {
      try {
        final cookies = <Cookie>[];
        
        // Get Set-Cookie header(s)
        // The http package may combine multiple Set-Cookie headers
        final setCookieHeader = response.headers['set-cookie'];
        
        if (setCookieHeader != null && setCookieHeader.isNotEmpty) {
          // Parse Set-Cookie header(s)
          // Multiple cookies might be separated by commas, but we need to be careful
          // because cookie values can contain commas. We'll split on ', ' (comma + space)
          // which is the standard separator for multiple Set-Cookie headers when combined
          final cookieStrings = _splitSetCookieHeaders(setCookieHeader);
          
          for (final cookieHeader in cookieStrings) {
            if (cookieHeader.trim().isNotEmpty) {
              // Parse Set-Cookie header: "name=value; Path=/; HttpOnly; Secure"
              final parts = cookieHeader.trim().split(';');
              if (parts.isNotEmpty) {
                final nameValue = parts[0].trim().split('=');
                if (nameValue.length == 2) {
                  final cookie = Cookie(nameValue[0].trim(), nameValue[1].trim());
                  
                  // Parse additional attributes
                  for (var i = 1; i < parts.length; i++) {
                    final attr = parts[i].trim().toLowerCase();
                    if (attr.startsWith('path=')) {
                      cookie.path = attr.substring(5).trim();
                    } else if (attr.startsWith('domain=')) {
                      // Remove leading dot if present (cookie_jar handles this)
                      final domain = attr.substring(7).trim();
                      cookie.domain = domain.startsWith('.') ? domain.substring(1) : domain;
                    } else if (attr == 'httponly') {
                      cookie.httpOnly = true;
                    } else if (attr == 'secure') {
                      cookie.secure = true;
                    } else if (attr.startsWith('max-age=')) {
                      // Handle max-age if needed
                      final maxAge = int.tryParse(attr.substring(8).trim());
                      if (maxAge != null) {
                        cookie.maxAge = maxAge;
                      }
                    } else if (attr.startsWith('expires=')) {
                      // Handle expires attribute if needed
                      // Note: Cookie class doesn't have expires, but we can set maxAge
                    }
                  }
                  
                  // Set default path if not specified (RFC 6265: default is the request path)
                  // For cookies without path, use "/" to make them available for all paths
                  if (cookie.path == null || cookie.path!.isEmpty) {
                    cookie.path = '/';
                  }
                  
                  // Set default domain if not specified (use request host)
                  // Don't set domain if it's null - let cookie_jar handle it
                  // Setting domain explicitly can cause issues with subdomain matching
                  // Only set if explicitly provided by server
                  // if (cookie.domain == null || cookie.domain!.isEmpty) {
                  //   cookie.domain = url.host;
                  // }
                  
                  cookies.add(cookie);
                }
              }
            }
          }
        }
        
        if (cookies.isNotEmpty) {
          await _cookieJar!.saveFromResponse(url, cookies);
          print('✅ Saved ${cookies.length} cookie(s) from response for ${url.host}${url.path}');
          for (final cookie in cookies) {
            print('   - ${cookie.name} (domain: ${cookie.domain ?? "default"}, path: ${cookie.path ?? "/"}, HttpOnly: ${cookie.httpOnly}, Secure: ${cookie.secure})');
          }
        }
      } catch (e) {
        print('⚠️ Error saving cookies: $e');
      }
    }
  }

  /// Split combined Set-Cookie headers
  /// Handles the case where multiple Set-Cookie headers are combined with commas
  static List<String> _splitSetCookieHeaders(String headerValue) {
    final cookies = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;
    
    for (int i = 0; i < headerValue.length; i++) {
      final char = headerValue[i];
      
      if (char == '"') {
        inQuotes = !inQuotes;
        buffer.write(char);
      } else if (char == ',' && !inQuotes) {
        // Check if this comma is followed by a space and a cookie name pattern
        // (Set-Cookie headers typically start with name=value)
        if (i + 1 < headerValue.length && headerValue[i + 1] == ' ') {
          // Check if the next part looks like a cookie (has an = sign)
          final nextPart = headerValue.substring(i + 2).trim();
          if (nextPart.contains('=') && !nextPart.startsWith('expires=') && 
              !nextPart.startsWith('path=') && !nextPart.startsWith('domain=')) {
            // This looks like a new cookie, split here
            cookies.add(buffer.toString().trim());
            buffer.clear();
            i++; // Skip the space after comma
            continue;
          }
        }
        buffer.write(char);
      } else {
        buffer.write(char);
      }
    }
    
    // Add the last cookie
    if (buffer.isNotEmpty) {
      cookies.add(buffer.toString().trim());
    }
    
    // If we didn't find multiple cookies, return the original as a single item
    return cookies.isEmpty ? [headerValue] : cookies;
  }

  /// Request timeout in seconds
  static const int _timeoutSeconds = 25;

  /// Log API response to console (all responses)
  static void _logResponse(String method, Uri url, http.Response response) {
    final contentType = response.headers['content-type'] ?? '';
    final isBinary = contentType.contains('image/') ||
        contentType.contains('octet-stream') ||
        contentType.contains('application/pdf');
    final bodyPreview = isBinary
        ? '[binary, ${response.bodyBytes.length} bytes]'
        : (response.body.length > 3000
            ? '${response.body.substring(0, 3000)}...[truncated, total ${response.body.length} chars]'
            : response.body);
    print('📥 Response $method ${url.path} → ${response.statusCode}');
    print('📥 Body: $bodyPreview');
  }

  /// Generic GET request with automatic client cleanup, cookie support, and timeout
  static Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
    bool allowSelfSigned = true,
  }) async {
    final client = createClient(allowSelfSigned: allowSelfSigned);
    try {
      final headersWithCookies = await _addCookiesToHeaders(url, headers);
      final response = await client
          .get(url, headers: headersWithCookies)
          .timeout(Duration(seconds: _timeoutSeconds));
      _logResponse('GET', url, response);
      await _saveCookiesFromResponse(url, response);
      return response;
    } finally {
      client.close();
    }
  }

  /// Generic POST request with automatic client cleanup, cookie support, and timeout
  static Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    bool allowSelfSigned = true,
  }) async {
    final client = createClient(allowSelfSigned: allowSelfSigned);
    try {
      final headersWithCookies = await _addCookiesToHeaders(url, headers);
      final response = await client
          .post(url, headers: headersWithCookies, body: body)
          .timeout(Duration(seconds: _timeoutSeconds));
      _logResponse('POST', url, response);
      await _saveCookiesFromResponse(url, response);
      return response;
    } finally {
      client.close();
    }
  }

  /// Generic PUT request with automatic client cleanup, cookie support, and timeout
  static Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    bool allowSelfSigned = true,
  }) async {
    final client = createClient(allowSelfSigned: allowSelfSigned);
    try {
      final headersWithCookies = await _addCookiesToHeaders(url, headers);
      final response = await client
          .put(url, headers: headersWithCookies, body: body)
          .timeout(Duration(seconds: _timeoutSeconds));
      _logResponse('PUT', url, response);
      await _saveCookiesFromResponse(url, response);
      return response;
    } finally {
      client.close();
    }
  }

  /// Generic DELETE request with automatic client cleanup, cookie support, and timeout
  static Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    bool allowSelfSigned = true,
  }) async {
    final client = createClient(allowSelfSigned: allowSelfSigned);
    try {
      final headersWithCookies = await _addCookiesToHeaders(url, headers);
      final response = await client
          .delete(url, headers: headersWithCookies, body: body)
          .timeout(Duration(seconds: _timeoutSeconds));
      _logResponse('DELETE', url, response);
      await _saveCookiesFromResponse(url, response);
      return response;
    } finally {
      client.close();
    }
  }

  /// Send a multipart request with automatic client cleanup and cookie support
  static Future<http.StreamedResponse> send(
    http.BaseRequest request, {
    bool allowSelfSigned = true,
  }) async {
    final client = createClient(allowSelfSigned: allowSelfSigned);
    try {
      // Add Tenant ID
      request.headers['x-tenant-id'] = ApiConfig.tenantId;
      print('🔑 Added x-tenant-id header to multipart request: ${ApiConfig.tenantId} for ${request.url.host}${request.url.path}');

      // Add cookies to multipart request
      if (_isInitialized && _cookieJar != null) {
        try {
          final cookies = await _cookieJar!.loadForRequest(request.url);
          if (cookies.isNotEmpty) {
            final cookieHeader = cookies.map((cookie) => '${cookie.name}=${cookie.value}').join('; ');
            request.headers['Cookie'] = cookieHeader;
          }
        } catch (e) {
          print('⚠️ Error loading cookies for multipart request: $e');
        }
      }
      
      final response = await client.send(request);
      
      // Save cookies from response headers
      if (_isInitialized && _cookieJar != null) {
        try {
          final setCookieHeader = response.headers['set-cookie'];
          final cookies = <Cookie>[];
          
          if (setCookieHeader != null && setCookieHeader.isNotEmpty) {
            final cookieStrings = _splitSetCookieHeaders(setCookieHeader);
            
            for (final cookieHeader in cookieStrings) {
              if (cookieHeader.trim().isNotEmpty) {
                final cookieParts = cookieHeader.trim().split(';');
                if (cookieParts.isNotEmpty) {
                  final nameValue = cookieParts[0].trim().split('=');
                  if (nameValue.length == 2) {
                    final cookie = Cookie(nameValue[0].trim(), nameValue[1].trim());
                    cookies.add(cookie);
                  }
                }
              }
            }
          }
          
          if (cookies.isNotEmpty) {
            await _cookieJar!.saveFromResponse(request.url, cookies);
            print('✅ Saved ${cookies.length} cookie(s) from multipart response');
          }
        } catch (e) {
          print('⚠️ Error saving cookies from multipart response: $e');
        }
      }
      
      return response;
    } finally {
      client.close();
    }
  }
}
