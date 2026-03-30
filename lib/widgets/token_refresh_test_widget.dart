import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/teacher_service.dart';
import '../services/statistics_service.dart';
import '../config/api_config.dart';
import '../utils/http_client_helper.dart';
import 'dart:convert';

/// Widget for testing token refresh mechanism
/// Add this to your debug menu or profile screen
class TokenRefreshTestWidget extends StatefulWidget {
  const TokenRefreshTestWidget({super.key});

  @override
  State<TokenRefreshTestWidget> createState() => _TokenRefreshTestWidgetState();
}

class _TokenRefreshTestWidgetState extends State<TokenRefreshTestWidget> {
  String _status = 'Ready to test';
  bool _isTesting = false;
  String? _tokenInfo;
  String? _cookieInfo;

  @override
  void initState() {
    super.initState();
    _loadTokenInfo();
    _loadCookieInfo();
  }

  Future<void> _loadTokenInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(ApiConfig.tokenKey);
      
      if (token != null) {
        // Decode JWT to get expiration
        final parts = token.split('.');
        if (parts.length == 3) {
          try {
            String payload = parts[1];
            // Add padding
            switch (payload.length % 4) {
              case 1:
                payload += '===';
                break;
              case 2:
                payload += '==';
                break;
              case 3:
                payload += '=';
                break;
            }
            
            final decoded = base64Url.decode(payload);
            final json = jsonDecode(utf8.decode(decoded));
            final exp = json['exp'] as int?;
            
            if (exp != null) {
              final expirationDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
              final now = DateTime.now();
              final isExpired = expirationDate.isBefore(now);
              final timeLeft = expirationDate.difference(now);
              
              setState(() {
                _tokenInfo = '''
Token Length: ${token.length} chars
Expiration: ${expirationDate.toString()}
Status: ${isExpired ? '❌ EXPIRED' : '✅ Valid'}
Time Left: ${isExpired ? 'Expired ${timeLeft.abs().inMinutes} minutes ago' : '${timeLeft.inMinutes} minutes'}
''';
              });
            }
          } catch (e) {
            setState(() {
              _tokenInfo = 'Token exists but could not decode: $e';
            });
          }
        }
      } else {
        setState(() {
          _tokenInfo = 'No token found';
        });
      }
    } catch (e) {
      setState(() {
        _tokenInfo = 'Error loading token: $e';
      });
    }
  }

  Future<void> _loadCookieInfo() async {
    try {
      final cookieJar = HttpClientHelper.cookieJar;
      final url = Uri.parse(ApiConfig.refreshTokenUrl);
      final cookies = await cookieJar.loadForRequest(url);
      
      if (cookies.isNotEmpty) {
        final cookie = cookies.firstWhere(
          (c) => c.name.toLowerCase() == 'refreshtoken',
          orElse: () => cookies.first,
        );
        
        setState(() {
          _cookieInfo = '''
Cookie Name: ${cookie.name}
Domain: ${cookie.domain ?? 'null'}
Path: ${cookie.path ?? 'null'}
HttpOnly: ${cookie.httpOnly}
Secure: ${cookie.secure}
Value Length: ${cookie.value.length} chars
Value Preview: ${cookie.value.length > 30 ? '${cookie.value.substring(0, 30)}...' : cookie.value}
''';
        });
      } else {
        setState(() {
          _cookieInfo = 'No cookies found for refresh token endpoint';
        });
      }
    } catch (e) {
      setState(() {
        _cookieInfo = 'Error loading cookies: $e';
      });
    }
  }

  Future<void> _testTokenRefresh() async {
    setState(() {
      _isTesting = true;
      _status = 'Testing token refresh...';
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Step 1: Invalidate the current token
      setState(() {
        _status = 'Step 1: Invalidating current token...';
      });
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(ApiConfig.tokenKey, 'invalid_token_for_testing');
      // Force reload to pick up the invalid token
      await authService.init();
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Step 2: Make an API request that should trigger refresh
      setState(() {
        _status = 'Step 2: Making API request with invalid token...';
      });
      
      final token = authService.token ?? 'invalid_token';
      final response = await TeacherService.getStudentTeachers(
        token: token,
        authService: authService,
      );
      
      if (response != null) {
        setState(() {
          _status = '✅ SUCCESS! Token refresh worked!\nResponse received with ${response.teachers.length} teachers';
        });
      } else {
        setState(() {
          _status = '❌ FAILED! Token refresh did not work.\nCheck logs for details.';
        });
      }
      
      // Reload token info
      await _loadTokenInfo();
      await _loadCookieInfo();
      
    } catch (e) {
      setState(() {
        _status = '❌ ERROR: $e';
      });
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  Future<void> _testManualRefresh() async {
    setState(() {
      _isTesting = true;
      _status = 'Manually refreshing token...';
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final error = await authService.refreshToken();
      
      if (error == null) {
        setState(() {
          _status = '✅ SUCCESS! Token refreshed manually';
        });
        await _loadTokenInfo();
        await _loadCookieInfo();
      } else {
        setState(() {
          _status = '❌ FAILED: $error';
        });
      }
    } catch (e) {
      setState(() {
        _status = '❌ ERROR: $e';
      });
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Token Refresh Test'),
        backgroundColor: const Color(0xFF38026B),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              color: _status.contains('✅') 
                  ? Colors.green[50] 
                  : _status.contains('❌') 
                      ? Colors.red[50] 
                      : Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _status,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Token Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Token Info',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _tokenInfo ?? 'Loading...',
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Cookie Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Refresh Token Cookie Info',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _cookieInfo ?? 'Loading...',
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Test Buttons
            ElevatedButton.icon(
              onPressed: _isTesting ? null : _testTokenRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Test Automatic Token Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF38026B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            
            const SizedBox(height: 12),
            
            ElevatedButton.icon(
              onPressed: _isTesting ? null : _testManualRefresh,
              icon: const Icon(Icons.sync),
              label: const Text('Test Manual Token Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            
            const SizedBox(height: 12),
            
            OutlinedButton.icon(
              onPressed: () {
                _loadTokenInfo();
                _loadCookieInfo();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh Info'),
            ),
            
            const SizedBox(height: 24),
            
            // Instructions
            Card(
              color: Colors.grey[100],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'How to Test',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Click "Test Automatic Token Refresh" to simulate a 401 error and test automatic refresh\n\n'
                      '2. Click "Test Manual Token Refresh" to manually trigger token refresh\n\n'
                      '3. Watch the logs in your console for detailed information\n\n'
                      '4. Check the status above to see if the test passed',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

